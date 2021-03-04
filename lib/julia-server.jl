using Pkg, Sockets, Serialization

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

# use the environment folder as a canonical location for sharing information for each julia-server.jl instances
# (this also achieves that multiple Atom instances can use the same symbol server for this user)

const symbolserver_script = joinpath( dirname(@__FILE__), "julia-symbolserver.jl" )
const store_location = dirname(Pkg.project().path)
const julia_exec = joinpath(Sys.BINDIR, Base.julia_exename())
# we need to find a way to get parent pid on Windows ...
const atom_pid = Sys.iswindows() ? 0 : ccall(:getppid, Int32, ())
const sspipe = Sys.iswindows() ? "\\\\.\\pipe\\" * "ss.pipe." * string(atom_pid) : joinpath(store_location, "ss.pipe." * string(atom_pid) )
const port = ARGS[1]
const startlockfile = joinpath( store_location, "serverstart.lock." * string(atom_pid))

# set this to true to get more output from the symbol server
const debugserver = false

### types ###

struct LintMsg
    filename::String
    message::String
    code::String
    severity::String
    startpos::Int64
    endpos::Int64
end

### functions ###

function find_line_column(fname::AbstractString, position::Int64)

    line = 1
    column = 1

    try
        open(fname, "r") do io
            before = read(io, position)
            line = count(x -> x == UInt8('\n'), before) + 1
            prevreturn = findprev( x -> x == UInt8('\n'), before, length(before) )
            column = isnothing(prevreturn) ? position : position - prevreturn
        end
    catch e
        print(stderr, "error $e while determining line and column in file $fname for position $position")
    end

    return line, column
end

function convertmsgtojson(msgs)
    output = Any[]
    for msg in msgs

        # determine line and column from the file
        @assert msg.startpos <= msg.endpos
        startline, startcolumn = find_line_column(msg.filename, msg.startpos)
        endline, endcolumn = find_line_column(msg.filename, msg.endpos)

        if startline > endline
            endline = startline
            print(stderr, "start line is smaller than end line")
        end
        if startline == endline && startcolumn > endcolumn
            startcolumn = endcolumn
            print(stderr, "start column is smaller than end column")
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

function filtermsgs(msgs, dict_data)
    if haskey(dict_data,"ignore_warnings")
        if dict_data["ignore_warnings"]
            msgs = filter(i -> i.severity != "warning", msgs)
        end
    end
    if haskey(dict_data,"ignore_info")
        if dict_data["ignore_info"]
            msgs = filter(i -> i.severity != "info", msgs)
        end
    end
    if haskey(dict_data,"ignore_codes")
        msgs = filter(i -> !(i.code in dict_data["ignore_codes"]), msgs)
    end

    return msgs
end

# relay the request to the symbol server
function handle_connection(conn)

    try

        dict_data = JSON.parse(conn)
        ss_conn = connect(sspipe)
        println( ss_conn, dict_data["file"] )
        # register our pid - we need this as Atom sometimes does not kill us properly
        println( ss_conn, getpid() )
        msgs = deserialize(ss_conn)
        msgs = filtermsgs(msgs, dict_data)
        out = convertmsgtojson(msgs)
        JSON.print(conn, out)
        close(ss_conn)

    catch err
        println(stderr, "connection ended with error $err")
    finally
        close(conn)
    end

end

### main script starts here ###

# check if the necessary packages are correctly installed

installed_packages = Dict(pkg.name=>pkg.version for pkg in values(Pkg.dependencies()) if pkg.is_direct_dep == true )

for (pkg, minver) in needed_packages
    try
        if !(pkg in keys(installed_packages))
            print(stderr, "linter-julia-installing-" * pkg)
            Pkg.add(pkg)
        elseif installed_packages[pkg] < minver
            print(stderr, "linter-julia-updating-" * pkg)
            Pkg.update(pkg)
        end
    catch
        print(stderr, "linter-julia-msg-installorupdate")
        rethrow()
    end
end

using JSON

try

    # launch the connection to Atom
    server = listen(port)

    # Atom may start a lot of servers. Spread out initial launches a bit, so they do not compete on the SS
    sleep(rand())

    # launch the single symbol server

    while !ispath(sspipe)

        if !isfile(startlockfile)
            touch( startlockfile )

            # (re)launch the symbol server
            print(stdout, "starting the symbol server ...")

            myenv = copy(ENV)
            if debugserver
                myenv["JULIA_DEBUG"] = "Main"
            end

            run( Cmd(`$julia_exec -t 3 --startup-file=no --project=$store_location $symbolserver_script $sspipe $atom_pid $startlockfile`, detach=true, env=myenv), wait=false )
        end
        # start the server only after it pipe is up
        sleep(5)
    end

    # this is important: the js side starts sending upon this string
    println(stdout, "Server running on port/pipe $port ...")

    # this is looping until a SIGTERM is received from Atom
    while true
        conn = accept(server)
        @async handle_connection(conn)
    end

finally
    close(server)
end
