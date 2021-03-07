using Pkg, Sockets, Serialization, Logging

import Base.Threads.@spawn

# both this script and the symbol server is going to use this shared environment
Pkg.activate("linter-julia", shared=true)

### variables ###

# packages needed and minimum versions
needed_packages = Dict(
    "StaticLint" => v"7.0.0",
    "SymbolServer" => v"6.0.1",
    "CSTParser" => v"3.1.0",
    "JSON" => v"0.21.1"
)

@inline function withtrace(e, msg=nothing)
    buffer = IOBuffer();
    if !isnothing(msg)
        println(buffer, msg)
    end
    println(buffer, e)
    st = stacktrace(catch_backtrace());
    for (idx, l) in enumerate(st)
        println(buffer, " [$idx] $l")
    end
    return(String(take!(buffer)))
end

# if you know a better way of getting the default Julia environment, please tell ...
const julia_exec = joinpath(Sys.BINDIR, Base.julia_exename())
const default_env = strip(read(`$julia_exec --startup-file=no -e "using Pkg; println(dirname(Pkg.project().path))"`, String))
const store_location = dirname(Pkg.project().path)
const port = ARGS[1]
const atom_pid = parse(Int32, split(port,"_")[end])

if ispath(port)
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

### environment set-up ###

# check if the necessary packages are correctly installed

installed_packages = Dict(pkg.name=>pkg.version for pkg in values(Pkg.dependencies()) if pkg.is_direct_dep == true )

for (pkg, minver) in needed_packages
    try
        if !(pkg in keys(installed_packages))
            @info "installing $pkg"
            Pkg.add(pkg)
        elseif installed_packages[pkg] < minver
            @info "updating $pkg"
            Pkg.update(pkg)
        end
    catch err
        @error withtrace(err, "something went wrong while installing $pkg")
        rethrow()
    end
end

# load the packages here

using StaticLint, SymbolServer, CSTParser, JSON

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
    # generation message sent
    msgsent::Bool
end

### variables ###

# this maps environments to symbol servers
symbolservers = Dict{AbstractString, SSData}()
server_queue = Channel(Inf)

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
        @warn "error while getting environment of file: $fname"
    end

    # return the default environment
    return default_env

end

function exit_if_atom_dies()

    while true
        if !Sys.iswindows()
            if ccall(:kill, Int32, (Int32, Int32), atom_pid, 0) != 0
                exit()
            end
        else
            # need to find a way to get test pids on Windows ...
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
        @warn "error while getting package root of env: $env"
    end

    return nothing

end

function generate_messages( fname::AbstractString, code::AbstractString, env::AbstractString, ss )::Vector{LintMsg}

    if isnothing(ss.server)
        if ss.msgsent == false
            ss.msgsent = true
            @debug "waiting message generated for $fname"
            return [ LintMsg(fname, "$env", "I000", "info", 1, 1) ]
        else
            return []
        end
    end

    rootfile = guess_package_root(env)
    if isnothing(rootfile)
        rootfile = fname
    end

    # lock server
    take!(ss.available)

    # this is a hack from StaticLint.lint_file() and lint_string()

    empty!(ss.server.files)
    root = StaticLint.loadfile(ss.server, rootfile)
    StaticLint.semantic_pass(root)
    buffer = StaticLint.File(fname, code, CSTParser.parse(code, true), root, ss.server)
    StaticLint.setfile(ss.server, fname, buffer)
    StaticLint.semantic_pass(buffer)
    for (p,f) in ss.server.files
        StaticLint.check_all(f.cst, StaticLint.LintOptions(), ss.server)
    end

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
            elseif CSTParser.headof(x) === :errortoken
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

    @debug "hints generated for $fname: $msgs"

    return msgs

end

function generate_symbolserver(ch, env::AbstractString)

    server = StaticLint.setup_server( env )
    put!(ch, (env, server))

end

