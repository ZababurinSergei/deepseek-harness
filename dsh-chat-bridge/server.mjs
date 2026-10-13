import { createServer } from 'node:http'
import { WebSocketServer } from 'ws'
let browserWs = null, pending = null
const wss = new WebSocketServer({ port: 8765, host: '127.0.0.1' })
wss.on('connection', (ws) => {
  console.log('[ws] extension connected'); browserWs = ws
  ws.on('message', (data) => {
    const msg = JSON.parse(data); if (!pending) return
    if (msg.type === 'chunk') pending.onChunk(msg.text)
    if (msg.type === 'done') { const p = pending; pending = null; p.resolve() }
    if (msg.type === 'error') { const p = pending; pending = null; p.reject(msg) }
  })
  ws.on('close', () => { console.log('[ws] disconnected'); if (browserWs === ws) browserWs = null })
})
createServer(async (req, res) => {
  if (req.method !== 'POST' || !req.url?.endsWith('/v1/messages')) { res.writeHead(404).end(); return }
  const chunks = []
  for await (const c of req) chunks.push(c)
  let body
  try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')) } catch { res.writeHead(400).end(); return }
  let prompt = ''
  for (let i = (body.messages?.length ?? 0) - 1; i >= 0; i--) {
    const m = body.messages[i]; if (m.role !== 'user') continue
    if (typeof m.content === 'string') { prompt = m.content; break }
    if (Array.isArray(m.content)) { const t = m.content.find(b => b.type === 'text'); if (t?.text) { prompt = t.text; break } }
  }
  if (!browserWs) { res.writeHead(503, { 'content-type': 'application/json' }); res.end(JSON.stringify({ error: { type: 'api_error', message: 'extension not connected' } })); return }
  res.writeHead(200, { 'content-type': 'text/event-stream; charset=utf-8', 'cache-control': 'no-cache', 'connection': 'keep-alive' })
  const write = (o) => res.write(`data: ${JSON.stringify(o)}\n\n`)
  write({ type: 'message_start', message: { id: 'msg_' + Date.now().toString(36), type: 'message', role: 'assistant', model: body.model ?? 'deepseek-web', content: [], usage: { input_tokens: 0, output_tokens: 0 } } })
  write({ type: 'content_block_start', index: 0, content_block: { type: 'text', text: '' } })
  browserWs.send(JSON.stringify({ type: 'ask', prompt }))
  try {
    await new Promise((resolve, reject) => { pending = { onChunk: (text) => write({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text } }), resolve, reject } })
    write({ type: 'content_block_stop', index: 0 })
    write({ type: 'message_delta', delta: { stop_reason: 'end_turn', stop_sequence: null }, usage: { output_tokens: 0 } })
    write({ type: 'message_stop' }); res.end()
  } catch (err) {
    const type = err.kind === 'rate_limit' ? 'rate_limit_error' : 'api_error'
    res.write(`event: error\ndata: ${JSON.stringify({ type: 'error', error: { type, message: err.message ?? String(err) } })}\n\n`); res.end()
  }
}).listen(8000, '127.0.0.1', () => { console.log('[http] http://127.0.0.1:8000/v1'); console.log('[ws]   ws://127.0.0.1:8765') })
