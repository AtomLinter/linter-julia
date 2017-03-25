LinterJulia = require '../lib/linter-julia'
path = require 'path'
lint = LinterJulia.provideLinter().lint
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

validfile = path.join(__dirname, 'testdata', 'validfile.jl')
E321 = path.join(__dirname, 'testdata', 'E321.jl')

describe "The linter-julia provider for linter", ->
  describe "works with Julia fileas and", ->
    beforeEach ->
      activationPromise =
        atom.packages.activatePackage('linter-julia')
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script').then(() ->
          atom.workspace.open(validfile))
      atom.packages.triggerDeferredActivationHooks()
      waitsForPromise(() -> activationPromise)

    it "finds at least one message", ->
      waitsForPromise ->
        atom.workspace.open(E321).then (editor) -> lint(editor)
        .then (messages) ->
          expect(messages.length).toBeGreaterThan(0)
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
