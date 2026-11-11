---
name: powershell-first
description: Generate PowerShell 5.1 scripts on Windows; unix utility replacements and PS antipatterns
---

# SKILL · powershell-first (universal, Windows-native)

<!-- created: 20261026-123519 -->
<!-- sources: RULES.md -->

Правило: **на Windows генерировать PowerShell 5.1-скрипты, а не bash.**
Bash — только через Git Bash и только если явно нужны.

## 0. Платформа
```powershell
$isWin = ($env:OS -eq "Windows_NT")
```

## 1. Запрещено в PS 5.1
- Тернарник `? :`, `??`, `&&`, `||`
- Heredoc `<<EOF`; массивы @(...) безопаснее here-string в интерактиве
- #requires в интерактивной сессии (падает: "При создании конвейера произошла ошибка")
- exit, set -e  ->  $ErrorActionPreference = "Continue" + try/finally
- Экранирование \" внутри "..." — НЕ работает; используйте одинарные кавычки снаружи
- Копипаст многострочных скриптов в консоль — только сохранить в .ps1 и запустить -File

## 2. Замены unix-утилит
- grep -> Select-String
- sed  -> -replace
- awk  -> ForEach-Object { -split }
- tail -> Get-Content -Tail
- head -> Get-Content -TotalCount
- wc -l -> Measure-Object -Line
- find -> Get-ChildItem -Recurse -Depth
- tee -a -> Add-Content

## 3. Clipboard (Cyrillic-safe) — только в finally
```powershell
$utf8  = [System.IO.File]::ReadAllText($TERM_LOG, [System.Text.Encoding]::UTF8)
$utf16 = [System.Text.Encoding]::Unicode.GetBytes($utf8)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "clip.exe"; $psi.RedirectStandardInput = $true; $psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardInput.BaseStream.Write($utf16, 0, $utf16.Length)
$p.StandardInput.Close(); $p.WaitForExit()
```

## 4. Запуск
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script.ps1
```

## 5. Если задача просит bash (.sh)
- Сохранить x.sh в корень проекта.
- Запустить: bash x.sh (bash есть: tool: bash OK).
- НЕ вставлять .sh в PowerShell — это разные оболочки.

<!-- windows-ps51: updated by update-all-skills -->


<!-- windows-ps51: antipatterns interactive-paste + case-insensitive-vars (session S-20261030-175016-12764) -->
- multiline try/finally в интерактивной консоли: вставка построчно висит на приглашении >> (после закрывающей } нужен пустой Enter) -> прогон обрывается, terminal.log пустой, артефакты частичные. Запуск только через: powershell -NoProfile -ExecutionPolicy Bypass -File .\script.ps1
- foreach $x in @(...) -> ParserError MissingOpenParenthesisAfterKeyword; канон: foreach ($x in @(...))
- Имена переменных регистронезависимы: $RAW (путь) и $raw (текст файла) — ОДНА переменная; симптом Add-Content -Encoding -> NamedParameterNotFound. Лечение: суффиксы путей (_F), локальные имена с префиксом ($fileText), pre-flight Group-Object { $_.ToLower() } по списку имён
- .ps1 с кириллицей сохранять UTF-8 С BOM (PS 5.1 без BOM читает как ANSI -> кракозябры в строках); для JS-вставок в тесты кириллицу писать \u-escape
<!-- windows-ps51: antipattern MOTW + execution policy (session S-20261030-175016-12764) -->
- Эффективная политика может быть зафиксирована GPO: Set-ExecutionPolicy -Scope Process Bypass -> «overridden by a policy defined at a more specific scope», effective остаётся RemoteSigned; -ExecutionPolicy Bypass в командной строке НЕ помогает.
- Файл, созданный внешним инструментом, помечен Zone.Identifier (MOTW) -> RemoteSigned требует цифровую подпись: «file is not digitally signed». Лечение: Unblock-File .\script.ps1 (проверить: Get-Item .\script.ps1 -Stream *), затем -File. Файлы, сохранённые редактором пользователя, запускаются сразу

<!-- ps51-patch-antipatterns: P23 apply-script (liza, 2026-11-08, lead ACCEPT 5301faf9) -->
- Счётчик якорей «LF + CRLF» для ОДНОСТРОЧНОГО якоря даёт n1+n2=2 (LF-вариант == CRLF-вариант, внутри якоря нет \n) -> валидный файл получает «ABORT: якорь не уникален», скрипт никогда не применится. Канон PatchFile: если якорь не содержит `n — считать ОДИН вариант (тот, что найден), уникальность = ровно одно вхождение в файле; многострочный якорь — искать LF-вариант и CRLF-вариант по отдельности, применять тот, что найден (==1), второй не суммировать.
- Функция PS возвращает ВЁС незакрытый конвейерный вывод: хелпер Log с Tee-Object внутри PatchFile «просачивает» строки ANCHOR в возвращаемое $t1 -> WriteAllText получает Object[] -> падение на записи. Лечение: ВСЕ вызовы Log/Section/Keep внутри функции-обработчика текста — с `| Out-Null`; канон: функция, возвращающая текст, не печатает вообще (счёт/отчёт — через Write-Host, он не входит в поток вывода функции).
- Фильтр лога пробы по подстроке отчёта (regex /parse-failed/) ловит штатную строку «parse-failed=0» -> ложный CONSOLE_BAD. Фильтровать по значению ошибки: 'parse-failed=[1-9]', 'exit code [1-9]', по префиксу уровня (ERROR/WARN), а не по имени метрики.

