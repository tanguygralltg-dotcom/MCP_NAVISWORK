---
name: ship
description: Commit and push the qualified (user-approved) changes to GitHub. Use when the user runs /ship or says the pending changes are qualified/approved.
---

The user has qualified the pending changes. Ship them:

1. Run `git status` and `git diff` to review what changed.
2. Stage the relevant files. Never stage secrets (`.env`, credentials, `.claude/settings.local.json`); warn the user if any are present.
3. Commit with a concise, descriptive message (why + what), ending with the attribution trailer.
4. `git push origin <current branch>`. Never force-push.
5. Report the commit hash and confirm the push. If the push fails, stop and report the exact error.

If there is nothing to commit, say so and stop.
