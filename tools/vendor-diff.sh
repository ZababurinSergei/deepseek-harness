#!/usr/bin/env bash
# vendor-diff.sh — печатает диффы вендора по диапазонам из vendor-diff.config.json.
#
# Использование:
#   tools/vendor-diff.sh                  # все диапазоны из конфига + рабочие правки
#   tools/vendor-diff.sh --list           # только оглавление диапазонов
#   tools/vendor-diff.sh --range <name>   # один диапазон по имени
#   tools/vendor-diff.sh --stat           # --stat по каждому диапазону
#   tools/vendor-diff.sh --working        # только незакоммиченные правки
#   tools/vendor-diff.sh --save           # всё в tmp/vendor-diff-<TS>.patch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/vendor-diff.config.json"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: config not found: $CONFIG" >&2
    exit 3
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: 'jq' not found. Установите jq (apt install jq)." >&2
    exit 3
fi

VENDOR_DIR="$(jq -r '.vendor_dir' "$CONFIG")"
TMP_DIR="$(jq -r '.tmp_dir'   "$CONFIG")"
TS="$(date +%Y%m%d-%H%M%S)"

cd "$VENDOR_DIR"
export GIT_PAGER=cat

MODE="all"
RANGE_NAME=""
case "${1:-}" in
    --list)         MODE="list" ;;
    --stat)         MODE="stat" ;;
    --working)      MODE="working" ;;
    --save)         MODE="save" ;;
    --range)        MODE="range"; RANGE_NAME="${2:-}" ;;
    ""|--all)       MODE="all" ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

# Список диапазонов в виде name<TAB>from<TAB>to<TAB>desc
ranges_list() {
    jq -r '.ranges[] | [.name, .from, .to, (.desc // "")] | @tsv' "$CONFIG"
}

emit_header() {
    local name="$1" from="$2" to="$3" desc="$4"
    echo "============================================================"
    echo "VENDOR DIFF — $name"
    echo "vendor dir:  $VENDOR_DIR"
    echo "from:        $from"
    echo "to:          $to"
    [ -n "$desc" ] && echo "desc:        $desc"
    echo "generated:   $(date -Iseconds)"
    echo "============================================================"
    echo
}

list_ranges() {
    echo "--- ranges in $CONFIG ---"
    printf "%-24s %-14s %-14s %s\n" "NAME" "FROM" "TO" "DESC"
    ranges_list | while IFS=$'\t' read -r name from to desc; do
        printf "%-24s %-14s %-14s %s\n" "$name" "$from" "$to" "$desc"
    done
    echo
}

run_range() {
    local name="$1" from="$2" to="$3" desc="$4"
    local stat_only="${5:-0}"

    # Проверка существования from/to
    if ! git rev-parse --verify "$from" >/dev/null 2>&1; then
        echo "WARN: '$from' не найден — пропуск диапазона $name" >&2
        return
    fi
    if ! git rev-parse --verify "$to" >/dev/null 2>&1; then
        echo "WARN: '$to' не найден — пропуск диапазона $name" >&2
        return
    fi

    emit_header "$name" "$from" "$to" "$desc"

    if [ "$stat_only" = "1" ]; then
        git --no-pager diff --stat "$from..$to"
        echo
        return
    fi

    echo "### commits: $from..$to"
    if [ "$(git rev-parse "$from")" = "$(git rev-parse "$to")" ]; then
        echo "(пустой диапазон: from == to)"
    else
        git --no-pager log --oneline --reverse "$from..$to"
    fi
    echo
    echo "### diff: $from..$to"
    git --no-pager diff "$from..$to"
    echo
    echo "============================================================"
    echo "END OF RANGE: $name"
    echo "============================================================"
    echo
}

run_all() {
    local stat_only="${1:-0}"
    local any=0
    while IFS=$'\t' read -r name from to desc; do
        any=1
        if [ -n "$RANGE_NAME" ] && [ "$name" != "$RANGE_NAME" ]; then
            continue
        fi
        run_range "$name" "$from" "$to" "$desc" "$stat_only"
    done < <(ranges_list)

    if [ "$MODE" = "range" ] && [ "$any" = "1" ]; then
        # проверка, что нашли запрошенный диапазон
        if ! ranges_list | awk -F'\t' -v n="$RANGE_NAME" '$1==n{found=1}END{exit !found}'; then
            echo "ERROR: range '$RANGE_NAME' не найден в конфиге" >&2
            exit 4
        fi
    fi

    if [ "$MODE" != "stat" ] && [ "$MODE" != "list" ]; then
        echo "### DIFF: working tree (незакоммиченные изменения)"
        git --no-pager diff
        echo
    fi
}

do_output() {
    case "$MODE" in
        list)
            list_ranges
            ;;
        stat)
            run_all 1
            ;;
        working)
            echo "### DIFF: working tree"
            git --no-pager diff
            ;;
        range)
            run_all 0
            ;;
        all|*)
            list_ranges
            run_all 0
            ;;
    esac
}

if [ "$MODE" = "save" ]; then
    mkdir -p "$TMP_DIR"
    OUT="$TMP_DIR/vendor-diff-$TS.patch"
    { list_ranges; run_all 0; } | tee "$OUT"
    echo
    echo ">>> saved to: $OUT"
else
    do_output
fi
