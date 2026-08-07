#!/usr/bin/env bash
set -euo pipefail

# Read-only macOS helper. Does NOT print environment-variable values or credentials.
OUT="${1:-zcode-cli-observation-$(date +%Y%m%d-%H%M%S).txt}"

{
  echo "# ZCode CLI observation"
  echo "timestamp=$(date)"
  echo "macOS=$(sw_vers -productVersion 2>/dev/null || true)"
  echo

  echo "## ZCode app version"
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString'     /Applications/ZCode.app/Contents/Info.plist 2>/dev/null || true
  echo

  echo "## Matching processes"
  ps -axo pid=,ppid=,user=,etime=,command= | grep '[z]code-cli' || true
  echo

  PIDS="$(pgrep -x zcode-cli 2>/dev/null || true)"
  [[ -n "$PIDS" ]] || { echo "No zcode-cli process found."; exit 0; }

  for PID in $PIDS; do
    echo "============================================================"
    echo "## PID $PID"
    ps -p "$PID" -o pid=,ppid=,user=,etime=,command= || true
    echo

    PARENT="$(ps -p "$PID" -o ppid= | tr -d ' ' || true)"
    if [[ -n "$PARENT" ]]; then
      echo "### Parent"
      ps -p "$PARENT" -o pid=,ppid=,user=,etime=,command= || true
      echo
    fi

    echo "### CWD"
    lsof -a -p "$PID" -d cwd -Fn 2>/dev/null || true
    echo

    echo "### Network"
    lsof -nP -a -p "$PID" -i 2>/dev/null || true
    echo

    echo "### Unix sockets"
    lsof -nP -a -p "$PID" -U 2>/dev/null || true
    echo

    echo "### Open files (first 200 lines)"
    lsof -nP -p "$PID" 2>/dev/null | sed -n '1,200p' || true
    echo

    echo "### Children"
    ps -axo pid=,ppid=,user=,etime=,command= | awk -v p="$PID" '$2 == p {print}' || true
    echo
  done
} > "$OUT"

echo "Wrote $OUT"
echo "Review before sharing; file paths may reveal private project names."
