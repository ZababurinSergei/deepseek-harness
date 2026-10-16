#!/usr/bin/env bash
# Универсальный генератор RULES-expanded.md для текущего каталога.
# Запуск: bash gen-rules.sh
set -uo pipefail; set +H; set +e
shopt -s nullglob

TASK="gen-rules"; TS=$(date +%Y%m%d-%H%M%S)
ROOT="$(pwd)"
DIR="$ROOT/tmp/$TASK-$TS"; mkdir -p "$DIR"
LOG="$DIR/run.log"; SUMMARY="$DIR/summary.txt"; RULES="$DIR/RULES-expanded.md"
: >> "$LOG"; : >> "$SUMMARY"
trap 'echo "[$(date +%H:%M:%S)] TRAP rc=$? (session kept alive)" | tee -a "$LOG" 2>/dev/null' ERR

log(){ echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }
w(){ echo "$@" >> "$SUMMARY"; }

log "START $TASK @ $TS"; log "ROOT=$ROOT"; log "DIR=$DIR"

IGNORES=(.git node_modules .cache dist build .next .nuxt .svelte-kit coverage .idea .vscode)
INCLUDE_DIRS=()
for d in "$ROOT"/*/; do
  [ -d "$d" ] || continue
  name=$(basename "$d"); skip=0
  for ig in "${IGNORES[@]}"; do [ "$name" = "$ig" ] && skip=1 && break; done
  [ "$skip" = 1 ] && continue
  INCLUDE_DIRS+=("$name")
done
log "detected INCLUDE_DIRS (${#INCLUDE_DIRS[@]}): ${INCLUDE_DIRS[*]:-none}"

{
  printf '# ПРАВИЛА ЧАТА (расширенные)\n\n## МЕТА\n'
  printf -- '- ROOT_PATH:     `%s`\n' "$ROOT"
  printf -- '- GENERATED_AT:  `%s`\n' "$TS"
  printf -- '- RULES_FILE:    `%s`\n' "$RULES"
  printf -- '- INCLUDE_DIRS:  `%s`\n' "${INCLUDE_DIRS[*]:-}"
  printf -- '- TREE_FILES:    `root-tree.txt`, `root-tree.filtered`, `root-tree.tsv`\n\n'
  printf 'ROOT_PATH — канонический корень проекта.\n\n---\n\n'
  cat <<'CANON'
# ПРАВИЛА ЧАТА
## 1. Формат ответа
Один ```bash block в конце. До — ≤3 строк (где/что/зачем). После — пусто.

## 2. Безопасность сессии
Запрещено: `exit`, `exec`, `logout`, `kill $$`, `kill $PPID`, `clear`, `reset`,
`history -c`, `trap ... exit`, `set -e`. `trap` только логирует. `set +e`.
Мягкий выход: `return 0 2>/dev/null || true`.

## 3. Сохранность данных
Логи только append. Артефакты в `./tmp/<task>-<TS>/`, не удалять.
Бэкап: `cp -n file file.bak-<task>-<TS>`. Запрещено: `rm -rf`, `> file`,
`git reset --hard`, `git checkout --`, `truncate -s 0`. Маркер `KEEP:`.

## 4. Сервер
Только свой `node:http`. Порт вне 80/443/3000/5173. PID/port → `$DIR/server.{pid,port}`.

## 5. Логика
Метки `[АКСИОМА]` / `[ТЕОРИЯ]` / `[ГИПОТЕЗА]`. Гипотезы H1..Hn со статусом
CONFIRMED/REJECTED/PARTIAL/UNKNOWN/DEFERRED. VERDICT в SUMMARY и FULL-SUMMARY.

## 6. ROOT TREE
Снимок от `ROOT_PATH`, глубина ≤3. Только `INCLUDE_DIRS`. Артефакты (KEEP):
`root-tree.txt`, `root-tree.filtered`, `root-tree.tsv`. Игноры: `.git`,
`node_modules`, `.cache`, `dist`, `build`. Отсутствие каталога — WARN.

## 7. Структура скрипта
Секции: CHECKS → BACKUP → ROOT TREE → ЛОГИКА → VERDICT → SUMMARY.
Хелперы: `log`, `section`, `w`, `hyp`, `axiom`, `theory`, `keep`.

## 8. Ошибки
WARN вместо FATAL при отсутствии инструментов. `trap ERR` не завершает shell.

## 9. Запреты
Нет `exit`/`exec`/`logout`/`kill $$`/`set -e`. Нет перезаписи логов и исходников.
Нет `rm -rf`. Нет чужих HTTP-серверов.

## 10. Шаблон задания
Контекст (где/что/зачем) → блок bash → SEND. Терминал не закрывать.

## 11. Самопроверка ROOT_PATH
`grep '^\- ROOT_PATH:' "$RULES"` совпадает с фактическим `pwd`.

## 12. Объяснение результатов (ОБЯЗАТЕЛЬНО)
`[ОБЪЯСНЕНИЕ] <что> → <результат> → <значит> → <ограничение>`.
NULL/0/пусто тоже объясняется. Пишется в LOG, SUMMARY, FULL-SUMMARY.

## 13. Вывод проверяемых гипотез (ОБЯЗАТЕЛЬНО)
13.1. В каждом задании — не менее двух гипотез (H1, H2, ...). Одна гипотеза — только если
      вторая объективно невозможна; тогда note: why-single.
13.2. Статусы: CONFIRMED | REJECTED | PARTIAL | UNKNOWN | DEFERRED.
13.3. Формат: `[HYPOTHESIS H<N>] ... => STATUS | evidence: <факт> | note: <оговорка>`
13.4. Нумерация без пропусков: H1..Hn.
13.5. CONFIRMED/REJECTED требуют evidence.
13.6. При >1 гипотез — priority: high|medium|low и связь (первична/производна).
13.7. Взаимоисключающие — `H<i> XOR H<j>` в note и в сводке.
13.8. Несколько причин в одной — разбивать на подгипотезы как отдельные H с приоритетами.
13.9. Сводка: `--- HYPOTHESES VERDICT ---` / `H1: STATUS | priority: ...`.
13.10. Дублируется в $SUMMARY и FULL-SUMMARY.txt.
13.11. Отчёт без §13 (или с <2 гипотез без why-single) — неполный.


## 14. Единый финальный отчёт
Блок: `=== ОБЪЯСНЕНИЕ РЕЗУЛЬТАТОВ ===` / `=== ВЫВОД ПРОВЕРЯЕМЫХ ГИПОТЕЗ ===` /
`=== ИТОГ ===`. Пишется в SUMMARY и FULL-SUMMARY.txt.

## 15. Задание на выполнение (в каждом сообщении, ОБЯЗАТЕЛЬНО)
15.1. Каждое сообщение завершается блоком «ЗАДАНИЕ НА ВЫПОЛНЕНИЕ».
15.2. Блок — последним.
15.3. Один ```bash code fence.
15.4. Готово к копированию, без плейсхолдеров.
15.5. Последняя строка: «Прислать: <артефакт>».
15.6. Нет задания — блок всё равно есть со строкой
      «Прислать: подтверждение выполнения предыдущего задания».
15.7. Мягкие формулировки запрещены — только императив.
15.8. В задании — не менее двух гипотез (см. §13), проверяются за один прогон.
15.9. Один прогон e2e измеряет сразу несколько гипотез; в отчёт — VERDICT.
15.10. Взаимоисключающие гипотезы помечать `H<i> XOR H<j>`.
15.11. Несколько причин в одной гипотезе — разбивать на подгипотезы (H3.1, H3.2 ...).


## 16. Контекст сбоя (ОБЯЗАТЕЛЬНО после любого сбоя/прерывания)
16.1. Первое сообщение после сбоя начинается с блока «КОНТЕКСТ СБОЯ» (≤3 строки):
      (1) Что было сделано в прошлой сессии (1–2 строки, самое существенное).
      (2) Где остановились (последний подтверждённый этап: файл / гипотеза / tmp-артефакт).
      (3) Что дальше (1 следующая конкретная задача, без вариантов).
16.2. В блоке обязательны KEEP-точки:
      - последние `tmp/<task>-<TS>/`;
      - файлы, которые точно рабочие (пути).
16.3. Формат строк:
      [СДЕЛАНО]   <1–2 строки>
      [STOP]      <файл|гипотеза|tmp/...>
      [NEXT]      <одна задача>
      [KEEP]      <путь1> <путь2> ...
16.4. Правило старта: если «КОНТЕКСТ СБОЯ» отсутствует — НЕ начинать новую задачу,
      а сначала собрать его 5 строками из последних артефактов `tmp/`.
16.5. Сборка «КОНТЕКСТА СБОЯ» из артефактов:
      (а) найти свежий `tmp/<task>-<TS>/` по mtime;
      (б) взять из него `FULL-SUMMARY.txt` и `summary.txt`;
      (в) извлечь последние `[STOP]`/`HYP ...`/`EX:` записи;
      (г) сформировать 3 строки + KEEP-точки.
16.6. «КОНТЕКСТ СБОЯ» пишется в лог и в файл:
      - `$DIR/context-after-failure.txt` (append);
      - дублируется в первом сообщении после сбоя.
16.7. Блок не заменяет §12–§15: он идёт ПЕРЕД ними в первом сообщении после сбоя.


## 18. Сжатие вывода при «Прислать: ...»
18.1. «Прислать: содержимое <файл>» → по умолчанию `grep -nE '<маркеры>' <файл>`, не весь файл.
18.2. Маркеры — в задании: `before|after|triggerCount|consoleErrors|parentId|__placeholder|OK_S|HEADLESS OK`.
18.3. Полный файл — только если ≤120 строк И структурированный (JSON с ключами).
18.4. Логи: `grep -nE '<маркеры>'` + `tail -n 30`.
18.5. Пусто по срезу → расширять паттерн, а не выгружать весь файл.

## 19. Итог задачи (единый отчёт)
19.1. Все гипотезы закрыты → вместо правок даётся итог ≤8 строк:
      что сделано; CONFIRMED/REJECTED; KEEP-артефакты; что осталось.
19.2. Пишется в SUMMARY и FULL-SUMMARY и дублируется в сообщении.

## 20. Минимум изменений на итерацию
20.1. Одна итерация = одна правка (один файл + один маркер). Больше — отдельные итерации
      или явное обоснование «почему вместе».
20.2. Новая правка не вводится, пока предыдущая не подтверждена headless-прогоном (иначе WARN).

CANON
} >> "$RULES"
log "written: $RULES ($(wc -l < "$RULES") lines)"

# ROOT TREE
TREE_ALL="$DIR/root-tree.txt"; TREE_FIL="$DIR/root-tree.filtered"; TREE_TSV="$DIR/root-tree.tsv"
: > "$TREE_ALL"; : > "$TREE_FIL"; : > "$TREE_TSV"
( cd "$ROOT" && find . -maxdepth 3 \
    \( -name .git -o -name node_modules -o -name .cache -o -name dist -o -name build \) -prune -o -print \
    | sort ) >> "$TREE_ALL" 2>/dev/null || true

{ echo "=== ROOT: $ROOT ==="; echo "=== FILTER: INCLUDE_DIRS (depth<=3) ==="; echo; } >> "$TREE_FIL"

for d in "${INCLUDE_DIRS[@]}"; do
  if [ -d "$ROOT/$d" ]; then
    printf '  [OK] %s/
' "$d" >> "$TREE_FIL"
    ( cd "$ROOT/$d" && find . -maxdepth 3 \
        \( -name .git -o -name node_modules -o -name .cache -o -name dist -o -name build \) -prune -o -print \
        | sort | sed 's/^/    /' ) >> "$TREE_FIL" 2>/dev/null || true
    # TSV: process substitution вместо pipe — переменные и >> видны гарантированно
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      t=$([ -d "$p" ] && echo dir || echo file)
      s=$(stat -c%s "$p" 2>/dev/null || stat -f%z "$p" 2>/dev/null || echo 0)
      printf '%s	%s	%s
' "${p#$ROOT/}" "$t" "$s" >> "$TREE_TSV"
    done < <(find "$ROOT/$d" -maxdepth 3 \
        \( -name .git -o -name node_modules -o -name .cache -o -name dist -o -name build \) -prune -o -print 2>/dev/null)
  else
    printf '  [MISS] %s/
' "$d" >> "$TREE_FIL"
    w "WARN: missing $d"
  fi
done

# VERIFY
extracted=$(grep -m1 '^\- ROOT_PATH:' "$RULES" 2>/dev/null | sed -E 's/.*`([^`]*)`.*/\1/')
[ "$extracted" = "$ROOT" ] && log "OK: ROOT_PATH matches pwd" || log "MISMATCH: '$extracted' vs '$ROOT'"
for k in "## 12." "## 13." "## 14." "## 15."; do
  log "  '$k' -> $(grep -c -- "$k" "$RULES" 2>/dev/null || echo 0)"
