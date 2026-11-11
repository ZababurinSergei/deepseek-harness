---
name: chat-mode-lead
description: "Two-phase cycle for CHAT-MODE without filesystem: [ЧАТ]→[ЛИЗА] analysis→task→human; [ЧАТ]→[ЛИД] summary→next task."
---

# SKILL · chat-mode-lead (CHAT-MODE no-FS)

## 1. Назначение
Для чата **без доступа к ФС** (FS=no, CANNOT=[fs,visual-files,probe]).
Единственный транспорт — **человек** (bash/pwsh).
Каждая фаза = **анализ [ЧАТ] в роли** + **задание человеку** + **ожидание OTVET**.

## 2. Двухфазный цикл (§20.8r)
**Фаза A — [ЧАТ] в роли [ЛИЗЫ]:**
1. [ЧАТ] получает ЗАПРОС/факты от человека.
2. [ЧАТ] анализирует **в роли [ЛИЗЫ]**: скилы, POSTMESSAGE, факты, риск.
3. [ЧАТ] выдаёт **задание человеку** (OTVET 1/2 SKRIPT + OTVET 2/2 VYVOD + ВОПРОСЫ).
4. Человек выполняет и присылает **VYVOD**.

**Фаза B — [ЧАТ] в роли [ЛИДА]:**
1. [ЧАТ] принимает VYVOD от человека.
2. [ЧАТ] анализирует **в роли [ЛИДА]**: VERDICT (H1..Hn), DELTA, обобщение.
3. [ЧАТ] выдаёт **следующее задание человеку** (в т.ч. фикс, следующий шаг).
4. Повтор.

## 3. Форматы (канон §20)
- OTVET 1/2: SKRIPT (fenced bash/pwsh, §21).
- OTVET 2/2: VYVOD (интерпретация, VERDICT, DELTA, ВОПРОСЫ).
- ZADANIE → `ADDRESSEE: ЧЕЛОВЕК` (§20.8b).
- VERDICT (H1..Hn), DELTA (≤120, SRC=path:sha1-8), STATE (§32).

## 4. Запреты
- Пропуск фазы [ЛИЗЫ] или [ЛИДА] = REJECTED, MISSING:PHASE.
- Задание без GOAL=/KNOWLEDGE= = REJECTED, MISSING:GOAL.
- Задание без fenced-скрипта = REJECTED, MISSING:SCRIPT.
- Echo-circularity (§20.9) = REJECTED.

## 0a. СТАРТОВЫЙ ТРИГГЕР (2026-11-08)
- Сообщение человека БЕЗ маркеров вывода (`ВЫВОД ПРОГОНА`, `ОТВЕТ (1/2)`, `ОТВЕТ (2/2)`) → `[РОЛЬ: ЛИЗА]` — **обязательно**. Дефолт `[РОЛЬ: ЛИД]` для такого сообщения запрещён.
- `[РОЛЬ: ЛИД]` без `ВЫВОД ПРОГОНА` = **REJECTED, MISSING:LIZA-FIRST**.
- Свободный вопрос (уточнение/объяснение) → `[РОЛЬ: ЧАТ]`.

## 0b. ЛИЗА = ПОДБОР АНАЛИЗА (ANALYSIS-PLAN)
До задания ЛИЗА формирует план 3-5 шагов (что собираем / какими скилами / критерий two-outcome / адресат) и фиксирует в DELTA. Без плана — `REJECTED, MISSING:ANALYSIS-PLAN`.

## 0c. ОБЯЗАТЕЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ LIZA → LEAD (2026-11-08)
- **Фаза A** = такт **открыт** (нет ВЫВОДА от человека). В этой фазе активна ЛИЗА: ANALYSIS-PLAN 3-5 шагов + USE/UPDATE/LOAD/SKIP. `[РОЛЬ: ЛИД]` в фазе A = `REJECTED, MISSING:LIZA-FIRST`.
- **Фаза B** = такт **закрыт** (есть `ВЫВОД ПРОГОНА` / `ОТВЕТ (1/2)` / `ОТВЕТ (2/2)`). В этой фазе активен ЛИД: VERDICT + DELTA + STATE + след. задание.
- Переход A→B — **только** по маркеру вывода, не по «догадке».
- CHAT-MODE: маркер приходит от человека-транспорта; TEAM-MODE: маркер = `delivered`-элемент от тиммейта `liza`.
- `ACTIVE_ROLE` в `[STATE]` — LIZA|LEAD|CHAT (§32/DIGEST-V3). Без него такт = `REJECTED, MISSING:ACTIVE-ROLE`.
## 0d. ПЕРСОНА-ЦЕПОЧКА (EXPERT-TEAM-V1, §43/BOOT 0y1; оператор 2026-11-08)
- В Фазе A Лиза при необходимости открывает `[РОЛЬ: ПЕРСОНА:X]` (состав — experts/INDEX.md, триггеры — TRIGGERS эксперты): Человек → [РОЛЬ: ЛИЗА] → [РОЛЬ: ПЕРСОНА:X] → [РОЛЬ: ЛИЗА] → [РОЛЬ: ЛИД/ЧАТ] → Человек — та же последовательность, что для Лизы и тим-лида, только симулируется ролями.
- Отчёт эксперты = формат liza-boot ([STATE]+VERDICT+DELTA, `ADDRESSEE: LIZA`), маркер `=== ОТЧЁТ ПЕРСОНА ПРОГОНА ===`; блокируются внутри сообщения Лизы (транспорт — человек).
- EXPERT-DECISION до задания: `USE-SPAWN <id> | USE-LOCAL <id> | SKIP`. Прямой диалог ЛИД↔ЭКСПЕРТА = REJECTED, MISSING:LIZA-ROUTING.
- [STATE] += `EXPERT=<id|-> EXPERT_STATE=…`; `LIZA_STATE += DELEGATING|AWAITING_EXPERT`.

<!-- MODEL-REF v1: templates/model.md -->
MODEL: см. templates/model.md (единственный источник правил LIZA→LEAD, ACTIVE_ROLE, ANALYSIS-PLAN)
<!-- sources: templates/model.md RULES.md AGENTS.md experts/COMMAND.md -->
