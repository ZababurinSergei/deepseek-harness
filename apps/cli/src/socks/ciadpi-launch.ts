import { spawn, type ChildProcess } from 'node:child_process'
import { existsSync } from 'node:fs'
import net from 'node:net'

async function findFreePort(start = 1080, end = 1090): Promise<number> {
  for (let p = start; p < end; p++) {
    const free = await new Promise<boolean>((resolve) => {
      const srv = net.createServer()
      srv.once('error', () => resolve(false))
      srv.listen(p, '127.0.0.1', () => srv.close(() => resolve(true)))
    })
    if (free) return p
  }
  return 0
}

export async function startCiadpi(
  binary: string,
  options: { preferredPort?: number } = {},
): Promise<{ child: ChildProcess | undefined; port: number }> {
  if (!existsSync(binary)) return { child: undefined, port: 0 }
  const start = options.preferredPort ?? 1080
  const port = await findFreePort(start, start + 10)
  if (port === 0) return { child: undefined, port: 0 }

  const child = spawn(binary, ['--ip', '127.0.0.1', '--port', String(port)], {
    stdio: ['pipe', 'pipe', 'pipe'],
  })
  child.stdout?.on('data', d => process.stderr.write(`[ciadpi] ${d}`))
  child.stderr?.on('data', d => process.stderr.write(`[ciadpi] ${d}`))

  const kill = (): void => { try { child.kill() } catch { /* ignore */ } }
  process.once('exit', kill)
  process.once('SIGINT', kill)
  process.once('SIGTERM', kill)

  process.stderr.write(`[ciadpi] listening on socks5://127.0.0.1:${port}\n`)
  return { child, port }
}