done

# HYPOTHESES / EXPLANATIONS в SUMMARY
tsv_lines=$(wc -l < "$TREE_TSV" 2>/dev/null || echo 0)
filtered_lines=$(wc -l < "$TREE_FIL" 2>/dev/null || echo 0)

H1_STATUS=$([ -f "$RULES" ] && echo CONFIRMED || echo REJECTED); H1_EV="file=$RULES"
H2_STATUS=$([ "$extracted" = "$ROOT" ] && echo CONFIRMED || echo REJECTED); H2_EV="extracted=$extracted pwd=$ROOT"
H3_STATUS=$(grep -q "## 13." "$RULES" && grep -q "## 15." "$RULES" && echo CONFIRMED || echo REJECTED); H3_EV="§13+§15 present"
H4_STATUS=$([ "$tsv_lines" -gt 0 ] && echo CONFIRMED || echo REJECTED); H4_EV="tsv_lines=$tsv_lines"

printf 'HYP H1: %s | evidence: %s\n' "$H1_STATUS" "$H1_EV" >> "$SUMMARY"
printf 'HYP H2: %s | evidence: %s\n' "$H2_STATUS" "$H2_EV" >> "$SUMMARY"
printf 'HYP H3: %s | evidence: %s\n' "$H3_STATUS" "$H3_EV" >> "$SUMMARY"
printf 'HYP H4: %s | evidence: %s\n' "$H4_STATUS" "$H4_EV" >> "$SUMMARY"

