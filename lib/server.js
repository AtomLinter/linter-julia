/* @flow */

import os from 'os';
import FS from 'fs';
import Path from 'path';
import uuid from 'uuid4';
import { async as getAsyncEnv } from 'consistent-env';
import { BufferedProcess, Disposable, CompositeDisposable } from 'atom';
import type { Server } from './types';

const JULIA_SERVER_PATH = Path.join(__dirname, 'Lint-julia-server.jl');

export async function getPipePath(): Promise<string> {
  const baseDir = process.platform === 'win32' ? '\\\\.\\pipe\\' : `${os.tmpdir()}/`;
  const uniqueId = uuid();
  return baseDir + uniqueId;
}

export async function spawnServer(juliaExecutable: string): Promise<Server> {
  const path = await getPipePath();
  const server = {
    pid: 0,
    path,
    subscriptions: new CompositeDisposable(),
  };
  const processEnv = await getAsyncEnv();

  await new Promise(((resolve, reject) => {
    const data = { stdout: '', stderr: '', resolved: false };
    const spawnedProcess = new BufferedProcess({
      command: juliaExecutable,
      args: [JULIA_SERVER_PATH, path],
      options: { env: processEnv },
      stdout(chunk) {
        data.stdout += chunk.toString('utf8');
        if (!data.resolved && data.stdout.includes('Server running on port')) {
          data.resolved = true;
          resolve();
        }
      },
      stderr(chunk) {
        data.stderr += chunk.toString('utf8');
      },
      exit(exitCode) {
        if (atom.inDevMode()) {
          /* eslint-disable no-console */
          console.debug(`[Linter-Julia] Server exited with code: ${exitCode}`);
          console.debug(`STDOUT: ${data.stdout}`);
          console.debug(`STDERR: ${data.stderr}`);
          /* eslint-enable no-console */
        }
      },
    });

    server.pid = spawnedProcess.process.pid;
    spawnedProcess.process.on('error', reject);
    server.subscriptions.add(new Disposable((() => {
      spawnedProcess.kill();
      FS.access(path, FS.R_OK, (error) => {
        if (error) return;
        FS.unlink(path, () => { /* No Op */ });
      });
    })));
  }));

  return server;
}

export function terminateServer(server: Server): void {
  server.subscriptions.dispose();
}
