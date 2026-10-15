import { Socks5ProxyAgent, fetch as undiciFetch } from 'undici'

let agent: Socks5ProxyAgent | null = null

/**
 * Return a fetch-compatible function that routes through the local SOCKS5 proxy.
 * We cast undici's fetch to `typeof fetch` because undici's Response carries its own
 * ReadableStream generics that do not line up with the DOM `Response` type the caller
 * consumes; the runtime shape is identical.
 */
export function modelFetch(socksPort: number): typeof fetch {
  if (!agent && socksPort > 0) {
    agent = new Socks5ProxyAgent(`socks5://127.0.0.1:${socksPort}`)
    process.stderr.write(`[model-fetch] using socks5://127.0.0.1:${socksPort}\n`)
  }
  if (!agent) return fetch
  return ((url: string | URL, options: RequestInit = {}) =>
    undiciFetch(url as string, { ...options, dispatcher: agent } as never)) as unknown as typeof fetch
}
