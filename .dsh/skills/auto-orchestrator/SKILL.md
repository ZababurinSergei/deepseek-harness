---
name: auto-orchestrator
description: "Orchestrate nk-elite-orillusion-map roadmap stages across parallel sessions via POSTMESSAGE, with stage checks and auto-launch"
whenToUse: "Use when asked to run, continue, auto-launch or supervise multi-stage work in parallel sessions of nk-elite-orillusion-map."
---

# SKILL — auto-orchestrator (параллельные сессии)
<!-- sources: .dsh/skills/auto-orchestrator/SKILL.md -->
<!-- synced: 20261106 (imported from project skills by format migration) -->



## 1. Роль
Ты — **оркестратор**. Ты не выполняешь этапы сам (если пользователь не попросит), а **управляешь** параллельными сессиями через `POSTMESSAGE`.
Твоя задача: после каждого обновления `POSTMESSAGE` проверить статус этапов и задать пользователю **один** вопрос: "Запустить следующий этап?"

## 2. Алгоритм
1. `tail -n 200 POSTMESSAGE` — прочитать.
2. Найти этапы (строки `stage=N status=...`) для N=1..5.
3. Построить карту: `{1: CONFIRMED, 2: DEFERRED, ...}`.
4. Найти **первый** этап, у которого статус **не** `CONFIRMED` и **не** `ALREADY_DONE`.
5. Если такого нет — сообщить: "Все этапы CONFIRMED, движок собран." и выйти.
6. Если есть — это `stage=K`. Спросить пользователя: "Этап K-1 завершён. Запустить этап K (<описание из roadmap>)? (да/нет)".
7. Дождаться ответа.
8. Если "да" — выполнить этап K в **этой же сессии** (по инструкции из `parallel-sessions.md` §6).
9. Если "нет" — записать `stage=K status=DEFERRED reason=user_declined` и завершить.

## 3. Как выполнять этап K
- **Этап 1:** `tests/core/EngineContext.ts` — класс с `register`, `get`, `inject`.
- **Этап 2:** `tests/plugins/StarfieldPlugin.ts` — `apply(ctx)`, регистрирует `ctx.starfield`.
- **Этап 3:** `tests/plugins/ShipPlugin.ts` — `inject: ["starfield"]`, регистрирует `ctx.ship`.
- **Этап 4:** `tests/plugins/VoxelPlugin.ts` — `inject: ["ship"]`, регистрирует `ctx.voxels`.
- **Этап 5:** интеграция в `tests/sky.ts` — только `EngineContext` + плагины.

## 4. Обязательные проверки
- После создания файла: `npm run build:sky` — `BUILD_OK=yes`.
- Если `BUILD_FAILED`: откат к бэкапу, записать `status=BUILD_FAILED`, спросить: "Повторить этап K?"
- Если `BUILD_OK`: записать `stage=K status=CONFIRMED session=<S> ts=<ISO> file=<path> evidence=build_ok=yes KEEP=<dir>`.

## 5. Авто-запуск (по запросу пользователя)
Если пользователь говорит: "Запусти весь пайплайн сам" — выполнить этапы 1..5 последовательно, без вопросов. После каждого этапа писать `CONFIRMED` в `POSTMESSAGE`.

## 6. Команда для пользователя
Пользователь может в любой момент сказать:
- **"статус"** — прочитать `POSTMESSAGE` и показать таблицу этапов.
- **"запусти этап N"** — выполнить этап N (если зависимости готовы).
- **"запусти всё"** — выполнить все этапы 1..5 подряд.
- **"что дальше?"** — прочитать `POSTMESSAGE` и задать вопрос про следующий этап.

## 7. Правила
- Не трогать `orillusion/src/**`.
- Все строки — через `printf` / `postmessage.sh write`.
- Не дублировать `CONFIRMED` этапы (`ALREADY_DONE`).
- Бэкапы перед правкой существующих файлов.

## [TEAM-MODE] 2026-11-07 (§29 LISA-TEAM-V1)
- TEAM-MODE: [ЛИЗА] = тиммейт `liza` (Agent Team, общий ФС-доступ): обмен `send_message`, `ZADANIE -> ADDRESSEE: LEAD (FS)`; человек = цели/приёмка, не транспорт. CHAT-MODE: без изменений (человек-транспорт).
- Нумерация после перенумерации 23:10: STATE-BLOCK = §31, Роли/[STATE] = §32, ЗАДАЧА-КОНТЕКСТ = §36 (старые dev-ссылки §20.10/§20.11/§22 dev читаются по §37 МАППИНГ; релейные §20.9/§20.10/§20.11/§22 не менялись).
- npm-хуки генераторов: `agents:create` / `agents:create:win` (§21.1; бывшие core-pack/core-pack:win упразднены).

<!-- added: doc-sync 2026-11-07 (liza, ACCEPT all) -->
