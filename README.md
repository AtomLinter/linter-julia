# linter-julia

This linter plugin for [AtomLinter](https://atomlinter.github.io/)
provides an interface to [StaticLint.jl](https://github.com/julia-vscode/StaticLint.jl).
It will be used with files that have the `Julia` syntax.

![screenshot](https://raw.githubusercontent.com/takbal/linter-julia/master/Screenshot.gif)

## Developed on

* julia-1.5.3
* [linter-ui-default](https://atom.io/packages/linter-ui-default)
* [linter](https://atom.io/packages/linter)
* tested on Ubuntu 18.04 and Windows

## Installation

- Install the package through Atom's UI. You can also use the `apm` tool in the CLI:
```
apm install linter-julia
```

- You may need to tell linter-julia where to find the Julia executable
(i.e. `/usr/bin/julia` or `C:\Julia-1.5.3\bin\julia.exe`). The default assumes 'julia' just works.

- Julia must have the General registry added.

## Settings

![screenshot](https://raw.githubusercontent.com/AtomLinter/linter-julia/master/settings.png)

## Features

* You can ignore the messages you don't need in settings. Provide the codes with a comma separated list.
  The codes can be found by expanding the hover of the error message if 'show error codes' is set.

[Issues](https://github.com/AtomLinter/linter-julia/issues) and [pull requests]
(https://github.com/AtomLinter/linter-julia/pulls) are welcome.


## Caveats

* The server needs a minute to spin up, then also some time to parse new Julia environments that this Atom instance
  have not seen before. A pop-up is shown when parsing a new environment starts (but not when it ends). After parsing finishes, you need to
  edit or reopen those files that are already in the editor for linting to start. If the environment had been already parsed, linting new files is immediate.
* The edited file has to be saved at least once for linting to start. This is by design of the linter package (https://github.com/steelbrain/linter/issues/1235)
* The environment for each file is guessed from its path. If this fails, Julia's default environment is assumed.
* The symbols are rebuilt if the modification time of the Project.toml or the Manifest.toml files change, for example,
you add, remove or update packages. Linting is not available during this rebuild.

## Internals

The code generates its private shared environment at the Julia depot in 'environments/linter-julia'. It also places a logfile there.

Guessing the environment works by walking upwards in the path and looking for Project.toml. If nothing found, the default
environment is assumed. The project's root file is then looked for at the canonical X/src/X.jl etc. locations.

I know nothing of Atom development or js, so the changes are likely messy there, please revise. Atom seems to be
unable to shut down the server process, so the server exits by polling Atom's PID right now.

## CHANGELOG

[See the full CHANGELOG here.](https://github.com/AtomLinter/linter-julia/blob/master/CHANGELOG.md)
