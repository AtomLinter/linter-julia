using Pkg, Logging, StaticLint, SymbolServer, JSON, Sockets, Serialization

import Base.Threads.@spawn

### consts ###

const julia_exec = joinpath(Sys.BINDIR, Base.julia_exename())
const default_env = strip(read(`$julia_exec --startup-file=no -e "using Pkg; println(dirname(Pkg.project().path))"`, String))
const store_location = dirname(Pkg.project().path)
const sspipe = ARGS[1]
const atom_pid = parse(Int32, ARGS[2])
const startlockfile = ARGS[3]
# list of hints that are going to be classified as "info"
const infohints = [ StaticLint.ConstIfCondition, StaticLint.PointlessOR, StaticLint.PointlessAND,
    StaticLint.UnusedBinding, StaticLint.UnusedTypeParameter, StaticLint.TypePiracy,
    StaticLint.UnusedFunctionArgument, StaticLint.NotEqDef, StaticLint.InappropriateUseOfLiteral  ]

### types ###

struct LintMsg
    filename::String
    message::String
    code::String
    severity::String
    startpos::Int64
    endpos::Int64
end

mutable struct SSData
    server::Union{StaticLint.FileServer, Nothing}
    project_mtime::Union{Float64,Nothing}
    manifest_mtime::Union{Float64,Nothing}
    # lock mechanism
    available::Channel{Bool}
end

### variables ###

# this maps environments to symbol servers
symbolservers = Dict{AbstractString, SSData}()
server_queue = Channel(Inf)
processes = Int32[]

### functions ###

"""
    guess_environment(fname::AbstractString)::AbstractString

Guesses the most likely environment path for a .jl file.
If no Project.toml is found in parents, the default environment is returned.
"""
function guess_environment(fname::AbstractString)::AbstractString

    try
        fname = realpath(fname)
        actdir = dirname(fname)

        while length(splitpath(actdir)) != 1
            act_candidate = joinpath(actdir, "Project.toml")
            if isfile(act_candidate)
                return dirname(act_candidate)
            end
            actdir = dirname(actdir)
        end
    catch e
        @warn "error while getting environment of file: $fname" exception=(e, catch_backtrace())
    end

    # return the default environment
    return default_env

end

function exit_if_atom_dies()

    global processes

    while true
        if ccall(:kill, Int32, (Int32, Int32), atom_pid, 0) != 0
            # kill all processes still running (Atom kills them erratically)
            for p in processes
                if ccall(:kill, Int32, (Int32, Int32), p, 0) == 0
                    ccall(:kill, Int32, (Int32, Int32), p, 8)
                end
            end
            exit()
        end
        sleep(5)
    end
end

"""
    guess_package_root(environment::AbstractString)::Union{AbstractString,nothing}

Guesses the most likely root for a package.
Can return nothing if a likely candidate is not found.
"""
function guess_package_root(env::AbstractString)::Union{AbstractString,Nothing}

    try
        # guess a project name first
        have_name = false
        if isfile( joinpath(env, "Project.toml") )
            projectdef = Pkg.TOML.parsefile( joinpath(env, "Project.toml") )
            if "name" in keys(projectdef)
                projectname = projectdef["name"]
                have_name = true
            end
        end
        if !have_name
            projectname = splitext(basename(env))[1]
        end

        candidates = [
            joinpath(env, "src", projectname * ".jl"),
            joinpath(env, projectname * ".jl")
        ]

        for c in candidates
            if isfile(c)
                return c
            end
        end

    catch e
        @warn "error while getting package root of env: $env" exception=(e, catch_backtrace())
    end

    return nothing

end

