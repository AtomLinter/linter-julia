# linter-julia

This linter plugin for [AtomLinter](https://atomlinter.github.io/)
provides an interface to [Lint.jl](https://github.com/tonyhffong/Lint.jl).
It will be used with files that have the `Julia` syntax.

![screenshot](https://raw.githubusercontent.com/TeroFrondelius/linter-julia/master/Screenshot.gif)

## Installation

Install the package through Atom's UI, or use the `apm` tool in the CLI:

```bash
$ apm install linter-julia
```

Note: if you have't installed [Juno](http://junolab.org/),
you need to tell linter-julia where to find the julia executable
(i.e. `/usr/bin/julia`). See Settings below.

In order to use this package, you will need to install Julia and Lint.jl
(version 0.2.6 or higher).
To get Julia see: http://julialang.org/downloads/ and to get Lint.jl
see: https://github.com/tonyhffong/Lint.jl#installation

Before [Lint.jl version 0.2.6 is released](https://github.com/tonyhffong/Lint.jl/releases),
you will need to do `Pkg.checkout("Lint")` after `Pkg.add("Lint")` command.
This will use the latest development version of the Lint.jl package.
After the version 0.2.6 is realeased, you can do `Pkg.free("Lint")`.

## Settings

![screenshot](https://raw.githubusercontent.com/TeroFrondelius/linter-julia/master/settings.png)

## Features

* By default linter-julia uses Juno's `julia`
* You can give a path to the `julia` executable that you want to use for Linting
* You can ignore the messages you don't need

[Issues](https://github.com/TeroFrondelius/linter-julia/issues) and [pull requests]
(https://github.com/TeroFrondelius/linter-julia/pulls) are welcome.

## CHANGELOG

[See the full CHANGELOG here.](https://github.com/TeroFrondelius/linter-julia/blob/master/CHANGELOG.md)