printf 'EX: ROOT_PATH в шапке → %s → совпадает с pwd → не покрывает смену cwd\n' "$extracted" >> "$SUMMARY"
printf 'EX: TSV строк → %s → дерево зафиксировано по INCLUDE_DIRS → глубина ограничена 3\n' "$tsv_lines" >> "$SUMMARY"
printf 'EX: FILTERED строк → %s → снимок отфильтрован → не покрывает скрытые каталоги\n' "$filtered_lines" >> "$SUMMARY"

{
  echo "=== $TASK SUMMARY ($TS) ==="
  echo "ROOT:  $ROOT"; echo "DIR:   $DIR"; echo "RULES: $RULES"
  echo "INCLUDE_DIRS: ${INCLUDE_DIRS[*]:-none}"
  echo; echo "--- HEAD ---"; head -12 "$RULES"
  echo; echo "--- TAIL ---"; tail -10 "$RULES"
} > "$DIR/FULL-SUMMARY.txt" 2>&1

ls -la "$DIR/" | tee -a "$LOG"
log "SEND: $DIR/FULL-SUMMARY.txt + $DIR/run.log"
log "KEEP: $RULES $TREE_ALL $TREE_FIL $TREE_TSV"
log "=== DONE (terminal intentionally NOT closed) ==="
