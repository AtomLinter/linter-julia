cd(@__DIR__)

using Pkg;
Pkg.activate(joinpath(pwd(),"StaticLintAtom"))
Pkg.instantiate()

# using StaticLintAtom
# include(joinpath(pwd(),"StaticLintAtom","src","StaticLintAtom.jl"))

using LanguageServer
using SymbolServer

# named_pipe = ARGS[1] # julia.exe path
named_pipe = "C:\\Users\\yahyaaba\\.julia\\environments\\v1.3"

server = LanguageServerInstance(stdin, stdout, true, named_pipe, "", Dict())
run(server)