<!-- SYNC-20261108-mera-otvergaet -->
## [MERA-OTVERGAET-KRITERIY 2026-11-08] lyubaya shema sravneniya = proveryayemy y kritery; pervaya zhe mera mozhet ego otvergnut' (@0174577d; mery lidy nezavisimye: 20 236 simv == 20 236 simv / raznica 0; bayty−simvoly = +4 066)
- PRIMER 1 (PS 5.1, clipboard): sravnivay **simv-vs-simv**: `(Get-Content -Raw -Encoding UTF8 fayl).Length` ↔ `(Get-Clipboard -Raw).Length`; **nikogda bayty-vs-simvoly** (`Get-Item.Length` = BAYTY UTF-8: kirillica ×2 → 24 302 bayt pri 20 236 simvolov). Baytnoe sravnenie daet «obrezanny y» (+4 066) pri POLNOM soderzhanii → v ploskosti B (chat bez FS) takaya proverka = avtoritet i ub ivaet validny y paste. Uzkol trailing `\r\n` iz `Set-Clipboard`: dopustima raznica **0|2**; >>2 = nastoyashchaya obrezka. Dokaz: tmp/liza-r2-packet-liza-20261108-0735/r2-packet.md:1A0A2EA2 + PM ADDENDUM B86B5DA5.
- PRIMER 2 (parallel nyje protsessy): kritery «pisey JSON = odinochka (odin protsess)» byl by prinyat po nazvaniyu, a **22 signatury `ENOENT …star-names.json.tmp` v 263 logakh + determinirnaya reproduciya 1/4** skazali TRUE lzhivos (dva `setImmediate` = parallel nyje soshraneniya VNUTRI protsessа); monitoring protsessa — `Get-NetTCPConnection -LocalPort 3001 -State Listen` (nie Stop-Process: urok [SRV4-JOBRUNNER] lozhet Job runner). SRC: tmp/gonka-lead-20261108-0905/ + pravka da3e173c.
- TRTIE: **sha/razmer generiruyemogo artefakta (core-pack.md) = NE zamorka** — tri tochki odnogo dnya: 24 160 b/C10DA1D2 → 24 304 b/2ACD4248 → 24 302 b/87A5CCF9 (stroki 233→234; kazhdy y `agents:create:win` menyaet timestamp :1). Merya vsegda **v moment deystviya** (tochka otSChyota), snapshot iz proshlogo takta = ustarrel.
- VYVOD: «meryat', a ne chinit'» + «kritery proveryayutsya pervoy meroy» = odin printsip na trekh urovnyakh: defekt (distanceInfo), kritery (odinochka), shema sravneniya (bayty-vs-simvoly).

