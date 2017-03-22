LinterJulia = require '../lib/linter-julia'
path = require 'path'
lint = LinterJulia.provideLinter().lint
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "LinterJulia", ->
  [workspaceElement, activationPromise] = []

  validfile = path.join(__dirname, 'testdata', 'validfile.jl')

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('linter-julia')

  describe "when the linter-julia lints a file", ->
    it "finds nothing wrong with a valid file", ->

      waitsForPromise ->
        activationPromise
        editor1 = atom.workspace.open(validfile)

      runs ->
        #atom.workspace.open(validfile).then(textEditor -> lint(textEditor))
        #.then((messages) -> expect(messages.length).toBe(0))
        console.log editor1
