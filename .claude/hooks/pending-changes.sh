#!/usr/bin/env bash
# Stop hook: remind the user when there are uncommitted changes awaiting qualification.
cat >/dev/null  # consume stdin
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo '{"systemMessage":"Uncommitted changes pending. Reply \"qualified\" (or run /ship) to commit & push to GitHub."}'
fi
exit 0
