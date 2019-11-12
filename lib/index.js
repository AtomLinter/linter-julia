/* @flow */

import net from 'net';
import { CompositeDisposable } from 'atom';
import { spawnServer, terminateServer } from './server';
import type { Server } from './types';

let spawnedServer: ?Server = null;
let subscriptions: ?Object = null;

let executablePath;
let backend;
let ignoreInfo;
let ignoreWarning;
let showErrorCodes;
let ignoreIssueCodes;

export function activate() {
  // eslint-disable-next-line global-require
  require('atom-package-deps').install('linter-julia');
  subscriptions = new CompositeDisposable();
  subscriptions.add(
    atom.config.observe('linter-julia.executablePath', async (value) => {
      executablePath = value;
      if (spawnedServer) {
        try {
          await terminateServer(spawnedServer);
          spawnedServer = null;
          spawnedServer = await spawnServer(executablePath);
        } catch (e) {
          const message = '[Linter-Julia] '
            + 'Unable to spawn server after config change';
          atom.notifications.addError(`${message}. See console for details.`);
          // eslint-disable-next-line no-console
          console.error(`${message}: `, e);
        }
      }
    }),
    atom.config.observe('linter-julia.backend', (value) => {
      backend = value;
    }),
    atom.config.observe('linter-julia.ignoreInfo', (value) => {
      ignoreInfo = value;
    }),
    atom.config.observe('linter-julia.ignoreWarning', (value) => {
      ignoreWarning = value;
    }),
    atom.config.observe('linter-julia.showErrorCodes', (value) => {
      showErrorCodes = value;
    }),
    atom.config.observe('linter-julia.ignoreIssueCodes', (value) => {
      ignoreIssueCodes = value;
    }),
  );
}

export function deactivate() {
  if (spawnedServer) {
    terminateServer(spawnedServer);
    spawnedServer = null;
  }
  if (subscriptions) {
    subscriptions.dispose();
  }
}

export function provideLinter() {
  if (backend === 'Lint') {
    return {
      name: 'Julia',
      scope: 'file',
      lintsOnChange: true,
      grammarScopes: ['source.julia'],
      async lint(textEditor: Object) {
        if (!spawnedServer) {
          spawnedServer = await spawnServer(executablePath);
        }
        const connection = net.createConnection(spawnedServer.path);
        connection.on('connect', function writeData() {
          this.write(JSON.stringify({
            file: textEditor.getPath(),
            code_str: textEditor.getText(),
            show_code: showErrorCodes,
            ignore_info: ignoreInfo,
            ignore_codes: ignoreIssueCodes,
            ignore_warnings: ignoreWarning,
          }));
        });

        return new Promise(((resolve, reject) => {
          setTimeout(() => {
            // This is the timeout because net.Socket doesn't have one for connections
            reject(new Error('Request timed out'));
            connection.end();
          }, 60 * 1000);
          connection.on('error', reject);

          const data = [];
          connection.on('data', (chunk) => {
            data.push(chunk);
          });
          connection.on('close', () => {
            let parsed;
            const merged = data.join('');
            try {
              parsed = JSON.parse(merged);
            } catch (_) {
              const msg = '[Linter-Julia] Server returned non-JSON response';
              atom.notifications.addError(`${msg}. See console for more info`);
              // eslint-disable-next-line no-console
              console.error(`${msg}: `, merged);
              resolve(null);
              return;
            }
            resolve(parsed);
          });
        }));
      },
    };
  } else if (backend === 'StaticLint') {
    return {

    };
  }
}
