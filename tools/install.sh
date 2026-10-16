#!/usr/bin/env bash
# Установка gen-rules.sh в целевой проект.
# Использование: bash install.sh <путь-к-проекту>
set -uo pipefail; set +H; set +e
TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "usage: bash install.sh <path-to-project>"; return 0 2>/dev/null || true; }
[ -d "$TARGET" ] || { echo "not a directory: $TARGET"; return 0 2>/dev/null || true; }

HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$TARGET/tools"
cp -n "$HERE/gen-rules.sh" "$TARGET/tools/gen-rules.sh"
cp -n "$HERE/README.md"    "$TARGET/tools/README.md"
chmod +x "$TARGET/tools/gen-rules.sh"
echo "installed into: $TARGET/tools/"
ls -la "$TARGET/tools/"
echo "next: (cd $TARGET && bash tools/gen-rules.sh)"
