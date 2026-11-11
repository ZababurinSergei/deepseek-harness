---
name: browser-testing
description: Browser launch rules for manual and automated tests with 16:9 viewport and console logging
---

# SKILL · browser-testing (universal)

<!-- created:
20261103-162358
 -->
<!-- sources: RULES.md .dsh/skills/playwright/SKILL.md .dsh/skills/browser-automation/SKILL.md -->

## 0. Назначение
Правила запуска браузера для ручных и авто-тестов: **aspect ratio 16/9** и **вся консоль в лог**.

## 1. Aspect ratio 16/9 (обязательно)
Окно/viewport открывается в пропорции **16:9** (1.777…).
- Playwright: viewport: { width: 1920, height: 1080 } (или 1280×720, 2560×1440).
- Puppeteer: defaultViewport: { width: 1920, height: 1080 }.
- Headed Chrome: --window-size=1920,1080.
  Проверка: window.innerWidth / window.innerHeight ~ 16/9 (допуск ±2 px на рамки ОС).

## 2. Консоль → в лог (обязательно)
Все сообщения браузера пишутся в tmp/<task>-<TS>/browser-console.log (append-only, §3):
- page.on("console", m => log("[console."+m.type()+"] "+m.text()))
- page.on("pageerror", e => log("[pageerror] "+e.message))
- page.on("requestfailed", r => log("[requestfailed] "+r.url()))
- page.on("response", r => { if (r.status() >= 400) log("[http."+r.status()+"] "+r.url()) })
  Лог не редактируется, только дописывается.

## 3. Скриншоты
- По умолчанию page.screenshot({ path }) без fullPage — детерминированный viewport 16:9.
- fullPage: true — только если явно нужно (документ).
- Имя: tmp/<task>-<TS>/shot-<NN>-<step>.png (KEEP).

## 4. Headless vs headed
- WebGPU/шейдеры — headless: false + --headless=new + системный Chrome (channel: "chrome"), см. .dsh/skills/playwright/SKILL.md, .dsh/skills/browser-automation/SKILL.md.
- Чистый DOM/e2e — headless: true допустим.

## 5. Запреты (§2/§3/§8)
- Нет rm -rf, нет exit, нет перезаписи логов.
- Нет запуска чужих HTTP-серверов без явной команды.
- Браузер закрывается в finally (или afterAll).

## 6. Мини-шаблон (Playwright)
```javascript
import { chromium } from "playwright";
import fs from "fs";
const LOG = "browser-console.log";
const log = (s) => { console.log(s); fs.appendFileSync(LOG, s + "\n"); };
const b = await chromium.launch({ headless: false, channel: "chrome", args: ["--window-size=1920,1080"] });
const ctx = await b.newContext({ viewport: { width: 1920, height: 1080 } });
const p = await ctx.newPage();
p.on("console", m => log("[console."+m.type()+"] "+m.text()));
p.on("pageerror", e => log("[pageerror] "+e.message));
p.on("requestfailed", r => log("[requestfailed] "+r.url()));
await p.goto("http://localhost:5173", { waitUntil: "networkidle" });
await p.screenshot({ path: "shot.png" });
await b.close();
```

## 7. Проверка
- window.innerWidth / window.innerHeight ~ 16/9.
- browser-console.log содержит [console.*], [pageerror], [requestfailed] (или пуст — тоже evidence).
## 8. Windows: npx vs .bin
- `npx playwright` может не видеть локальный `.bin` (ошибка "could not determine executable to run").
- Запускать: `.\node_modules\.bin\playwright.cmd test ...` или `npm run test:e2e -- ...`.
- Браузеры: `.\node_modules\.bin\playwright.cmd install chromium`.
- Проект ESM: `require` в `.js` даст "require is not defined"; писать `import` (`import { test, expect } from "@playwright/test";`).
