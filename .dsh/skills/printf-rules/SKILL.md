---
name: printf-rules
description: "Router for shell output and session-discipline facts: printf rules, SSE and logs, workers, build gates, StarField session log, scintillation, API limits"
whenToUse: "Use when you need shell output rules, log/SSE/worker diagnostics, build-and-rollback discipline, or StarField render-session facts and must pick one scoped skill."
---

# PRINTF-RULES — роутер

Факты исходного `printf-rules.md` разнесены по скоупам: printf/вывод, SSE и логи, воркеры и supervisor, build-гейты и откаты, сессия StarField, scintillation, API-лимиты. Дублирующиеся разделы исходника схлопнуты в один.

## Скоуп-скилы (грузи только нужный)
- `printf-rules-core` — секции 1-8, set +H, чек-лист перед запуском
- `printf-rules-sse-logs` — SSE в Express, log-stream, worker-stdout, read-only SQLite
- `printf-rules-workers` — откат из bak, shebang, pgrep, state.json, stdio fd, service/svc
- `nk-elite-build-gates` — секции 26, 33-42 (сборка, esbuild, откат, HEAD)
- `nk-elite-starfield-session-log` — секции 23-24, 27-32, 43-52, 54-56 (ECS, pipeline, FMT-CHOOSE, starCount)
- `nk-elite-starfield-twinkle` — секции 53, 58-62, 65, 66
- `nk-elite-api-limits` — секции 25, 57, 63, 64

## Как читать
- Начни с этого роутера, дальше грузи **один** скоуп-скил под задачу; полный текст больше не нужен.
- Факты не дублируются между скоупами: разделы исходника разнесены по одному месту.

<!-- sources: .dsh/skills/printf-rules/SKILL.md -->
<!-- synced: 20261106 (split into 7 scope skills; content preserved) -->
