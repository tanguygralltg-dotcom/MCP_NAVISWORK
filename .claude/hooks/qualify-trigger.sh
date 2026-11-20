#!/usr/bin/env bash
# UserPromptSubmit hook: when the user qualifies (approves) the pending changes,
# instruct Claude to commit and push them.
input=$(cat)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

prompt=$(printf '%s' "$input" | tr '\n' ' ' | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# Approval words: qualified / qualifié / valid / validé / approved / ship / ok push
if printf '%s' "$prompt" | grep -Eiq '^[[:space:]]*(qualifi|valid|approv|ship|ok push)'; then
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"QUALIFICATION RECEIVED: if this message is an approval of the pending changes, commit and push them now: review git status/diff, stage the relevant files (never secrets such as .env or .claude/settings.local.json), commit with a descriptive message plus the attribution trailer, then git push origin <current branch>. Never force-push. Report the commit hash, or the exact error if the push fails."}}
EOF
  fi
fi
exit 0
