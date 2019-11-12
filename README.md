# linter-julia

This linter plugin for [AtomLinter](https://atomlinter.github.io/)
provides an interface to [Lint.jl](https://github.com/tonyhffong/Lint.jl).
It will be used with files that have the `Julia` syntax.

![screenshot](https://raw.githubusercontent.com/AtomLinter/linter-julia/master/Screenshot.gif)

## Installation

- Install the package through Atom's UI and install the package.

You can also use the `apm` tool in the CLI:
```bash
$ apm install linter-julia
```

- You need to tell linter-julia where to find the julia executable
(i.e. `/usr/bin/julia` or `C:\Julia-1.3.0-rc4\bin\julia.exe`). See Settings below.

- This package installs the master branch of Lint.jl automatically, to make it activated just restart Atom one more time! (two time total)


- Note: if you have't installed [Juno](http://junolab.org/), and [Julia]( http://julialang.org/downloads/)

- Note: If after two restarts the linter didn't work, add the Lint.jl manually:
```julia
] add https://github.com/tonyhffong/Lint.jl
```

## Settings

![screenshot](https://raw.githubusercontent.com/AtomLinter/linter-julia/master/settings.png)

## Features

* By default linter-julia uses Juno's `julia`
* You can give a path to the `julia` executable that you want to use for Linting
* You can ignore the messages you don't need

[Issues](https://github.com/AtomLinter/linter-julia/issues) and [pull requests](https://github.com/AtomLinter/linter-julia/pulls) are welcome.

## CHANGELOG

[See the full CHANGELOG here.](https://github.com/AtomLinter/linter-julia/blob/master/CHANGELOG.md)

## Development
Install Atom, then:
```bash
$ apm dev linter-julia
```
Inside the project in Atom:
-  Press Ctrl-Shift-P to open the Command Palette.
-  Type updu which should select Update Package Dependencies: Update
-  Press Enter
