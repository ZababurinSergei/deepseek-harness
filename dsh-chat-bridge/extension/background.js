let ws = null, activeTabId = null, relayListener = null, connecting = false

// === Keep-alive через chrome.alarms (MV3 service worker засыпает без этого) ===
chrome.alarms.create('keepalive', { periodInMinutes: 0.3 }) // 18 сек
chrome.alarms.onAlarm.addListener(() => {
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    console.log('[bg] keepalive ping — reconnecting')
    connect()
  }
})

function connect() {
  if (connecting) return
  if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) return
  connecting = true
  try {
    ws = new WebSocket('ws://127.0.0.1:8765')
    ws.onopen = () => {
      connecting = false
      console.log('[bg] WS connected', new Date().toISOString())
    }
    ws.onmessage = async (e) => {
      const task = JSON.parse(e.data)
      if (task.type === 'ask') await handleAsk(task)
    }
    ws.onclose = () => {
      connecting = false
      console.log('[bg] WS closed', new Date().toISOString())
      setTimeout(connect, 1000)
    }
    ws.onerror = (e) => {
      connecting = false
      console.error('[bg] WS error', e)
    }
  } catch (e) {
    connecting = false
    console.error('[bg] connect failed', e)
  }
}

async function humanClick(tabId, x, y) {
  const dbg = { tabId }
  await chrome.debugger.sendCommand(dbg, 'Input.dispatchMouseEvent', { type: 'mouseMoved', x, y })
  await new Promise(r => setTimeout(r, 30 + Math.random() * 40))
  await chrome.debugger.sendCommand(dbg, 'Input.dispatchMouseEvent', { type: 'mousePressed', button: 'left', x, y, clickCount: 1 })
  await new Promise(r => setTimeout(r, 40 + Math.random() * 30))
  await chrome.debugger.sendCommand(dbg, 'Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', x, y, clickCount: 1 })
}

async function humanType(tabId, text) {
  for (const ch of text) {
    await chrome.debugger.sendCommand({ tabId }, 'Input.dispatchKeyEvent', { type: 'char', text: ch })
    await new Promise(r => setTimeout(r, 15 + Math.random() * 45))
  }
}

async function handleAsk(task) {
  const tabs = await chrome.tabs.query({ url: 'https://chat.deepseek.com/*' })
  if (tabs.length === 0) {
    ws.send(JSON.stringify({ type: 'error', kind: 'fatal', message: 'no deepseek tab' }))
    return
  }
  activeTabId = tabs[0].id
  try {
    await chrome.debugger.attach({ tabId: activeTabId }, '1.2')
    const coords = await chrome.tabs.sendMessage(activeTabId, { type: 'getInputCoords' })
    if (!coords) throw new Error('input not found')
    await humanClick(activeTabId, coords.x, coords.y)
    await humanType(activeTabId, task.prompt)
    await chrome.debugger.sendCommand({ tabId: activeTabId }, 'Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 })
    await chrome.debugger.sendCommand({ tabId: activeTabId }, 'Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 })
    await chrome.debugger.detach({ tabId: activeTabId })
    await chrome.tabs.sendMessage(activeTabId, { type: 'startMonitoring' })
    relayListener = (msg) => {
      if (msg.type === 'chunk') ws.send(JSON.stringify({ type: 'chunk', text: msg.text }))
      if (msg.type === 'done') { ws.send(JSON.stringify({ type: 'done' })); unrelay() }
      if (msg.type === 'error') { ws.send(JSON.stringify({ type: 'error', ...msg })); unrelay() }
    }
    chrome.runtime.onMessage.addListener(relayListener)
  } catch (e) {
    try { await chrome.debugger.detach({ tabId: activeTabId }) } catch {}
    ws.send(JSON.stringify({ type: 'error', kind: 'fatal', message: String(e) }))
  }
}

function unrelay() {
  if (relayListener) {
    chrome.runtime.onMessage.removeListener(relayListener)
    relayListener = null
  }
}

// Запускаем подключение при инициализации
connect()
