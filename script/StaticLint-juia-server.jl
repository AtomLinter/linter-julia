cd(@__DIR__)

using Pkg;
Pkg.activate(joinpath(pwd(),"StaticLintAtom"))
Pkg.instantiate()
