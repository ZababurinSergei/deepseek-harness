---
name: printf-rules-workers
description: "Worker and supervisor operations: rollback from bak, shebang rule, pgrep restarts, state.json pids, node --check failures, service vs svc, stdio fd, node:sqlite"
whenToUse: "Use when restarting supervisors, recreating workers, diagnosing worker crashes, rolling back from .bak, or wiring node:sqlite."
---

<!-- sources: .dsh/skills/printf-rules/SKILL.md -->
<!-- synced: 20261106 -->
## 13. Откат из bak после syntax-сбоя

Когда regex-патч задел шапку (например `#!/usr/bin/env node`) и `node --check` даёт `SyntaxError: Invalid or unexpected token`, **не пытайтесь править дальше**:
1) `cp -n "$BAK" "$PATCHED"` — вернуть исходник;
2) `node --check` = 0 (обязательный gate);
3) переписать патч узко: менять **только тело** функций, не вставлять импорты перед shebang;
4) `cp -n` исходника в новый `bak-<step>` до повторного патча.

Шаблон:

    node --check "$F" >/dev/null 2>&1 || { cp -n "$BAK" "$F"; node --check "$F"; }

## 14. Не патчить shebang

Если `node --check` даёт `SyntaxError` на строке N, и в этой строке стоит `#!/usr/bin/env node` — файл **уже невалиден** (shebang не на первой строке). Не пытайтесь править regex’ом — **восстанавливайте из валидного bak** (`node --check bak` = 0).
Проверки:
- `sed -n '1p' file` — первый символ `#!` только в строке 1;
- скрипт поиска валидного bak: перебрать `*.bak-*`, проверить `node --check`, взять самый свежий с rc=0.
И только **после** восстановления — узкий патч в теле (например `stdio: ['ignore', fd, fd]`), без вставок импортов перед `#!`.

### 14.1. Shebang не на строке 1

`SyntaxError: Invalid or unexpected token` на `#!/usr/bin/env node` = shebang **не первая строка**. **Не ищите валидный bak** (может быть, его нет), а переставьте:

    node -e 'const fs=require("node:fs");const p=process.argv[1];const a=fs.readFileSync(p,"utf8").split(/\n/);const i=a.findIndex(l=>l.trim()==="#!/usr/bin/env node");if(i>0){const b=a.slice(0,i),c=a.slice(i+1);fs.writeFileSync(p+".tmp",["#!/usr/bin/env node"].concat(b).concat(c).join("\n"));fs.renameSync(p+".tmp",p);console.log("MOVED");}else{console.log("OK/NO");}' file.mjs

Затем `node --check file.mjs` — обязательный gate. Патчить файл допустимо только **после** `rc=0`.

## 15. Restart supervisor: kill by pgrep

`supervisor.state.json` хранит **PID’ы сервисов** (`services.*.pid`), но не свой собственный. Если `sup_pid=null`, kill через state.json **не останавливает supervisor**. Правильно:

    SUP_PIDS="$(pgrep -f 'node[[:space:]]+scripts/supervisor.mjs' | grep -v "^$$$")"
    for PID in $SUP_PIDS; do kill "$PID"; done
    # wait 5s; ps -> пусто
    nohup node scripts/supervisor.mjs > logs/supervisor.out 2>&1 &
    # wait up to 15s; curl http://127.0.0.1:3001/api/health == 200
    # wait up to 20s; test -s logs/simbad-worker.log

Проверка: `pgrep -af 'scripts/supervisor.mjs'` — один процесс, а не старый+новый.

## 16. state.json pids=null → пересоздание воркеров

После правки `supervisor.mjs` (например stdio fd) нужно, чтобы supervisor **пересоздал** воркеров — иначе старые остаются с `stdio:'pipe'`.
Алгоритм:
1. `pgrep -f "node.*scripts/supervisor.mjs|scripts/simbad-to-sqlite.mjs|scripts/populate-db.mjs"` → `kill`, через 3s `kill -9` если жив.
2. В `logs/supervisor.state.json` обнулить `services.*.pid = null` и `sup_pid = null`, затем `nohup node scripts/supervisor.mjs > sup.out 2>&1 &`.
3. Ждать до 15s `curl :3001/api/health == 200`; до 20s `test -s logs/simbad-worker.log`.
4. Проверить первые строки: `tail logs/simbad-worker.log` — должны быть `[simbad-to-sqlite] ids из --ids: …`.

## 17. RuntimeError после node --check

`node --check` проверяет только синтаксис. Если `supervisor.out` содержит `[WARN] fatal service is not defined`, значит **в самом коде** есть вызов `fatal(...)` или `service.fatal(...)` без объявления. `node --check` это пропустит.

Правило:
- после перезапуска сервиса — **всегда** `head -n 30 logs/supervisor.out`; если есть `[WARN] … not defined` / `[fatal]`, это RuntimeError, а не конфиг;
- быстрая правка: объявить `function fatal(...args) { warn(...args); }` в шапке (после `warn`) — это делает supervisor устойчивым к «fatal»-вызовам, не блокируя старт;
- воркеры (`simbad-worker`, `populate-worker`) стартуют первыми строками **до** сетевых вызовов — `ss_bytes>0` означает «path логирования работает», даже если SIMBAD 500.

