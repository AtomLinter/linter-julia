/* @flow */

import tmp from 'tmp'
import Path from 'path'
import { async as getAsyncEnv } from 'consistent-env'
import { BufferedProcess, Disposable, CompositeDisposable } from 'atom'
import type { Server } from './types'

const JULIA_SERVER_PATH = Path.join(__dirname, 'julia-server.jl')

export async function getPipePath(): Promise<{ subscription: CompositeDisposable, path: string }> {
  const subscription = new CompositeDisposable()
  let path = await new Promise(function(resolve, reject) {
    tmp.file(function(error, tempPath, fd, cleanupCallback) {
      if (error) {
        reject(error)
        return
      }
      subscription.add(new Disposable(cleanupCallback))
      resolve(tempPath)
    })
  })

  if (process.platform === 'win32') {
    path = '\\\\.\\pipe\\' + Path.basename(path)
  }

  return { subscription, path }
}

export async function spawnServer(juliaExecutable: string): Promise<Server> {
  const { path, subscription: pathSubscription } = await getPipePath()
  const server = {
    pid: 0,
    path,
    subscriptions: new CompositeDisposable(),
  }
  const processEnv = await getAsyncEnv()
  server.subscriptions.add(pathSubscription)

  await new Promise(function(resolve, reject) {
    const data = { stdout: '', stderr: '', resolved: false }
    const spawnedProcess = new BufferedProcess({
      command: juliaExecutable,
      args: [JULIA_SERVER_PATH, path],
      options: { env: processEnv },
      stdout(chunk) {
        data.stdout += chunk.toString('utf8')
        if (!data.resolved && data.stdout.includes('Server running on port')) {
          data.resolved = true
          resolve()
        }
      },
      stderr(chunk) {
        data.stderr += chunk.toString('utf8')
      },
      exit(exitCode) {
        console.debug('[Linter-Julia] Server exited with code:', exitCode, 'STDOUT:', data.stdout, 'STDERR:', data.stderr)
      },
    })

    server.pid = spawnedProcess.process.pid
    spawnedProcess.process.on('error', reject)
    server.subscriptions.add(new Disposable(function() {
      spawnedProcess.kill()
    }))
  })

  return server
}

export function terminateServer(server: Server): void {
  server.subscriptions.dispose()
}
