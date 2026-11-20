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

## Coordination setup of the example model (`Example naviswork file/Test navis work.nwf`)

**Search sets** (`SETS_PRK`): every set = `Elément > Fichier source` contains `MSBIM-AP-<ARC|STR|MEP>` AND `Objet > Catégorie` = Revit category (pipes/ducts also split by `Classification du système` / `Type de système > Nom`). Folders 01_ARC, 02_STR, 03_CVC, 04_PLB, 05_ELE, 06_SSI, 07_A-VERIFIER and 10_CLASH (the sets used by clash tests). Coverage: 100 % of physical elements; the only excluded categories are Lignes, Ligne d'axe and Pièces. Backup of the previous sets: `Example naviswork file/backup/`.

**Colours**: permanent overrides per set, plus an Appearance Profiler profile `SETS_PRK - Disciplines.xml` (copy in `Example naviswork file/`; install it in `%APPDATA%\Autodesk\Navisworks Manage 2027\AppearanceProfiler\`). ARC = light greys, STR = warm colours (columns red, beams orange), CVC = blue, PLB = green, ELE = yellow/purple, SSI = red/magenta, unclassified = pink. ARC's copy of the structure is 85 % transparent.

**Clash matrix** (Hard tests 10 mm, Clearance tests 50 mm, merge composites on): 01–04 STR vs CVC/PLB/ELE/SSI, 05–08 ARC vs CVC/PLB/ELE/SSI, 09–14 MEP vs MEP, 15–16 clearance PLB/CVC vs ELE. The rigid discipline is always side A, and side B (the one that moves) defines the group. Old tests are kept as `_ANCIEN - …`.

**Groups**: level + network to move + grid zone (`N1 | Chemins de câbles (5 éléments) | vs Sols, Ossature | P2-PB | 6 conflits`). Singletons of the same level and network are merged into one `conflits isolés` group.

**Viewpoints**: `00_VUES GENERALES` (federated, ARC, STR, MEP, STR+MEP), then `10_CONFLITS/<test>/<n> | <group>`: one viewpoint per group, highlighted (A red, B green, rest dimmed).

**Gotcha**: Clash Detective ignores hidden items. Unhide everything (keep only the non-physical categories hidden) before running tests, otherwise the results go to *Resolved*.

## Interactive clash report

`Example_reports/Rapport_Clash_PRK_<date>.html` is a single offline file with KPIs, a discipline matrix, conflicts by level, filters and snapshots. You can edit status, assignee, priority and comments per group or per conflict; changes are stored in the browser. **Exporter les décisions** writes a JSON file that Claude can re-import into Navisworks (`clash_results_edit`). It is regenerated with `tools/Build-ClashReport.ps1` and `tools/clash-report-template.html`.

## Notes

- Also installed: the autom8labs MCP Connector plugin. Its free tier is read-only; full use costs £10 per seat per month.
- AECO MCPs shares anonymised tool-failure data ("learning") unless `"learningEnabled": false` is set in its config.
