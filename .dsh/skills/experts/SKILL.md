---
name: experts
description: "Analyzer expert pack: experts/<id>.md files with SKILLS, TRIGGERS and METHOD for multi-perspective analysis"
whenToUse: "Use when a task needs a named analyst expert, a expert trigger match, or several independent perspectives on one evidence set."
---

# SKILL · experts (universal)
<!-- sources: .dsh/skills/experts/SKILL.md, experts/INDEX.md, experts/COMMAND.md, experts/asuse.md, experts/grid.md, experts/tree.md, experts/wiki.md, experts/gitlab.md, experts/card.md, experts/sd.md, RULES.md, scripts/win/agents-create.ps1 -->
<!-- synced: 20261106 (imported from project skills by format migration) -->



Набор личностей-анализаторов. Каждая личность — файл `experts/<id>.md` с `## SKILLS`, `## TRIGGERS`, `## METHOD`.
Загрузка в начале сессии:

    cat experts/INDEX.md
    find experts -maxdepth 1 -name '*.md'

Активация под текст задачи:

    bash scripts/expert-activate.sh "<текст задачи>"
    # -> EXPERTS OK: webgpu-pass,front-limit
    # -> tmp/expert-activate-<TS>/index.tsv (id, priority, triggers_hit, active)

Правила:
- Личность включается **только** при совпадении триггера (`grep -Fqi`).
- Несколько активных — сортировать по `priority` (меньше = важнее).
- Если `EXPERTS NONE` — личность не нужна, работать по общим правилам.
- Триггеры — **маркеры** из реальных логов/кода, не «общие слова».

## Таблица активации 7 экспертов (§2 / RULES §33) — P7b, 2026-11-08
- Канон 7 экспертов (id+priority ASC, §20.8g-a): T2 (AGENTS.md), RULES.md §33 (таблица «Галактика | Priority |», RULES.md:548), core-pack.md §2.
- `experts/INDEX.md` + файлы экспертов: id/priority = 7/7 MATCH канону; триггеры INDEX/файлов — расширенные (маркеры активации), в §33 — сжатые.
- Генераторы (core-pack `{TABLE}`): ищут заголовок таблицы в AGENTS.md → не находят (§33 вне ядра) → печатают fallback-hardcode; полный носитель таблицы = RULES.md §33 (патч источника — зона лида).
- **Примечание 2026-11-08:** 7 nk-elite экспертов = ANALYZER-режим (роли анализа Лизы); для infoenergo-ui-задач не активировать.

## КОМАНДА ЛИЗЫ (EXPERT-SKILLS-INLINE-V3, §43c; оператор 2026-11-11) — ЛИД ПРИМЕНЯЕТ СКИЛЫ ЭКСПЕРТОВ САМ
**ПРАВИЛО ОПЕРАТОРА (2026-11-11, приоритет над V2-текстом ниже): сабагенты и эксперто-тиммейты НЕ спавнятся и НЕ загружаются отдельно — лид читает носители экспертов и применяет их скилы сам (inline).**
- **SKILL-INIT вместо TEAM-INIT:** никаких `spawn_teammate`/`subagent` для экспертов. Вместо спавна — загрузка носителя: `experts/<id>.md` (SKILLS/TRIGGERS/METHOD); при отсутствии файлов — этот SKILL.md + скилы домена из каталога харнеса (`skill` tool). Критерий: состав прочитан + список применённых скилов в DELTA (SRC=path:sha1-8).
- **EXPERT-DECISION (новый enum):** `USE-SKILL <id>` (лид применил METHOD сам) | `USE-SKILL-LIZA <id>` (Лиза сама) | `SKIP` с evidence. Значения `USE-SPAWN` и прокси-субагент — **УСТАРЕЛИ, не применять**.
- **Отчёт:** квита EXPERT-START и агентского маркера «=== ОТЧЁТ ЭКСПЕРТА ПРОГОНА ===» нет; сегмент анализа помечается `[ЭКСПЕРТА:X] (inline)` внутри сообщения лида/Лизы + SRC носителя скила.
- **STATE:** `EXPERT=<id|->` + `EXPERT_STATE=INLINE-DONE|SKIP`; `LIZA_STATE` без DELEGATING/AWAITING_EXPERT; `WAITING_FOR=LIZA|NONE`.
- **Носители в этом ROOT:** каталог `experts/` (INDEX.md / COMMAND.md / <id>.md) **отсутствует** (проверено globom 2026-11-11) — рабочий носитель только этот SKILL.md + скилы харнеса (defect: SKILL-INIT по fallback).
- Разрешено: `skill`, `read`/`grep`, `team_task_*` (лид↔Лиза). Запрещено: `spawn_teammate` для экспертов, `subagent`/`subagent_fork` для экспертов, `=== SPAWN-SUBAGENT-REQUEST ===`.

## КОМАНДА ЛИЗЫ (EXPERT-TEAM-V2, §43; оператор 2026-11-09) — УСТАРЕЛО с 2026-11-11, см. V3 выше
- 7 доменных экспертов (`experts/{asuse,grid,tree,wiki,gitlab,card,sd}.md`; sys-interfaces vyveden iz massiva, operator 2026-11-09; sd — timmeyt s soderzhanie STUB TODO-find); polnyj kontur, rang kanalov i STATE — **experts/COMMAND.md (V3)**; pravila — RULES.md/AGENTS.md §43.
- Ранг TEAM-MODE: (1) **эксперт-тиммейт** (`spawn_teammate(name=<id>)` спавнит ЛИД по запросу Лизы; задача = `team_task_create(owner=<id>)`/`send_message(target=<id>)`) → (2) прокси-субагент (`=== SPAWN-SUBAGENT-REQUEST ===`, лид-транспорт; проверен t12/13/16/19) → (3) `USE-LOCAL`. Прямые субагенты экспертов у Лизы отвергаются харнесом (depth-2).
- Диспетчер = **ЛИЗА**: EXPERT-DECISION `USE-SPAWN <id> | USE-LOCAL <id> | SKIP`; ≤3 параллельно; правило связи эксперта: только `send_message(target:"liza")`, отчёт — маркер `=== ОТЧЁТ ЭКСПЕРТА ПРОГОНА ===`, `ADDRESSEE: LIZA`, SRC=полный путь от ROOT:sha1-8 (урок #27); ЛИД с экспертами НЕ общается.
- Ответы экспертов — формат liza-boot.md; write-scope доменов advisory, сериализует Лиза (board team_task_* = лид/Лиза).
- STATE-расширение: `LIZA_STATE += DELEGATING|AWAITING_EXPERT`; `EXPERT_STATE ∈ IDLE|SCANNING|ANALYZING|REPORTING|BLOCKED|DONE|STUB-BLOCKED`; `[STATE]`-строка += `EXPERT=<id|-> EXPERT_STATE=…`; уровень лида — `WAITING_FOR=LIZA|NONE`.
- CHAT-MODE (плоскость B): та же цепочка ролями: Человек→[ЛИЗА]→[ЭКСПЕРТА:X]→[ЛИЗА]→[ЧАТ/ЛИД]→Человек, формат отчёта единый.
- STUB-эксперты (sd): первый такт = разведка TODO-find, операции запрещены; заглушки помечены в файлах экспертов (card — снята takt-10).
