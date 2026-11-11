---
name: doc-sync
description: "Find and sync stale documentation (.dsh/skills/ + .dsh/skills/, RULES.md, POSTMESSAGE) against the code baseline"
whenToUse: "Use when documentation drifts from code and you must locate outdated sections, then refresh and record them."
---

# SKILL — doc-sync (синхронизация документации)
<!-- sources: .dsh/skills/doc-sync/SKILL.md, .dsh/skills/README.md, .dsh/skills/README.md, scripts/skills-audit.mjs, .gitignore -->
<!-- updated: 2026-11-08 P14 (раздел §7: bak-инвентарь + gitignore-инвариант + карта счётчиков 125/57/126) -->
<!-- synced: 20261106 (imported from project skills by format migration) -->



## 1. Зачем
Документация в скилах двух корней `.dsh/skills/` + `.dsh/skills/` (файлы `SKILL.md` + `README.md`, §20.8d), `RULES.md` и `POSTMESSAGE` часто меняется. Нужно быстро понять, какие файлы устарели относительно эталона.
Используем **fingerprint**: `mtime + size + sha1` для каждого файла.

## 2. Команда
```bash
./scripts/doc-sync.sh
```
Скрипт создаёт `tmp/doc-sync-<TS>/manifest.tsv` и сравнивает с `tmp/doc-manifest-etalon.tsv`.
Если эталона нет — создаёт его (baseline).
Если эталон есть — показывает `diff` (какие файлы изменились).

## 3. Синхронизация
- Если `diff` пуст — всё синхронизировано.
- Если `diff` показывает файл — он изменился, нужно обновить документацию.
- После обновления — перезаписать эталон:
```bash
cp -f tmp/doc-sync-<TS>/manifest.tsv tmp/doc-manifest-etalon.tsv
```

## 4. Автоматизация
Оркестратор (`.dsh/skills/auto-orchestrator/SKILL.md`) может вызывать `doc-sync.sh` после каждого этапа и записывать результат в `POSTMESSAGE`:
```bash
./scripts/doc-sync.sh >> tmp/doc-sync-<TS>/run.log
```

## 5. Правила
- Не трогать `tmp/doc-manifest-etalon.tsv` без явной синхронизации.
- `manifest.tsv` — всегда append-only (не перезаписывать).
- Все логи — через `printf`.

## 6. Команды запуска

**Проверить синхронизацию:**
```bash
./scripts/doc-sync.sh
```
Вывод: если diff пуст — всё синхронизировано. Если есть +/-, эти файлы изменились.

**Обновить эталон после ручной синхронизации:**
```bash
cp -f tmp/doc-sync-<TS>/manifest.tsv tmp/doc-manifest-etalon.tsv
```

**Проверить и сразу обновить эталон (если всё ок):**
```bash
./scripts/doc-sync.sh && cp -f "$(ls -td tmp/doc-sync-* | head -n1)/manifest.tsv" tmp/doc-manifest-etalon.tsv
```

**Записать результат в POSTMESSAGE (для оркестратора):**
```bash
./scripts/doc-sync.sh >> tmp/doc-sync-<TS>/run.log 2>&1
MSG=$(printf "doc-sync %s: diff_lines=%s" "$(date +%Y%m%d-%H%M%S)" "$(grep -c "^[+-][^+-]" tmp/doc-sync-<TS>/run.log 2>/dev/null)")
./scripts/postmessage.sh write "$MSG"
```

**Правила:**
- Не трогать `tmp/doc-manifest-etalon.tsv` без явной синхронизации.
- `manifest.tsv` — всегда append-only.
- Все строки — через `printf` / `postmessage.sh write`.

## 7. Гигиена bak-артефактов и счётчиков (P14, 2026-11-08)
Бэкапы `*.bak-<такт>-<TS>` (§3 KEEP) накапливаются длинным циклом; инвентаризация — скриптом:
```powershell
$baks=@(Get-ChildItem . -Recurse -File -Force | Where-Object { $_.Name -match '\.bak-' -and $_.FullName -notmatch '\\\.git\\' })
# в bak.tsv: путь / размер / sha1-8 / git check-ignore статус; сводка: TOTAL, NOT_IGNORED=0
```
- Инвариант gitignore: `.gitignore` содержит `*.bak-*` → `NOT_IGNORED=0` и `git status --porcelain` по bak = пусто
  (fact P14: 1372/1372 IGNORED). Новый bak-паттерн без покрытия = дрейф → патч-запрос в .gitignore.
