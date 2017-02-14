# linter-julia
=========================

This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides
an interface to [Lint.jl](https://github.com/tonyhffong/Lint.jl). It will be
used with files that have the “Julia” syntax.

![screenshot](Screenshot.gif)

## Installation
In order to use this package, you will need to start the lintserver, with
following command:
```bash
julia -e "using Lint; lintserver(2223)"
```
To get Julia see: http://julialang.org/downloads/ and to get Lint.jl
see: https://github.com/tonyhffong/Lint.jl#installation
