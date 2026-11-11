---
name: webgpu-debug
description: Debugging WebGPU shaders and pipelines with naga-cli, wgsl_reflect and validation scopes
---

<!-- sources: RULES.md -->
<!-- added: doc-sync 2026-11-07 (маркера не было) -->
# WEBGPU DEBUG — скилы для отладки шейдеров и пайплайнов

## Когда использовать
- Invalid RenderPipeline, GPUValidationError, redeclaration, «0 ошибок, но ничего не видно».
- Uniform'ы «не доезжают» до шейдера.
- Нужно понять layout struct vs то, что шлёт setUniform.

## Инструменты (по слоям)

### 1. naga-cli — валидация WGSL без браузера
Установка: cargo install naga-cli
Запуск: naga shader.wgsl
Ловит синтаксис и семантику до браузера: дубли @group/@binding, redeclaration, несовпадение типов. Это первое, что надо запускать при любой ошибке WGSL.

### 2. wgsl_reflect — рефлексия WGSL (JS/TS)
Установка: npm i -D wgsl_reflect
Парсит WGSL и даёт реальные @group/@binding, layout struct, смещения полей, entry points, resources. Использовать, чтобы сверить struct GlobalUniform с тем, что шлёт setUniform (порядок/набор полей).

### 3. WebGPU Inspector (Chrome extension) — RenderDoc-style в DevTools
- Инспекция GPU-объектов, live-редактирование шейдеров, просмотр uniform/storage буферов, захват кадров.
- Установка: Chrome Web Store -> «WebGPU Inspector» (Brendan Duncan).
- В скиле: открой WebGPU Inspector -> Inspect -> найди globalUniform -> посмотри реальные значения viewMat/projMat -> сравни с struct.

### 4. WebGPU Dev Extension (greggman) — ошибки в месте генерации
- Показывает WebGPU-ошибки там, где они произошли (ошибки асинхронные, без этого стек не даёт строку), дампит шейдеры, adapter info, track pass state.
- Установка: Chrome Web Store -> «WebGPU Dev» (gman).

### 5. В коде проекта: pushErrorScope + getCompilationInfo
Обязательный стандарт вокруг createShaderModule / createRenderPipeline:

device.pushErrorScope('validation');
const module = device.createShaderModule({ code: wgsl });
const info = await module.getCompilationInfo();
if (info.messages.length) console.error(info.messages);
const err = await device.popErrorScope();
if (err) console.error('shader module error:', err.message);

Без этого Invalid RenderPipeline остаётся «is invalid due to a previous error» без текста.

## Порядок действий при ошибке шейдера
1. naga shader.wgsl — синтаксис/семантика.
2. wgsl_reflect — layout/биндинги.
3. Playwright Console (page.on console/pageerror) — полный текст ошибки.
4. WebGPU Inspector — реальные значения буферов.
5. WebGPU Dev Extension — место генерации ошибки.

## KEEP
- .dsh/skills/webgpu-debug/SKILL.md


## Дополнение 20261025-230158: точечная диагностика pipeline

- **`getCompilationInfo()`** **не** показывает ошибки `PipelineLayout` (например, missing
  `BindGroupLayout` для `@group(1)`). Для них использовать:
  `device.pushErrorScope('validation'); device.createRenderPipeline(desc); await device.popErrorScope()`
  или **`await device.createRenderPipelineAsync(desc)`** — выдаёт **`GPUPipelineError`** с точным текстом.

- **`client = await ctx.newCDPSession(page); await client.send('Page.captureScreenshot', { format: 'png', fromSurface: true })`**
  — **надёжнее** `page.screenshot()` (последний виснет на `document.fonts.ready` до 30 с).

- **`canvas.toDataURL()`** и **`getImageData(drawImage(webgpuCanvas))`** для WebGPU-канваса
  возвращают **пустой bitmap** (`preserveDrawingBuffer` не работает). Для пиксельного diff
  использовать **CDP screenshot** + PIL/Pillow.

- **`page.route('**/*', ...)`** — abort `webgpu_inspector.js` (jsdelivr/cdn) и `fonts.*`,
  иначе `screenshot` виснет; `page.setDefaultTimeout(10000)`.
