# linter-julia
==============

This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides
an interface to [Lint.jl](https://github.com/tonyhffong/Lint.jl). It will be
used with files that have the “Julia” syntax.

![screenshot](https://raw.githubusercontent.com/TeroFrondelius/linter-julia/master/Screenshot.gif)

## Installation
Install package through Atom or use CLI:

```bash
$ apm install linter-julia
```

In order to use this package, you will need to install Julia and Lint.jl
(version 0.2.6 or higher).
To get Julia see: http://julialang.org/downloads/ and to get Lint.jl
see: https://github.com/tonyhffong/Lint.jl#installation


Before [Lint.jl version 0.2.6 is released](https://github.com/tonyhffong/Lint.jl/releases),
you will need to do `Pkg.checkout("Lint")` after `Pkg.add("Lint")` command.
This will use the latest development version of the Lint.jl package.
After the version 0.2.6 is realeased, you can do `Pkg.free("Lint")`.


## Features
* By default linter-julia uses Juno's julia
* User can give path to the julia, which they want to use for Linting
* Ignore the messages you don't need


[Issues](https://github.com/TeroFrondelius/linter-julia.jl/issues) and [pull requests]
(https://github.com/TeroFrondelius/linter-julia.jl/pulls) are welcome.
