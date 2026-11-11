---
name: task-types
description: Classification of 10 task types (snapshot, read-only, contract, UI, build, browser, rollback)
---

# SKILL · task-types (universal)

<!-- created:
20261103-162557
 -->
<!-- sources: RULES.md .dsh/skills/rules-first-task/SKILL.md .dsh/skills/session-handoff/SKILL.md -->

## 0. Назначение
Классификация типов заданий «на выполнение». Помогает новой сессии быстро понять:
1) это первое задание (snapshot) или рабочее? 2) что читать до? 3) какие артефакты (tmp/) и гипотезы (H1..Hn) обязательны?
   Не переписывает RULES.md §9/§16, а уточняет их по опыту реальных сессий.

## 1. Как классифицировать (чек-лист)
1. Это первое сообщение сессии? -> ТИП 1 (snapshot / first-task, RULES §16).
2. Пользователь просит «проанализируй / посмотри / где лежит»? -> ТИП 2 (read-only analysis).
3. «какой контракт / что шлёт / какой payload»? -> ТИП 3 (contract discovery).
4. «создай / вставь / добавь компонент»? -> ТИП 4 (UI / component change).
5. «переименуй скилл / подключи / отладь скилл»? -> ТИП 5 (skills edit).
6. «почему падает / где сконфигурировано / success:false»? -> ТИП 6 (infra diagnostics).
7. «собери / запусти dev / proxy / probe»? -> ТИП 7 (build / runtime).
8. «открой в браузере / найди на сайте / прогони сценарий»? -> ТИП 8 (browser test).
9. «отладь экранирование / sed / perl / heredoc»? -> ТИП 9 (escaping / bash fix).
10. «откати / восстанови из бэкапа / верни как было»? -> ТИП 10 (rollback / restore).

## 2. ТИП 1 — Snapshot / first-task
Признак: первое сообщение сессии; RULES §15/§16.
Читать: RULES.md §16 дословно, скилы двух корней .dsh/skills/ + .dsh/skills/ (SKILL.md + README.md, маркер SKILLS_COUNT=<n>, §20.8d), POSTMESSAGE (tail 200), .dsh/skills/postmessage/SKILL.md, .dsh/skills/rules-first-task/SKILL.md.
Артефакты: tmp/initial-snapshot-<TS>/{dirs,files,tree,facts,summary,terminal.log}.
Гипотезы: H0 root=pwd, H1 skills, H2 tree, H3 tmp writable, H4 POST.
Формат: PowerShell 5.1, шаблон §16 дословно.

## 3. ТИП 2 — Read-only analysis
Признак: «проанализируй», «посмотри», «где лежит», «что в скиле».
Читать: скилы двух корней .dsh/skills/ + .dsh/skills/ (SKILL.md + README.md, §20.8d; особенно context, commands, asuse-*).
Артефакты: tmp/<task>-<TS>/terminal.log + report.txt + facts.txt.
Гипотезы: H1 (файл/каталог существует), H2 (маркер/паттерн найден), H3 (сводка согласована).
Evidence: grep/sed строки, не только агрегаты.
Правки: НЕТ. Только Log/Raw в tmp/.

## 4. ТИП 3 — Contract discovery
Признак: «какой контракт у API», «что шлёт фронт», «какие поля в ответе».
Читать: .dsh/skills/trees-workflow/SKILL.md, .dsh/skills/asuse-frontend/SKILL.md, .dsh/skills/asuse-meta/SKILL.md, .dsh/skills/asuse-gateway/SKILL.md, .dsh/skills/postgres-readonly/SKILL.md (для SELECT pg_get_functiondef).
Артефакты: tmp/<task>-<TS>/contract.txt + facts.txt.
Гипотезы: H1 (controller/dal найден), H2 (args-поля), H3 (форма ответа — плоская/дерево), H4 (DB-функция/таблица).
Минимум: пример payload + пример ответа (даже частичный).

## 5. ТИП 4 — UI / component change
Признак: «создай компонент», «вставь в App.vue», «добавь дерево».
Читать: .dsh/skills/asuse-frontend/SKILL.md, .dsh/skills/trees-workflow/SKILL.md, .dsh/skills/browser-testing/SKILL.md.
Артефакты: tmp/<task>-<TS>/backup/ (обязательно: App.vue.bak-<TS> + новый компонент .bak-<TS>).
Гипотезы: H1 (компонент записан), H2 (App.vue ссылается), H3 (audit/build не сломан).
Правки: Copy-Item бэкап -> New-Item/Set-Content (не Remove).
После: npm run build + probe (Invoke-WebRequest к /api).

## 6. ТИП 5 — Skills edit
Признак: «переименуй скилл», «подключи скиллы», «создай скил», «отладь скил».
Читать: .dsh/skills/README.md, .dsh/skills/rules-first-task/SKILL.md, .dsh/skills/session-handoff/SKILL.md, scripts/skills-audit.mjs.
Артефакты: tmp/<task>-<TS>/backup/ (все затрагиваемые .md) + terminal.log.
Гипотезы: H1 (файл создан/переименован), H2 (ссылки обновлены), H3 (audit STALE=0, MISSING=0).
Правки: Move-Item (не Remove), .Replace (literal), НЕ @"..."@ с $ внутри.
После: node scripts/skills-audit.mjs -> AUDIT_FILES/AUDIT_OK/AUDIT_STALE/AUDIT_MISSING_MARKERS.