- Сторонние файлы в `tmp/` (не `.bak-*`, напр. `tmp/bak-list.*`) паттерном не покрыты — учёт в инвентаре, решение за лидом.
- **Карта счётчиков канона** (иначе «живут» только в PM):
  - `.dsh/skills/README.md` → `SKILLS_COUNT=125` = 124 SKILL.md (67 .dsh/skills/ + 57 .dsh/skills/) + .dsh/skills/README.md (P6-эпоха, SRC: README:191);
  - `.dsh/skills/README.md` → `DSH_COUNT=57` = зеркальное подмножество 57 из 67; уникальны только в .dsh/skills/: 9 foreign + task-output (SRC: .dsh README);
  - аудит `files=126` = 67 + 57 + 2 README (depth-1) = **126 = 125 + 1** (+.dsh/skills/README.md, добавлен P10);
  - инварианты: `57 ⊂ 67 ⊂ 125` (проверка Compare-Object: B_in_A=57, B_not_in_A=0); при регенерации README сверять все три числа одним прогоном: аудит + две README-строки.
  - Расхождение чисел = STALE индекса → пересобрать README-индексы (P6-процедура), затем аудит `--rebase`.

<!-- SYNC-20261108-assembly-append: liza takt7 (lead H4 @c33adf02; ACCEPT takta-6) -->
## [ASSEMBLY-APPEND/VSE-ODIN-ZAPIS + PS5.1-CASE + EOL-PARITET] 2026-11-08 @c33adf02
- UZEL: generator assembly pishet v OGN strojnyj StringBuilder; fajl = OGIN [IO.File]::WriteAllText. Ljuboj 'Add-Content v put' vnutri funktsii = defekt: append k puti do WriteAllText → finale perepyshet vse → sektsii ischezaut (silence, exit 0; @51060ff9: §29a propal iz AGENTS, 41 vs 60).
- PS5.1 CASE-INSENSITIVE: peremennye funktsii i skripta kollidirujut bez ucheta regista —  (param) ≡  (skript); parametry funktsij assembly ne dolzhny sovpadat' s skriptovymi po regilu; mera = proverka gde pishetsja (put' vs bufer).
- PARITET D8 DVONIKOV: mera = spisok sektsij (^## ==) + marker/bytes segmenta; SHA segmenta = EOL-chuvstvitel'na (pwsh CRLF vs sh LF; pervoe razlichie @29) → sha v relay kak est', NE vorota.
- MERA PRIYOMKI regen: BUDGET bytes=<N>/65536 OK; marker celevoj sektsii = 1; RUNTIME-доказательstvo = perezagruzka instructionov harneasa (svezhiy AGENTS active); P7 audit exit 0 (+--rebase posle PM-zapisi).
- SVYAZ': powershell-first (BOM urok edit-tool; Copy-Item NET -NoClobber v PS5.1 → -Force + Test-Path), nk-elite-build-gates (vorota do deystviya), escaping-message (H5 pathspec: D-net = validny, amend bez pathspec dlya D).

<!-- SHA-HYGIENE-20261109: lead takt-0 @liza H2 (ACCEPT H-A/H-B, takt0; urok #39) -->
## [SHA-HYGIENE: ЭТАЛОН lines + HELP-marker] 2026-11-09 (lead, takt-0; SRC=tmp/lead-sha-hygiene-20261109-124401/)
- **Urok #39 (etalon zamera `lines`):** v skills-manifest `lines=` = **NEPUSTYE** stroki (`Where-Object Trim -ne '' | .Count`); `Get-Content .Count` = VSE stroki → pri sfertke dadut lozhnye STALE×71. Etagonom manifest-faila = ne-pustye; pered sfertkoj s SHa-failom vsegda proveryay metod scheta.
- **HELP-marker v tele skilla** (`HELP-<id>:sha1-8`) P7-auditom NE proveryaetsya (audit = marker SHA faila SKILL.md vs registry) → vnutrenniie stale-sha chinyatsya vruchnuju: Select-String 'HELP-<id>:' + Get-FileHash HELP-faila → zamenit; primeneno k asuse-gateway:46 (862b07ca→A333B170).
- P7-poryadok: pravka skilla → `node scripts/skills-audit.mjs` (exit 0) → `--rebase` pri planovom sdvige sha → exit 0 → tochechnyj git add (urok #35).