<!-- SYNC-20261108-edinity-simvolov -->
## [EDINITSY-IZMIRENIYA-SIMVOLOV 2026-11-08] chem izmeryat': chitatel i BOM opredelyayut «chislo simvolov» (@3da42780; dokazatel stvo: 20 214 PS / 20 215 node+BOM pri odnom fayle)
- OPREDELENIYE: dlya sravneniya s buferom obmena ediny y merya = **PS `Get-Content -Raw -Encoding UTF8` → `.Length`** (chitatel SH TATNOY: BOM snyaetsya avtomaticheski, kak i u `Get-Clipboard -Raw`). Node `readFileSync('utf8')` i Python schityvayut BOM **kak simvol (+1)** i dlya sravneniya s bulferom **ne godiatsya** bez vyminganiya (`charCodeAt(0)===0xFEFF`).
- ZAPRESHCHYNNYYE PARY (sravneniye raznykh edinic = fantom): `Get-Item.Length` (UTF-8 bayty) vs `Get-Clipboard`.Length (simvoly) — urok +4 066; node-utf8 vs PS `-Raw` (raznitsa = BOM, +1) — urok 2026-11-08 07:53: «raznica 1» = ne «obrezka», a BOM.
- PORYADOK PRI RAZNITSE: 0 = ideal no; 2 = dopustimy y dopusk (trailing CRLF ot Set-Clipboard); **1 = SNACHALA proveryaetsya BOM/chitatel** (perechitat oboyimi, sravnit parno), a ne «paste obrezan»; >2 = proverka markerov pervaya/poslednyaya (`=== LOAD (1/1): …` / `=== END LOAD ===`).
- DOKAZATEL STVO TAKTA: `core-pack.md` = 0DC6734B · 24 291 b · **20 214 simv. (PS -Raw)** · **20 215 (node utf8, BOM)** · bulfer = 20 214 · raznica PS-vs-bulfer = 0 · marker `=== END LOAD ===` sovpal → SOBYTIE 4 GO TOV.
- SVYAZ: [MERA-OTVERGAET-KRITERIY] (:76 — tre urovn: defekt/kriteriy/shema; zdes' uroven «chem») i [MERA-SNARUZH-PISATELYA] (gde — otdel ny y progon; chem — etot blok). Edinitsy: bayty = bytovay razmer; simvoly = .Length PS; stroki = `Get-Content).Count`; v kazhday mere ukazaty edinitsu i chitatelya.

<!-- SYNC-20261108-interpolyatsiya-ciklov -->
## [INTERPOLYATSIYA-CIKLOV-ZAPRESHCHYONA 2026-11-08] tret y porozhdayushchi y defekt PS: cikl vnutri interpolyatsii sryvayet vsyu merochnuyu stroku (@27e6ce9f; 3 padaeniya za den)
- PRAVILO 1: vnutri strokovoy interpolyatsii `$( … )` **zapreshcheny** `foreach`, `switch` i mnohostochnyye vyra zheniya (PS 5.1: «Unexpected token 'in'» → padaetsya vsya stroka, nichego ne izmeryaetsya). Razresheno v `$( )`: odna peremennaya, odin vyzov komandy, prostoy uslovny y operator.
- PRAVILO 2 (shablon mery): cikl — **otdel no v peremennuyu**, v stroke tol ko peremennaya. Etalon:
  `$s = ''; foreach($f in …){ $s += (Get-FileHash $f).Hash.Substring(0,8) + ' ' }` → zattem `Write-Output "  DO : $s"`.
- PRAVILO 3 (proverka pered progonom): pri padenii PS na sinksise padaet VSYA mera (pyatye soobshcheniy → nulevoy rezul tativ), poetomu pered polnym progonom — minimal naya kopiya stroki: `powershell -NoProfile -Command "<shtatnaya stroka>"` na odnom obekte. Esli mera uzh e sorvalas — chisla NE vynosyatsya («izmerenie nedostupno»), povtorny y progon otdel no (sm. [MERA-SNARUZH-PISATELYA], postmessage :174).
- DOKAZATEL STVA (odin defekt, tri sryva za den): (a) segodnya: `(foreach($f in …))` v `$(…)` v merochnoy stroke → «Unexpected token 'in'» dva podyada (zhdu-v10); (b) raneye: vtroenny y `powershell -Command` → ternarny y `?` → ParserError (zhdu-v6; uzhe v kanone postmessage); (c) raneye: vtroenny y `node -e` v stroke → «The string is missing the terminator». Vyvod: pravilo ne pro cikl, a pro **granitsu mezhdu vychisleniem i strokoy**: vychislenie = otdel ny y shag, stroka = tol ko podstanovka.
- SVYAZ: [EDINITSY-IZMIRENIYA-SIMVOLOV] (chem), [MERA-SNARUZH-PISATELYA] (gde), [MERA-OTVERGAET-KRITERIY] (kak) — vsey tri zakryvayut odin potok mery; defekt interpolyatsii = pyaty y variant putsi «mera upala → pusty e chisla».


<!-- ps51-anchor-quoting: P26 (liza, 2026-11-08, P26-PROGON lead 9a5f51e0) -->
- **Anchor s ${VAR} v PS DVOINYKH kavychkakh** → interpolyatsiya v pustuyu stroku →
  anchor n=0 → patch molcha ABORT (P26: \ s '#' + '{PANEL_ID}' v "..." → n=0; lechenie —
  odinarnye kavychki). Pravilo: anchory/stroki vstavki v odinarnykh kavychkakh; nuzhna
  interpolyatsiya — sklejka ('a' + \ + 'b'), no NE v tekste anchora.

<!-- SYNC-20261108-crlf-fantom: liza takt5 (lead H2 @3805d007; ACCEPT takta-4) -->
## [CRLF-FANTOM-M] git add normalizuet EOL → 'M' bez content-diff ischezaet; priyomka paketa = 'status 0 + diff HEAD 0', NE schyotchyk M do/posle (@3805d007: 6-tochka M = fanтом data/star-names.json; posle add = LF canonical v index, content==HEAD)
- PROYAVLENIE: M v 'git status --porcelain' pri sravnenii s index; EOL-worktree (CRLF) ≠ EOL-index (LF); posle git add put' ischezает bez izmeneniya soderzhimogo.
- PRIYOMKA PAKETA: pered kommitom = plan M; posle kommita — 'git status --porcelain' = 0 AND 'git diff HEAD' = 0 (chistaya baza). Schyotchiki M do/posle = vspomogatel'nye, ne kriteriy.
- SVYAZ': git-config core.autocrlf=true (Windows normalizatsiya), escaping-message (PS5.1 EOL pri zapisi), powershell-first Out-File (UTF8 BOM + CRLF = istochnik phantomov).
<!-- SYNC-20261108-if-paren: liza takt14 (12-y defekt @c67b639b; ACCEPT takta-13) -->
## [(IF-V-SKOBKAH = RUNTIME-PADENIE; VSEGDA DOLLAR-SKOBKAH)] 2026-11-08 @c67b639b
- FAKT: Log ('X='+(+$m){...}{...}) v stroke = PARSE OK (parzer propuskaet if kak vyrazhenie v skobkah), NO v RUNTIME = CommandNotFoundException (12-y defekt serii, loven PROGONOM ne SELFCHECKom).
- KANON: v PS 5.1 vsegda $(if $x ){ 'a' }{ 'b' } — podvyrazhenie s $. Bez $ = lopnut' pri ispolnenii.
- MERA: proverka vtorogo zapuska (syr-programmy) = nadezhnee PARSE; v strokah Log/mer — izbegat' (if, pishit' zaranee vychislenno v peremennuyu ILI $(if).
## [TEST-PATH-PERED-CHTENIEM-VNESHNEGO-LOGA 2026-11-08] vneshniy protsess mozhet ne pisat' v redirect (@927597af, urok #14; prakika takt-15 parity)
- FAKT: vneshniy protsess (pwsh -File/Start-Process s -RedirectStandardOutput) pechataet v konsol', redirect NE vsegda primenyaetsya → Get-Content nenavodimogo loga = ItemNotFoundException, skript umeret' v seredine mera (takt-15 parity.ps1 @50: pwsh-двoyник napechal v konsol', relay-seans umer; lid dopmeril rukami).
- KANON: pered chteniem loga vneshnego protsessa = Test-Path; net = CHITAT' KONSOL'NYY VYVOD (peremeshchennyy (… | Out-String)), ne umeret'. Eto zhe dlya logov node/bash-dvoynikov, GPO-zapuskov.
- MERA: takt-16/17/18 = vstroennyj Test-Path v vseh chteniyakh logov = zelyonyye progonny; pattern: if (Test-Path ) { Get-Content … } else { Log 'log pust — konsol ny vyvod vyshe' }.