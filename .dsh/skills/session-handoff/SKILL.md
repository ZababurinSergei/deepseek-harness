---
name: session-handoff
description: Session transfer format for POSTMESSAGE and HANDOFF; first message of new session is RULES 16
---

# SKILL · session-handoff (universal)

<!-- created: 20261026 -->
<!-- sources: RULES.md .dsh/skills/postmessage/SKILL.md .dsh/skills/rules-first-task/SKILL.md -->

Навык **переноса сессии**: что и **в каком формате** писать в `POSTMESSAGE` и `docs/HANDOFF.md`,
чтобы новая сессия **начала** с **правильного** первого сообщения, а **не** с правок.

## 0. ГЛАВНОЕ — первое сообщение новой сессии
**Первое сообщение новой сессии — это `RULES.md §16` ДОСЛОВНО** (шаблон, не переписывать).
Оно **обязательно** и **идёт первым**, **до** любых чтений/правок.
В `POSTMESSAGE`/`HANDOFF` это пишется **явно**:
> **Первое сообщение новой сессии:** запустить `RULES.md §16` (снимок ROOT + skills + POSTMESSAGE + facts).
> Пока снимок и `SKILLS OK` не собраны — прочие задачи НЕ начинать.

## 1. Формат `POSTMESSAGE` (append-only, см. .dsh/skills/postmessage/SKILL.md)
Каждое сообщение — **блок**:

    ## session=<ID> @ <ISO8601>
    <многострочный текст>
    ---

Правила:
- **Заголовок** `## session=<ID> @ <ISO>` — **обязателен**.
- **Разделитель** `---` — **обязателен**.
- Только **append** (через `scripts/postmessage.sh write` или `flock` + `>>`).
- Не редактировать/удалять чужие блоки.
- В начале сессии: `session-start <ID> <ISO>`.
- В конце: `session-end <ID>` + итог.

## 2. Формат `docs/HANDOFF.md` (append)
Секция **на каждую сессию**:

    ---
    ## Сессия <TS> — <краткое название>

    **Первое сообщение новой сессии:** запустить `RULES.md §16`, затем читать skills + POSTMESSAGE + этот HANDOFF.

    **CONFIRMED (рантайм):**
    - <факт> | evidence: <путь:строка> / <PROBE>
    - ...

    **Гипотеза (следующий шаг):**
    - <что править> | где: <файл:строка> | как проверить: <команда/PROBE>

    **Откаты / оставлено (безвредно):**
    - откат: <файл.bak-...> -> <файл>
    - оставлено: <...>

    **Бэкапы:** <glob-маски, не полный список>

## 3. Что обязательно (минимальный набор)
- `ROOT`, `TS`, `SESSION_ID`.
- **Root cause** (1–3 строки) — **не** «всё сломалось».
- **CONFIRMED** — каждый факт с evidence (путь:строка / PROBE / `grep`-вывод).
- **Гипотеза** — с меткой `[ГИПОТЕЗА]`, **что** и **где** править, **как** проверить.
- **Откаты** — что откатили, что оставили.
- **Бэкапы** — glob (`*.bak-*`), **не** полный список.
- **Первое сообщение новой сессии** — `RULES.md §16` (дословно).

## 4. Что НЕ писать
- «Всё плохо»/«надо чинить» без evidence.
- Непроверенные догадки **как** факты (метка `[ГИПОТЕЗА]` обязательна).
- Полные диффы/логи (только пути + строки).
- **Не** переписывать `RULES.md §16` — только **ссылаться**.

## 5. Чек-лист закрытия сессии
1. `POSTMESSAGE`: `session-end <ID>` + итог + «первое сообщение — RULES §16».
2. `docs/HANDOFF.md`: секция `## Сессия <TS>` по формату §2.
3. `CHANGES:` — список файлов (относительно ROOT).
4. `BACKUP:` — glob-маски.
5. `KEEP:` — `tmp/<task>-<TS>/`.

## KEEP
- .dsh/skills/session-handoff/SKILL.md

## Ссылки (для skills-audit)

- `RULES.md §9/§15/§16` — задание, первое задание, шаблон.
- `.dsh/skills/postmessage/SKILL.md` — формат и протокол обмена.
- `.dsh/skills/rules-first-task/SKILL.md` — чек-лист первого задания.
## Windows / PowerShell 5.1
- HANDOFF append: `Add-Content -Path docs\HANDOFF.md -Value  ## TARGET_PATTERN (added 20261026-123054)  TARGET_PATTERN: StarfieldModule|StarfieldShader|VoxelMonitor|ShipController|shaderDataConverter|ts-fallback|server-routes|sky\.(ts|html)  # Использование: §16 в RULES.md читает TARGET_PATTERN отсюда, а не из RULES. # Меняй pattern здесь под текущий проект — RULES.md остаётся универсальным.  -Encoding UTF8`.
- Ссылка на формат скриптов: `.dsh/skills/powershell-first/SKILL.md`.

<!-- windows-ps51: updated by update-all-skills -->

## [TEAM-MODE] 2026-11-07 (§29 LISA-TEAM-V1)
- TEAM-MODE: [ЛИЗА] = тиммейт `liza` (Agent Team, общий ФС-доступ): обмен `send_message`, `ZADANIE -> ADDRESSEE: LEAD (FS)`; человек = цели/приёмка, не транспорт. CHAT-MODE: без изменений (человек-транспорт).
- Нумерация после перенумерации 23:10: STATE-BLOCK = §31, Роли/[STATE] = §32, ЗАДАЧА-КОНТЕКСТ = §36 (старые dev-ссылки §20.10/§20.11/§22 dev читаются по §37 МАППИНГ; релейные §20.9/§20.10/§20.11/§22 не менялись).
- npm-хуки генераторов: `agents:create` / `agents:create:win` (§21.1; бывшие core-pack/core-pack:win упразднены).

<!-- added: doc-sync 2026-11-07 (liza, ACCEPT all) -->
