# MCP_NAVISWORK

MCP server for Autodesk Navisworks.

## Git workflow: commit + push after qualification

- Do not commit or push until the user **qualifies** (approves) the changes, e.g. by replying "qualified" / "validé" / "approved" or running `/ship`.
- Once qualified, commit and push immediately to the current branch on `origin` (GitHub) without asking again: descriptive commit message, then `git push`.
- Never force-push. Never commit secrets (`.env`, credentials, `.claude/settings.local.json`).
- Hooks in `.claude/settings.json` support this: a Stop hook reminds the user when changes are pending, and a UserPromptSubmit hook detects the approval words.
