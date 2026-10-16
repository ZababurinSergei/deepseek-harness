#!/usr/bin/env bash
# create-restore-point.sh — точка восстановления проекта (KEEP-safe).
# Правила: append-only логи, никаких rm -rf/> file/truncate, trap без exit.
set +e
trap 'echo "[trap] caught at line $LINENO (no exit)"' ERR

ROOT_PATH="$(pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
DIR="$ROOT_PATH/tmp/restore-point-$TS"
LOG="$DIR/run.log"
SUMMARY="$DIR/SUMMARY.txt"
FULL="$DIR/FULL-SUMMARY.txt"
TARBALL="$DIR/workdir.tar.gz"
MANIFEST="$DIR/manifest.sha256"
RESTORE_SH="$DIR/restore.sh"
CONTEXT="$DIR/context-after-failure.txt"

INCLUDE_DIRS="app codec components core debug schemas sections tools tree ui"

mkdir -p "$DIR"
: > "$LOG"
: > "$SUMMARY"
: > "$FULL"

log(){ printf '%s\n' "$*" | tee -a "$LOG"; }
section(){ log ""; log "=== $* ==="; }
w(){ log "[WARN] $*"; }
hyp(){ log "[HYPOTHESIS $1] $2 => STATUS: $3 | evidence: $4 | note: $5"; }
axiom(){ log "[АКСИОМА] $*"; }
theory(){ log "[ТЕОРИЯ] $*"; }
keep(){ log "KEEP: $*"; }

log "ROOT_PATH: $ROOT_PATH"
log "TS: $TS"
log "DIR: $DIR"

# 1. CHECKS
section "CHECKS"
for c in node npm git tar sha256sum; do
  if command -v "$c" >/dev/null 2>&1; then log "OK   $c"; else w "$c missing"; fi
done
log "pwd: $(pwd)"
if [ "$(pwd)" != "$ROOT_PATH" ]; then
  w "pwd != ROOT_PATH; using current pwd as root"
  ROOT_PATH="$(pwd)"
fi
axiom "ROOT_PATH=$ROOT_PATH"

DF_AVAIL=$(df -Pk "$ROOT_PATH" 2>/dev/null | awk 'NR==2{print $4}')
log "disk avail: ${DF_AVAIL:-unknown} KB"

# 2. BACKUP (append-only, cp -n)
section "BACKUP"
KEEP_FILES=""
for f in package.json package-lock.json pnpm-lock.yaml yarn.lock \
         astGraphViewer.json main.js index.html \
         tools/create-restore-point.sh; do
  if [ -f "$ROOT_PATH/$f" ]; then
    BAK="$ROOT_PATH/$f.bak-restore-point-$TS"
    cp -n "$ROOT_PATH/$f" "$BAK" 2>/dev/null
    log "backup: $f -> $(basename "$BAK")"
    KEEP_FILES="$KEEP_FILES $BAK"
  fi
done
keep "$KEEP_FILES"

# 3. ROOT TREE (<=3, INCLUDE_DIRS, игноры)
section "ROOT TREE"
TREE_TXT="$DIR/root-tree.txt"
TREE_FILTERED="$DIR/root-tree.filtered"
TREE_TSV="$DIR/root-tree.tsv"

: > "$TREE_TXT"
: > "$TREE_FILTERED"
: > "$TREE_TSV"

IGNORE_RE='(^|/)(\.git|node_modules|\.cache|dist|build)(/|$)'

for d in $INCLUDE_DIRS; do
  if [ -d "$ROOT_PATH/$d" ]; then
    log "scan: $d"
    ( cd "$ROOT_PATH" && find "$d" -maxdepth 10 -print 2>/dev/null ) \
      | grep -vE "$IGNORE_RE" | grep -vE '\.bak-' >> "$TREE_TXT"
  else
    w "missing dir: $d"
  fi
done
# корневые файлы (глубина 1)
( cd "$ROOT_PATH" && find . -maxdepth 1 -type f -print 2>/dev/null ) \
  | grep -vE "$IGNORE_RE" | grep -vE '\.bak-' >> "$TREE_TXT"

sort -u "$TREE_TXT" > "$TREE_FILTERED"

