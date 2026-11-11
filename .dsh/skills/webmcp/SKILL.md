---
name: webmcp
description: "WebMCP — регистрация инструментов страницы для AI-агентов"
whenToUse: "Use when building client-side tools callable via document.modelContext.registerTool()"
---

# SKILL · webmcp

## Что это
WebMCP — браузерный JS API: страница регистрирует инструменты, AI-агенты их вызывают. Клиент-only.

## Требования
- Chromium 146+
- Флаг chrome://flags/#enable-webmcp-testing
- Origin trial Chrome 149–156

## Императивный API
~~~javascript
const controller = new AbortController();
await document.modelContext.registerTool({
  name: 'calculate_area',
  description: 'Calculate area of a rectangle.',
  inputSchema: { type: 'object', properties: { width: { type: 'number' }, height: { type: 'number' } }, required: ['width','height'] },
  annotations: { readOnlyHint: true },
  async execute({ width, height }) {
    if (typeof width !== 'number') return { error: 'width must be number' };
    return { area: width * height };
  }
}, { signal: controller.signal });
~~~

## Правила
1. Description не дублирует схему.
2. Валидация в execute — браузер не проверяет.
3. Ошибки возвращать значением, не throw.
4. readOnlyHint / consequentialHint / untrustedContentHint.
5. Отмена через AbortSignal.

## Готовый рабочий пример (HTML + JS)
Сохраните как webmcp-demo.html, откройте в Chrome 146+ с флагом.
~~~html
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><title>WebMCP Demo</title></head>
<body><h1>WebMCP Demo</h1><p id="status">…</p><pre id="output"></pre>
<script>
(async () => {
  if (!('modelContext' in document)) { document.getElementById('status').textContent = 'no WebMCP'; return; }
  const c = new AbortController();
  await document.modelContext.registerTool({
    name: 'summarize_text',
    description: 'Summarize text in 1-2 sentences.',
    inputSchema: { type: 'object', properties: { text: { type: 'string' } }, required: ['text'] },
    annotations: { readOnlyHint: true },
    async execute({ text }) {
      if (typeof text !== 'string') return { error: 'text must be string' };
      const s = text.split(/[.!?]+/).filter(x => x.trim());
      return { summary: s.slice(0,2).join('. ') + '.' };
    }
  }, { signal: c.signal });
  document.getElementById('status').textContent = 'registered';
  window.addEventListener('beforeunload', () => c.abort());
})();
</script></body></html>
~~~

## KEEP
- .dsh/skills/webmcp/SKILL.md
