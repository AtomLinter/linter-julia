/* @flow */

import net from 'net'
import { CompositeDisposable } from 'atom'
import { spawnServer, terminateServer } from './server'
import type { Server } from './types'

let spawnedServer: ?Server = null
let subscriptions: ?Object = null

let ignoreInfo
let ignoreWarning
let showErrorCodes
let ignoreIssueCodes

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
  subscriptions.add(atom.config.observe('linter-julia.ignoreInfo', (_ignoreInfo) => {
    ignoreInfo = _ignoreInfo
  }))
  subscriptions.add(atom.config.observe('linter-julia.ignoreWarning', (_ignoreWarning) => {
    ignoreWarning = _ignoreWarning
  }))
  subscriptions.add(atom.config.observe('linter-julia.showErrorCodes', (_showErrorCodes) => {
    showErrorCodes = _showErrorCodes
  }))
  subscriptions.add(atom.config.observe('linter-julia.ignoreIssueCodes', (_ignoreIssueCodes) => {
    ignoreIssueCodes = _ignoreIssueCodes
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
      const connection = net.createConnection(spawnedServer.path)
      connection.on('connect', function() {
        this.write(JSON.stringify({
          file: textEditor.getPath(),
          code_str: textEditor.getText(),
          show_code: showErrorCodes,
          ignore_info: ignoreInfo,
          ignore_codes: ignoreIssueCodes,
          ignore_warnings: ignoreWarning,
        }))
      })

      await new Promise(function(resolve, reject) {
        setTimeout(function() {
          // This is the timeout because net.Socket doesn't have one for connections
          reject(new Error('Request timed out'))
          connection.end()
        }, 60 * 1000)
        connection.on('error', reject)

        const data = []
        connection.on('data', function(chunk) {
          data.push(chunk)
        })
        connection.on('close', function() {
          let parsed
          const merged = data.join('')
          try {
            parsed = JSON.parse(merged)
          } catch (_) {
            console.error('[Linter-Julia] Server returned non-JSON response: ', merged)
            reject(new Error('Error parsing server response. See console for more info'))
            return
          }
          console.debug('[Linter-Julia] Server response:', parsed)
          resolve(parsed)
        })
      })
    },
  }
}
