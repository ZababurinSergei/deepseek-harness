#!/usr/bin/env bash
# build-context-bundle.sh — собрать единый MD для загрузки в чат.
# Включает: правила + снимок проекта + последняя точка восстановления + KEEP.
set +e
trap 'echo "[trap] caught at line $LINENO (no exit)"' ERR

ROOT_PATH="$(pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
DIR="$ROOT_PATH/tmp/context-bundle-$TS"
OUT="$DIR/context.md"
LOG="$DIR/run.log"
mkdir -p "$DIR"
: > "$LOG"

log(){ printf '%s\n' "$*" | tee -a "$LOG"; }
section(){ log ""; log "=== $* ==="; }
w(){ log "[WARN] $*"; }
keep(){ log "KEEP: $*"; }

INCLUDE_DIRS="app codec components core debug schemas sections tools tree ui"

# find helpers
find_rules(){
  for f in tools/RULES-expanded.md tools/RULES.md RULES-expanded.md RULES.md; do
    [ -f "$ROOT_PATH/$f" ] && { echo "$ROOT_PATH/$f"; return 0; }
  done
  # fallback: любой RULES*.md в tools/ или корне
  find "$ROOT_PATH" -maxdepth 2 -type f \( -name 'RULES*.md' -o -name '*rules*.md' \) 2>/dev/null | head -1
}

find_last_restore(){
  for d in "$ROOT_PATH"/tmp/restore-point-[0-9]*/; do
    [ -f "$d/manifest.sha256" ] && [ -f "$d/workdir.tar.gz" ] && echo "$d"
  done | sort | tail -1
}

# find latest tmp/ dir with context-after-failure
find_last_context(){
  ls -1dt "$ROOT_PATH"/tmp/*/ 2>/dev/null | while read -r d; do
    [ -f "$d/context-after-failure.txt" ] && { echo "$d/context-after-failure.txt"; return; }
  done | head -1
}

# 1. HEADER
GIT_HEAD="$(git -C "$ROOT_PATH" rev-parse HEAD 2>/dev/null)"
GIT_BRANCH="$(git -C "$ROOT_PATH" branch --show-current 2>/dev/null)"
HOST="$(hostname 2>/dev/null)"

{
  echo "# CONTEXT BUNDLE — ast-graph-viewer"
  echo ""
  echo "GENERATED_AT: $TS"
  echo "ROOT_PATH:    $ROOT_PATH"
  echo "HOST:         ${HOST:-unknown}"
  echo "GIT_HEAD:     ${GIT_HEAD:-n/a}"
  echo "GIT_BRANCH:   ${GIT_BRANCH:-n/a}"
  echo ""
  echo "> Один файл для загрузки в чат: правила + снимок проекта + точка восстановления + KEEP."
  echo ""
  echo "---"
  echo ""
} > "$OUT"

# 2. RULES
RULES_FILE="$(find_rules)"
{
  echo "## §RULES"
  echo ""
  echo "SOURCE: ${RULES_FILE:-not-found}"
  echo ""
  if [ -n "$RULES_FILE" ] && [ -s "$RULES_FILE" ]; then
    echo '```markdown'
    cat "$RULES_FILE"
    echo '```'
  else
    echo "_Правила не найдены. Ожидались: tools/RULES-expanded.md, tools/RULES.md, RULES.md._"
  fi
  echo ""
  echo "---"
  echo ""
} >> "$OUT"

# 3. RESTORE POINT
LAST_RP="$(find_last_restore)"
{
  echo "## §RESTORE-POINT"
  echo ""
  if [ -n "$LAST_RP" ]; then
    echo "PATH: $LAST_RP"
    [ -f "$LAST_RP/SUMMARY.txt" ] && {
      echo ""
      echo "### SUMMARY"
      echo ""
      echo '```'
      cat "$LAST_RP/SUMMARY.txt"
      echo '```'
    }
    echo ""
    echo "TARBALL:  $LAST_RP/workdir.tar.gz ($(wc -c < "$LAST_RP/workdir.tar.gz" 2>/dev/null) bytes)"
    echo "MANIFEST: $LAST_RP/manifest.sha256 ($(wc -l < "$LAST_RP/manifest.sha256" 2>/dev/null) entries)"
    echo "RESTORE:  $LAST_RP/restore.sh"
  else
    echo "_Точка восстановления не найдена в tmp/restore-point-*/._"
    echo ""
    echo "Создать: \`./tools/create-restore-point.sh\`"
  fi
  echo ""
  echo "---"
  echo ""
} >> "$OUT"

