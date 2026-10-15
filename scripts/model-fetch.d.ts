export function modelFetch(socksPort: number): (
  url: string | URL,
  options?: RequestInit & { dispatcher?: unknown },
) => Promise<Response>
