cd(@__DIR__)

using Pkg;
Pkg.activate(joinpath(pwd(),"StaticLintAtom"))
Pkg.instantiate()

using StaticLintAtom

include(joinpath(pwd(),"StaticLintAtom","src","StaticLintAtom.jl"))
