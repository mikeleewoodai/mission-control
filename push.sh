#!/usr/bin/env bash
# push.sh — publish this folder to github.com/mikeleewoodai/mission-control
#
#   ./push.sh                 first run: creates the repo (if needed) and pushes
#   ./push.sh "commit msg"    later runs: commits everything and pushes
#
# Auth is yours: this uses your own `gh` login or your existing git credentials.
# Nothing here stores or transmits a token.

set -euo pipefail
cd "$(dirname "$0")"

OWNER="mikeleewoodai"
REPO="mission-control"
DESC="Two Claude skills that turn a business into a working Mission Control: a Cowork project with scheduled briefs, on-demand skills, and a live dashboard. Local-first by default; optional Supabase + hosted dashboard when you need it on your phone."
MSG="${1:-Update Mission Control skills}"

command -v git >/dev/null || { echo "git not found"; exit 1; }

# Rebuild bundles so skills/ always matches the sources.
if command -v zip >/dev/null; then
  ./build.sh
else
  echo "note: zip not found — skipping bundle rebuild, pushing skills/ as-is"
fi

if [ ! -d .git ]; then
  git init -q
  git branch -M main
fi

git add -A
git commit -q -m "$MSG" || echo "nothing new to commit"

if ! git remote get-url origin >/dev/null 2>&1; then
  if command -v gh >/dev/null; then
    if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
      echo "repo exists — adding remote"
      git remote add origin "https://github.com/$OWNER/$REPO.git"
    else
      echo "creating $OWNER/$REPO"
      gh repo create "$OWNER/$REPO" --public --description "$DESC" --source . --remote origin
    fi
  else
    echo "gh CLI not found — create $OWNER/$REPO on github.com first (empty, no README), then re-run."
    git remote add origin "https://github.com/$OWNER/$REPO.git"
  fi
fi

git push -u origin main

if command -v gh >/dev/null; then
  gh repo edit "$OWNER/$REPO" --description "$DESC" \
    --add-topic claude --add-topic claude-skills --add-topic cowork \
    --add-topic anthropic --add-topic automation --add-topic supabase \
    --add-topic dashboard --add-topic ops >/dev/null 2>&1 \
    && echo "description + topics set"
fi

echo "done → https://github.com/$OWNER/$REPO"
