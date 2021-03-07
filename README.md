# linter-julia

This linter plugin for [AtomLinter](https://atomlinter.github.io/)
provides an interface to [StaticLint.jl](https://github.com/julia-vscode/StaticLint.jl).
It will be used with files that have the `Julia` syntax.

This is a fork that replaces Lint.jl with StaticLint.jl from the Julia VSCode plugin.

![screenshot](https://raw.githubusercontent.com/takbal/linter-julia/master/Screenshot.gif)

## Developed on

* julia-1.5.3
* [linter-ui-default](https://atom.io/packages/linter-ui-default)
* [linter](https://atom.io/packages/linter)
* tested on ubuntu 18.04 and windows

## Caveats

* The server needs some time to parse new Julia environments that this Atom instance have not seen before.
  A pop-up is shown about the environments that are being currently parsed. If the environment is parsed,
  linting in new files is fast.
* The edited file has to be saved at least once for linting to start. This seems to be by design of the linter package (https://github.com/steelbrain/linter/issues/1235)
* The environment for each file is guessed from its path. If this fails, Julia's default environment is assumed.
* The symbols are rebuilt if the modification time of the Project.toml or the Manifest.toml files change, for example,
you add, remove or update packages. Linting is not available during this rebuild.
* It works on Windows, but does not shuts down correctly.

## Internals

I know nothing of Atom development or js, so the changes are likely messy there, please revise. Atom seems to be
unable to shut down the server process, so it exits by watching the PID right now. This does not work on Windows yet.

The code generates its private shared environment at the Julia depot in 'environments/linter-julia'. It also places a logfile there.

Environment guessing works by walking upwards in the path and looking for Project.toml. The project's
root file is then looked for at the canonical X/src/X.jl etc. locations.

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
* You can ignore the messages you don't need

[Issues](https://github.com/AtomLinter/linter-julia/issues) and [pull requests]
(https://github.com/AtomLinter/linter-julia/pulls) are welcome.

## CHANGELOG

[See the full CHANGELOG here.](https://github.com/AtomLinter/linter-julia/blob/master/CHANGELOG.md)