# 4. ROOT TREE (из точки восстановления или свежий снимок)
{
  echo "## §ROOT-TREE"
  echo ""
  if [ -n "$LAST_RP" ] && [ -f "$LAST_RP/root-tree.filtered" ]; then
    echo "SOURCE: $LAST_RP/root-tree.filtered"
    echo ""
    echo '```'
    head -200 "$LAST_RP/root-tree.filtered"
    TOTAL=$(wc -l < "$LAST_RP/root-tree.filtered")
    if [ "$TOTAL" -gt 200 ]; then
      echo ""
      echo "# ... (${TOTAL} entries total, показаны первые 200)"
    fi
    echo '```'
  else
    echo "SOURCE: fresh snapshot (depth<=3, INCLUDE_DIRS)"
    echo ""
    echo '```'
    IGNORE_RE='(^|/)(\.git|node_modules|\.cache|dist|build)(/|$)'
    for d in $INCLUDE_DIRS; do
      [ -d "$ROOT_PATH/$d" ] && ( cd "$ROOT_PATH" && find "$d" -maxdepth 3 -print 2>/dev/null ) | grep -vE "$IGNORE_RE" | grep -vE '\.bak-'
    done | LC_ALL=C sort -u | head -200
    echo '```'
  fi
  echo ""
  echo "---"
  echo ""
} >> "$OUT"

# 5. KEEP POINTS (из последнего context-after-failure)
CTX="$(find_last_context)"
{
  echo "## §KEEP"
  echo ""
  if [ -n "$CTX" ]; then
    echo "SOURCE: $CTX"
    echo ""
    echo '```'
    cat "$CTX"
    echo '```'
  else
    echo "_context-after-failure.txt не найден._"
  fi
  echo ""
  echo "### Скрипты tools/"
  echo ""
  echo '```'
  ls -1 "$ROOT_PATH/tools" 2>/dev/null | grep -vE '\.bak-' | head -50
  echo '```'
  echo ""
  echo "---"
  echo ""
} >> "$OUT"

# 6. RECENT TMP
{
  echo "## §TMP (последние 10)"
  echo ""
  echo '```'
  ls -1dt "$ROOT_PATH"/tmp/*/ 2>/dev/null | head -10 | sed "s|$ROOT_PATH/||"
  echo '```'
  echo ""
  echo "---"
  echo ""
} >> "$OUT"

# 7. USAGE
{
  echo "## §USAGE"
  echo ""
  echo "**Загрузить в чат:** прикрепить файл \`$(basename "$OUT")\` или вставить его содержимое."
  echo ""
  echo "**Что внутри:**"
  echo "- §RULES — правила чата (инвариант сессии)"
  echo "- §RESTORE-POINT — последняя точка восстановления"
  echo "- §ROOT-TREE — снимок структуры (≤200 строк)"
  echo "- §KEEP — артефакты, которые нельзя терять"
  echo "- §TMP — свежие рабочие каталоги"
  echo ""
  echo "**Регенерация:** \`./tools/build-context-bundle.sh\` → \`tmp/context-bundle-*/context.md\`"
  echo ""
} >> "$OUT"

# HYPOTHESES / SUMMARY
section "HYPOTHESES"
SIZE=$(wc -c < "$OUT" 2>/dev/null || echo 0)
LINES=$(wc -l < "$OUT" 2>/dev/null || echo 0)
HAS_RULES=$([ -n "$RULES_FILE" ] && [ -s "$RULES_FILE" ] && echo 1 || echo 0)
HAS_RP=$([ -n "$LAST_RP" ] && echo 1 || echo 0)

log "[HYPOTHESIS H1] Bundle содержит §RULES, §RESTORE-POINT, §ROOT-TREE, §KEEP, §TMP => STATUS: $([ "$HAS_RULES" = 1 ] && [ "$HAS_RP" = 1 ] && echo CONFIRMED || echo PARTIAL) | evidence: rules=$HAS_RULES restore_point=$HAS_RP | note: priority high"
log "[HYPOTHESIS H2] Bundle готов к загрузке в чат (единый MD, <=200KB) => STATUS: $([ "$SIZE" -gt 0 ] && [ "$SIZE" -lt 200000 ] && echo CONFIRMED || echo PARTIAL) | evidence: size=$SIZE bytes, lines=$LINES | note: priority high"
log "H1 XOR H2"

section "SUMMARY"
log "OUT:   $OUT"
log "SIZE:  $SIZE bytes"
log "LINES: $LINES"
log "RULES: ${RULES_FILE:-not-found}"
log "RP:    ${LAST_RP:-not-found}"
keep "$OUT"
keep "$LOG"

cat <<EOF

=== ОБЪЯСНЕНИЕ РЕЗУЛЬТАТОВ ===
bundle         -> $OUT ($SIZE bytes, $LINES lines) -> [ok/miss]
rules          -> ${RULES_FILE:-not-found}           -> [found/not-found]
restore-point  -> ${LAST_RP:-not-found}              -> [found/not-found]
root-tree      -> первые 200 строк из точки или fresh -> [ok]
keep           -> из context-after-failure.txt        -> [ok/miss]

=== ВЫВОД ПРОВЕРЯЕМЫХ ГИПОТЕЗ ===
H1: $([ "$HAS_RULES" = 1 ] && [ "$HAS_RP" = 1 ] && echo CONFIRMED || echo PARTIAL) | priority: high
H2: $([ "$SIZE" -gt 0 ] && [ "$SIZE" -lt 200000 ] && echo CONFIRMED || echo PARTIAL) | priority: high
H1 XOR H2

=== ИТОГ ===
Bundle: $OUT
Загрузить: прикрепить файл к сообщению в чате.
EOF

exit 0
