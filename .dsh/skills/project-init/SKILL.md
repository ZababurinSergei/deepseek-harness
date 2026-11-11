---
name: project-init
description: Project init - loads AGENTS.md, prints greeting/roles/capabilities, then gathers facts in FS-chat (plane A) or emits the first task to the human in no-FS chat (plane B)
---

# SKILL · project-init (universal)

Инициализация проекта/сессии по канону RULES.md: загрузка `AGENTS.md`, вывод приветствия,
ролей и возможностей, и **первое задание** — двумя методами для двух плоскостей (§41 DUAL-MODE-BOOT).
Правила задаёт `RULES.md` (SOURCE OF TRUTH, §20.8j); скил их не переписывает, а исполняет по шагам.

## 0. Шаг 0 — загрузка канона
1. Прочитать `AGENTS.md` в корне пакета (инжект харнеса = то же содержимое; бюджет 65536 b, §40):
   - pwsh: `Get-Content AGENTS.md -Encoding UTF8 -TotalCount 120`
   - bash: `sed -n '1,120p' AGENTS.md`
2. Проверить начало сессии: строки «Workspace instruction budget … truncated» быть не должно.
   Если есть — артефакт переполнен: перегенерировать (`npm run agents:create:win` / `agents:create`), §40.
3. Тела вне ядра (§16/§16a полностью, §20.8a-s) — из `RULES.md`: границы искать по `Select-String '^## '` / `grep -n '^## '`.

## 1. Шаг 1 — детект плоскости (§41, §29)
- Есть файловая система и инструменты Agent Team (`list_agents`) → **плоскость A / TEAM-MODE**.
- Файлов нет (чат-релей) → **плоскость B / CHAT-MODE**.
- FS есть, команды Agent Team нет → плоскость A, одиночный режим (человек = транспорт, §29.2).

## 2. Шаг 2 — первое сообщение (обе плоскости, T-ПОРЯДОК §20.8n)
Вывести дословно, в этом порядке, без пересказа (§20.8g-a, §1a — кириллица):
1. **T1** приветствие (2 предложения от системы);
2. **T2** блок `=== РОЛИ (обязательно в первом сообщении) ===` … `=== КОНЕЦ РОЛЕЙ ===` (дословно из AGENTS.md);
3. **T3** блоки `=== ВОЗМОЖНОСТИ ===` и `=== КАК ДЕЛАЮТСЯ ЗАПРОСЫ ===`;
4. **T6a** блок `=== РЕЖИМ ===` (TEAM-MODE / CHAT-MODE);
5. два первых задания: [ЛИЗА] — загрузка скилов/экспертов (T4), [ЧАТ] — структура проекта (T5).
Пропуск РОЛЕЙ = `REJECTED, MISSING:ROLES`; пропуск задания = `REJECTED, MISSING:FIRST-TASK`.

## 2a. Шаг 2a — TEAM-INIT: загрузка команды (§43 TEAM-INIT, только TEAM-MODE/плоскость A)
После первого сообщения (T-ПОРЯДОК), лидом:
1. `list_agents` — идемпотентность (существующих не спавнить); состав/статусы — `experts/INDEX.md`.
2. Спавн **всей команды** (лимит тиммейтов 8): `liza` (prompt = liza-boot.md) + эксперты-тиммейты
   `asuse, grid, tree, wiki, gitlab, card, sd` (prompt = `experts/<id>.md` + правило связи
   «все сообщения только `send_message(target:"liza")`» + **EXPERT-START**: до работы квит Лизе
   `STARTED: <формулировка задачи>`, урок #31). Sostav-7: `sd` — v massive (slot vyvoda
   sys-interfaces, operator 2026-11-09); §43a-proksi dlya sd bolshe NE nuzhen.
3. Критерий T6 += TEAM-INIT выполнен (состав в INDEX). CHAT-MODE (плоскость B): состав симулируется
   ролями Человек→[ЛИЗА]→[ЭКСПЕРТА:X]→[ЛИЗА]→[ЛИД/ЧАТ], спавна нет.
4. Полная схема взаимодействия и возможностей — скил `/help` (`.dsh/skills/help/SKILL.md`).

## 3. Шаг 3A — плоскость A (с ФС): получить всю необходимую информацию
Исполнить эталон **§16a** (pwsh, Windows) или **§16** (bash, Linux/macOS) — дословно, меняя только `<TS>`:
`CHECKS → SKILLS READ (два корня .dsh/skills/ + .dsh/skills/) → ROOT TREE (maxdepth 3) → LOGIC → VERDICT → SUMMARY → KEEP`.
Дополнить (§15): `tail -n 200 POSTMESSAGE` (канал на два уровня выше ROOT, §21.1), наличие `RULES.md`,
права записи в `tmp/`, версии инструментов. Артефакты: `tmp/initial-snapshot-<TS>/` (KEEP).
Дальше — `team_task_*` / `send_message` тиммейту `liza` (§29.6–§29.7), человек не транспорт.
- **GPO-капкан (Windows, D1):** запуск эталона как файла падает «…is not digitally signed» (RemoteSigned блокирует `powershell -File` и `&`). Канал: `powershell -NoProfile -Command "Get-Content -Raw -Encoding UTF8 <файл> | Invoke-Expression"` (тот же обход, что npm-хук `agents:create:win`, §21.1/§41). Сохранить извлечённый §16a в `.ps1` **с BOM** (§21.1) перед прогоном.

