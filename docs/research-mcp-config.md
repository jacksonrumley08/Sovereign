# MCP Configuration Research — Blender + Godot via Claude Code

Date of research: 2026-04-28
Method: 3 parallel audit agents → synthesis → 3 parallel devil's-advocate agents → verification round → final DA round → synthesis

## TL;DR

Run the project in **two phases**:

- **Phase 1 (now):** Godot side only. Install `hi-godot/godot-ai` v2.2.0 (pinned commit). Use Claude Code to write GDScript, manipulate scenes, run the project, read errors. Use free assets (Kenney, Quaternius) while validating the workflow.
- **Phase 2 (later, ~5–8h of setup):** Add `ahujasid/blender-mcp` for asset authoring. Requires PreToolUse validation hook, SessionStart OneDrive guard, and `start-session.ps1` to be reliable.

---

## Tool Picks (verified)

### Blender side — `ahujasid/blender-mcp` (defer to Phase 2)

- 20.8k stars, MIT license, actively maintained as of April 2026
- Exposes `execute_blender_code` for arbitrary `bpy` Python — required for "implement creative ideas" use case (rigs, animation export, custom geometry)
- **Win11 port issue:** port 9876 is blocked on Win11 (issue #193). Workaround: set `BLENDER_PORT=9001` env var on the MCP server and match in the Blender addon
- Telemetry on by default — disable with `DISABLE_TELEMETRY=true`
- `execute_blender_code` is unsandboxed (issue #207) — bad scripts can hang Blender. Save .blend before each agent run.

### Godot side — `hi-godot/godot-ai` v2.2.0

- Repo created 2026-04-12 (very young — solo maintainer dsarno)
- Pin to commit `27752ebdc412751905b064942919d24b064e7a1c` (v2.2.0 tag)
- 134 stars, MIT, plugin-based architecture
- Architecture: GDScript addon ↔ WebSocket port 9500 ↔ Python FastMCP server on port 8000 ↔ Claude Code over HTTP MCP
- Tools (15 dispatchers w/ sub-ops, ~120 effective operations):
  - `node_create`, `node_manage` (reparent, delete, rename, duplicate, move)
  - `scene_manage` (create, save, load, instance)
  - `script_create`, `script_patch`, `script_attach`
  - `signal_manage` (connect, disconnect, find)
  - `filesystem_manage` (reimport — returns retryable `EDITOR_IMPORTING` error per PR #95)
  - `resource_manage`, `logs_read` (sources: plugin / game / editor / combined)
- **Known caveat:** crash issues #242 and #247 are **self-update path only** — fresh installs at v2.2.0 are unaffected. Do NOT click the in-dock self-update banner.
- **Reentrancy gap:** no `is_scanning` guard, no blocking `wait_for_reimport`. Use the typed `EDITOR_IMPORTING` retryable error pattern from PR #95 instead of polling logs.

### Rejected alternatives

- `Coding-Solo/godot-mcp` — CLI-per-call, no persistent editor state. State is lost between calls. Fine for bootstrapping, useless for iteration.
- `youichi-uda/godot-mcp-pro` ($5–$15, sources disagreed) — closed-source paid server, can't audit, doesn't solve the reimport gap, and Blender workflow not mentioned.
- `ee0pdt/Godot-MCP` — last commit 2025-03-19, 13 months stale.
- `GDAI MCP` ($19) — older, decent, but dominated on price + capability by alternatives.
- `Anthropic's official Blender connector` (announced 2026-04-28) — works with Claude Code per [tutorial](https://claude.com/resources/tutorials/using-the-blender-connector-in-claude), but curated tool surface (no `execute_blender_code`), so won't cover rigs/animation. Worth re-evaluating in ~30 days if Blender Lab publishes a Python-exec tool.

---

## Sync mechanics (Phase 2 only)

### glTF export settings for clean Godot 4.4+ import

- Format: glTF Binary `.glb` (not `.gltf+.bin+textures`) — embed textures
- +Y up, scale 1.0, **apply transforms** before export
- Apply Modifiers ON, Tangents ON, Vertex Colors ON, Backface Culling ON in materials
- Materials: **Principled BSDF only.** Anything else degrades to flat color (Godot issue #75567)
- Animation: push to NLA, "Group by NLA Track" ON, "Export all actions" OFF
- Don't rely on Empty rotations surviving glTF — use child mesh marker if orientation matters
- `-col` / `-colonly` / `-rigid` suffixes only work for direct `.blend` import, not `.glb` (issue #32363)

### File layout (when Phase 2 activates)

```
GameTesting2/                 <- res:// root
├── project.godot
├── addons/
│   └── godot_ai/             <- hi-godot/godot-ai plugin (Phase 1)
├── scenes/
├── scripts/
├── assets/
│   ├── models/               <- exported .glb only
│   └── textures/
└── docs/

C:\Users\Jacks\GameTesting2-blender\   <- .blend sources, OUTSIDE res://
├── characters/
└── props/
```

### Reimport pattern (avoid polling logs)

Godot's `editor_file_system.cpp` doesn't emit a stable per-file success token (verified by searching the source). Polling `logs_read` for "imported" is fragile. Instead:

1. Call `filesystem_manage(reimport)` 
2. If next call returns `EDITOR_IMPORTING` typed error, retry with backoff (250ms, 500ms, 1s, cap 5s, 10 attempts max)
3. Don't string-match log lines

### Documented Godot/Blender pipeline gotchas

- Reimport requires editor focus (proposals #9520, #3252 closed without fix). Plugin must call `EditorFileSystem.scan()` explicitly — but watch for reentrancy crashes (#54864, #46893, #48257)
- UID instability: overwriting a `.glb` can change UIDs in scenes that reference it (#114493). `.uid` files don't regenerate cleanly if deleted (#99779)
- Re-import of overwritten `.glb` sometimes does nothing (#90241)
- OneDrive paths stall Godot's file picker (#100387). Project must NOT be on OneDrive
- 260-char `MAX_PATH` blows Godot's import cache on deep paths

---

## Required hooks for production-grade Phase 2

### 1. PreToolUse hook (`.claude/hooks/validate-blender.py`)

Without this, expect ~15–25% of sessions to produce flat-color cubes because Claude forgot Principled BSDF. CLAUDE.md prose alone is unreliable.

- Match `mcp__blender__execute_blender_code` calls
- Reject: `ShaderNodeBsdfDiffuse|ShaderNodeBsdfGlass`
- Require `ShaderNodeBsdfPrincipled` if any shader node is touched
- Reject `bpy.ops.wm.save_as_mainfile` with paths under res://
- Normalize export paths to forward slashes
- Effort: 2–4h

### 2. SessionStart hook (`.claude/hooks/onedrive-guard.ps1`) — Phase 1 priority

```powershell
$p = $env:CLAUDE_PROJECT_DIR
if ((Get-Item $p).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint) -or $p -like "*OneDrive*") {
  Write-Error "Project is on OneDrive — aborting"
  exit 2
}
```

- Wired as `SessionStart` matcher `"startup"` in settings.json
- Effort: 30 min

### 3. `start-session.ps1` (Phase 2)

- `Start-Process` Blender, poll TCP 127.0.0.1:9001 until open
- `Start-Process` Godot with `--path <project>`
- Poll WebSocket 127.0.0.1:9500 until plugin reachable
- `Start-Process claude`
- Effort: 1–2h

### Why hooks, not a custom MCP wrapper

A custom wrapper around `ahujasid/blender-mcp` means forking, re-exposing 19 tools, maintaining indefinitely. A PreToolUse hook is ~50 lines of Python, intercepts at the right boundary, exits cleanly with `permissionDecision: deny`.

---

## Tool surface dilution

Combined surface: Blender ~20 tools + Godot ~15 dispatchers. Anthropic's docs explicitly state ["tool selection accuracy degrades past 30–50 tools"](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool). Mitigation in Claude Code: `Tool Search` / `defer_loading` is auto-enabled when descriptions exceed ~10K tokens. **Doesn't justify dropping an MCP**, but if you observe mis-routing, disable one server per session via `disabledMcpjsonServers` in `.claude/settings.local.json`.

Namespace prefixing is automatic (`mcp__blender__execute_blender_code` etc.) — collision risk is low.

---

## Per-claim verification status (final round)

| Claim | Verdict |
|---|---|
| `ahujasid/blender-mcp` 20.8k stars, MIT, active | CONFIRMED |
| Win11 port 9876 blocked, workaround port 9001 (#193) | CONFIRMED |
| `hi-godot/godot-ai` v2.2.0 released 2026-04-28 | CONFIRMED (busy maintenance, ~2 releases/day) |
| `hi-godot/godot-ai` SIGABRT crashes affect fresh installs | REFUTED — self-update path only |
| `EDITOR_IMPORTING` retryable error replaces log polling | CONFIRMED (PR #95 closed 2026-04-19) |
| `youichi-uda/godot-mcp-pro` price $5 | UNCLEAR (sources gave $5 and $15) |
| `youichi-uda/godot-mcp-pro` 172 tools / 24 categories | REFUTED — actually 163 / 23 |
| Anthropic Blender connector NOT in Claude Code | REFUTED — supported per official tutorial |
| Tool dilution past 40 tools real | CONFIRMED (Anthropic docs say 30–50) |
| Tool Search auto-mitigates | CONFIRMED in Claude Code at >10K token threshold |
| `editor_file_system.cpp` lacks per-file import success token | CONFIRMED via source search |

---

## Sources

- [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- [ahujasid/blender-mcp issue #193 (Win11 port 9876)](https://github.com/ahujasid/blender-mcp/issues/193)
- [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai)
- [hi-godot/godot-ai docs/TOOLS.md](https://github.com/hi-godot/godot-ai/blob/main/docs/TOOLS.md)
- [Anthropic — Claude for Creative Work (2026-04-28)](https://www.anthropic.com/news/claude-for-creative-work)
- [Anthropic Blender connector tutorial](https://claude.com/resources/tutorials/using-the-blender-connector-in-claude)
- [Tool Search Tool docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)
- [Claude Code MCP docs](https://code.claude.com/docs/en/mcp)
- [Claude Code hooks reference](https://code.claude.com/docs/en/hooks)
- [Godot 4.4 UID changes blog](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
- [Godot importing 3D scenes docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)
- [Godot issue #90241 — .glb reimport doesn't update](https://github.com/godotengine/godot/issues/90241)
- [Godot issue #75567 — Principled BSDF required for materials](https://github.com/godotengine/godot/issues/75567)
- [Godot issue #114493 — overwrite changes UID](https://github.com/godotengine/godot/issues/114493)
- [Godot issue #100387 — OneDrive file picker stalls](https://github.com/godotengine/godot/issues/100387)
- [Godot issue #54864 — EditorFileSystem.scan reentrancy crash](https://github.com/godotengine/godot/issues/54864)
- [Blender Studio — Workflow with Blender and Godot](https://studio.blender.org/blog/our-workflow-with-blender-and-godot/)
- [9to5Mac — Anthropic releases 9 Claude connectors (2026-04-28)](https://9to5mac.com/2026/04/28/anthropic-releases-9-new-claude-connectors-for-creative-tools-including-blender-and-adobe/)
