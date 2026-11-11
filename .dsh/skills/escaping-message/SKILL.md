---
name: escaping-message
description: "Bash escaping rules for sed, perl, awk, grep, printf, heredoc, git commit, tee, plus Windows PowerShell 5.1 notes"
whenToUse: "Use when writing bash, sed, perl, awk, grep or printf commands, heredocs, multi-line output, code patches or scripts where quoting and escaping can break the command"
---

# SKILL · escaping-message (universal)
<!-- sources: .dsh/skills/escaping-message/SKILL.md -->
<!-- synced: 20261106 (merged project bash-escaping.md into escaping-message; installed supplements kept) -->
<!-- windows-ps51: updated by update-all-skills -->


> Объединено 20261106: полный bash-escaping (секции 0–13) + уникальные секции установленного
> escaping-message (антипаттерны сессии, Windows / PowerShell 5.1).
Правила экранирования в bash: sed, perl, awk, heredoc, $(…), printf.
Составлен по реальным поломкам: см. антипаттерны 1–6 ниже.

## 0. Общий принцип
Если строка содержит `$`, `` ` ``, `\`, `!`, `"`, `'`, `|`, `(`, `)`, `{`, `}`, `[`, `]`, `*`, `?` — сначала подумай, потом пиши.
Одинарные кавычки `'...'` — единственный «литеральный» способ. Внутри них НЕЛЬЗЯ поставить `'` (только `'"'` или через heredoc).

## 1. sed: BRE vs ERE, literal `|`
Антипаттерн (ломалось в сессии):
```
sed '133s/^\s*let source_id\s*:\s*string\s*\|\s*null\s*=\s*null;.*$/REPL/' file
```
В BRE (`sed` без -E) `\\|` — АЛЬТЕРНАЦИЯ, не literal `|`. Команда сработала как «или `\\s*string\\s*`, или `\\s*null = null;`» → получилось `/* removed */| null = null;`.

Правильно:
```
# literal | → [|] или \| в ERE
sed -i '133s/^[[:space:]]*let source_id[[:space:]]*:[[:space:]]*string[[:space:]]*|[[:space:]]*null[[:space:]]*=[[:space:]]*null;[[:space:]]*$/\/* removed *\//' file
# или:
sed -i -E '133s/^[[:space:]]*let source_id[[:space:]]*:[[:space:]]*string[[:space:]]*\|[[:space:]]*null[[:space:]]*=[[:space:]]*null;[[:space:]]*$/\/* removed *\//' file
```
Правила:
- `|` в BRE — literal; `\\|` — альтернация. В ERE — наоборот.
- `[[:space:]]` надёжнее `\\s` (BSD sed не знает `\\s`).
- Держи регулярку в одинарных кавычках, если внутри нет одинарных.
- Для замены лучше `perl`, если есть `|` и группы.

## 2. perl: `print unless /A/; print unless /B/` — двойной вывод
Антипаттерн (ломалось в сессии):
```
perl -i -ne 'print unless /A/; print unless /B/' file
```
Строка, не матчащая НИ ОДИН паттерн, печатается ДВАЖДЫ → tsconfig.json удвоился, JSON сломался.

Правильно:
```
perl -i -ne 'print unless /A|B/' file
# или через sed (без двойного print):
sed -i '/A/d; /B/d' file
```

## 3. perl: `-0pi -e "s{...}{...}"` — `$` и `{}` подставляются
Антипаттерн:
```
perl -0pi -e "s{from @orillusion/core}{from $target}g" file
```
В двойных кавычках `$target` интерполируется, `{` `}` — квантификаторы, `@orillusion` — массив. Работает «иногда», ломается на особых символах.

Правильно (одинарные + ENV):
```
export TARGET="$target"
perl -pi -e 's/from \@orillusion\/core/from '"{TARGET}"'/g' file
```
Или через `quotemeta` в perl:
```
perl -pi -e 'BEGIN { $t = quotemeta($ENV{TARGET}) } s/from \@orillusion\/core/from $t/g' file
```

