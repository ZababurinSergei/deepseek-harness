import type { ChildProcess } from 'node:child_process'
export function startCiadpi(
  binary: string,
  options?: { preferredPort?: number },
): Promise<{ child: ChildProcess | undefined; port: number }>
