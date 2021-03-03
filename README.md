# linter-julia

This linter plugin for [AtomLinter](https://atomlinter.github.io/)
provides an interface to [StaticLint.jl](https://github.com/julia-vscode/StaticLint.jl).
It will be used with files that have the `Julia` syntax.

This is a fork that replaces Lint.jl with the same linter that is in the Julia VSCode plugin.
It seems to work for me, but consider this an alpha code.

![screenshot](https://raw.githubusercontent.com/AtomLinter/linter-julia/master/Screenshot.gif)

## Caveats

* The server need a few minutes to parse symbols in a new Julia environment that this Atom instance did not observe before.
  Please be patient when opening a new project, or starting the editor the first time.
* It only considers files that are on the disk. You need to save all files to lint correctly.
* Linting seems to be triggered only when saving or opening files. To re-lint, you need to save the file again.
* The symbols are rebuilt if the modification time of the Project.toml or the Manifest.toml files change, for example,
you add, remove or update packages. Linting is not available during this rebuild.
* Should work on Windows, but was tested only on Linux.

## Internals

Only the Julia server code was changed - I know nothing of Atom development or js.

A separate process builds SymbolServers for each environment detected. Detection works by walking
upwards from the file and looking for Project.toml. The project's root file is then looked for at
the canonical X/src/X.jl etc. locations. If no root is detected, the file becomes the root. If no
environment found, the default environment is used.

Atom seems to be erratic in launching and shutting down server processes. Right now, the symbol server process
registers pids of servers, and kills them on shutdown.

The code generates its private shared environment at the Julia depot in environments/linter-julia, and places
files there, the symbol server log in particular.

## Installation

- Install the package through Atom's UI. You can also use the `apm` tool in the CLI:
```bash
$ apm install linter-julia
```

- You need to tell linter-julia where to find the julia executable
(i.e. `/usr/bin/julia` or `C:\Julia-1.3.0-rc4\bin\julia.exe`). See Settings below.

- This package installs the master branch of StaticLint.jl and SymbolServer.jl automatically into
the linter-julia shared environment.

Was tested with [linter-ui-default](https://atom.io/packages/linter-ui-default) and [atom-ide-ui](https://atom.io/packages/atom-ide-ui) installed.

## Settings

![screenshot](https://raw.githubusercontent.com/AtomLinter/linter-julia/master/settings.png)

## Features

* By default linter-julia uses Juno's `julia`
* You can give a path to the `julia` executable that you want to use for Linting
* You can ignore the messages you don't need

[Issues](https://github.com/AtomLinter/linter-julia/issues) and [pull requests]
(https://github.com/AtomLinter/linter-julia/pulls) are welcome.

## CHANGELOG

[See the full CHANGELOG here.](https://github.com/AtomLinter/linter-julia/blob/master/CHANGELOG.md)
