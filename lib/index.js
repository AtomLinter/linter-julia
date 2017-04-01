/* @flow */

import { CompositeDisposable } from 'atom-linter'
import { spawnServer, terminateServer } from './server'

let spawnedServer = null
let subscriptions = null

export function activate() {
  // eslint-disable-next-line global-require
  require('atom-package-deps').install('linter-julia')
  subscriptions = new CompositeDisposable()
  subscriptions.add(atom.config.observe('linter-julia.executablePath', async (executablePath) => {
    if (spawnedServer) {
      try {
        await terminateServer(spawnedServer)
        spawnedServer = null
        spawnedServer = await spawnServer(executablePath)
      } catch (e) {
        console.error('[Linter-Julia] Unable to spawn server after config change', e)
      }
    }
  }))
}

export function deactivate() {
  if (spawnedServer) {
    terminateServer(spawnedServer)
    spawnedServer = null
  }
  if (subscriptions) {
    subscriptions.dispose()
  }
}

export function provideLinter() {
  return {
    name: 'Julia',
    scope: 'file',
    lintsOnChange: false,
    grammarScopes: ['source.julia'],
    async lint(textEditor: Object) {
      if (!spawnedServer) {
        spawnedServer = await spawnServer(atom.config.get('linter-julia.executablePath'))
      }
      console.log('Invoked on', textEditor.getPath())
      return []
    },
  }
}
