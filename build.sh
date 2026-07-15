#!/usr/bin/env bash
# Repack the unpacked skill sources into installable .skill bundles.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p skills
for s in mission-control-blueprint mission-control-cloud; do
  rm -f "skills/$s.skill"
  zip -q -r "skills/$s.skill" "$s" -x '*.DS_Store'
  echo "built skills/$s.skill"
done
