---
name: rules-first-task
description: Checklist for the first task in a new session loading skills and POSTMESSAGE
---

# SKILL · rules-first-task (universal)

Чек-лист первого задания новой сессии. Дополняет RULES.md §15 и §16,
не переписывая шаблон §16. Применяется в каждой новой сессии.

## 0. Обязательный минимум (RULES §12, §15)
1. `Get-Content skills\README.md,skills\context\SKILL.md,skills\commands\SKILL.md,skills\powershell-first\SKILL.md`
2. спец: `.dsh/skills/webgpu-debug/SKILL.md`, `.dsh/skills/playwright/SKILL.md` (если есть)
3. `Get-Content skills\postmessage\SKILL.md` — правила межсессионного обмена.
4. Прочитать **`POSTMESSAGE`** (в корне проекта) — последние N строк:
   ```bash
   tail -n 200 "$ROOT/../../POSTMESSAGE" 2>/dev/null || echo "(POSTMESSAGE missing)"
   ```
5. Прочитать свой seen-маркер (если есть): `Get-Content (Join-Path $ROOT ("POSTMESSAGE.seen." + $SESSION_ID)) -ErrorAction SilentlyContinue`.

## 1. Что делать с POSTMESSAGE
- Читать **в начале каждой новой сессии** (первое задание) и **перед каждой крупной правкой** (см. RULES §13).
- Писать через helper: `scripts/postmessage.sh write "<msg>"` (flock + append).
- Не редактировать чужие блоки, не удалять, только append.
- Если в POSTMESSAGE есть `claim <path>` от другой сессии — не трогать этот `<path>`.
- Если есть `ask <text>` к тебе — ответить `answer <text>` через `write`.

## 2. Что добавить в первое задание (кроме снимка)
После снимка ROOT, но до любой правки — вывести:
- `SESSION_ID` (env или `S-$(date +%s)-$$`)
- `wc -l POSTMESSAGE` (сколько накопилось)
- `tail -n 30 POSTMESSAGE` (последние сообщения)
- `cat POSTMESSAGE.seen.$SESSION_ID` (до чего дочитал)
- `ls -la .dsh/skills/` (что есть)

## 3. Если POSTMESSAGE нет
 - НЕ создавать в `$ROOT` (стрэй-ловушка P16): канал = `../../POSTMESSAGE` (§21.1); нет канала — писать «(POSTMESSAGE missing)», не touch.
- Это делает `scripts/postmessage.sh` при первом вызове.
- `.gitignore` уже содержит `POSTMESSAGE.seen.*` и `POSTMESSAGE.lock` (см. скилл `postmessage.md`).

## 4. Конфликты
- Если две сессии пишут одновременно — `flock` в helper сериализует append.
- Если видишь `claim <path>`, а тебе нужен `<path>` — `write "ask <path>: нужен, освободи?"` и ждать `release`.
- Если `rotate` (ротация POSTMESSAGE) — участвовать только после явного `write "rotate ack"`.

## 5. Ссылки
- `.dsh/skills/postmessage/SKILL.md` — формат, поля, helper.
- `scripts/postmessage.sh` — `write`/`read`/`last`.
- `RULES.md` §15 (первое задание), §16 (шаблон — не переписывать).

## KEEP
- .dsh/skills/rules-first-task/SKILL.md
## 6. Платформа (Windows-first)
- Если $env:OS -eq 'Windows_NT' — генерировать .ps1, не bash.
- Запуск: powershell -NoProfile -ExecutionPolicy Bypass -File .\script.ps1
- #requires только в .ps1; в интерактиве падает.
- Внутри двойных кавычек PS 5.1 НЕЛЬЗЯ экранировать кавычку через обратный слеш; используйте одинарные снаружи.
- grep/sed/awk -> Select-String/-replace/-split; clipboard — powershell-first.md §3.

<!-- windows-ps51: updated by update-all-skills -->

<!-- sources: scripts/skills-audit.mjs -->
<!-- updated: 20261030 (audit run S-20261030-175016-12764, RULES.md §12/§15) -->

## 5. Обязательные скиллы (подключены)
DSH грузит их автоматически из двух корней .dsh/skills/ + .dsh/skills/ (SKILL.md + README.md, §20.8d). Ручная загрузка (чат без ФС):
1. .dsh/skills/postgres-readonly/SKILL.md
2. .dsh/skills/postmessage/SKILL.md
3. .dsh/skills/session-handoff/SKILL.md
4. .dsh/skills/trees-workflow/SKILL.md
5. .dsh/skills/escaping-message/SKILL.md
6. .dsh/skills/browser-testing/SKILL.md
7. .dsh/skills/bash-escaping/SKILL.md (историческое имя, файл отсутствует)
8. .dsh/skills/use-ai-grid/SKILL.md
9. .dsh/skills/shader-analysis/SKILL.md
10. .dsh/skills/webgpu-debug/SKILL.md

## 6. Типы заданий
- Прочитать `.dsh/skills/task-types/SKILL.md` — 10 типов заданий (snapshot, read-only, contract, UI change, skills edit, infra diag, build/runtime, browser test, escaping fix, rollback).
- Использовать §1 «Как классифицировать» в начале каждой задачи.

## [TEAM-MODE] 2026-11-07 (§29 LISA-TEAM-V1)
- TEAM-MODE: [ЛИЗА] = тиммейт `liza` (Agent Team, общий ФС-доступ): обмен `send_message`, `ZADANIE -> ADDRESSEE: LEAD (FS)`; человек = цели/приёмка, не транспорт. CHAT-MODE: без изменений (человек-транспорт).
- Нумерация после перенумерации 23:10: STATE-BLOCK = §31, Роли/[STATE] = §32, ЗАДАЧА-КОНТЕКСТ = §36 (старые dev-ссылки §20.10/§20.11/§22 dev читаются по §37 МАППИНГ; релейные §20.9/§20.10/§20.11/§22 не менялись).
- npm-хуки генераторов: `agents:create` / `agents:create:win` (§21.1; бывшие core-pack/core-pack:win упразднены).

<!-- added: doc-sync 2026-11-07 (liza, ACCEPT all) -->

<!-- CHAT-MODE-FIRST-TAKT-LIZA 2026-11-08 -->
## CHAT-MODE первый рабочий такт = ЛИЗА
После T6 первый рабочий такт в CHAT-MODE — `[РОЛЬ: ЛИЗА]` с ANALYSIS-PLAN. `[РОЛЬ: ЛИД]` без ВЫВОДА = `REJECTED, MISSING:LIZA-FIRST`.
<!-- MODEL-REF v1: templates/model.md -->
MODEL: см. templates/model.md (единственный источник правил LIZA→LEAD, ACTIVE_ROLE, ANALYSIS-PLAN)
