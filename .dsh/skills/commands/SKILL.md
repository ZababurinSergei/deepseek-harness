---
name: commands
description: Universal commands, npm scripts, read-only probes and clipboard for asuse-ai-front-min
---

# COMMANDS — asuse-ai-front-min (Windows)

<!-- updated: 20261026-112804 -->
<!-- foreign-context sources: package.json -->
<!-- foreign-context: файл описывает чужой проект, пути нерезолвимы в этом репозитории (doc-sync 2026-11-07) -->

## Корень
cd /c/Users/szababurin/WebstormProjects/asuse-ai-front-min    # Git Bash
# PowerShell: Set-Location C:\Users\szababurin\WebstormProjects\asuse-ai-front-min

## package.json scripts (из факта)
- `npm run dev` — Vite dev server
- `npm run build` — vite build
- `npm run preview` — vite preview
- `npm run test:e2e` — e2e (playwright или аналог)

## Проверки (read-only)
```bash
test -f package.json && node -e "const p=require('./package.json');console.log(p.name, Object.keys(p.scripts||{}).join(','))"
find skills .dsh/skills -mindepth 2 -maxdepth 3 -type f \( -name "SKILL.md" -o -name "README.md" \) 2>/dev/null | wc -l   # SKILLS_COUNT (§20.8d: два корня)
test -f POSTMESSAGE && wc -l POSTMESSAGE
```

## Bash (ТОЛЬКО через Git Bash)
На Windows основной путь — PowerShell-first (см. `.dsh/skills/powershell-first/SKILL.md`).
Bash-скрипты `.sh` запускать только так:
```bash
bash <script>.sh
```

## PowerShell 5.1 (нативные скрипты §16-Windows)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\<script>.ps1
```

## Clipboard
- Windows: `clip.exe через ProcessStartInfo + UTF-16LE (см. powershell-first.md §3)`
- PowerShell: `Get-Content $log -Raw -Encoding UTF8 | Set-Clipboard`
- Linux: `xclip -selection clipboard` -> `wl-copy`
- macOS: `pbcopy`

## Безопасность (RULES)
- без `rm -rf`
- логи только append (`tee -a`)
- артефакты в `tmp/<task>-<TS>/` (KEEP)
- бэкап: `cp -n file file.bak-<task>-<TS>`
- POSTMESSAGE — append-only, чужие блоки не трогать

## Полезные факты (этот ROOT)
- `scripts/skills-audit.mjs` — MISSING
- `scripts/postmessage.sh` — MISSING
- `package.json` scripts — только dev/build/preview/test:e2e
- starfield-файлы (orillusion/, tests/sky.html, src/ts/index.ts) — отсутствуют (другой проект)

## TARGET_PATTERN (added 20261026-123054)

TARGET_PATTERN: StarfieldModule|StarfieldShader|VoxelMonitor|ShipController|shaderDataConverter|ts-fallback|server-routes|sky\.(ts|html)

# Использование: §16 в RULES.md читает TARGET_PATTERN отсюда, а не из RULES.
# Меняй pattern здесь под текущий проект — RULES.md остаётся универсальным.

<!-- windows-ps51: updated by update-all-skills -->


<!-- session-close-20261027-144435 -->
## gateway-min run
- `cd C:\Users\szababurin\WebstormProjects\infoenergo-core\asuse-ai-gateway-min; node index.js` (dotenv reads .env; port 3100; /health, /common, /api).
## meta-min run (TODO)
- port 3108; see docs/HANDOFF-meta-min.md.
<!-- sources: .dsh/skills/commands/SKILL.md -->
