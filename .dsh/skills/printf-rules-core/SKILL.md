---
name: printf-rules-core
description: "printf output rules: formats, escaping, anti-patterns, task template, layout check, POSTMESSAGE writes, set +H, pre-run checklist"
whenToUse: "Use when writing shell output, multi-line strings, task templates, POSTMESSAGE records or a pre-run checklist in bash."
---

<!-- sources: .dsh/skills/printf-rules/SKILL.md -->
<!-- synced: 20261106 -->
# SKILL — printf-rules (вывод без поломки верстки)

## 1. Зачем
В заданиях мы выводим много строк (логи, `summary.txt`, `POSTMESSAGE`, скрипты). `echo` с многострочными строками ломает верстку, если внутри есть `$`, кавычки, `\\`, `!` или `flt()`. `printf` с явным форматом — безопасен.

## 2. Базовое правило
- Любой вывод в bash-блоке — только через `printf`.
- Формат задаётся **явно**: `printf "%s\\n" "line1" "line2"` или `printf "k=%s v=%s\\n" "$k" "$v"`.
- Никаких `echo` в коде задания (кроме `echo ""` для пустой строки — но лучше `printf "\\n"`).

## 3. Форматы

### 3.1. Простая строка
```bash
printf "hello\\n"
```

### 3.2. Переменная
```bash
printf "ROOT=%s\\n" "$ROOT"
```

### 3.3. Несколько строк
```bash
printf "%s\\n" "line1" "line2" "line3"
```

### 3.4. Ключ=значение
```bash
printf "stage=%s status=%s session=%s\\n" "$N" "$STATUS" "$SID"
```

### 3.5. Блок (heredoc-замена)
```bash
printf "%s\\n" \
  "# Title" \
  "" \
  "Body line 1" \
  "Body line 2"
```

### 3.6. Запись в файл
```bash
{ printf "a=%s\\n" "$A"; printf "b=%s\\n" "$B"; } > "$FILE"
```

### 3.7. Через tee (для логов)
```bash
printf "[%s] %s\\n" "$(date +%H:%M:%S)" "$MSG" | tee -a "$LOG"
```

## 4. Экранирование
- `%s` — строка (безопасно).
- `%d` — целое.
- `%f` — float.
- `\\n` — новая строка.
- `\\t` — таб.
- `%%` — знак `%`.
- **Никогда** не используйте `$var` внутри формата `printf "%s"` — только в аргументах.

## 5. Анти-паттерны

| Плохо | Почему | Хорошо |
|---|---|---|
| `echo "a=$A b=$B"` | ломается при `!`, `$`, `\\` | `printf "a=%s b=%s\\n" "$A" "$B"` |
| `echo -e "line1\\nline2"` | зависит от шелла (`dash` vs `bash`) | `printf "%s\\n" "line1" "line2"` |
| `cat <<EOF` (heredoc) | ломается при `$` и `\\` | `printf "%s\\n" "line" ...` |
| `echo "$(flt)"` | `flt()` — функция, попадёт в текст | `flt < "$F"` |
| `printf "%s" "$(flt)"` | внутри формата функция | `flt < "$F" > "$OUT"` |

## 6. Шаблон задания
```bash
clear
#!/usr/bin/env bash
set +e
export LANG="${LANG:-C.UTF-8}"
ROOT="$(pwd)"; TS="$(date +%Y%m%d-%H%M%S)"; DIR="$ROOT/tmp/task-$TS"
mkdir -p "$DIR"
printf "ROOT=%s\\n" "$ROOT"
printf "TS=%s\\n" "$TS"
printf "%s\\n" "=== START ==="
# ... код ...
printf "%s\\n" "=== DONE ==="
```

## 7. Проверка верстки
После запуска задания проверьте `terminal.log`:
```bash
./scripts/doc-sync.sh
```
Если `manifest.tsv` изменился только по вашим файлам — верстка цела.

## 8. Правила для POSTMESSAGE
- `postmessage.sh write "<msg>"` — строка **без переносов**.
- Если нужен многострочный блок — `printf "%s\\n" "line1" "line2"` и передайте в `write`.
- Никаких `echo` в `POSTMESSAGE`.

## set +H (обязательно в начале скрипта)
- Любой bash-скрипт задания начинать: `set +H` (второй строкой после `clear`, до `set +e`).
- Причина: `!` в heredoc/py-сниппетах (например `!this.bufferSize`) даёт `event not found`, ломая `python3`-патчи.

---

## 4. Проверено на практике (сессия 2026-11-01)

Следующие ошибки реально ломали bash-блоки в проекте.
Все исправлены — вот правила, которые нельзя нарушать.

### 4.1 Круглые скобки в format-строке printf

ОШИБКА - падает на парсинге:

    printf "CHANGES: .dsh/skills/nk-elite-sqlite-stars-gui/SKILL.md (создан)\\n"

ПРАВИЛО - скобки только в аргументе:

    printf "%s\\n" "CHANGES: .dsh/skills/nk-elite-sqlite-stars-gui/SKILL.md"

### 4.2 Символ | в format

ОШИБКА - bash считает | пайпом в аргументе:

    printf "a | b | c\\n"

ПРАВИЛО - весь литерал в %s:

    printf "%s\\n" "a | b | c"

### 4.3 heredoc с backticks-блоками

Backticks в heredoc НЕ ломают bash, но копипаст через чат ломает.
ПРАВИЛО - вместо backticks использовать отступ 4 пробела:

    sqlite3 data/stars.db
    .tables

### 4.4 wc -c внутри printf

ОШИБКА - число слипается с именем файла:

    printf 'bytes=%s\n' "$(wc -c < file)"

ПРАВИЛО - сначала в переменную, потом tr:

    raw=$(wc -c < file)
    n=$(printf '%s' "$raw" | tr -dc '0-9')
    printf 'bytes=%s\n' "$n"

### 4.5 trap EXIT с wait без PID

wait без PID ждёт всех детей, но в trap EXIT это безопасно,
если main завершился. Если ждёт слишком долго - timeout.

### 4.6 sect с двумя аргументами

ПРАВИЛО - sect берёт только $1:

    sect() { printf "\\n%s\\n" "$1" | tee -a "$LOG"; }

Не $* и не несколько аргументов.

## 5. Чек-лист перед запуском

- нет открывающих скобок в printf format
- нет | внутри format
- все переменные через %s
- heredoc с префиксом, не с backticks
- wc через переменную
- bash -n <скрипт> проходит

---
