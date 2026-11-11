---
name: use-ai-grid
description: "FOREIGN-CONTEXT/устаревший: useAiGrid (master-detail каскад AiDataTable) удалён из src пакета; скил описывает прошлое состояние infoenergo-ui и потребитель asuse-ai-front-min"
---

# SKILL · use-ai-grid (FOREIGN-CONTEXT / устаревший)

<!-- updated: 20261108-214500 by liza (task-3, takt-4) -->
<!-- pre-state: 1CA5B642 (версия doc-sync 2026-11-07 с пометкой foreign-context) -->

## 0. СТАТУС: НЕ ПРИМЕНЯТЬ В ЭТОМ ПАКЕТЕ (проверено 2026-11-08)
- `useAiGrid` **удалён из src**: grep `useAiGrid` по `src/**/*.ts` = not_found; grep по `example/**` (кроме node_modules/dist/vendor) = not_found.
- composables-экспорт пакета (`src/composables/index.ts`, 4 строки) его НЕ содержит: useTabsBaseOperations/TABS_API_KEY, useTabsState, initGlobalSettings, useDialog.
- Импорт `useAiGrid` от `@infoenergo/infoenergo-ui` НЕВОЗМОЖЕН (entry `src/index.ts` re-export'ит composables — см. выше).
- Следы удаления: ~30 бэкапов `src/composables/useAiGrid.ts.bak-*` (последние 20261028-1022xx) — код выведен из дерева 2026-10-28.
- Утверждение прошлой версии «example/tests/useAiGrid.spec.ts — 8 тестов» = не резолвится (файла нет).

## 1. Границы применимости
- СКИЛ = исторический: описывает комposable `useAiGrid`, который существовал в infoenergo-ui до 2026-10-28, и его потребление приложением asuse-ai-front-min (подпроект `example/asuse-ai-front-min/`, исторический).
- Актуальная замена для таблиц в этом пакете: компонент `AiDataTable` + composable-слой — см. скил use-ai-data-table.
- Если useAiGrid потребуется снова: восстановление возможно из `src/composables/useAiGrid.ts.bak-final-20261028-013525` (артефакты KEEP, §3), с повторной экспортной прошивкой в composables/index.ts и гейтами build:types/test:run.

## 2. Историческая справка (без гарантий применимости; из pre-state 1CA5B642)
- Паттерн: master → detail → detail каскад таблиц на AiDataTable; сетка = конфиг `{ name, api: { get }, parentGrid }`; каскад t1→t2→t3 работал при v-if в App.vue потребителя (INITIAL_REQUESTS=5, TABLE_ROWS=[5,5,5]).
- Требования потребителя: initGlobalSettings + AiAppProviders + NDialogProvider до mount (актуальны и для AiDataTable сегодня).
- Известные ограничения эпохи useAiGrid: setData([...]) в мок-режиме → rows.find is not a function; AiDataTable не обновлял focusedRowKey после refreshData (watch(data.length) без deep); useDataStore читал tableProps.api.get без guard.

## 3. Что делать агенту
- Не предлагать import useAiGrid из пакета и не использовать примеры §2 как рабочие.
- При задаче «каскад/grid» в этом пакете: LOAD use-ai-data-table; решение о восстановлении useAiGrid принимает ЛИД.

<!-- sources: src/composables/index.ts src/index.ts .dsh/skills/use-ai-grid/SKILL.md .dsh/skills/use-ai-data-table/SKILL.md .dsh/skills/context/SKILL.md -->
