---
name: browser-automation
description: Puppeteer and Playwright launch with system Chrome, WebGPU bypass, CDP connection
---

<!-- scope: foreign(nk-elite-orillusion-map) — to asuse-ai-front-min NOT applicable; kept for universal WebGPU/Playwright rules -->
# SKILL · browser-automation (universal)

Не привязан к проекту. Описывает, как правильно запускать Puppeteer и Playwright, какой выбрать в каком случае, и как обходить проблему отсутствия GPU (использовать системный Chrome, где GPU уже работает).

## Главное правило: системный Chrome, не bundled

Оба инструмента по умолчанию скачивают свой Chromium. Для WebGPU этого недостаточно: bundled-сборка может не иметь GPU-процесса или нужных флагов. Всегда указывайте путь к системному Chrome:
- `executablePath: /usr/bin/google-chrome` (Linux)
- или `channel: chrome` (Playwright/Puppeteer, если установлен)

Проверка: `google-chrome --version` >= 115.

## Playwright vs Puppeteer: что выбрать

| Критерий | Playwright | Puppeteer |
|---|---|---|
| Браузеры | Chromium, Firefox, WebKit | Chrome/Chromium |
| Языки | JS/TS, Python, Java, .NET | JS/TS |
| Тест-раннер | Playwright Test | нет встроенного |
| Изоляция | browser contexts | контексты вручную |
| WebGPU | требует полный Chrome | требует полный Chrome + флаги на Linux |

Выбор:
- Playwright — кросс-браузерный E2E, встроенный тест-раннер, Python/Java/.NET, параллельные тесты.
- Puppeteer — только Chrome, лёгкий API для скриптов/скрейпинга/PDF/скриншотов.

## Playwright + WebGPU: обход проблемы GPU

Ключевой факт: `headless: true` в Playwright запускает `chrome-headless-shell`, у которого НЕТ GPU-процесса, поэтому `navigator.gpu` отсутствует при любых флагах.

Решение — запускать полный Chrome в новом headless-режиме:
```js
const { chromium } = require('playwright');
const browser = await chromium.launch({
  headless: false,
  ignoreDefaultArgs: ['--headless'],
  args: [
    '--headless=new',
    '--no-sandbox',
    '--enable-unsafe-webgpu',
    '--enable-features=Vulkan',
    '--use-angle=vulkan',
    '--ignore-gpu-blocklist',
  ],
  executablePath: '/usr/bin/google-chrome',
});
```

Важно (Windows): НЕ добавляйте `--use-angle=vulkan` / `--enable-features=Vulkan` — они уводят Dawn с D3D12, и `requestAdapter()` возвращает `null`. На Linux флаги Vulkan нужны.

Проверка после запуска:
```js
const gpu = await page.evaluate(async () => {
  const hasGpu = !!navigator.gpu;
  const adapter = hasGpu ? await navigator.gpu.requestAdapter() : null;
  return { hasGpu, adapter: adapter ? { vendor: adapter.info?.vendor, arch: adapter.info?.architecture } : null };
});
```

## Puppeteer + WebGPU: запуск с системным Chrome

```js
const puppeteer = require('puppeteer-core');
const browser = await puppeteer.launch({
  headless: 'new',
  executablePath: '/usr/bin/google-chrome',
  args: [
    '--no-sandbox',
    '--enable-unsafe-webgpu',
    '--enable-features=Vulkan',
    '--use-angle=vulkan',
    '--disable-vulkan-surface',
    '--ignore-gpu-blocklist',
  ],
});
```

На Linux без Vulkan-флагов Chrome часто отдаёт `navigator.gpu`, но `requestAdapter()` возвращает `null`. `--disable-vulkan-surface` нужен для compute-only сценариев (без swapchain).

## Подключение к уже запущенному Chrome (CDP)

Если Chrome уже запущен с GPU (например, ваш рабочий браузер), можно подключиться к нему, а не запускать новый.

Chrome запуск:
```bash
google-chrome --remote-debugging-port=9222 --user-data-dir=$HOME/.config/my-cdp-profile
```

Puppeteer connect:
```js
const browser = await puppeteer.connect({ browserWSEndpoint: 'ws://127.0.0.1:9222/devtools/browser/<id>' });
const browser = await puppeteer.connect({ browserURL: 'http://127.0.0.1:9222' });
```
WS endpoint берите из `http://127.0.0.1:9222/json/version` -> `webSocketDebuggerUrl`.

