const SELECTORS = {
  input: 'textarea[placeholder="Сообщение для DeepSeek"]',
  assistant: '.ds-markdown.ds-assistant-message-main-content',
  message: '.ds-message',
  messageList: '.ds-virtual-list',
}
let observer = null, pollTimer = null, lastMutation = Date.now(), answered = false, lastAnswerText = ''
function getInputCoords() {
  const el = document.querySelector(SELECTORS.input)
  if (!el) return null
  const r = el.getBoundingClientRect()
  return { x: Math.round(r.left + r.width / 2), y: Math.round(r.top + r.height / 2) }
}
function hasStopButton() {
  return !!document.querySelector('button[aria-label*="Stop" i], button[aria-label*="停止"]')
}
function messagesBalanced() {
  const msgs = document.querySelectorAll('div.ds-message').length
  const bars = document.querySelectorAll('div.ds-flex').length
  return msgs > 0 && msgs === bars
}
function checkComplete() {
  if (answered) return
  const noStop = !hasStopButton()
  const idle = Date.now() - lastMutation > 1200
  const balanced = messagesBalanced()
  if (noStop && (idle || balanced)) {
    answered = true; cleanup()
    const text = extractAnswer()
    if (text && text !== lastAnswerText) { lastAnswerText = text; chrome.runtime.sendMessage({ type: 'chunk', text }) }
    chrome.runtime.sendMessage({ type: 'done' })
  }
}
function extractAnswer() {
  const all = document.querySelectorAll(SELECTORS.assistant)
  return all[all.length - 1]?.innerText?.trim() ?? ''
}
function detectError() {
  const errEl = document.querySelector('[role="alert"], [class*="error" i], [class*="toast" i]')
  if (errEl) { const text = errEl.innerText?.trim(); if (text && text.length > 0 && text.length < 300) return { type: 'ui_error', text } }
  const last = document.querySelector('.ds-message:last-of-type')
  if (last?.innerHTML?.includes('CONTENT_FILTER')) return { type: 'content_filter' }
  return null
}
function startMonitoring() {
  answered = false; lastMutation = Date.now(); lastAnswerText = ''
  const target = document.querySelector(SELECTORS.messageList) ?? document.body
  observer = new MutationObserver(() => { lastMutation = Date.now() })
  observer.observe(target, { childList: true, subtree: true, characterData: true })
  pollTimer = setInterval(() => {
    checkComplete()
    const err = detectError()
    if (err) { cleanup(); chrome.runtime.sendMessage({ type: 'error', ...err }) }
  }, 400)
}
function cleanup() { observer?.disconnect(); observer = null; clearInterval(pollTimer); pollTimer = null }
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'getInputCoords') { sendResponse(getInputCoords()); return true }
  if (msg.type === 'startMonitoring') { startMonitoring(); sendResponse({ ok: true }); return true }
})
