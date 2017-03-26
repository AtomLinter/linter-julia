LinterJulia = require '../lib/linter-julia'
path = require 'path'
lint = LinterJulia.provideLinter().lint
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

validfile = path.join(__dirname, 'testdata', 'validfile.jl')
E321 = path.join(__dirname, 'testdata', 'E321.jl')
W351 = path.join(__dirname, 'testdata', 'W351.jl')

describe "The linter-julia provider for linter", ->
  [workspaceElement, activationPromise] = []
  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.config.set('linter-julia.julia','julia')
    activationPromise = atom.packages.activatePackage('linter-julia')
  describe "works with Julia fileas and", ->
    it "opens the file", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          atom.workspace.open(E321).then (editor) ->
            expect(editor.getPath()).toContain 'E321.jl'
    it "finds E321 message correctly", ->
      msgText = "E321 something: use of undeclared symbol"
      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          atom.workspace.open(E321).then (editor) -> lint(editor)
          .then (messages) ->
            expect(messages.length).toBeGreaterThan(0)
            expect(messages[0].text).toBe(msgText)
            expect(messages[0].type).toBe("Error")
            expect(messages[0].file).toBe(E321)
            expect(messages[0].range).toEqual([[0, 0], [0, 80]])
            expect(messages[0].html).not.toBeDefined()

    it "finds W351 message correctly", ->
      msgText = "W351 pi: redefining mathematical constant"
      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          atom.workspace.open(W351).then (editor) -> lint(editor)
          .then (messages) ->
            expect(messages.length).toBeGreaterThan(0)
            expect(messages[0].text).toBe(msgText)
            expect(messages[0].type).toBe("Warning")
            expect(messages[0].file).toBe(W351)
            expect(messages[0].range).toEqual([[0, 0], [0, 80]])
            expect(messages[0].html).not.toBeDefined()



###
    beforeEach ->
      #waitsForPromise ->
      #  atom.packages.activatePackage('linter-julia')
      waitsForPromise ->
        atom.packages.activatePackage('language-julia').then(() ->
          atom.workspace.open(validfile))
      atom.packages.triggerDeferredActivationHooks()
      #waitsForPromise -> activationPromise
###
        #.then (messages) ->
        #  expect(messages.length).toBeGreaterThan(0)
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
