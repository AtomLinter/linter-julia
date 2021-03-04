# linter-julia

This linter plugin for [AtomLinter](https://atomlinter.github.io/)
provides an interface to [StaticLint.jl](https://github.com/julia-vscode/StaticLint.jl).
It will be used with files that have the `Julia` syntax.

This is a fork that replaces Lint.jl with StaticLint.jl from the Julia VSCode plugin.
It seems to work for me, but consider this an alpha code.

![screenshot](https://raw.githubusercontent.com/takbal/linter-julia/master/Screenshot.gif)

## Developed on

* julia-1.5.3
* ubuntu 18.04
* [linter-ui-default](https://atom.io/packages/linter-ui-default)
* [linter](https://atom.io/packages/linter)
* [atom-ide-ui](https://atom.io/packages/atom-ide-ui) (with diagnostics disabled)

## Caveats

* The server needs a few minutes to parse new Julia environments that this Atom instance have not seen before.
  There is no feedback given on this process yet. Please be patient when opening a new project, or starting the editor the first time.
* The file you are linting must be either 1) included from the project root file, or 2) should not be in a directory that has a
Project.toml in any of its parents.
* It only considers files that are on the disk. You need to save all files in order to lint them correctly.
* Linting seems to be triggered only when saving or opening files. To re-lint, you need to save the file again.
* The symbols are rebuilt if the modification time of the Project.toml or the Manifest.toml files change, for example,
you add, remove or update packages. Linting is not available during this rebuild.
* It works on Windows, but does not shuts down correctly.

## Internals

Only the Julia server code was changed - I know nothing of Atom development or js. Something is wrong there, as Atom seems to be
erratic in launching and shutting down server processes. Therefore, the symbol server process registers pids of servers,
and kills them on shutdown. This does not work on Windows yet.

The code generates its private shared environment at the Julia depot in environments/linter-julia, installs its
dependencies there, and also places files there, the symbol server log in particular.

A separate process builds SymbolServers for each environment detected. Detection works by walking
upwards in the path and looking for Project.toml. The project's root file is then looked for at
the canonical X/src/X.jl etc. locations. If no root is detected, the file becomes the root. If no
environment found, the default environment is used.

## Installation

- Install the package through Atom's UI. You can also use the `apm` tool in the CLI:
```bash
$ apm install linter-julia
```

- You need to tell linter-julia where to find the julia executable
(i.e. `/usr/bin/julia` or `C:\Julia-1.5.3\bin\julia.exe`). See Settings below.

## Settings

![screenshot](https://raw.githubusercontent.com/AtomLinter/linter-julia/master/settings.png)

## Features

* By default linter-julia uses Juno's `julia`
* You can give a path to the `julia` executable that you want to use for Linting
* You can set to ignore the messages you don't need

[Issues](https://github.com/AtomLinter/linter-julia/issues) and [pull requests]
(https://github.com/AtomLinter/linter-julia/pulls) are welcome.

## CHANGELOG

[See the full CHANGELOG here.](https://github.com/AtomLinter/linter-julia/blob/master/CHANGELOG.md)