## 18. Диагностика воркера: сначала ручной `node scripts/<worker>.mjs`

Когда supervisor «стартует, но лога нет», **сначала** запусти воркер вручную:

    node scripts/simbad-to-sqlite.mjs --ids=9 --verbose > out 2> err

Если в `out` есть первая строка (`[simbad-to-sqlite] ids из --ids: …`) — воркер жив, проблема в `stdio` supervisor’а (`openServiceLog` не подключён к spawn). Если первая строка тоже **не появляется** — проблема в воркере (падение до первого `console.log`, `EACCES`, `SyntaxError`). И только **потом** смотри `supervisor.out` на `fatal … not defined` — это **RuntimeError**, `node --check` его не ловит.

## 19. Не путать `service` и `svc`

В `supervisor.mjs` в теле `runService(svc, …)` переменная называется **`svc`**, а не `service`. Патч, вставляющий `service.name` в тело `spawn`, вызывает **`ReferenceError: service is not defined`**, который перехватывает `main().catch(e => warn('fatal', e.message))` — и в `supervisor.out` появляется `[WARN] fatal service is not defined` **без stack trace**. `node --check` этого не ловит.

Правило: после любых вставок `*` в `spawn` — **`grep -n 'service\\.name\\|svc\\.name' supervisor.mjs`**; в `runService` только `svc.name`, в `runCronJob` только `job.name`.

И `Object.assign({ stdio: [...] }, { cwd, env, stdio: [...] })` **не работает**: второй объект перетирает `stdio`. Передавайте `stdio` в один объект: `_o = { cwd, env, stdio: ['ignore', fd, fd] }`.

## 19. Не путать `service` и `svc`

В `supervisor.mjs` в теле `runService(svc, …)` переменная называется **`svc`**, а не `service`. Патч, вставляющий `service.name` в тело `spawn`, вызывает **`ReferenceError: service is not defined`**, который перехватывает `main().catch(e => warn('fatal', e.message))` — и в `supervisor.out` появляется `[WARN] fatal service is not defined` **без stack trace**. `node --check` этого не ловит.

Правило: после любых вставок в `spawn` — `grep -n 'service\.name\|svc\.name' supervisor.mjs`; в `runService` только `svc.name`, в `runCronJob` только `job.name`.

И `Object.assign({ stdio: [...] }, { cwd, env, stdio: [...] })` **не работает**: второй объект перетирает `stdio`. Передавайте `stdio` в один объект: `_o = { cwd, env, stdio: ['ignore', fd, fd] }`.

## 20. stdio: fd → child.stdout === null

При `stdio: ['ignore', fd, fd]` в `spawn` — `child.stdout` и `child.stderr` **равны `null`**. Если код безусловно делает `child.stdout.on('data', …)` → `TypeError: Cannot read properties of null (reading 'on')`, который ловит `main().catch(e => warn('fatal', e.message))` и пишет `[WARN] fatal Cannot read properties of null`.

Правило: когда `stdio` переводится на файл-fd, **убрать** подписки `.on('data')` или обернуть их:

    if (child.stdout) child.stdout.on('data', …);
    if (child.stderr) child.stderr.on('data', …);

Файл `<name>.log` уже получает весь stdout/stderr через fd — подписки больше не нужны.

## 21. stdio:fd → не подписывайся на `child.stdout`

Если `spawn` использует `stdio: ['ignore', fd, fd]`, то `child.stdout === null` и `child.stderr === null`. Любая подписка `.on('data', …)` даёт `TypeError: Cannot read properties of null (reading 'on')`. Это ловится `main().catch(e => warn('fatal', e.message))` → `[WARN] fatal Cannot read properties of null`.

Правило:
- При stdio: fd — **не подписываться** на `child.stdout/stderr`; файл `<name>.log` получает данные через fd.
- Строки вида `child.stdout.on('data', …)` **удалять целиком**, а не оборачивать в try/catch — `null` бросается **до** `try`.
- `appendToSupervisorLog`/`logStream` остаются для собственного лога supervisor’а (`START/RESTART/health`), но **не** для stdout воркера.

## 22. node:sqlite как замена better-sqlite3

Node 22 включает `node:sqlite` (`DatabaseSync`). Для read-only GUI это надёжнее `better-sqlite3`, т.к. не требует `node-gyp`/prebuilt и не падает на `Could not locate the bindings file`.

    import { DatabaseSync } from "node:sqlite";
    const db = new DatabaseSync("data/stars.db", { readOnly: true });
    db.prepare("SELECT 1 AS x").get();
    db.close();

API: `prepare().all()/get()/run()`, `db.close()`. Параметры: `readOnly: true` — обязательный, если база должна оставаться неизменной. Для пагинации: `LIMIT ? OFFSET ?` работают, как в `better-sqlite3`.
