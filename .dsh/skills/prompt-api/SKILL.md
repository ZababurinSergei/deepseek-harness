---
name: prompt-api
description: "Chrome Prompt API — on-device LLM (Gemini Nano)"
whenToUse: "Use when calling an on-device language model"
---

# SKILL · prompt-api

## Что это
Prompt API — Gemini Nano на устройстве. Без сети.

## Требования
Windows 10/11, macOS 13+, Linux, ≥22 ГБ, GPU ≥4 ГБ VRAM или CPU ≥16 ГБ RAM + 4 ядра.

## Базовое использование
~~~javascript
const av = await LanguageModel.availability({ expectedInputs: [{ type: 'text', languages: ['en'] }] });
if (av === 'unavailable') return;
const session = await LanguageModel.create();
const result = await session.prompt('Write a poem');
~~~

## Structured output
~~~javascript
const schema = { type: 'boolean' };
const r = await session.prompt('Is this about pottery?', { responseConstraint: schema });
console.log(JSON.parse(r));
~~~

## Управление сессией
~~~javascript
console.log(session.contextUsage + '/' + session.contextWindow);
session.addEventListener('contextoverflow', () => console.log('overflow'));
await session.destroy();
~~~

## Интеграция с WebMCP
~~~javascript
const session = await LanguageModel.create({ tools: [{
  name: 'get_weather',
  description: 'Get weather',
  inputSchema: { type: 'object', properties: { city: { type: 'string' } }, required: ['city'] },
  async execute({ city }) { return { temp: 22 }; }
}] });
~~~

## Готовый рабочий пример (HTML + JS)
Сохраните как prompt-api-demo.html, Chrome 148+.
~~~html
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><title>Prompt API Demo</title></head>
<body><h1>Prompt API</h1><p id="status">…</p>
<textarea id="inp" rows="3" cols="60">Rate 1-5: "food was great"</textarea><br>
<button id="run">Run</button><pre id="out"></pre>
<script>
(async () => {
  const s = document.getElementById('status');
  if (!('LanguageModel' in self)) { s.textContent = 'no Prompt API'; return; }
  const av = await LanguageModel.availability();
  s.textContent = 'availability: ' + av;
  if (av === 'unavailable') return;
  document.getElementById('run').addEventListener('click', async () => {
    const session = await LanguageModel.create();
    const schema = { type:'object', properties:{ rating:{type:'number'}, is_positive:{type:'boolean'} }, required:['rating','is_positive'] };
    try {
      const r = await session.prompt(document.getElementById('inp').value, { responseConstraint: schema });
      document.getElementById('out').textContent = r;
    } catch(e) { document.getElementById('out').textContent = 'err: ' + e.message; }
    finally { await session.destroy(); }
  });
})();
</script></body></html>
~~~

## KEEP
- .dsh/skills/prompt-api/SKILL.md
