#!/usr/bin/env bash
# run-e2e.sh — запуск e2e-сценария из ./e2e/<name>/
# Usage:
#   ./tools/run-e2e.sh <e2e-dir-name>            # headless, без пауз
#   ./tools/run-e2e.sh <e2e-dir-name> --step     # headed, пошагово (Enter между шагами)
# Env:
#   SLOWMO=200                                   # замедлить playwright (ms)
set -u
ROOT="/home/sergei/Desktop/system/packages/a4_6537"
cd "$ROOT"

NAME="${1:-}"
STEP=0
for a in "$@"; do [ "$a" = "--step" ] && STEP=1; done

[ -z "$NAME" ] && { echo "usage: $0 <e2e-dir-name> [--step]"; ls -1 ./e2e 2>/dev/null; exit 1; }
E2E_ABS="$ROOT/e2e/$NAME"
[ -d "$E2E_ABS" ] || { echo "[FAIL] нет каталога $E2E_ABS"; exit 1; }

# приоритет probe-stepwise.mjs при --step, иначе probe-isdirty/with-artifacts/orphan
if [ "$STEP" = "1" ] && [ -f "$E2E_ABS/probe-stepwise.mjs" ]; then
  PROBE="$E2E_ABS/probe-stepwise.mjs"
else
  PROBE="$E2E_ABS/probe-isdirty.mjs"
  [ -f "$PROBE" ] || PROBE="$E2E_ABS/probe-with-artifacts.mjs"
  [ -f "$PROBE" ] || PROBE="$E2E_ABS/probe-orphan.mjs"
  [ -f "$PROBE" ] || PROBE="$(ls -1 "$E2E_ABS"/probe-*.mjs 2>/dev/null | head -1)"
fi
[ -n "${PROBE:-}" ] && [ -f "$PROBE" ] || { echo "[FAIL] нет probe-*.mjs в $E2E_ABS"; exit 1; }

RUN="$ROOT/tmp/run-e2e-$NAME-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN"

# KILL портов 6537/6538
for p in 6537 6538; do
  for pid in $(lsof -t -i :$p 2>/dev/null || true); do
    [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ] && kill -9 "$pid" 2>/dev/null || true
  done
done
pkill -9 -f 'ms-playwright|headless_shell' 2>/dev/null || true
sleep 2

# server + vite (в фоне)
node server.js > "$RUN/server.stdout" 2>&1 &
echo $! > "$RUN/server.pid"
npx --no-install vite --config vite.config.ts --port 6538 --strictPort > "$RUN/vite.stdout" 2>&1 &
echo $! > "$RUN/vite.pid"

wait_port () {
  local port="$1"; local tries=80
  while [ "$tries" -gt 0 ]; do
    if (echo > "/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1; then return 0; fi
    tries=$((tries - 1)); sleep 0.5
  done
  return 1
}
wait_port 6537 || { echo "[FAIL] server 6537"; tail -n 30 "$RUN/server.stdout"; exit 1; }
wait_port 6538 || { echo "[FAIL] vite 6538";   tail -n 30 "$RUN/vite.stdout";   exit 1; }
sleep 4

# выбор режима
if [ "$STEP" = "1" ]; then
  echo "[run-e2e] headed + stepwise; Enter=продолжить, s=без пауз, q=выход"
  ACTIVE_FOR_NODE=6538 E2E_DIR="$E2E_ABS" HEADED=1 STEPWISE=1 SLOWMO="${SLOWMO:-300}" node "$PROBE" 2>&1 | tee "$RUN/run.txt"
else
  echo "[run-e2e] headless"
  ACTIVE_FOR_NODE=6538 E2E_DIR="$E2E_ABS" node "$PROBE" 2>&1 | tee "$RUN/run.txt"
fi

# остановка
for f in "$RUN/vite.pid" "$RUN/server.pid"; do
  [ -f "$f" ] || continue
  pid="$(cat "$f")"
  kill "$pid" 2>/dev/null || true
  sleep 1
  kill -0 "$pid" 2>/dev/null && kill -TERM "$pid" 2>/dev/null || true
done

echo ""
echo "KEEP: $RUN"
echo "E2E-артефакты: $E2E_ABS"
echo "Trace: npx --no-install playwright show-trace $E2E_ABS/trace.zip"