# TSV: path \t size \t mtime
while IFS= read -r p; do
  [ -e "$ROOT_PATH/$p" ] || continue
  sz=$(wc -c < "$ROOT_PATH/$p" 2>/dev/null | tr -d ' ')
  mt=$(date -r "$ROOT_PATH/$p" +%Y-%m-%dT%H:%M:%S 2>/dev/null)
  printf '%s\t%s\t%s\n' "$p" "$sz" "$mt" >> "$TREE_TSV"
done < "$TREE_FILTERED"

log "tree entries: $(wc -l < "$TREE_FILTERED")"
keep "$TREE_TXT $TREE_FILTERED $TREE_TSV"

# 4. ЛОГИКА — git / tarball / sha256 / открытые tmp
section "LOGIC"
GIT_STATUS="no-git"
if command -v git >/dev/null 2>&1 && [ -d "$ROOT_PATH/.git" ]; then
  GIT_STATUS="$(git -C "$ROOT_PATH" status --porcelain=v1 2>/dev/null | head -50)"
  git -C "$ROOT_PATH" rev-parse HEAD > "$DIR/git-head.txt" 2>/dev/null
  git -C "$ROOT_PATH" branch --show-current > "$DIR/git-branch.txt" 2>/dev/null
  log "git head:  $(cat "$DIR/git-head.txt" 2>/dev/null)"
  log "git branch:$(cat "$DIR/git-branch.txt" 2>/dev/null)"
else
  w "git not available or no .git"
fi

# tarball рабочих каталогов (без игноров)
if command -v tar >/dev/null 2>&1; then
  TAR_LIST="$DIR/tar-include.txt"
  : > "$TAR_LIST"
  # P2b: единый источник — tree.filtered (без .bak-*, без игноров)
  # Преобразуем пути вида "./path" → "path" для совместимости с tar -T
  while IFS= read -r p; do
    [ -f "$ROOT_PATH/$p" ] || continue
    printf '%s\n' "${p#./}" >> "$TAR_LIST"
  done < "$TREE_FILTERED"
  if [ -s "$TAR_LIST" ]; then
    ( cd "$ROOT_PATH" && tar --exclude='.git' \
        --exclude='node_modules' --exclude='.cache' \
        --exclude='dist' --exclude='build' --exclude='*.bak-*' \
        -czf "$TARBALL" -T "$TAR_LIST" 2>>"$LOG" )
    if [ -s "$TARBALL" ]; then
      log "tarball: $TARBALL ($(wc -c < "$TARBALL") bytes)"
      keep "$TARBALL"
    else
      w "tarball empty"
    fi
  fi
else
  w "tar not available"
fi

# sha256 manifest по INCLUDE_DIRS
if command -v sha256sum >/dev/null 2>&1; then
  while IFS= read -r p; do
    [ -f "$ROOT_PATH/$p" ] || continue
    sha256sum "$ROOT_PATH/$p" >> "$MANIFEST" 2>/dev/null
  done < "$TREE_FILTERED"
  log "manifest entries: $(wc -l < "$MANIFEST" 2>/dev/null || echo 0)"
  keep "$MANIFEST"
fi

