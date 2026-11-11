---
name: printf-rules-sse-logs
description: "SSE live status in Express, merged log stream with history, worker stdout to a separate log, read-only SQLite for a GUI"
whenToUse: "Use when streaming live status over SSE, merging logs, redirecting worker stdout, or exposing a read-only SQLite view."
---

<!-- sources: .dsh/skills/printf-rules/SKILL.md -->
<!-- synced: 20261106 -->
## 9. SSE в Express (live-стрим статуса)

`Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`. После заголовков — `res.flushHeaders()`. Данные — `res.write("data: <json>\\n\\n")`; **не** `res.send`/`res.end` до конца потока. На `req.on('close')` — `clearInterval` и `res.end()`. Пример:

    res.setHeader('Content-Type','text/event-stream');
    res.setHeader('Cache-Control','no-cache');
    res.setHeader('Connection','keep-alive');
    res.flushHeaders();
    const t = setInterval(() => res.write(`data: ${JSON.stringify(s)}\n\n`), 1000);
    req.on('close', () => { clearInterval(t); res.end(); });

Клиент: `new EventSource('/events')`; `es.onmessage = e => …`. Источник формата: MDN/Express SSE [citation:19][citation:20][citation:22].

## 10. Read-only SQLite для GUI

`better-sqlite3`: `new Database(path, { readonly: true, fileMustExist: true })` — открывает без права записи и без WAL-переключения. Закрывать после запроса: `db.close()`. Для счётчиков в GUI — только `SELECT COUNT(*)`. Источник: docs/api [citation:5][citation:13].

## 11. SSE + объединённый log-stream (история + текущее)

Когда воркеров несколько и у каждого свой лог, «сейчас» собирается из нескольких файлов:
- читаем по N последних строк из каждого (`K` файлов, `N`=20..60),
- складываем в `[{src, line}]`,
- режем до последних `N` (история = последние строки по времени, не по файлам),
- `current` = по последней непустой строке «самого активного» воркера (эвристика: больше непустых строк в хвосте),
- отдаём в SSE `/events` как `event: snapshot` — клиент рендерит `Now` и `History`.
Не делайте `tail -f` в SSE; `setInterval(1s)` дешевле и не блокирует.
Источник: паттерн Express SSE + чтение файлов (fs.readFileSync, стараться держать ≤64 KB на файл).

## 12. Worker-stdout в отдельный лог

Supervisor на `child_process.spawn(cmd,args)` должен направлять stdout/stderr воркера в `logs/<name>.log`, а не в `nohup.out` — иначе GUI/история не смогут показать «что сейчас делает воркер».
Правильно:
- `const fd = fs.openSync(path.join('logs', name + '.log'), 'a')`
- `spawn(cmd, args, { stdio: ['ignore', fd, fd] })`
- параллельно `child.stdout?.on('data', d => appendFileSync('logs/supervisor.log', '[' + name + '] ' + d))` — чтобы `tail supervisor.log` работал как «история».
Тогда GUI читает оба лога без `tail -f`, а `currentWorker()` находит активного воркера по свежей строке.
