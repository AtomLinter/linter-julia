LinterJulia = require '../lib/linter-julia'
path = require 'path'
lint = LinterJulia.provideLinter().lint
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

validfile = path.join(__dirname, 'testdata', 'validfile.jl')
E321 = path.join(__dirname, 'testdata', 'E321.jl')

describe "LinterJulia", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    atom.workspace.destroyActivePaneItem()
    waitsForPromise ->
      atom.packages.activatePackage('linter-julia')
      return atom.packages.activatePackage('language-julia').then () ->
        atom.workspace.open(validfile)

  describe "when the linter-julia lints a file", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(E321).then((openEditor) ->
          editor = openEditor)
    it "finds at least one message", ->
      waitsForPromise ->
        lint(editor).then(messages ->
          expect(messages.length).toBeGreaterThan(0))
###
    it "finds E321 correctly", ->
      waitsForPromise ->
        atom.workspace.getTextEditors()[0].open(E321).then(textEditor ->
          lint(textEditor)).then(messages -> console.log messages)


    it "finds E321 correctly", ->

      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          atom.workspace.open(validfile).then(textEditor -> lint(textEditor))
          .then((messages) -> expect(messages.length).toBe(0))
###
