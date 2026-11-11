---
name: summarizer
description: "Chrome Summarizer API — on-device суммаризация"
whenToUse: "Use when summarizing long text on-device"
---

# SKILL · summarizer

## Что это
Summarizer API — on-device суммаризация. Внутри — Prompt API (Gemini Nano).

## Базовое использование
~~~javascript
if ((await Summarizer.availability()) !== 'available') return;
const s = await Summarizer.create({ type: 'key-points', format: 'markdown', length: 'short' });
const summary = await s.summarize('Long text...');
~~~

## Параметры
type: key-points|tldr|teaser|headline; format: markdown|plain-text; length: short|medium|long.

## Fallback для Prompt API
~~~javascript
session.addEventListener('contextoverflow', async () => {
  const history = await getHistory();
  const sm = await Summarizer.create({ type: 'tldr', length: 'short' });
  const compressed = await sm.summarize(history);
  await session.destroy();
  const ns = await LanguageModel.create({ initialPrompts: [{ role: "system", content: compressed }] });
});
~~~

## Ограничения
Языки: en, ja, es, de, fr. Русский — проверять availability().

## Готовый рабочий пример (HTML + JS)
Сохраните как summarizer-demo.html, Chrome 138+.
~~~html
<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><title>Summarizer Demo</title></head>
<body><h1>Summarizer</h1><p id="status">…</p>
<textarea id="inp" rows="6" cols="70">Длинный текст для суммаризации.</textarea><br>
<button id="run">Summarize</button><pre id="out"></pre>
<script>
(async () => {
  const s = document.getElementById('status');
  if (!('Summarizer' in self)) { s.textContent = 'no Summarizer'; return; }
  const opts = { type:'key-points', format:'plain-text', length:'short' };
  const av = await Summarizer.availability(opts);
  s.textContent = 'availability: ' + av;
  if (av === 'unavailable') return;
  document.getElementById('run').addEventListener('click', async () => {
    if (av === 'downloadable') { s.textContent = 'click again to download'; return; }
    const sm = await Summarizer.create(opts);
    try { document.getElementById('out').textContent = await sm.summarize(document.getElementById('inp').value); }
    catch(e) { document.getElementById('out').textContent = 'err: ' + e.message; }
  });
})();
</script></body></html>
~~~

## KEEP
- .dsh/skills/summarizer/SKILL.md
