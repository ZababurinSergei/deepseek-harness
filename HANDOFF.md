# HANDOFF — deepseek-harness

Дата: 20261111-194043
ROOT: C:\Users\szababurin\WebstormProjects\deepseek-harness

## Состояние сессии

- Такт 0: закрыт (39 SKILL.md загружены, ROOT TREE снят, POSTMESSAGE = NULL=evidence)
- M1: demo ×3 созданы (webmcp, prompt-api, summarizer)
- M2: all-in-one.html + README.md созданы
- M3: статическая валидация 4/4 OK; Playwright не установлен (NULL=evidence)

## Артефакты

### Skills (39)

- skills/asuse-databases/SKILL.md:b8540234
- skills/asuse-frontend/SKILL.md:df2afd31
- skills/asuse-gateway/SKILL.md:0a03e240
- skills/asuse-meta/SKILL.md:21c2268a
- skills/auto-orchestrator/SKILL.md:27f0d87b
- skills/browser-automation/SKILL.md:aa2284cb
- skills/browser-testing/SKILL.md:eca9543c
- skills/chat-mode-lead/SKILL.md:64aaadf7
- skills/commands/SKILL.md:0d4451fe
- skills/context/SKILL.md:e0840b61
- skills/doc-sync/SKILL.md:fbab445c
- skills/escaping-message/SKILL.md:794a81f8
- skills/experts/SKILL.md:1d28e083
- skills/help/SKILL.md:8c25e8a8
- skills/kill-process/SKILL.md:c80f7f1b
- skills/ots-core/SKILL.md:b8eb4379
- skills/playwright/SKILL.md:d1111dcc
- skills/postgres-readonly/SKILL.md:7c7538a2
- skills/postmessage/SKILL.md:80a40ee6
- skills/powershell-first/SKILL.md:c42c7b88
- skills/printf-rules/SKILL.md:e91bec66
- skills/printf-rules-core/SKILL.md:2172477d
- skills/printf-rules-sse-logs/SKILL.md:7024cb2c
- skills/printf-rules-workers/SKILL.md:fbf939c5
- skills/project-init/SKILL.md:510554d6
- skills/prompt-api/SKILL.md:3990d683
- skills/read-mode-task/SKILL.md:966a34a5
- skills/rules-first-task/SKILL.md:74595466
- skills/session-handoff/SKILL.md:1454b23a
- skills/shader-analysis/SKILL.md:76a56d4b
- skills/summarizer/SKILL.md:11959bf2
- skills/task-output/SKILL.md:965be45d
- skills/task-types/SKILL.md:d7ad9a80
- skills/trees-workflow/SKILL.md:9e32300c
- skills/type-check/SKILL.md:0629cb87
- skills/use-ai-data-table/SKILL.md:575bd59c
- skills/use-ai-grid/SKILL.md:3f64de1e
- skills/webgpu-debug/SKILL.md:a33e4f0b
- skills/webmcp/SKILL.md:462df81e

### Demo

- demo/all-in-one.html:f7575e6d
- demo/prompt-api-demo.html:09b2b269
- demo/README.md:692e5e5f
- demo/summarizer-demo.html:de082d07
- demo/webmcp-demo.html:200873ec

### Ключевые скилы

- `.dsh/skills/escaping-message/SKILL.md:794a81f8` — 3 секции PS 5.1:
  - `[PS51-HERESTRING-INTERACTIVE]` — `@'...'@` в интерактивной консоли ненадёжен
  - `[PS51-DRIVE-VAR]` — `$name:` → `InvalidVariableReferenceWithDrive`, правильно `${name}:`
  - (плюс ловушка `else` на отдельной строке)
- `.dsh/skills/webmcp/SKILL.md:462df81e`
- `.dsh/skills/prompt-api/SKILL.md:3990d683`
- `.dsh/skills/summarizer/SKILL.md:11959bf2`

## Следующая сессия

1. Прочитать `HANDOFF.md` (этот файл).
2. Проверить `.dsh/skills/` — 39 SKILL.md, ключевые sha выше.
3. Открыть `demo/README.md` — инструкция по флагам Chrome.
4. Опционально: `npm i -D playwright` + `npx playwright install chromium` для headless-валидации.
5. Работа с задачами M4/PM — по запросу.

## POSTMESSAGE

- NULL=evidence: POSTMESSAGE не найден в ROOT, .., ..\..

## KEEP

- HANDOFF.md
- tmp/handoff-*/