## 4. Шаг 3B — плоскость B (без ФС): первое задание человеку
- Роль [ЛИЗА] = вторая личность чата; [ЧАТ] обобщает; адресат = **`ADDRESSEE: ЧЕЛОВЕК`** (§20.8b, §29.5).
- Единственный fenced-блок сообщения = эталон §16 (TRANSPORT: bash) **или** §16a (TRANSPORT: pwsh) по ОС исполнителя
  (§21, §20.8q: ОДИН шаблон в одном сообщении). Блок готов к запуску, без плейсхолдеров.
- После блока — строка «Запустите этот блок и пришлите вывод» (§23). Ответ без двух приветствий ДО блока = НЕДЕЙСТВИТЕЛЕН (T4/BOOT).
- Канон чата без ФС — полный LOAD (`core-pack.md` из генератора, буфер обмена): в нём есть §16/§16a, роли, §20-протокол, матрица §41.
- Ответ исполнителя = OTVET (1/2) СКРИПТ с RAW-выводом + (2/2) VYVOD; данных нет → `NULL=evidence` (§20.10).

## 5. Шаг 4 — закрытие инициализации
- Сессия загружена, когда выполнены оба первых задания (скилы/эксперты + структура ROOT), T6.
- Формат каждого сообщения: `[STATE]` (enum §32/DIGEST-V3) → текст ≤3 строк → VERDICT/DELTA (`SRC=path:sha1-8`) →
  блок ВОПРОСЫ (≤3 блокера) → `=== ЗАДАНИЕ НА ВЫПОЛНЕНИЕ ===` (ровно один исполнимый fenced-блок, последний элемент).
- Гейт чистоты скилов: `node scripts/skills-audit.mjs` СРАЗУ после перегенерации канона, нужен exit 0 (§40).

## 6. Запреты
- Английский пересказ канона = `REJECTED, MISSING:LANG` (§1a).
- Пересказ РОЛЕЙ (не дословно) = `REJECTED, MISSING:ROLE` (§20.8g-a).
- Задание plain-текстом (не скрипт) = незакрытый такт (§20.7).
- Два fenced-блока в одном сообщении = `REJECTED, MISSING:ONE-TEMPLATE` (§20.8p).
- Задавать себе «применить?» = нарушение §20.8o (применять без вопроса).

## 7. Покрытие матрицы §41 — функции, не разобраные в шагах 0–5 (полные тела: AGENTS.md §41, liza-boot.md)
- Скилы (B-метод): `SKILLS_REQUEST` → DELTA (i/n) + inbox-<id>.md; A-метод — чтение .dsh/skills/ + .dsh/skills/ (шаг 3A).
- Вопросы: A — `ask_user_question` (варианты); B — блок ВОПРОСЫ (≤3 блокера) после VYVOD (§20.8h).
- Приёмка: один enum `ACCEPT | REJECT | DEFERRED-LOCAL | DEFERRED-REMOTE | не открывал` для обеих плоскостей.
- Визуальная оценка: A — CANNOT, просить оператора; B — сильная сторона чата (критерии, приёмка).
- Память такта: A — `tmp/relay-<TS>/NNN.md` + relay-строка в POSTMESSAGE (§20.5); B — контекст чата + sha1-8 в DELTA.
- Граф/handoff: A — `tmp/graph-<TS>/` + `HANDOFF.md` (§17); B — HANDOFF текстом в DELTA (сегменты S1..Sn).
- Коммит/push: git — только лид; B — запрос лиду, приёмка `DEFERRED-REMOTE@commit`.
- POSTMESSAGE (B): relay-строка текстом; пишет и читает лид (`tail -n 200`).
- Прочие строки матрицы (канон, первое сообщение, первое задание, ЛИЗА, факты/замеры, [STATE], транспорт) — шаги 0–5 выше; транспорт §21, GPO-капкан — шаг 3A.

## KEEP
- .dsh/skills/project-init/SKILL.md

<!-- sources: AGENTS.md, RULES.md, scripts/win/agents-create.ps1, liza-boot.md -->
<!-- added: project-init 2026-11-08 (lead, двухплоскостной бут по §41/§42; эталоны §16/§16a; приёмка оператора) -->
<!-- d3: list_agents -->

<!-- CHAT-MODE-FIRST-TAKT-LIZA 2026-11-08 -->
## 3B-1. CHAT-MODE: первый рабочий такт = ЛИЗА (2026-11-08)
После закрытия инициализации (T6 «СЕССИЯ ЗАГРУЖЕНА») первый рабочий такт **всегда** открывается `[РОЛЬ: ЛИЗА]` с ANALYSIS-PLAN (3-5 шагов). Метка `[РОЛЬ: ЛИД]` в этом такте = `REJECTED, MISSING:LIZA-FIRST`.
<!-- MODEL-REF v1: templates/model.md -->
MODEL: см. templates/model.md (единственный источник правил LIZA→LEAD, ACTIVE_ROLE, ANALYSIS-PLAN)