## 7. ТИП 6 — Infra diagnostics
Признак: «почему success:false», «где сконфигурировано», «probe вернул ошибку».
Читать: .dsh/skills/asuse-meta/SKILL.md, .dsh/skills/asuse-gateway/SKILL.md, .dsh/skills/kill-process/SKILL.md.
Артефакты: tmp/<task>-<TS>/diagnose.txt (grep-строки) + facts.txt.
Гипотезы: H1 (код прокси), H2 (конфиг/services), H3 (upstream URL/port), H4 (логи сервиса).
Правки: НЕТ до подтверждения диагноза. Сначала read-only.

## 8. ТИП 7 — Build / runtime
Признак: «собери», «запусти dev/proxy», «сделай probe».
Читать: .dsh/skills/powershell-first/SKILL.md, .dsh/skills/commands/SKILL.md.
Артефакты: tmp/<task>-<TS>/build.log + probe-response.json.
Гипотезы: H1 (build OK), H2 (dev 5173 слушает), H3 (proxy 8247 слушает), H4 (probe 200).
Известная проблема: Low Integrity -> esbuild remove Access denied. Обход: $env:TEMP=C:\\Temp\\esbuild-tmp перед npm run build.

## 9. ТИП 8 — Browser test (Playwright)
Признак: «открой в браузере», «найди на сайте», «прогони сценарий».
Читать: .dsh/skills/browser-testing/SKILL.md, .dsh/skills/browser-automation/SKILL.md, .dsh/skills/playwright/SKILL.md.
Правила: viewport 16:9 (1920x1080), консоль в лог (console/pageerror/requestfailed), скриншот viewport (не fullPage).
Артефакты: tmp/<task>-<TS>/browser-console.log + shot-<NN>.png.
Гипотезы: H1 (DxTreeView/AiDataTable найден), H2 (корневые узлы), H3 (консоль без ошибок).
Запуск: node find-orgnav.mjs (не копипастить JS в PowerShell).

## 10. ТИП 9 — Escaping / bash fix
Признак: «отладь экранирование», «sed/perl/heredoc не работает».
Читать: .dsh/skills/escaping-message/SKILL.md (ранее: bash-escaping.md — переименован).
Артефакты: tmp/<task>-<TS>/bash-run.log + terminal.log.
Гипотезы: H1 (файл переименован), H2 (L1/L144 без старого имени), H3 (audit STALE=0).
Git Bash: C:\\Program Files\\Git\\bin\\bash.exe.
Антипаттерны из скилла: BRE vs ERE, literal |, here-string с $, -replace по regex-метасимволам.

## 11. ТИП 10 — Rollback / restore
Признак: «откати», «верни как было», H3=REJECTED в предыдущем прогоне.
Читать: tmp/<task>-<TS>/backup/ (список бэкапов), .dsh/skills/session-handoff/SKILL.md.
Артефакты: tmp/<task>-<TS>/rollback.log + facts.txt.
Гипотезы: H1 (Move-Item обратно), H2 (Copy-Item -Force из бэкапа), H3 (audit STALE=0).
Правило: только Move-Item и Copy-Item. Никаких Remove-Item/rm -rf.

## 12. Общие правила для всех типов
- set +e / $ErrorActionPreference = Continue. Нет exit/exec/set -e.
- Логи только append (Add-Content/tee -a). Артефакты в tmp/<task>-<TS>/ (KEEP).
- Бэкап перед любой правкой: Copy-Item file file.bak-<task>-<TS>.
- Каждое сообщение заканчивается блоком ЗАДАНИЕ НА ВЫПОЛНЕНИЕ (RULES §9), минимум 2 гипотезы, последняя строка «Прислать: <артефакт>».
- PowerShell 5.1: без ?:, ??, &&, ||, heredoc <<EOF; -and внутри if(...) с внешними скобками.
- Не копипастить многострочные скрипты в консоль: сохранять в .ps1 и запускать -File (§17).

## 13. Таблица: тип -> минимальный evidence
| Тип | terminal.log | facts.txt | доп. артефакт |
|---|---|---|---|
| 1 Snapshot | + | + | dirs/files/tree/summary |
| 2 Read-only | + | + | report.txt |
| 3 Contract | + | + | contract.txt |
| 4 UI change | + | + | backup/App.vue.bak-<TS> |
| 5 Skills edit | + | + | backup/*.md.bak-<TS> |
| 6 Infra diag | + | + | diagnose.txt |
| 7 Build/runtime | + | + | build.log/probe-response.json |
| 8 Browser test | + | + | browser-console.log + shot-<NN>.png |
| 9 Escaping fix | + | + | bash-run.log |
| 10 Rollback | + | + | rollback.log |

## 14. Примеры из реальных сессий
- tmp/initial-snapshot-20261103-151841 — ТИП 1
- tmp/front-prod-find-20261103-160934 — ТИП 2
- tmp/counteragent-contract-20261103-155238 — ТИП 3
- tmp/skills-update-20261103-162358 — ТИП 5
- tmp/counteragent-proxy-diag-* — ТИП 6 (частично, не завершён)
- tmp/escaping-check-20261103-162425 — ТИП 9

## 15. Что НЕ является отдельным типом
- «Прислать подтверждение» — это не задание, а завершающая строка (§9).
- «Покажи список скиллов» — это ТИП 2 (read-only).
- «Запусти ещё раз» — это повтор предыдущего типа; evidence тот же.

## 16. Windows: запуск Playwright
- `npx playwright` может не видеть `.bin`; запускать `.\node_modules\.bin\playwright.cmd test ...` или `npm run test:e2e -- ...`.
- ESM: `require` запрещён, только `import`.
