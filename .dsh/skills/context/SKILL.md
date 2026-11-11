---
name: context
description: Project context for @infoenergo/infoenergo-ui - identity, entry points, what exists and what is missing
---

# CONTEXT — @infoenergo/infoenergo-ui

<!-- updated: 20261108-211500 by liza (task-2, takt-3; замена foreign-context asuse-ai-front-min) -->
<!-- updated: 20261108-220100 by liza (takt-10: тест-стан 41/406 -> 43/431 после M1-M4; pre-state c74dd780) -->
<!-- pre-state: B8F9FAB5 (foreign-context asuse-ai-front-min, doc-sync 2026-11-07) -->

## Идентичность
- name: `@infoenergo/infoenergo-ui` version `0.0.21` (package.json:2) — Vue 3 UI-библиотека (НЕ приложение-потребитель).
- Дистрибутив: `main=./dist/infoenergo-ui.cjs`, `module=./dist/infoenergo-ui.mjs`, `types=./dist/types/public-api.d.ts` (package.json:4–6); vite lib entry `src/index.ts`, name `InfoenergoUI`, formats es+cjs (vite.config.ts:17–21).
- Зависимости потребителя (README.md:6): vue@3.5.x, naive-ui@2.43.x.
- Платформа разработки: Windows, PowerShell 5.1 (GPO RemoteSigned → Invoke-Expression-канал), Node/npm.

## Скрипты (package.json)
- `build` = vite build; `build:types` = vue-tsc -p tsconfig.build.json (declaration→dist/types); `dev` = vite build --watch.
- `test` / `test:run` / `test:coverage` = vitest (happy-dom, include src/**/*.{test,spec}.{js,ts}, vitest.config.ts:17–20; стан 2026-11-08: 43 файла/431 тест зелёные (после M1-M4 dataTypeInference)).
- `sb` / `build-sb` / `preview-sb` = Storybook (порт 6006); `lint:eslint` + `lint:prettier` + `lint:ci`.
- `agents:create` (bash) / `agents:create:win` (pwsh Invoke-Expression) — генераторы канона agent-kit.

## Точки входа
- `src/index.ts` — lib entry: `export * from './components/ui' | './components/icons' | './composables'`.
- `src/public-api.ts` — ТИПЫ entry dist/types/public-api.d.ts: theme, AiAppProviders, AiDialog, AiTabs, icons, tabs-composables; типов AiDataTable/Props НЕ содержит (см. ограничения в use-ai-data-table).
- `src/components/ui/index.ts:5` — `AiDataTable`; `src/composables/index.ts` — initGlobalSettings, useDialog, useTabsBaseOperations, useTabsState (4 строки, useAiGrid НЕ экспортируется).
- Компонент таблицы и composable'ы: `src/components/ui/AiDataTable/`, `src/composables/AiDataTable/` (API-контракт — скил use-ai-data-table).
- Документация компонента: `src/components/ui/AiDataTable/stories/description/AiDataTable.mdx` (+ Tree.mdx), примеры `examples/`; архитектура: `docs/architecture/ARCHITECTURE.md`.
- Consumers-примеры: `example/a4_6537/` (свой package.json, vite, vitest, e2e, openapi.json, server/), `example/asuse-ai-front-min/` (потребитель с собственным POSTMESSAGE/ — исторический, не трогать).
- tsconfig'ы: `tsconfig.json`, `tsconfig.build.json` (исключает src/index.ts, components/ui/index.ts, tests/stories/examples), `tsconfig.vitest.json`.

## Что здесь ЕСТЬ
- RULES.md / AGENTS.md / BOOT.md / liza-boot.md / core-pack.md / templates/ / experts/ (8) / scripts/ (skills-audit.mjs, agents-create.ps1) — канон agent-kit (деплой 2026-11-08); оригинальные AGENTS/RULES infoenergo — в `*.bak-kit-20261108-204806`.
- `.dsh/skills/` (70 скилов, вкл. use-ai-data-table) — единственный корень скилов (SKILLS ROOTS=1, skills/ намеренно удалён).
- Канальный POSTMESSAGE: **`..\..\POSTMESSAGE` = PM-A (git-корень Chat-Stream-Monitor)**; решение лида 2026-11-08 takt-2: пишем PM-A, локальный `./POSTMESSAGE` (77380702, starter kit-деплоя) НЕ трогаем; `packages/POSTMESSAGE` = P16 stray («ne pisat'»).
- tmp/ — артефакты прогонов (KEEP); storybook-static/, coverage/, test-results/, tree/, _sandbox/, tools/.
- BACKLOG.md + BACKLOG_GUIDE.md, CHANGELOG.md + CHANGELOG_GUIDE.md, dev.md, AI_TASK_TEMPLATE.md, .gitlab-ci.yml.

## Что здесь НЕТ (и где искать)
- `useAiGrid.ts` в src/composables — УДАЛЁН (grep useAiGrid src/**/*.ts = not_found; остались только .bak; use-ai-grid скил = foreign-context/устаревший).
- НЕТ кода бэкенда ASUSE (gateway/meta/databases) — см. скилы asuse-* (foreign-context, описывают отдельные репозитории).
- НЕТ nk-elite-кода (scripts/win/fps.mjs, tests/sky.html, tsconfig.check.json и др.) — ~8 отсутствующих ссылок в маркерах nk-elite-скилов = документированная норма (missing=8, exit=1 допустим).
- `chat-mode-lead/SKILL.md` — единственная без sources-маркера (no_marker=1 в P7-аудите).

## Инварианты (Windows / PS 5.1)
- Транспорт pwsh: `$ErrorActionPreference='Continue'`; `.ps1` — UTF-8 С BOM (восстанавливать после edit-инструмента, §21.1); запуск через `Get-Content -Raw | Invoke-Expression` (GPO RemoteSigned блокирует -File).
- Кириллица: чтение/запись только `-Encoding UTF8` / .NET UTF8Encoding($false); пути — `Join-Path $ROOT`, никогда ведущий backslash (урок #20).
- Логи только append (Tee-Object -Append); бэкапы `if (-not (Test-Path $bak)) { Copy-Item }` (Copy-Item -NoClobber НЕ существует в PS 5.1, урок kit-deploy-v2).
- P7-гейт: `node scripts/skills-audit.mjs` после правок скилов/доков (sha1-реестр tmp/audit-state.json, `--rebase` для фиксации); маркер скила — HTML-комментарий с ключом `sources:` и путями от ROOT пакета.

<!-- sources: package.json src/index.ts src/public-api.ts src/components/ui/index.ts src/composables/index.ts vite.config.ts vitest.config.ts tsconfig.build.json README.md docs/architecture/ARCHITECTURE.md BACKLOG.md CHANGELOG.md -->
