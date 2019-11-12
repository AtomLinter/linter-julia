using Pkg;

LanguageServerPkg = PackageSpec(url="https://github.com/julia-vscode/LanguageServer.jl", rev="master");
SymbolServerPkg = PackageSpec(url="https://github.com/julia-vscode/SymbolServer.jl", rev="master");
StaticLintPkg = PackageSpec(url="https://github.com/julia-vscode/StaticLint.jl", rev="master");

named_pipe = ARGS[1]

if get(Pkg.installed(), "Lint", nothing) == nothing == nothing
    print(Base.stderr, "linter-julia-installing-lint");
    try
        Pkg.add(LanguageServerPkg);
        Pkg.add(SymbolServerPkg);
        Pkg.add(StaticLintPkg);

    catch
        print(Base.stderr, "linter-julia-msg-install");
        rethrow();
    end
else
    verLanguageServer = get(Pkg.installed(), "LanguageServer", nothing)
    verSymbolServer = get(Pkg.installed(), "SymbolServer", nothing)
    verStaticLint = get(Pkg.installed(), "StaticLint", nothing)

    if  verLanguageServer < v"1.0.0"
        print(Base.stderr, "linter-julia-updating-lint");
        try
            Pkg.update(LanguageServerPkg);
            Pkg.update(SymbolServerPkg);
            Pkg.update(StaticLintPkg);

        catch
            print(Base.stderr, "linter-julia-msg-update");
            rethrow();
        end
    else # start the server
        try
            using LanguageServer
            using SymbolServer

            server = LanguageServerInstance(stdin, stdout, true, expanduser("~/.julia/environments/v1.0"), "", Dict())
            run(server)
        catch
            print(Base.stderr, "linter-julia-msg-load");
            rethrow();
        end
    end
end