function generate_messages( fname::AbstractString, env::AbstractString, ss )::Vector{LintMsg}

    if isnothing(ss.server)
        @debug "waiting message generated for $fname"
        # return [ LintMsg(fname, "generating symbols for environment $env, please refresh later ...", "I000", "info", 1, 1) ]
        # it is annoying to have this info at start on all files, so just turn it off
        return []
    end

    rootfile = guess_package_root(env)
    if isnothing(rootfile)
        rootfile = fname
    end

    # lock server
    take!(ss.available)

    # This changes the server! lint_file should definitely have ! in its name ...
    StaticLint.lint_file(rootfile, ss.server)

    msgs = LintMsg[]

    for (path, file) in ss.server.files
        # skip hints unrelated to this file
        if path != fname
            continue
        end
        act_hints = StaticLint.collect_hints(file.cst, ss.server)
        for (offset, x) in act_hints
            if StaticLint.haserror(x)
                msg = StaticLint.LintCodeDescriptions[x.meta.error]
                if x.meta.error in infohints
                    code = "I"*string(Int32(x.meta.error), pad=3)
                    severity = "info"
                else
                    code = "W"*string(Int32(x.meta.error), pad=3)
                    severity = "warning"
                end
            elseif StaticLint.headof(x) === :errortoken
                msg = "Parsing error"
                code = "E000"
                severity = "error"
            else
                msg = "Missing reference"
                code = "W000"
                severity = "warning"
            end
            push!( msgs, LintMsg(path, msg, code, severity, offset, offset + x.fullspan) )
        end
    end

    # enable the server for other threads
    put!(ss.available, true)

    @debug "hints generated for $fname: " msgs

    return msgs

end

function generate_symbolserver(ch, env::AbstractString)

    server = StaticLint.setup_server( env )
    put!(ch, (env, server))

end

function handle_connection(conn)

    global symbolservers, server_queue, processes

    fname = readline(conn)
    process = parse(Int32, readline(conn))

    # insert new processes - we need this as Atom does not kill them properly
    if !(process in processes)
        push!(processes, process)
    end

    # insert waiting servers
    while isready(server_queue)
        # there might be a race condition lurking around right here,
        # but this is light without a yield, and we do not use threading here
        senv, server = take!(server_queue)
        symbolservers[senv].server = server
        @info "added server for $senv"
    end

    @debug "request for file $fname"

    # determine the environment
    env = guess_environment(fname)

    # check mtime of Project.toml and Manifest.toml
    project_mtime = isfile(joinpath(env, "Project.toml")) ? stat( joinpath(env, "Project.toml") ).mtime : nothing
    manifest_mtime = isfile(joinpath(env, "Manifest.toml")) ? stat( joinpath(env, "Manifest.toml") ).mtime : nothing

    # build symbol server if needed
    if !(env in keys(symbolservers)) || symbolservers[env].project_mtime != project_mtime || symbolservers[env].manifest_mtime != manifest_mtime
        @debug "launching server generation for $env"
        symbolservers[env] = SSData(nothing, project_mtime, manifest_mtime, Channel{Bool}(1))
        put!(symbolservers[env].available, true)
        @spawn generate_symbolserver(server_queue, env)
    end

    msgs = generate_messages( fname, env, symbolservers[env] )

    # send messages
    serialize(conn, msgs)

    @debug "symbolservers: " [ (k, !isnothing(v.server)) for (k,v) in symbolservers ]

    flush(logger)

end

### main script starts here ###

if ispath(sspipe)
    # if another is already set up, just finish quietly
    exit()
end

# remove previous logs
logs = readdir(store_location, join = true)
for f in logs
    if basename(splitext(f)[1]) == "symbolserver.log"
        rm(f)
    end
end

logger = open(joinpath(store_location, "symbolserver.log." * string(atom_pid)), "w")

global_logger( SimpleLogger(logger) )

@spawn exit_if_atom_dies()

try

    server = listen(sspipe)
    @info "symbol server started"

    rm(startlockfile)

    # this is looping until Atom dies
    while true
        conn = accept(server)
        @async try
            handle_connection(conn)
        catch e
            @error "error while handling connection: " exception=(e, catch_backtrace())
            rethrow()
        finally
            close(conn)
        end
    end

catch e
    @error "error in server loop: " exception=(e, catch_backtrace())
    rethrow()
finally
    close(server)
end