Playwright connect:
```js
const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
```
Или через CLI: `playwright-cli attach --cdp=http://localhost:9222`.

Плюс: используется уже работающий GPU. Минус: Chrome должен быть запущен, порт доступен.

## Чек-лист перед прогоном

1. `google-chrome --version` >= 115.
2. Системный Chrome существует (`which google-chrome`).
3. Playwright: `headless: false` + `ignoreDefaultArgs: [--headless]` + `args: [--headless=new]` + `executablePath`.
4. Puppeteer: `headless: new` + `executablePath`.
5. Linux: Vulkan-флаги (`--enable-unsafe-webgpu`, `--enable-features=Vulkan`, `--use-angle=vulkan`).
6. Windows: НЕ добавлять Vulkan-флаги.
7. Проверить `navigator.gpu` и `requestAdapter()` в `page.evaluate`.
8. Если adapter `null` — проверить `chrome://gpu` (WebGPU Disabled vs Unavailable).

## Частые ошибки

- `headless: true` в Playwright -> shell без GPU -> `navigator.gpu` undefined.
- Запуск bundled Chromium вместо системного -> нет GPU.
- Linux без Vulkan-флагов -> adapter `null`.
- Windows с Vulkan-флагами -> adapter `null` (Dawn уходит с D3D12).
- `browser.disconnect()` не закрывает браузер (в отличие от `close()`).
- `--disable-extensions` не работает для `--user-data-dir` с установленным расширением.

## Orillusion 0.9.2: поиск компонентов в Playwright

`obj.getComponent('MeshRenderer')` (по строке) **зависает** — метод ожидает
класс, а не имя. Искать так:

let comps = instObj.components;
if (Array.isArray(comps)) {}
else if (comps?.values) comps = Array.from(comps.values());
else if (comps) comps = Object.values(comps);
let mr = null;
for (const c of comps) {
if (c?.constructor?.name === 'MeshRenderer' || (c && c.geometry && c.material)) { mr = c; break; }
}

`container.components` — Map/объект, не массив. `Map.get('instanced')` для
дочерних объектов работает штатно.
## Windows / PowerShell 5.1
- `npm i -D playwright` / `npm i -D puppeteer` работают в PS 5.1 нативно.
- Системный Chrome на Windows: `executablePath` = `C:\Program Files\Google\Chrome\Application\chrome.exe` или `channel: 'chrome'`.
- Флаги WebGPU на Windows/AMD: НЕ добавлять `--use-angle=vulkan` / `--enable-features=Vulkan` — это уводит Dawn с D3D12.
- **Доконанный Windows-набор Playwright-WebGPU-аргов (2026-11-08, Intel UHD630):**
  `args: ['--headless=new','--no-sandbox','--enable-unsafe-webgpu','--enable-dawn-features=allow_unsafe_uploads']`
  (эталон `scripts/win/probe.mjs`; `allow_unsafe_uploads` обязателен для buffer-uploads в headless).
- **Intel UHD630 + Vulkan-флаги = GPU-process crash** («Page crashed», init-FLAKY: `context3D.device=false` навечно;
  37 leftover headless chrome = adapter exhaustion). Чистка: `Get-Process chrome | ? { $_.MainWindowTitle -eq '' } | Stop-Process -Force` (GUI-окно с заголовком не трогать).
- **Init-gate в probes:** после `goto` поллить `__engine.context3D.device && __starField` (до ~50с); при таймауте
  exit 2 = INIT-FLAKY (не REJECT-рендер), перезапустить. Эталон: `scripts/win/sky-check-win.mjs`, `scripts/win/probe-hover.mjs`.
- **Canvas-clip для brightness:** скриншотить `clip` по bounding box canvas (без UI-панелей); иначе lit = виджеты панелей (ложный ACCEPT).
- Запуск скрипта: `powershell -NoProfile -ExecutionPolicy Bypass -File .\run-playwright.ps1`. Не копипаст в консоль.

<!-- windows-ps51: updated by update-all-skills -->

<!-- sources: scripts/skills-audit.mjs -->
<!-- updated: 20261030 (audit run S-20261030-175016-12764, RULES.md §12/§15) -->
