## 0.7.4
* Update dependencies
* Fix usage of `uuid4` (#60)
* Specify as able to lint unsaved changes (#60)

## 0.7.3 - Move to AtomLinter organization
* Move to the AtomLinter organization for future maintainability

## 0.7.2 - static linter version 1.11.21
* This tries to fix #38
* Also installation instructions updated, thanks @waldyrious

## 0.7.1 - Some clarification to README.md
* Thanks @waldyrious for the effort

## 0.7.0 - Install Lint.jl automatically
* See issue #30
* linter-julia checks if Lint.jl is installed and if not runs Pkg.add("Lint")

## 0.6.0 - Major change in package to start using the JSON format
* All the magic moves to Lint.jl package
* JSON is used in both way communications
* This simplifies this package code a lot
* Answers to issue #4

## 0.5.5 - Fix parsing of Lint error message on windows
* Thanks @samtkaplan for the effort

## 0.5.4 - Adding Settings section to README
* Fixing issues #32 and #33

## 0.5.3 - Fixing issue #20
* Fixing issue #20

## 0.5.2 - Display the LintMessage variable
* Fixing issue #29

## 0.5.1 - Fixing the linter dependency
* Fixing issue #25

## 0.5.0 - Possibility to turn off the Error codes from the message
* Adding setting to not show the error codes in the message

## 0.4.0 - Settings to ignore infos and warnings
* Adding Settings to ignore infos and warnings

## 0.3.1 - Adding linter as a dependency in package.json
* Adding linter as a dependency in package.json

## 0.3.0 - Ignore codes
* Added a setting to ignore error messages

## 0.2.2 - JunoDocs page added
* http://docs.junolab.org/

## 0.2.1 - patches documentation
* CHANGELOG.md updated
* Settings descriptions clarified
* README.md updated

## 0.2.0 - Julia path from Juno
* By default the julia path comes from Juno (atom.config.get('julia-client.juliaPath'))
* User have possibility to give the path to the julia they want to use.

## 0.1.0 - First Release
* First Release
