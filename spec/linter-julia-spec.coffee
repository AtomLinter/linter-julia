LinterJulia = require '../lib/linter-julia'
path = require 'path'
lint = LinterJulia.provideLinter().lint
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

validfile = path.join(__dirname, 'testdata', 'validfile.jl')
badfile = path.join(__dirname, 'testdata', 'badfile.jl')

describe "The linter-julia provider for linter", ->
  [workspaceElement, activationPromise] = []
  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.config.set('linter-julia.julia','julia')
    activationPromise = atom.packages.activatePackage('linter-julia')

  describe "works with Julia files and", ->
    textEditor = null
    it "opens the file", ->
      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          atom.workspace.open(badfile).then (editor) ->
            textEditor = editor
            expect(textEditor.getPath()).toContain('badfile.jl')

    it 'should be in the packages list', () ->
      waitsForPromise ->
        activationPromise
      runs ->
        expect(atom.packages.isPackageLoaded('linter-julia')).toBe(true)

    it 'should be an active package', () ->
      waitsForPromise ->
        activationPromise
      runs ->
        expect(atom.packages.isPackageActive('linter-julia')).toBe(true)
        console.log atom.packages.isPackageActive('linter-julia')

    it "finds E321 message correctly", ->
      msgText = "E321 something: use of undeclared symbol"
      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          lint(textEditor).then (messages) ->
            console.log messages
        runs ->
          expect(messages.length).toBeGreaterThan(0)
          expect(messages[0].text).toBe(msgText)
          expect(messages[0].type).toBe("Error")
          expect(messages[0].file).toBe(E321)
          expect(messages[0].range).toEqual([[0, 0], [0, 80]])
          expect(messages[0].html).not.toBeDefined()
###
it "finds W351 message correctly", ->
      msgText = "W351 pi: redefining mathematical constant"
      beforeEach ->
        waitsForPromise ->
          activationPromise
        waitsForPromise ->
          lint(textEditor).then (messages) ->
            expect(messages.length).toBeGreaterThan(0)
            expect(messages[1].text).toBe(msgText)
            expect(messages[1].type).toBe("Warning")
            expect(messages[1].file).toBe(W351)
            expect(messages[1].range).toEqual([[0, 0], [0, 80]])
            expect(messages[1].html).not.toBeDefined()
###
