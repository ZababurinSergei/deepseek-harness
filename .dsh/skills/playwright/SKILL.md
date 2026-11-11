---
name: playwright
description: Playwright WebGPU headless Chrome launch, console capture, CDP screenshots
---

<!-- scope: foreign(nk-elite-orillusion-map) — to asuse-ai-front-min NOT applicable; kept for universal WebGPU/Playwright rules -->
# PLAYWRIGHT — WebGPU-прогон sky.html (Console + скриншот)

## Ключевой факт
Playwright headless: true запускает chrome-headless-shell, где НЕТ GPU-процесса и navigator.gpu отсутствует при любых флагах. Для WebGPU нужен полный Chrome в новом headless-режиме.

## Запуск (полный Chrome + WebGPU)

const { chromium } = require('playwright');
const browser = await chromium.launch({
headless: false,
ignoreDefaultArgs: ['--headless'],
args: ['--headless=new', '--no-sandbox', '--enable-unsafe-webgpu'],
// channel: 'chrome',
});

- НЕ добавлять --use-angle=vulkan / --enable-features=Vulkan на Windows/AMD: это уводит Dawn с D3D12, requestAdapter() -> null.
- Для SwiftShader (если нет GPU): --enable-features=Vulkan --use-vulkan=swiftshader --disable-vulkan-surface.
- Secure context: http://localhost:3001 уже secure; page.setContent/about:blank — navigator.gpu undefined.

## Что собирать

page.on('console', m => console.log('[' + m.type() + '] ' + m.text()));
page.on('pageerror', e => console.log('[pageerror] ' + e.message));
await page.goto('http://localhost:3001/sky.html', { waitUntil: 'load' });
await page.waitForTimeout(9000);
await page.screenshot({ path: 'shot.png' });
const stats = await page.evaluate(() => window.__StarfieldModule && window.__StarfieldModule.getStats ? window.__StarfieldModule.getStats() : null);
console.log('stats:', JSON.stringify(stats));

- page.on('console') — все строки, включая GPUValidationError с текстом.
- page.on('pageerror') — SyntaxError (например, дубль const time) сразу.
- screenshot — детерминированный кадр.
- getStats — данные о звёздах/буфере.

## Установка (одна итерация, согласовать)
cd tests/map && npm i -D playwright
или использовать общий packages/node_modules/playwright.

## Правило
Console — блокер. Если Playwright не установлен — первым шагом ставить его, а не гонять статику.

## KEEP
- .dsh/skills/playwright/SKILL.md

## Linux/AMD: рабочие флаги (подтверждено 2026-10-25)

`--headless=new --enable-unsafe-webgpu` без Vulkan-флагов даёт
`Instance dropped in popErrorScope` / `Buffer was destroyed before mapping`
— device умирает ДО компиляции шейдеров, `modules_with_msgs=0`,
`pipelines_with_err=0`. Это НЕ ошибка WGSL.

args: [
'--headless=new',
'--no-sandbox',
'--enable-unsafe-webgpu',
'--use-angle=vulkan',
'--enable-features=Vulkan',
'--disable-vulkan-surface',
],
executablePath: '/usr/bin/google-chrome',

Признак живого прогона: `frameCount` растёт (~60/s), `deviceLost=[]`,
`consoleErrors=[]`, `modules_with_msgs=0`.

## Чистый визуальный прогон (без инспектора)

await ctx.route('**/webgpu_inspector.js', r => r.abort());

Иначе виджет инспектора `title="Recent frame times..."` (canvas 60x16)
попадает в композит и мешает diff.


## Дополнение 20261025-230158: CDP screenshot (стабильный)

- **Не** `page.screenshot()` — виснет на `document.fonts.ready` (до 30 с), особенно
  с `webgpu_inspector.js` (jsdelivr) в `sky.html`.
- **Надёжно:**
  `const client = await ctx.newCDPSession(page);`
  `const { data } = await client.send('Page.captureScreenshot', { format: 'png', fromSurface: true });`
  `fs.writeFileSync(shot, Buffer.from(data, 'base64'));`
- `ctx.route('**/*', route => /fonts\.|googleapis|jsdelivr|cdn\.|webgpu_inspector/.test(url) ? route.abort() : route.continue())`
- `page.setDefaultTimeout(10000)`.

## Дополнение 20261025-230158: canvas readback

- **`canvas.toDataURL()`** для WebGPU — **пустой** (`preserveDrawingBuffer` не работает).
- **`getImageData(drawImage(webgpuCanvas))`** — тоже **нули**.
- Пиксельный diff — **только** через `Page.captureScreenshot` (CDP) + PIL.
## Windows / PowerShell 5.1
- Скрипт прогона — `run-playwright.ps1`, запуск: `powershell -NoProfile -ExecutionPolicy Bypass -File .\run-playwright.ps1`.
- `npm i -D playwright` в PS 5.1 работает нативно.
- Путь к системному Chrome: `C:\Program Files\Google\Chrome\Application\chrome.exe` (проверить `Test-Path`).
- Флаги WebGPU на Windows/AMD: без `--use-angle=vulkan`/`--enable-features=Vulkan` — Dawn уходит с D3D12.

<!-- windows-ps51: updated by update-all-skills -->

<!-- sources: scripts/skills-audit.mjs -->
<!-- updated: 20261030 (audit run S-20261030-175016-12764, RULES.md §12/§15) -->


<!-- pwprobe: P26 (liza, 2026-11-08, P26-PROGON lead 9a5f51e0) -->
- **PNG chunk-parser**: posle kazhdogo chunka propuskat' CRC (pos += 4); bez negо
  inflate padaet 'unexpected end of file' (dekodér ekrannogo zona).
- **flyTo v probe**: globalShipController.flyTo trebuet nastoyashchiy Vector3 (vnutri
  .clone()) — massiv [x,y,z] padaet; eksportirujte __Vector3 global v sky.ts.
- **Init-gate zona**: vlyuchat' window.__scientificAtlas (eksport [7/7] pozhe __starField) —
  inache 'Cannot read properties of undefined (reading 'ship')'.
- Log zonda — abs puti: Push-Location + otnositel'nyy \ → tmp/tmp → log propal (povtor P25-1).

- **PNG chunk-parser (TOCHNO)**: kazhdyj chunk = 4 (len) + 4 (type) + len (data) + 4 (CRC).
  Propusk: `pos += len + 4` (data+CRС), a NE `pos += 4`: pri `pos+=4` inflae padaet
  'unexpected end of file' (povtor v ghost-ab.mjs P28 — vneseno lidom v ego kopii; eto
  zhe bilo v screen360). Etalon: scripts/win/probe.mjs decodePNG.
