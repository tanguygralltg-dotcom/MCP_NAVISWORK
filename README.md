# MCP_NAVISWORK

Connects Claude Code to Autodesk Navisworks Manage 2027 through an MCP server, so Claude can work with the open model: properties, sets, viewpoints, Clash Detective, TimeLiner and exports.

## Current setup

| Item | Value |
|---|---|
| Navisworks | Manage 2027 (Windows) |
| MCP server | [Navisworks MCP by AECO MCPs](https://aecomcps.com/navisworks): free, closed-source |
| Version | v0.2.26 (releases: [SHMH-MCPs/navis-mcp-releases](https://github.com/SHMH-MCPs/navis-mcp-releases)) |
| Navisworks plugin | `%APPDATA%\Autodesk\ApplicationPlugins\NavisMcp.bundle` |
| Server executable | `%APPDATA%\MCPs\NavisMcp\bin\navis-mcp.exe` |
| Claude Code name | `navisworks-mcp` (user scope, stdio) |

How it works: the plugin runs inside Navisworks, and `navis-mcp.exe` is the local MCP server Claude Code starts. The two talk over a private named pipe on this PC.

## Install / reinstall

1. Close Navisworks.
2. Download `NavisMcp-Setup.exe` and `SHA256SUMS.txt` from the latest release. Check the hash with `Get-FileHash NavisMcp-Setup.exe` before running. The installer is **not code-signed**.
3. Run `NavisMcp-Setup.exe /releases:SHMH-MCPs/navis-mcp-releases` and sign in (Microsoft, Google or GitHub).
4. The installer registers the server for Claude Desktop and VS Code, **but not for Claude Code**. Register it yourself:
   ```powershell
   claude mcp add --scope user navisworks-mcp -- "$env:APPDATA\MCPs\NavisMcp\bin\navis-mcp.exe"
   claude mcp list   # expect: navisworks-mcp ... Connected
   ```
   If `claude` isn't on PATH, use the binary bundled with the VS Code extension: `%USERPROFILE%\.vscode\extensions\anthropic.claude-code-*\resources\native-binary\claude.exe`.
5. Open Navisworks with a model and restart Claude Code. `/mcp` should list `navisworks-mcp` with its tools.

## Troubleshooting

- **"sign-in service could not be reached … HttpClient.Timeout of 30 seconds"**: IPv6 is broken on the network. curl falls back to IPv4, but the installer's .NET HTTP client keeps trying IPv6 until it times out. To make Windows prefer IPv4, run this as Administrator:
  ```powershell
  netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 60 4   # prefer IPv4
  netsh interface ipv6 set prefixpolicy ::ffff:0:0/96 35 4   # undo (Windows default)
  ```
  To check: `curl.exe -6 https://aecomcps.com/` fails while `curl.exe -4 https://aecomcps.com/` returns 200.

## Notes

- Also installed: the autom8labs MCP Connector plugin. Its free tier is read-only; full use costs £10 per seat per month.
- AECO MCPs shares anonymised tool-failure data ("learning") unless `"learningEnabled": false` is set in its config.