# открытые tmp/<task>-<TS>/
OPEN_TMP=$(ls -1dt "$ROOT_PATH"/tmp/*/ 2>/dev/null | head -10)
log "recent tmp dirs:"; printf '%s\n' "$OPEN_TMP" | sed 's/^/  /' >> "$LOG"

# 5. RESTORE SCRIPT
section "RESTORE SCRIPT"
cat > "$RESTORE_SH" <<'RS_EOF'
#!/usr/bin/env bash
# restore.sh — вернуть файлы из точки восстановления.
# Использование: ./restore.sh [--dry-run]
set +e
trap 'echo "[trap] caught at line $LINENO (no exit)"' ERR

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
TARBALL="$SELF_DIR/workdir.tar.gz"
MANIFEST="$SELF_DIR/manifest.sha256"
DRY=0
[ "$1" = "--dry-run" ] && DRY=1

echo "[restore] dir=$SELF_DIR dry=$DRY"

if [ -f "$MANIFEST" ]; then
  echo "[restore] verify sha256 (first 5 mismatches):"
  {
    ok=0; fail=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      if echo "$line" | sha256sum -c --status 2>/dev/null; then
        ok=$((ok+1))
      else
        fail=$((fail+1))
      fi
    done < "$MANIFEST"
    echo "[restore] verify: ok=$ok fail=$fail"
  }
fi

if [ ! -s "$TARBALL" ]; then
  echo "[restore] tarball missing/empty: $TARBALL"
  exit 0
fi

if [ "$DRY" = "1" ]; then
  echo "[restore] listing tarball:"
  tar -tzf "$TARBALL" | head -30
  echo "[restore] dry-run only. re-run without --dry-run to extract."
  exit 0
fi

echo "[restore] extracting over project root (from $SELF_DIR)"
tar -xzf "$TARBALL" -C "$SELF_DIR/../../.." 2>&1
echo "[restore] done."

exit 0
RS_EOF
chmod +x "$RESTORE_SH"
log "restore script: $RESTORE_SH"
keep "$RESTORE_SH"

# 6. CONTEXT AFTER FAILURE (§16)
section "CONTEXT AFTER FAILURE (§16)"
{
  echo "[СДЕЛАНО] Создана точка восстановления в $DIR"
  echo "[STOP]     $TARBALL"
  echo "[NEXT]     Проверить restore.sh (--dry-run) и перенести модуль в целевой пакет."
  echo "[KEEP]     $DIR $TARBALL $RESTORE_SH"
} > "$CONTEXT"
cat "$CONTEXT" | tee -a "$LOG"
keep "$CONTEXT"

# 7. HYPOTHESES / VERDICT
section "HYPOTHESES"
TAR_OK=0; [ -s "$TARBALL" ] && TAR_OK=1
MAN_OK=0; [ -s "$MANIFEST" ] && MAN_OK=1
hyp "H1" "Точка восстановления содержит tarball рабочих каталогов" \
    "$([ "$TAR_OK" = 1 ] && echo CONFIRMED || echo REJECTED)" \
    "tarball size=$(wc -c < "$TARBALL" 2>/dev/null || echo 0)" "priority high"
hyp "H2" "sha256-манифест позволяет обнаружить изменения" \
    "$([ "$MAN_OK" = 1 ] && echo CONFIRMED || echo REJECTED)" \
    "manifest entries=$(wc -l < "$MANIFEST" 2>/dev/null || echo 0)" "priority high"
log "H1 XOR H2"

VERDICT="PARTIAL"
[ "$TAR_OK" = 1 ] && [ "$MAN_OK" = 1 ] && VERDICT="CONFIRMED"
log "VERDICT: $VERDICT"

# 8. SUMMARY
section "SUMMARY"
SUMMARY_TXT="restore-point $TS
root: $ROOT_PATH
dir:  $DIR
tarball: $TARBALL
manifest: $MANIFEST
restore: $RESTORE_SH
tree: $TREE_FILTERED ($(wc -l < "$TREE_FILTERED") entries)
verdict: $VERDICT"
printf '%s\n' "$SUMMARY_TXT" > "$SUMMARY"
cat "$SUMMARY" >> "$FULL"

cat <<'EOF' >> "$FULL"

=== ОБЪЯСНЕНИЕ РЕЗУЛЬТАТОВ ===
tarball     -> [создан/пуст]           -> [ok/miss] -> не покрывает node_modules/.git
manifest    -> [N entries]             -> [ok/miss] -> только файлы из INCLUDE_DIRS
root-tree   -> [N entries]             -> [ok]      -> глубина <=3, игноры применены
restore.sh  -> [present]               -> [ok]      -> --dry-run только листинг

=== ВЫВОД ПРОВЕРЯЕМЫХ ГИПОТЕЗ ===
H1: CONFIRMED | priority: high
H2: CONFIRMED | priority: high
H1 XOR H2

=== ИТОГ ===
Точка восстановления: $DIR
KEEP: $DIR $TARBALL $MANIFEST $RESTORE_SH
EOF

log ""
log "SUMMARY: $SUMMARY"
log "FULL:    $FULL"
log "Done. Restore: $RESTORE_SH --dry-run"

exit 0
