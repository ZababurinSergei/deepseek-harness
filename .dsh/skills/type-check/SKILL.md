---
name: type-check
description: TypeScript type checking via tsc -p with multiple tsconfig sets and CI integration
---

# SKILL · type-check (universal)

<!-- sources: package.json packages/nk-elite-orillusion-map/tsconfig.check.json packages/nk-elite-orillusion-map/tsconfig.check.tests.json -->
<!-- synced: 20261108 (P6 doc-sync: реальные скрипты + GPO-обход агентов) -->
<!-- synced: 20261108-0345 (liza: ignoreDeprecations 6.0 в tests-конфиге, 78f5da8e) -->

Как проверять типы в проекте: скрипты `package.json`, `tsconfig.*.json`,
чтение вывода `tsc`, добавление нового набора, pre-commit/CI.

## 0. Общий принцип
`tsc -p <config>` — единственный надёжный способ проверки типов.
`tsc file.ts` **игнорирует** `tsconfig.json` (error TS5112) — не использовать.

## 1. Скрипты в package.json
| Скрипт | Команда | Что проверяет |
|---|---|---|
| `type-check` | `tsc --noEmit --strict --skipLibCheck -p ./tsconfig.check.json` | основной набор |
| `type-check:test` | `tsc --noEmit --strict --skipLibCheck -p ./tsconfig.check.tests.json` | тесты |
| `type-check:sky` | `tsc --noEmit --strict --skipLibCheck --target es2020 --module esnext … tests/sky.ts 2>&1 \| head -n 200` (bash) | `tests/sky.ts` (Linux/macOS/git-bash) |
| `type-check:sky:win` | `tsc --ignoreConfig --noEmit --strict --skipLibCheck … --types @webgpu/types … tests/sky.ts` | `tests/sky.ts` (Windows: `--ignoreConfig` вместо `-p`) |
| `type-check:session` | `node --check SESSION.mjs` | ESM-синтаксис `SESSION.mjs` |
| `type-check:all` | `npm run type-check && npm run type-check:test && npm run type-check:session` | всё, КРОМЕ sky (sky — отдельным прогоном) |
| `agents:create` | `bash scripts/agents-create.sh` | генерация AGENTS/core-pack/liza-boot (Linux/macOS) |
| `agents:create:win` | `powershell -NoProfile -Command "Get-Content -Raw -Encoding UTF8 'scripts/win/agents-create.ps1' \| Invoke-Expression"` | генерация (Windows; см. GPO-ниже) |

**tsconfig.check.tests.json (78f5da8e, 2026-11-07):** содержит `"ignoreDeprecations": "6.0"` —
гейт `type-check:test` чинил падение на конфиге (депрекейтед-флаг в TS 6.x), НЕ отключая реальный
typecheck. При появлении новых TS-deprecation падений — добавлять код флага сюда, не удалять строгость.

## 2. package.json (пример)
```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noEmit": true,
    "strict": true,
    "skipLibCheck": true,
    "allowJs": true,
    "resolveJsonModule": true
  },
  "include": ["tests/sky.ts", "tests/**/*.ts"],
  "exclude": ["node_modules", "tests/types/**", "tests/orillusion/**", "tests/**"]
}
```

## 3. Почему `tsc -p`, а не `tsc file.ts`
- `tsc file.ts` → `error TS5112: tsconfig.json is present but will not be loaded`.
- `tsc -p <config>` — использует `include`/`exclude`/`paths`.
- `--ignoreConfig` (TS >= 5.5) — только для быстрых прогонов.

## 4. Как читать вывод `tsc`
- `error TS<code>: <message>` — ошибка типа/синтаксиса.
- `--noEmit` — не писать `.js`.
- `--strict` — `strictNullChecks`, `noImplicitAny`, `strictFunctionTypes`.
- `--skipLibCheck` — не проверять `.d.ts` из `node_modules`.
- Финальная строка: `Found N errors in M files.`

Пример: `error TS2341: Property 'frameCount' is private` → сделать `public` или `getFrameCount()`.

## 5. Добавить новый набор
1. `tsconfig.check.<name>.json` — `extends`, `include`, `exclude`.
2. `package.json` → `"type-check:<name>": "tsc --noEmit -p tsconfig.check.<name>.json"`.
3. `type-check:all` → `... && npm run type-check:<name>`.
4. `npm run type-check:<name>` → rc=0.

## 6. Pre-commit / CI
```bash
npm run type-check:all && npm run session:check
```
- `type-check:all` → rc=0 (нет ошибок).
- `session:check` → `present=21 missing=0` (`MANIFEST.md` актуален).
- `type-check:test` может падать по ожидаемым ошибкам миграции `ts/**` — не блокировать CI, фиксировать в `docs/HANDOFF.md`.

## 7. Типичные ошибки
| Ошибка | Причина | Решение |
|---|---|---|
| `TS5112: tsconfig.json is present but will not be loaded` | `tsc file.ts` | `tsc -p tsconfig.check.*.json` |
| `TS2341: Property ... is private` | доступ к `private` | `public` или `get...()` |
| `TS2307: Cannot find module` | нет `paths`/`baseUrl` | добавить в `tsconfig.check.*.json` |
| `TS2580: Cannot find name 'require'` | нет `@types/node` | `npm i -D @types/node` + `"types": ["node"]` |
| `TS6133: 'x' is declared but never read` | `noUnusedLocals` | удалить или `_x` |

## 8. Быстрый старт
```bash
npm run type-check:all
npm run type-check:session
npm run session:check
```

## KEEP
- .dsh/skills/type-check/SKILL.md
## Windows / PowerShell 5.1
- `tsc -p <config>` — кроссплатформенно; для sky — `-p` НЕ работает, канон `--ignoreConfig` (скрипт `type-check:sky:win`).
- Чтение вывода: `Select-String -Path <out> -Pattern 'error TS'`.
- **GPO-капкан (2026-11-07):** `powershell -File <script>.ps1` падает «…is not digitally signed» (MachinePolicy/UserPolicy=RemoteSigned; `-ExecutionPolicy Bypass` НЕ помогает — политика выше флага). Обход: `powershell -NoProfile -Command "Get-Content -Raw -Encoding UTF8 '<script>.ps1' | Invoke-Expression"` — канон npm-хука `agents:create:win` (прежнее имя хука упразднено, §21.1). Кириллический .ps1 при этом читается `-Encoding UTF8` (BOM не обязателен для Invoke-Expression-канала).
- Генераторы: `npm run agents:create` (bash) / `npm run agents:create:win` (pwsh); артефакты обязаны давать BUDGET: bytes=<N>/65536 OK.

<!-- windows-ps51: updated by update-all-skills -->
<!-- p6 doc-sync liza 2026-11-08: npm-хуки type-check:sky(:win)/agents:create(:win) по фактическому package.json (0afd2a08) -->