## 4. `$(...)` внутри `echo "..."` — вложенные кавычки
Антипаттерн (ломалось в сессии):
```
echo "sm_has_setStorageBuffer=$(grep -c \"setStorageBuffer('starBuffer'\" "$SM")"
```
Вложенные кавычки в `$(...)` внутри `"..."` ломают bash (`syntax error near unexpected token`).

Правильно:
```
CNT=$(grep -c -F "setStorageBuffer('starBuffer'" "$SM")
echo "sm_has_setStorageBuffer=$CNT"
```
Правила:
- Сначала присвой в переменную, потом подставляй в строку.
- `grep -c -F` (fixed) — не regex, никаких экранирований.
- Не используй `\"` внутри `$(...)` внутри `\"...\"`.

## 5. Heredoc: `<<'EOF'` (quoted) — безопасный
Антипаттерн:
```
cat > file <<EOF
some $VAR text
EOF
```
`<<EOF` (unquoted) интерполирует `$VAR`, `$(...)`, `\``. Для записи кода/конфигов это ломается.

Правильно:
```
cat > file <<'EOF'
some $VAR text
EOF
```
Правила:
- Внутри quoted heredoc `$` и `\\`` — литералы.
- Если нужно вставить переменную — только через явный `printf` или `cat` склейку, не через heredoc.
- Не вкладывай heredoc в `$(...)` без нужды.

## 6. printf vs echo -e
Антипаттерн:
```
echo -e "line1\\nline2\\n"
```
В BSD/macOS `echo -e` — не работает. В некоторых шеллах `\\n` остаётся буквальным.

Правильно:
```
printf '%s\n' 'line1' 'line2'
printf '%s\n' "$LINE"
```

## 7. Регулярки: что литерал, что метасимвол
| Символ | BRE (sed, grep) | ERE (sed -E, grep -E, perl) |
|---|---|---|
| `.` `*` `[` `]` `^` `$` `\\` | метасимвол | метасимвол |
| `+` `?` `|` `(` `)` `{` `}` | литерал | метасимвол |
| `\\|` `\\(` `\\)` `\\+` `\\?` `\\{` | метасимвол | литерал (обычно) |

Правило: **сначала решай, что тебе нужно** — literal или метасимвол, потом выбирай BRE/ERE и экранирование.

## 8. `grep`: `-F` для literal, `-E` для regex
Антипаттерн:
```
grep 'from @orillusion/core' file   # @ — не метасимвол, но слэши и | могут ломать
```
Правильно:
```
grep -F "from '@orillusion/core'" file      # fixed string
grep -E 'from .+@orillusion/core' file        # если нужен regex
```

## 9. `cp -n` — предупреждение GNU
GNU coreutils: `cp: warning: behavior of -n is non-portable`. Это warning, не ошибка. Если не нужен — `cp --update=none` (новые) или игнорировать.

## 10. Чек-лист перед запуском скрипта
1. Есть ли в строке `$` или `\\`? → одинарные кавычки или heredoc.
2. Есть ли `|`, `(`, `)`, `{`, `}`, `[`, `]`? → явно реши BRE/ERE + экранирование.
3. Есть ли `$(...)`? → сначала присвой в переменную, потом в строку.
4. Многострочный текст? → quoted heredoc `<<'EOF'`.
5. `sed` vs `perl`? Если нужны группы/альтернация/lookaround → `perl -pi -e` (одинарные кавычки).
6. После правки файла — **валидируй**: `node -e "JSON.parse(...)"` (для JSONC — сначала strip `//`), `node --check`, `grep -c` остатка.
7. Если правка должна изменить N мест — **до** прогона проверь `grep -c` (сколько матчей), **после** — тоже (сколько осталось).

## KEEP
- .dsh/skills/bash-escaping.md

## 11. Длинные bash-блоки: закрытие, git commit, printf

### 11.1. Блок должен быть **закрыт** ` ``` `
**Антипаттерн:** bash-блок в чате **не** закрыт ` ``` ` в конце → копирование **ломается**, `clear`/shebang **съедаются**.
**Правильно:** **всегда** закрывать ` ``` ` **отдельной** строкой **после** последней команды. В **одном** сообщении — **один** fenced-блок (RULES §9).

### 11.2. `git commit -m "..."` — только через **файл** (`-F`)
**Антипаттерн:**
~~~bash
git commit -m "docs: §17 facts
- §17.1: readonly
- §17.2: generate -> MemoryInfo -> RangeError"
~~~
Многострочное сообщение с `$`, `` ` ``, `->`, `§` — **хрупкое** (bash-escaping §4–§5). В **некоторых** шеллах **ломается**.

**Правильно** (quoted heredoc → файл → `-F`):
~~~bash
MSG_FILE="$DIR/commit-msg.txt"
cat > "$MSG_FILE" <<'MSG'
docs: §17 vertex buffer facts

- §17.1: readonly getter
- §17.2: generate -> MemoryInfo -> RangeError
- §17.3: desc.vertexBuffers
MSG
git commit -F "$MSG_FILE"
~~~
Внутри `<<'MSG'` — `$`, `` ` ``, `§`, `->` — **литералы**.

### 11.3. `printf` для многострочного — **не** `echo -e`
**Антипаттерн:**
~~~bash
echo -e "line1\nline2\n"
~~~
BSD/macOS `echo -e` — **не** работает; `\n` — **литерал**.

**Правильно:**
~~~bash
printf '%s\n' 'line1' 'line2'
printf '%s\n' "$LINE"
~~~

### 11.4. `grep -c` — **всегда** `| tr -d '\n'` и `|| echo 0`
**Антипаттерн:**
~~~bash
N=$(grep -cE 'pat' file)
[ "$N" -eq 5 ] && ...
~~~
Если `grep` **не** нашёл — `N=""` (пусто) → `[: : integer expected` → **скрипт** падает.

**Правильно:**
~~~bash
N=$(grep -cE 'pat' file 2>/dev/null | tr -d '\n'); N=${N:-0}
[ "$N" -eq 5 ] && ...
~~~

### 11.5. Чек-лист длинного bash-блока
- [ ] Блок **закрыт** ` ``` ` (отдельная строка).
- [ ] **Один** fenced-блок на сообщение (RULES §9).
- [ ] `git commit -m` → **`-F`** + quoted heredoc.
- [ ] Многострочный текст → `printf '%s\n'` (не `echo -e`).
- [ ] `grep -c` → `| tr -d '\n'` + `|| echo 0`.
- [ ] `$`/`` ` `` в тексте → **quoted heredoc** (`<<'EOF'`), не `"..."`.
- [ ] **Внутри** heredoc — **`~~~`** (не ` ``` `), иначе **внешний** блок **ломается** (RULES §16).

## [TEE-PANIC] exec > >(tee -a ...) падает на больших объёмах

Симптом:
- `thread main panicked at src/uu/tee/src/tee.rs:188: assertion left==right failed: 2nd pipe should have enough spare (left: Ok(8192) right: Ok(65536))`
- Скрипт "висит": tee упал, но родительский bash держит pipe.

Причина:
- Process substitution `exec > >(tee -a "$LOG") 2>&1` создаёт pipe ограниченного размера.
- При выводе > ~8 КБ за раз (например, `grep` по 4-МБ `orillusion.es.js` без `head`) tee не успевает.

Правило:
- НЕ гонять мегабайты через `tee`.
- Для больших объёмов: `exec >> "$LOG" 2>&1` (без tee) или `| head -n N`/`grep -m 1`.
- Никогда `grep` по бандлам >1 МБ без `-m 1` или `| head -n 20`.
- `grep -c pattern file 2>/dev/null || echo 0` (всегда защищаться от пустого вывода).

## 12. [ANTIPATTERN-12-STRUCTURAL] awk/sed для структурной замены блоков кода

### Антипаттерн (ломалось в сессии)
`awk` для вставки `engine = engine` в `Engine3D.init({...})` — вставил **внутрь** объекта, разорвав `{` и `}`.
`sed` для замены `projMat` → `viewMat` — применился к обеим строкам, обе стали `viewMat`.

### Причина
`awk` оперирует строками, не AST. Вставка «после паттерна» ломает многострочные конструкции.
`sed` глобальный: `s/A/B/g` без `g` меняет первое вхождение **на строке**, но при `sed -i` меняет **все** строки, матчащие паттерн.

### Правильно
**Явная замена блока по номерам строк:**
~~~bash
START=$(grep -n 'let offset = 0;' "$F" | head -n 1 | cut -d: -f1)
END=$(grep -n 'device.queue.writeBuffer(this.uniformBuffer' "$F" | head -n 1 | cut -d: -f1)
sed -i "${START},${END}d" "$F"
sed -i "$((START-1))r $NEWBLOCK" "$F"
~~~
**Или через шаблонный файл** + `cp` + `sed -n` для вставки.

### Чек-лист
- [ ] `node --check` (для JS/TS) или `npm run build` — **после** каждой структурной правки.
- [ ] `grep -c 'паттерн'` **до** и **после** — сколько матчей было/осталось.
- [ ] Если правка должна изменить N мест — проверить, что изменилось ровно N.
- [ ] Для правок внутри `{}` (объектов, функций) — **не** `awk`, а `sed` по номерам строк.
- [ ] Для многострочных **вставок** — писать во временный файл и вставлять через `sed -i "${N}r file"`, не через `print` в awk.

## 13. [PERL-U-ESCAPE] — perl -0pi с \uXXXX не работает

### Антипаттерн (ломалось в сессии 13:28)
Попытка вставить rAF-цикл в `sky.ts`:
~~~bash
perl -0pi -e "s/console\\.log\\('\\[FRAME-HOOK-SF\\] \u043c\u0438\u043d\u0438-\\u0445\\u0443\\u043a \u0443\u0441\u0442\u0430\u043d\u043e\u0432\u043b\u0435\u043d[^\\n]*\\);/.../" "$SKY"
~~~
Результат: **`[SF-RAF-LOOP]` не вставился**, `[SF-ONUPDATE-HOOK-ERR]` остался. `[RATE-SKIP-V2]` и `[SF-STARS-CAPTURE]` тоже **не** сработали при попытке через `perl -0pi` с `\u`.

### Причина
- `\uXXXX` в **двойных** кавычках **perl** — **не** escape, а **literal** `\u043c` (backslash-u-0-4-3-c).
- В **одинарных** кавычках `\u` — **тоже** literal (perl видит `\u` как **upcase-next-char**, если **не** в regex).
- `-0pi` читает **весь** файл, но **замена** ищет **literal** `\uXXXX` — **не находит**.
- **`$1`, `\n`, `{}`** в **двойных** кавычках — интерполируются **bash** → perl получает **мусор**.

### Правильно — python3 для multiline/unicode
~~~bash
python3 - "$SKY" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = "console.log('[FRAME-HOOK-SF] мини-хук установлен"
new = "console.log('[FRAME-HOOK-SF] мини-хук установлен');\n    /* [SF-RAF-LOOP] */ ..."
if old in s:
    s = s.replace(old, new, 1)
    open(p, 'w').write(s)
    print("REPLACED")
else:
    print("NOOP: pattern not found")
PY
~~~
- **quoted heredoc** `<<'PY'` — `$`, `\`, `{}` — **литералы**.
- `python3` **читает** файл **как** UTF-8, **пишет** UTF-8.
- **Простая** **замена** `s.replace(old, new, 1)` — **без** regex.
- **Проверка** — `print("REPLACED")` / `print("NOOP")` — **сразу** **видно**, **сработало** **или** **нет**.

### Альтернатива — perl с ENV
~~~bash
export OLD="console.log('[FRAME-HOOK-SF] мини-хук установлен"
export NEW="console.log('[FRAME-HOOK-SF] мини-хук установлен'); /* [SF-RAF-LOOP] */"
perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/' "$SKY"
~~~
- `\Q...\E` — **quotemeta** (literal).
- `$ENV{OLD}` — **не** **интерполируется** **bash** (в **одинарных** кавычках **perl**).
- **Работает** **только** **если** **нет** **multiline** **и** **нет** **спецсимволов** **regex**.

### Чек-лист
- [ ] **`python3`** **вместо** `perl -0pi`, **если** **есть** **кириллица**, `\u`, **multiline**.
- [ ] **`<<'PY'`** (**quoted** heredoc), **не** `<<PY`.
- [ ] **`s.replace(old, new, 1)`** — **не** `re.sub` **без** **нужды**.
- [ ] **`print("REPLACED")`** **или** **`print("NOOP")`** — **видно** **результат**.
- [ ] **`node --check`** **после** **правки** — **синтаксис** **не** **сломан**.
- [ ] **Никогда** **`perl -0pi`** **с** `\uXXXX` **в** **двойных** **кавычках**.

## [PYTHON-REGEX-FRAGILE] (autofix 20261104-202026)

- `python3`-regex по `server-gaia.mjs` (1277 строк) **дважды** сломал синтаксис: `SyntaxError: Unexpected token "catch"`.
- Правило: для `.mjs` >500 строк — только построчные якоря (`const rowPattern`, `while (...)`) или ручная правка; regex — **нет**.
- После любой правки: `node --check server-gaia.mjs` **до** перезапуска; FAILED → `cp -f .bak` откат.
- `Math.min(parseInt(limit), 1)` → `parseInt(limit)` — regex съел `Math.min(`, оставил `Math.parseInt` (не существует). Не заменять с regex.

## Дополнение 20261025-230158: антипаттерны из сессии

- **`!` в double-quoted heredoc** — history expansion (`bash: !j.error: event not found`).
  Решение: `set +H`, или одинарные кавычки, или `python3` / `perl`.
- **`sed` для многострочных regex** — часто `pattern NOT FOUND` (BRE/ERE, `\s`, `//`).
  Для **многострочных** **замен** — **`python3 - <<'PY'`** с **`re.compile(pattern, re.MULTILINE)`**
  и **явным** **`print("pattern NOT FOUND")`** / **`sys.exit(1)`**.
- **`grep -c '^=== GREP_RAW ==='`** — считать **первую** строку блока, **не** все `===`.
  Для POST-валидации **минимум 1** (`grep -c`).
- **`pattern NOT FOUND`** — **не** **ошибка** **сессии**, **а** **сигнал**, **что** **файл** **уже** **пропатчен**
  (**после** **предыдущей** **сессии**). **Всегда** **`grep -n`** **до** **и** **после** **патча**.
- **`sed -i 's/private frameCount/public frameCount/'`** — **заменит** **все** **вхождения**;
  **проверять** **`grep -n 'private frameCount'`** **после** (**должно** **быть** **0**).
## Windows / PowerShell 5.1
- На Windows bash-эталоны применимы ТОЛЬКО через Git Bash: `bash script.sh`.
- В PowerShell 5.1 нет `sed`/`awk`/`grep`. Замены: `Select-String`, `-replace`, `ForEach-Object { -split }`.
- Ключевое правило PS 5.1: внутри `"..."` обратный слеш НЕ экранирует кавычку. Строку с `$` и `"` держать в ОДИНАРНЫХ кавычках снаружи.
- Многострочные скрипты (в т.ч. с `@'...'@`) — только в `.ps1` через `-File`; в интерактив не копипастить.
- Эталон clipboard на Windows: `clip.exe` через `ProcessStartInfo` + UTF-16LE. См. `.dsh/skills/powershell-first/SKILL.md` §3.

<!-- SYNC-20261108-git-untrack-pathspec: liza takt4 (lead H5 @4674e93e; ACCEPT takta-3) -->
## [GIT-UNTRACK-PATHSPEC-LOVUSHKA 2026-11-08] git commit/amend s pathspec = temp-index iz HEAD, staged-D molcha propugivaetsya (@4674e93e; cepochka v1 e8a79f2c → 81bef8e4 → 4674e93e)
- SIMPTOM: git rm --cached X (D v indekse) → git commit --amend -- <pathspec> = «1 file changed», D ne popadayut v kommit (pathspec-limited kommit stroit vremennyj index iz HEAD; udaleniya, zanesennye v index, v nego ne include-itsya; «nothing to commit»/«1 file changed» vran).
- KANON: untrack-kommit = 'git rm --cached X' + 'git commit --amend' BEZ pathspec (v moment, kogda index soderzhit TOL KO celevye D) ILI obychnyj 'git commit' bez pathspec posle ochistki indexa ot poverhnostnyh M. Pathspec-limited kommit ('commit -- <puti>') goden TOL KO dlya rabochih IZMENENIJ (M-fajlov), ne dlya udalenij iz indexa.
- MERA PRIYOMKI: git show --stat = ozhidannye puti i flagy (D = 'Bin N -> 0' / 'N ---'), LITTER_LSFILES=0, LITTER_IN_HEAD=0; diski Test-Path=True (KEEP §3, rm bez --cached zapreshchen).
- PS5.1-KOTY: imena s '`$`' (litter '``/shot.png','``') — v odinarnyh kotirovkakh; git pathspec poluchaet litera; dvoinye kotirovki v "..." interpoliruyut '`$`' v pustotu (urok P26).
- SVYAZ': powershell-first (kotirovki), postmessage P15 (dry-run+ConfirmPath: DRY meryaet celi, EXECUTE untrackit), RULES §3 (diski KEEP).
## 14. OUTPUT-HANDLING — как правильно захватывать вывод

Скил покрывает *написание* команд (вход). Эта секция — про *захват* их вывода: stdout/stderr, кодировки, пайпы, большие объёмы. Ошибки здесь тише, чем в синтаксисе, но ломают данные.

### 14.1. bash: stdout + stderr вместе
~~~bash
# Плохо: stderr теряется, в файл идёт только stdout
cmd > out.log

# Правильно: оба потока в файл, порядок сохраняется
cmd > out.log 2>&1

# Правильно: оба в файл + на экран (append, без перезаписи)
cmd 2>&1 | tee -a out.log
~~~
`tee` с `-a` — append. Без `-a` файл перезаписывается (нарушает §3 KEEP).

### 14.2. bash: `set -o pipefail` — не терять код возврата в пайпе
~~~bash
set +e
set -o pipefail
cmd | grep -q 'pat' ; rc=$?
# rc = код cmd, а не grep, если cmd упал
set +o pipefail
~~~
Без `pipefail` `cmd | grep` вернёт код `grep`, даже если `cmd` упал — ложно-успешный такт.

### 14.3. bash: большие объёмы — НЕ через `tee` (см. TEE-PANIC выше)
~~~bash
# Плохо: tee падает на >~8 КБ за раз, скрипт висит
exec > >(tee -a "$LOG") 2>&1

# Правильно: прямой redirect, без tee
exec >> "$LOG" 2>&1

# Или ограничить вывод до tee
cmd | head -n 200 | tee -a "$LOG"
~~~
Для grep по бандлам >1 МБ — `-m 1` или `| head -n 20`.

### 14.4. bash: `grep -c` может вернуть пусто → `[: : integer expected`
~~~bash
# Плохо: пустая строка, если 0 матчей (BSD grep -c печатает "0", GNU — тоже, но
# при ошибке файла/паттерна может быть пусто)
N=$(grep -cE 'pat' file)

# Правильно: снять \n, защититься от пустого
N=$(grep -cE 'pat' file 2>/dev/null | tr -d '\n'); N=${N:-0}
[ "$N" -eq 5 ] && ...
~~~

### 14.5. bash: `wc -l` vs `grep -c`
- `grep -c` — число строк с матчем.
- `wc -l` — число строк в файле (по `\n`).
- `printf '%s'` без `\n` в конце — `wc -l` даёт на 1 меньше. Всегда добавлять `\n` в файл-вывод.

### 14.6. pwsh 5.1: кодировка вывода — только UTF-8
~~~powershell
# Плохо: PS 5.1 по умолчанию пишет UTF-16LE в Out-File, кириллица ломается при чтении
Get-Content file.txt | Out-File out.txt

# Правильно: явный UTF-8 без BOM
[System.IO.File]::WriteAllText('out.txt', $content, (New-Object System.Text.UTF8Encoding($false)))
# или
$content | Out-File -FilePath out.txt -Encoding UTF8 -Append
~~~
Чтение — всегда `-Encoding UTF8`:
~~~powershell
Get-Content file.txt -Encoding UTF8
Get-Content file.txt -Raw -Encoding UTF8
~~~

### 14.7. pwsh 5.1: `Out-String` и `-NoNewline`
~~~powershell
# Out-String добавляет \r\n в конце — режет при сравнении/хеше
$s = (cmd | Out-String).Trim()

# Write-Host не идёт в пайп, Write-Output — идёт
Write-Output "data" | Set-Content out.txt -Encoding UTF8

# Строка без завершающего перевода строки
[System.IO.File]::WriteAllText('out.txt', 'data', (New-Object System.Text.UTF8Encoding($false)))
~~~

### 14.8. pwsh 5.1: `[Console]::OutputEncoding` — кириллица в консоли
~~~powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
~~~
Ставить в начале скрипта, если в выводе кириллица и хост — Windows Terminal / VS Code.

### 14.9. pwsh 5.1: `Tee-Object -Append` — аналог `tee -a`
~~~powershell
"line" | Tee-Object -FilePath $TERM_LOG -Append | Out-Host
~~~
`Out-Host` обязателен, иначе строка уйдёт только в файл. Писать в лог **append**, не `-Force` (перезапись = §3 KEEP).

### 14.10. Чек-лист захвата вывода
- [ ] bash: `2>&1` или `| tee -a`, не `> file` (теряет stderr).
- [ ] bash: `set -o pipefail` перед пайпом, `set +o` после.
- [ ] bash: не гнать мегабайты через `tee` — `exec >>` или `head -n`.
- [ ] bash: `grep -c | tr -d '\n'` + `${N:-0}`.
- [ ] pwsh: чтение — `-Encoding UTF8`; запись — .NET `UTF8Encoding($false)`.
- [ ] pwsh: `Out-String` режет `\n` — `Trim()` или `[IO.File]::WriteAllText`.
- [ ] pwsh: `Tee-Object -Append | Out-Host` — строка идёт и в файл, и на экран.
- [ ] pwsh: `[Console]::OutputEncoding = UTF8` — для кириллицы в консоли.

## KEEP
- .dsh/skills/escaping-message/SKILL.md (эта секция)

## [PS51-HERESTRING-INTERACTIVE] — @'...'@ в интерактивной консоли PS 5.1 ненадёжен (2026-11-11)

### Симптом
Скрипт с многострочным `@'...'@` скопирован в интерактивную консоль PowerShell 5.1. Консоль показывает `>>` continuation prompt, затем рвёт here-string на строке, начинающейся с `~~~`, `##`, `-` или `|`. Всё после разрыва парсится как код → `ParserError: MissingExpressionAfterOperator` ×N.

### Причина
1. `@'...'@` — literal here-string, но интерактивная консоль PS 5.1 не полноценный парсер: эвристически определяет конец here-string и ломается на строках, начинающихся с `~`, `#`, `-`, `|`.
2. `~~~` в начале строки в PS раскрывается как `$HOME`.
3. Официальная рекомендация Microsoft: многострочные скрипты (в т.ч. с `@'...'@`) — только в `.ps1` через `-File`.

### Правильно (канон)
**Вариант 1 — массив строк + `[IO.File]::WriteAllLines`:**
~~~powershell
$lines = @(
    'line 1',
    'line 2 with  literal',
    '## heading',
    '~~~html'
)
$enc = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllLines($path, $lines, $enc)
~~~

**Вариант 2 — `.ps1` через `-File`:**
~~~powershell
Set-Content -Path script.ps1 -Value $lines -Encoding UTF8
powershell -NoProfile -File script.ps1
~~~

### Ловушка: AppendAllLines vs WriteAllLines
- `[IO.File]::AppendAllLines($path, $lines, $enc)` — в **.NET Framework 4.x** (PS 5.1) **НЕТ** перегрузки с Encoding. Только `(path, lines)`. Третий аргумент → `MethodCountCouldNotFindBest`.
- `[IO.File]::WriteAllLines($path, $lines, $enc)` — **принимает** Encoding. Использовать его.
- Если нужен append с кодировкой — читать `ReadAllLines`, склеивать `[array]::Concat($old, $new)`, писать `WriteAllLines`.

### Ловушка: ложный лог после упавшего метода
Строка `[IO.File]::AppendAllLines(...)` падает, но следующий `Log "UPDATED"` всё равно печатается — лог врёт. Оборачивать запись в `try/catch` или проверять `$?`.

### Чек-лист
- [ ] В интерактивной PS 5.1 НЕ использовать `@'...'@` для многострочных литералов.
- [ ] Для append с UTF-8 — `ReadAllLines` + `[array]::Concat` + `WriteAllLines` (не `AppendAllLines`).
- [ ] Перед перезаписью — бэкап `.bak-<TS>`.
- [ ] После записи — проверить `has_section` и `sha`, не доверять логу.

## KEEP
- .dsh/skills/escaping-message/SKILL.md (эта секция)

## [PS51-DRIVE-VAR] — $name: в строке = InvalidVariableReferenceWithDrive (2026-11-11)

### Симптом
Строка вида `"demo/$name:$sha"` или `"path:$name:value"` в PowerShell 5.1 падает:
`Недопустимая ссылка на переменную. За знаком : не следует допустимый знак имени переменной.`
`FullyQualifiedErrorId: InvalidVariableReferenceWithDrive`.

### Причина
PowerShell видит `:` после имени переменной как **drive separator** (`$env:PATH`, `$global:x`, `$script:y`). `$name:` = «переменная name в drive (пусто)» → ошибка парсинга всего блока. Это ломает не только строку, но и весь скрипт: парсер останавливается, остальные команды не выполняются.

### Правильно
Использовать `${name}` везде, где после переменной идёт `:`:
~~~powershell
"demo/${name}:${sha}:ok=$ok"
"SRC=path:${name}:${sha}"
~~~
Или `$($name):` (subexpression):
~~~powershell
"demo/$($name):$($sha):ok=$ok"
~~~
Правило: если после `$var` идёт `:` (или `.` в некоторых контекстах) — `${var}`, не `$var`.

### Сопутствующая ловушка: else на отдельной строке
В интерактивной PS 5.1:
~~~powershell
if ($x) { "yes" }
else { "no" }   # CommandNotFoundException: else не распознан
~~~
Правильно: `} else {` на одной строке или блок в `.ps1`:
~~~powershell
if ($x) { "yes" } else { "no" }
~~~

### Чек-лист
- [ ] В интерполяции `$var:` → `${var}:` или `$($var):`.
- [ ] `else` — на той же строке, что `}`: `} else {`.
- [ ] Многострочные if/else — в `.ps1` через `-File`, не в интерактив.

## KEEP
- .dsh/skills/escaping-message/SKILL.md (эта секция)
