using Lint

named_pipe = ARGS[1]
notinstalled = Pkg.installed("Lint") == nothing

if notinstalled
    print(STDERR, "linter-julia-installing-lint")
    try
        Pkg.add("Lint")
    catch
        print(STDERR, "linter-julia-msg-install")
        rethrow()
    end
else
    if Pkg.installed("Lint") < v"0.3.0"
        print(STDERR, "linter-julia-updating-lint")
        try
            Pkg.update("Lint")
        catch
            print(STDERR, "linter-julia-msg-update")
            rethrow()
        end
    else # start the server
        try
            lintserver(named_pipe,"standard-linter-v1")
        catch
            print(STDERR, "linter-julia-msg-load")
            rethrow()
        end
    end
end
