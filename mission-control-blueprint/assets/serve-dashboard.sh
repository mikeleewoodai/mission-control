#!/usr/bin/env bash
# ===== Mission Control - local server launcher (macOS/Linux) =====
# Run from inside the project folder:  bash serve-dashboard.sh
# Serves the folder at http://localhost:8000 and opens the dashboard.
# Ctrl+C to stop.
cd "$(dirname "$0")" || exit 1
URL="http://localhost:8000/dashboard.html"
echo "Serving $(pwd)"
echo "Dashboard: $URL   (Ctrl+C to stop)"
( sleep 1; (command -v open >/dev/null && open "$URL") || (command -v xdg-open >/dev/null && xdg-open "$URL") ) >/dev/null 2>&1 &
if command -v python3 >/dev/null 2>&1; then python3 -m http.server 8000; else python -m http.server 8000; fi
