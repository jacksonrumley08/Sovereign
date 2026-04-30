# GameTesting2 — Phase 1 (Godot only via MCP)

## Status
This project is in **Phase 1** of a planned two-phase MCP setup. Currently active:
- Godot 4.5.1 driven by `hi-godot/godot-ai` v2.2.0 MCP plugin

Phase 2 (Blender MCP + asset pipeline) is intentionally deferred. See `docs/research-mcp-config.md` for the full rationale and the Phase 2 readiness checklist.

## Environment
- Godot 4.5.1 stable: `C:\Users\Jacks\Desktop\Godot_v4.5.1-stable_win64.exe`
- Project root: `C:\Users\Jacks\GameTesting2` (NOT under OneDrive — SessionStart hook enforces this)
- MCP transport: HTTP at `http://127.0.0.1:8000/mcp`
- Plugin ↔ server WebSocket: `127.0.0.1:9500`

## Layout
- `addons/godot_ai/` — the MCP plugin (must be enabled in Project Settings → Plugins after first open)
- `scenes/` — `.tscn` game scenes
- `scripts/` — GDScript files
- `assets/models/` — 3D models (`.glb` only when Phase 2 lands; for now use Kenney / Quaternius free assets)
- `assets/textures/` — texture files
- `docs/research-mcp-config.md` — full audit findings
- `.claude/hooks/onedrive-guard.ps1` — SessionStart guard

## Iteration loop (Phase 1)
1. **Always open the Godot editor before talking to me.** The MCP plugin only responds while the editor is running.
2. Tell me what to build. I drive scene/node/script operations via MCP tools (`node_create`, `script_create`, `script_patch`, `signal_manage`, etc.)
3. Run scenes via the plugin's run tool; I read errors via `logs_read`.

## Reimport pattern (Phase 2 only — recorded here so we don't relearn it)
- Call `filesystem_manage(reimport)`
- If the next dependent call returns `EDITOR_IMPORTING`, retry with backoff: 250ms → 500ms → 1s, cap 5s, max 10 attempts
- **Do NOT poll `logs_read` for an "imported" success line.** Godot's `editor_file_system.cpp` doesn't emit a stable per-file success token. Use the typed retryable error from PR #95 instead.

## Hard rules
- **Never click the godot-ai plugin's in-dock self-update banner.** Self-update path has open SIGABRT crashes (#242, #247). Update by re-cloning at a release tag.
- **Never move this project under OneDrive.** The SessionStart hook will refuse to start a session.
- **Never put `.blend` files in `res://`** (Phase 2 concern; recording the rule now).
- Pin `hi-godot/godot-ai` to v2.2.0 (commit `27752ebdc412751905b064942919d24b064e7a1c`).

## Known limitations
- `godot-ai` is 16 days old (created 2026-04-12), solo-maintained. Expect occasional rough edges.
- No `wait_for_reimport` primitive — use the `EDITOR_IMPORTING` retry pattern.
- Tool surface stays small in Phase 1 (~15 dispatchers); Tool Search auto-mitigates if it grows in Phase 2.

## When to revisit
- ~30 days from 2026-04-28: check whether Anthropic's official Blender connector adds `execute_blender_code` (would replace `ahujasid/blender-mcp` for Phase 2)
- When godot-ai ships a tagged release with the self-update fix from #244
- If observing tool mis-routing in Phase 2: disable one MCP per session via `disabledMcpjsonServers` in `.claude/settings.local.json`
