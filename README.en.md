# DeskBox Agent & MCP Setup Guide

**[中文](README.md)** | **English**

Official setup documentation, auto-bootstrap script, full **12 Domain Capability Packs / 37 atomic capabilities** reference, flat `schemaVersion: 1` JSON Schema, and companion Skill for connecting AI Agents (**Claude Code**, **OpenAI Codex**, **Cursor**, **VS Code Copilot**, **Windsurf**, **Trae**, **Antigravity**, **OpenCode**, **DeepSeek Harness (`dsh`)**) to [DeskBox](https://github.com/Tianyu199509/DeskBox) (`v1.6.0+`) on Windows 11.

---

## Option A: DeskBox Already Installed (1-Click Setup Prompt)

1. Open **DeskBox Settings → AI & Agents → External Agent Ecosystem**.
2. Click **Copy Setup Prompt** (DeskBox automatically fills the exact command for your installation channel).
3. Paste the prompt into your AI coding client so it registers the `deskbox` MCP server and runs a read-only verification check.

| Channel | Command | Notes |
|---|---|---|
| **Microsoft Store** | `deskbox.exe --mcp` | Uses the Windows App Execution Alias; stays stable across version updates |
| **Direct Installer / Portable** | `"C:\Users\<User>\AppData\Local\Programs\DeskBox\DeskBox.exe" --mcp` | Copy the exact machine path from DeskBox Settings → AI & Agents |

---

## Option B: DeskBox Not Installed Yet (Zero-Touch Agent Bootstrap)

Paste this prompt into your AI Agent (or install the `deskbox-widget` Skill from this repository):

```text
Please read https://github.com/Tianyu199509/deskbox-agent and set up my DeskBox desktop widget environment:
1. Install the companion Skill (`skills/deskbox-widget`) and run `scripts/ensure-deskbox.ps1` to check whether DeskBox (v1.6.0+) is installed.
2. If `installed: false` or outdated, ask for my confirmation first, then run `ensure-deskbox.ps1 -Install -StartHost` to download the architecture-matched official GitHub Release installer (with SHA-256 verification), install DeskBox, and start the host.
3. Register the `deskbox` stdio MCP server using the `mcpCommand` and `mcpArgs` reported by the script via my client's official config mechanism (preserving existing servers without modifying trust stores).
4. Call `deskbox_get_widget_spec` (`detail: "compact"`) to verify connectivity and report the result.
```

---

## Architecture & Safety Boundaries

- **Pure `stdio` + Session-Scoped Named Pipe**: Zero local HTTP/TCP ports. Clients spawn `DeskBox.exe --mcp` (<15 ms NativeAOT startup) which talks to the desktop host over a current-user ACL Named Pipe.
- **Canonical Flat `schemaVersion: 1` Element Graph**: Every widget uses `"root"` + flat `"elements"` + `"popovers"` + semantic icon names (no legacy nested `"view"` trees or raw PUA icon hex codes). `deskbox_upsert_widget` supports both full manifests and incremental element edits (`upsertElements`, `removeElements`, `patchRoot`, `removeRootKeys`, `scriptHunks`).
- **Stage-by-Default (`deskbox_upsert_widget`)**: Without `commit: true`, writes are validated and staged into Workshop preview (`stageId`) without touching the live desktop. Only after explicit user confirmation does `{ "commit": true, "stageId": "<stageId>" }` apply the widget (`manifestJson` may be omitted on `stageId`-only commits, with full idempotency on retry).
- **Bidirectional Studio Awareness (`deskbox_get_studio_context`)**: Agents can inspect the user's open Widget Workshop draft, selected target node path, capsule/expanded viewport focus, pinned capabilities, and pending stages in real time.
- **Token-Lean Progressive Disclosure**: Pass `detail: "compact"` to `deskbox_get_widget_spec` (~3 KB index) and fetch Golden JSON snippets on demand via `deskbox_get_capability_spec` across all **12 Domain Capability Packs / 37 atomic capabilities**.

---

## MCP Tools Catalog (8 Tools, MCP 2025-03-26 Annotations)

| Tool | Works Offline | Description |
|---|---|---|
| `deskbox_get_widget_spec` | Yes | Read the runtime widget specification (`detail: "compact" \| "full"`) and optional Draft 2020-12 JSON Schema |
| `deskbox_get_capability_spec` | Yes | Query any of the 12 Domain Capability Packs or 37 atomic capabilities by `capabilityId` or keyword for tokens and flat v1 Golden JSON snippets |
| `deskbox_get_studio_context` | Yes (graceful fallback) | Read live Widget Workshop state: open widget, user-selected node path, viewport mode, draft `manifest.json`, and pending `stageId`s |
| `deskbox_validate_manifest` | Yes | Validate flat `schemaVersion: 1` `manifest.json`, WinUI element bindings, QuickJS `logic.js`, and `locales` dictionaries |
| `deskbox_list_widgets` | Yes (disk fallback) | List desktop widgets and workspace folders, or pass `widgetId` for live runtime state & collection counts |
| `deskbox_upsert_widget` | Host required | Stage-by-default (`manifestJson` or incremental `upsertElements`/`removeElements`/`patchRoot`/`scriptHunks`; returns `stageId`, desktop unchanged); pass `commit: true` + `stageId` after user confirmation to commit idempotently |
| `deskbox_capture_widget_preview` | Host required | Capture a real native WinUI 3 PNG screenshot (`expanded` / `capsule` / `live`, Dark or Light theme) |
| `deskbox_push_widget_data` | Host required | Push real-time reactive `state` or `collection` updates (e.g. `agent-hud` live telemetry) |