function find_line_column(io::IOBuffer, position::Int64)

    line = 1
    column = 1

    try
        before = read(io, position)
        line = count(x -> x == UInt8('\n'), before) + 1
        prevreturn = findprev( x -> x == UInt8('\n'), before, length(before) )
        column = isnothing(prevreturn) ? position : position - prevreturn
    catch err
        @error withtrace(err, "error while determining line and column for position $position")
    end

    return line, column
end

function find_line_column_file(fname::AbstractString, position::Int64)
    open(fname, "r") do io
        return find_line_column(io, position)
    end
end

function find_line_column_string(str::AbstractString, position::Int64)
    return find_line_column(IOBuffer(str), position)
end

function convertmsgtojson(msgs, code)
    output = Any[]
    for msg in msgs

        # determine line and column from the file
        @assert msg.startpos <= msg.endpos
        startline, startcolumn = find_line_column_string(code, msg.startpos)
        endline, endcolumn = find_line_column_string(code, msg.endpos)

        if startline > endline
            endline = startline
            @warn "start line is smaller than end line"
        end
        if startline == endline && startcolumn > endcolumn
            startcolumn = endcolumn
            @warn "start column is smaller than end column"
        end

        # Atom index starts from zero thus minus one
        errorrange = Array[[startline-1, startcolumn], [endline-1, endcolumn]]

        push!(output, Dict( "severity" => msg.severity,
                            "location" => Dict("file" => msg.filename,
                                                "position" => errorrange),
                            "excerpt" => msg.message,
                            "description" => msg.code) )

    end
    return output
end

function filtermsgs(msgs, data)
    if haskey(data,"ignore_warnings")
        if data["ignore_warnings"]
            msgs = filter(i -> i.severity != "warning", msgs)
        end
    end
    if haskey(data,"ignore_info")
        if data["ignore_info"]
            msgs = filter(i -> i.severity != "info", msgs)
        end
    end
    if haskey(data,"ignore_codes")
        msgs = filter(i -> !(i.code in data["ignore_codes"]), msgs)
    end

    return msgs
end

function handle_connection(conn)

    global symbolservers, server_queue

    try

        # insert waiting servers
        while isready(server_queue)
            # there might be a race condition lurking around right here,
            # but this is light without a yield, and we do not use threading here
            senv, server = take!(server_queue)
            symbolservers[senv].server = server
            @info "added server for $senv"
        end

        data = JSON.parse(conn)
        fname = data["file"]

        @debug "request for file : $fname"

        # determine the environment
        env = guess_environment(fname)

        # check mtime of Project.toml and Manifest.toml
        project_mtime = isfile(joinpath(env, "Project.toml")) ? stat( joinpath(env, "Project.toml") ).mtime : nothing
        manifest_mtime = isfile(joinpath(env, "Manifest.toml")) ? stat( joinpath(env, "Manifest.toml") ).mtime : nothing

        # build symbol server if needed
        if !(env in keys(symbolservers)) || symbolservers[env].project_mtime != project_mtime || symbolservers[env].manifest_mtime != manifest_mtime
            @debug "launching server generation for $env"
            symbolservers[env] = SSData(nothing, project_mtime, manifest_mtime, Channel{Bool}(1), false)
            put!(symbolservers[env].available, true)
            @spawn generate_symbolserver(server_queue, env)
        end

        msgs = generate_messages( fname, data["code_str"], env, symbolservers[env] )

        msgs = filtermsgs(msgs, data)
        out = convertmsgtojson(msgs, data["code_str"])
        JSON.print(conn, out)

        @debug "symbolservers: " [ (k, !isnothing(v.server)) for (k,v) in symbolservers ]

        flush(logger)

    catch err
        @error withtrace(err, "connection ended with error")
    finally
        close(conn)
    end

end

### main script starts here ###

@spawn exit_if_atom_dies()

try
    server = listen(port)

    # # this is looping until Atom dies
    while true
        conn = accept(server)
        @async handle_connection(conn)
    end

finally
    close(server)
end
