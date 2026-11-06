---
name: deskbox-widget
description: Design, create, visually verify, stage-and-commit, and push live telemetry to native WinUI 3 Custom Widgets (manifest.json) in DeskBox on Windows 11. Automatically detects or installs DeskBox if missing.
---

# DeskBox Native Custom Widget Developer Guide (AI Agent Skill)

## 0. Environment Check & Auto-Bootstrap (When DeskBox or MCP Is Missing)

Before designing or modifying a widget, check whether the `deskbox` MCP tools (`deskbox_get_widget_spec`, `deskbox_validate_manifest`, `deskbox_upsert_widget`, etc.) are available in your current session:

1. **If `deskbox` MCP tools are already available**:
   - Call `deskbox_get_widget_spec` first to read the current runtime specification (the running DeskBox server is always the single source of truth).
2. **If `deskbox` MCP tools are NOT available**:
   - Run the bundled environment probe script to check whether DeskBox (`v1.6.0+`) is installed and running on this Windows PC:
     ```powershell
     powershell -NoProfile -ExecutionPolicy Bypass -File "<path-to-this-skill>/scripts/ensure-deskbox.ps1"
     ```
   - Inspect the JSON output from `ensure-deskbox.ps1`:
     - **`installed: false` (or `mcpSupported: false`)**:
       - Inform the user that DeskBox (`v1.6.0+`) is not installed on this computer yet, and ask for their confirmation to download and install the latest official release from `https://github.com/Tianyu199509/DeskBox/releases/latest` (or open the release/Store page).
       - Once the user confirms, run:
         ```powershell
         powershell -NoProfile -ExecutionPolicy Bypass -File "<path-to-this-skill>/scripts/ensure-deskbox.ps1" -Install -StartHost
         ```
         This downloads the architecture-matched installer (`DeskBox_Setup_<ver>_x64.exe` or `arm64.exe`), verifies its SHA-256 checksum against the official release metadata, installs DeskBox, launches the desktop host, and outputs the ready-to-use `mcpCommand` and `mcpArgs`.
     - **`installed: true`, `pipeOnline: false`**:
       - Start the DeskBox desktop host by running `ensure-deskbox.ps1 -StartHost`.
     - **Register MCP Server**:
       - Use the `mcpCommand` (`deskbox.exe` for Microsoft Store edition, or the full `DeskBox.exe` path for Direct edition) and `mcpArgs` (`["--mcp"]`) returned by `ensure-deskbox.ps1` to configure the `deskbox` MCP server in the current client using its official configuration mechanism (do not modify client trust stores directly).

### Core Workflow & Safety Contract

1. **Runtime Specification First**: Call `deskbox_get_widget_spec` before designing or changing a widget. Use `deskbox_get_capability_spec` for individual capabilities (or consult [`references/API_REFERENCE.md`](references/API_REFERENCE.md) and [`references/manifest.schema.json`](references/manifest.schema.json) when offline).
2. **Read & Validate**: Read the existing widget before changing it. Validate the manifest with `deskbox_validate_manifest`.
3. **Stage-by-Default (`deskbox_upsert_widget`)**: Calling `deskbox_upsert_widget` without `commit: true` validates the bundle, creates a pending stage, and returns a `stageId` **without changing the desktop**. Present the proposed result for user review.
4. **Explicit Confirmation & Idempotent Commit**: Only after the user confirms, call `deskbox_upsert_widget` with `commit: true`, the same `stageId`, and the exact staged `manifestJson`. Reusing a committed `stageId` with identical content is idempotent (`idempotent: true`) and will not write the desktop twice. Editing a file inside a Workshop draft workspace updates the preview only, not the desktop.
5. **Visual Preview & Live Telemetry**: Use `deskbox_capture_widget_preview` to inspect a live widget when appropriate. Use `deskbox_push_widget_data` only when the user asks for live state/event updates.

---

## 1. Architecture & Fluent 2 Design Rules
- **Zero WebView2 / Zero HTML**: Every node in `view` maps to native WinUI 3 controls (`StackPanel`, `Grid`, `Border`, `TextBlock`, `TextBox`, `Button`, `ToggleSwitch`, `ProgressRing`, `Polyline` sparkline, etc.) and inherits DeskBox's Windows 11 Mica/Acrylic backdrop, theme palette, and compact capsule animations.
- **Windows 11 Native Restraint & No Duplicate Header**: DeskBox's host window already provides a translucent glass surface and renders the top header bar (`icon`, `name`, collapse toggle, and context menu). **NEVER add a duplicate static widget-title header bar at the top of `view`**. Keep sibling sections visually consistent (`Card` with `tone`: `"subtle"` or `"default"`, max 2 nested `Card` levels), size `defaultSize.height` so all initial sections fit without vertical clipping (use `Tabs` when combining 3+ panels), and keep root `padding` compact (`"10,6,10,10"` or `"12,8,12,12"`) with `spacing` at `6`–`10`.
- **Dual-Surface Continuity & Emoji Identity**: Always set `"id"` to `"custom.<kebab-slug>"` (`deskbox.*` is reserved for official built-in presets), set top-level `"icon"` and `"capsule.glyph"` to a single expressive Unicode Emoji matching the widget's purpose (e.g., `"💧"`, `"📝"`, `"📊"`, `"🎯"`, `"🚀"`, `"🤖"`, `"📰"`, `"🔥"`), and define a `"capsule"` block (`title`, `summary`, `badge`, optional `badgeIsWarning`, `progress`, `enableBounceOnUpdate`, and 1-click `primaryAction`: `{ "icon": "\uE710", "tooltip": "...", "onClick": ... }`) so the collapsed desktop capsule displays live status and supports quick actions.
- **Copy Language Strategy**: For user-created widgets, write clean single-language plain strings matching the user's requested/input language (or active DeskBox UI language). Never place an inline `"i18n"` block inside `manifest.json`; when multi-language support is needed, store per-locale dictionaries in `locales/<culture>.json` (`{ "title": "...", "fmt": "{0} items" }`) alongside `locales/_meta.json`, and reference `${$i18n.title}`, parameterized `${t('fmt', state.count)}`, or `ctx.t('title')` inside `logic.js`.

## 2. Expression Syntax (`${...}`) & Declarative Data Sources (`sources`)
- `state.<key>`: Reads reactive state defined in `"state"`.
- `$settings.<key>`: Reads user-configurable preferences defined in `"settings"`.
- `$i18n.<key>` / `t('<key>', arg0, ...)`: Reads localized copy (and formats `{0}`, `{1}` positional arguments) from optional `locales/<culture>.json` dictionaries (live-switched with DeskBox UI language, falling back to `en-US` / `zh-CN`).
- `$computed.<key>`: Reads ephemeral in-memory scalar or JSON array values computed by optional `logic.js` (never written to `store.json`; array keys can also bind to `List.items`, `BarList.collection`, and `Sparkline.collection` as `"$computed.<listKey>"`).
- `collections.<name>.count` / `collections.<name>.todayCount` / `collections.<name>.latest.<field>`: Reads persistent collection aggregates.
- `$item.<field>` / `$index` (0-based) / `$rank` (1-based: `"1"`, `"2"`, `"3"`, ideal for rankings and leaderboards) / `$value` (selected option value inside `Segmented.onChange`): Inside a `List`'s `itemTemplate` or `hoverActions`, reads the current record (`id`, `timeText`, `dateText`, `isToday`, plus custom fields).
- `$drop.name` / `$drop.path` / `$drop.mode` / `$drop.text`: Inside `onDrop.action`, reads dropped file metadata (`$drop.text` safely extracts up to 8 KB of plain text when the user drops `.txt`, `.md`, `.csv`, `.json`, `.log`, `.yml`, `.xml`, `.ini`, or `.toml` files — ideal for drag-to-summarize micro-agent widgets).
- **Host Telemetry & Native Sources**:
  - `$weather.*` (`$weather.city`, `$weather.temp`, `$weather.tempText`, `$weather.condition`, `$weather.icon`, `$weather.rangeText`, `$weather.humidity`, `$weather.wind`, `$weather.uv`, `$weather.sunrise`, `$weather.sunset`) + 7-day `forecast` collection (`$item.dayLabel`, `$item.icon`, `$item.condition`, `$item.high`, `$item.low`, `$item.precipProb`) when `"sources": [{ "type": "weather", "city": "${$settings.city ?? ''}", "targetCollection": "forecast", "intervalMs": 1800000 }]` (zero API key required!).
  - `$calendar.*` (`$calendar.today`, `$calendar.monthTitle`, `$calendar.weekday`, `$calendar.lunar`, `$calendar.lunarTitle`, `$calendar.festival`, `$calendar.subtitle`, `$calendar.selectedDate`) when `"sources": [{ "type": "calendar", "intervalMs": 60000 }]`.
  - `$clock.*` (`$clock.fullTime`, `$clock.utcTime`, `$clock.localOffset`, `$clock.unixSeconds`, `$clock.iso`) + multi-timezone function `tz('<zoneId>', '<format>')` (e.g. `${tz('America/New_York', 'HH:mm')}`) when `"sources": [{ "type": "clock", "intervalMs": 1000 }]`.
  - `$device.*` (`$device.volume`, `$device.volumeText`, `$device.muted`, `$device.brightness`, `$device.brightnessText`, `$device.audioDeviceName`, `$device.wifiEnabled`, `$device.wifiStatus`, `$device.bluetoothEnabled`, `$device.bluetoothStatus`, `$device.keepAwake`, `$device.mediaPlaying`, `$device.mediaStatus`, `$device.mediaToggleIcon`, `$device.mediaCover`, `$device.mediaTitle`, `$device.mediaArtist`, `$device.mediaSummary`, `$device.recycleBinCount`, `$device.recycleBinStatus`) when `"sources": [{ "type": "deviceState", "intervalMs": 2000 }]`.
  - `$drives.*` (`$drives.count`, `$drives.summary`, `$drives.primaryPercent`) + `drives` collection (`$item.name`, `$item.title`, `$item.percent`, `$item.freeGb`, `$item.totalGb`, `$item.summary`) when `"sources": [{ "type": "storageDrives", "targetCollection": "drives", "intervalMs": 15000 }]`.
  - `$clipboard.*` (`$clipboard.text`, `$clipboard.preview`, `$clipboard.length`, `$clipboard.lines`, `$clipboard.kind`, `$clipboard.kindLabel`) when `"sources": [{ "type": "clipboard", "intervalMs": 2000 }]`.
  - `$sys.*` (`$sys.cpu.percent`, `$sys.cpu.history`, `$sys.memory.percent`, `$sys.memory.summaryText`, `$sys.memory.history`, `$sys.gpu.name`, `$sys.gpu.percent`, `$sys.gpu.history`, `$sys.gpu.vramSummary`, `$sys.gpu.vramPercent`, `$sys.disk.selectedName`, `$sys.disk.selectedPercent`, `$sys.disk.selectedFreeGb`, `$sys.net.downText`, `$sys.net.upText`, `$sys.uptime.text`, `$sys.battery.statusText`) when `"sources": [{ "type": "systemMetrics", "intervalMs": 2000 }]`.
  - `$pomodoro.*` when `"sources": [{ "type": "pomodoro", "intervalMs": 1000 }]`.
  - `$countdown.*` (supports solar + 1901-2100 Chinese lunar recurring birthdays/anniversaries via `"calendarType": "lunar"`, `"recurrence": "yearly"`; v3.0 adds payday weekend rules, count-up milestones, `${$countdown.work.percent}` work-hour progress and `${$countdown.holiday.days}` next-China-statutory-holiday countdown from the built-in 2025–2027 schedule) when `"sources": [{ "type": "countdown", "intervalMs": 60000 }]`.
  - `$ai.*` when `"sources": [{ "type": "aiMonitor", "intervalMs": 60000 }]`.
- **Encrypted Secret Vault (`"type": "secret"`) & Live Network Data Sources (`rss` & `httpJson`, HTTPS GET only, interval >= 300000 ms / 5 min)**:
  - Declare `{ "key": "apiKey", "type": "secret", "label": "API Key" }` in `"settings"` to store per-widget tokens in Windows DPAPI (`widget-secrets.json`, never saved to `store.json` or exported in `.dbbox`) and reference `${$secrets.apiKey}` inside `httpJson.headers` (e.g., `"headers": { "Authorization": "Bearer ${$secrets.apiKey}" }`). DeskBox automatically renders an inline setup banner when unconfigured!
  - **RSS 2.0 / Atom 1.0 (`"type": "rss"`)**: Ideal for news, blogs, GitHub releases, Hacker News, V2EX, SSPai (`https://sspai.com/feed`), IT之家 (`https://www.ithome.com/rss/`), etc.!
    Example: `{ "id": "feed", "type": "rss", "url": "https://www.ithome.com/rss/", "targetCollection": "articles", "intervalMs": 900000, "maxItems": 15 }`
    Automatically populates `targetCollection` items with `$item.title`, `$item.summary`, `$item.url`, `$item.publishedAt`, `$item.category`, `$item.author`, and updates `state.feedTitle`, `state.feedCount`, `state.topHeadline`, `state.sourceStatus` (`"idle"` | `"loading"` | `"ok"` | `"auth_required"` | `"error"`), `state.sourceError`, `state.sourceUpdatedAt` (`"HH:mm"`).
  - **Public or Authenticated JSON API (`"type": "httpJson"`)**: Supports `url`, optional `headers` (`${$secrets.*}`), `stateMap`, `targetCollection`, `itemsPath`, `fieldMap`, `maxItems`.
    Example: `{ "id": "api", "type": "httpJson", "url": "https://api.example.com/v1/list?sort=${state.tab}", "intervalMs": 300000, "stateMap": { "total": "data.total" }, "targetCollection": "rows", "itemsPath": "data.items", "fieldMap": { "title": "name", "pct": "changePct", "url": "html_url" }, "maxItems": 15 }`
- Operators supported inside `${...}`: `??` (fallback), `? :` (ternary), `||`, `&&`, `==`, `!=`, `>=`, `<=`, `>`, `<`, and numeric arithmetic `+`, `-`, `*`, `/`, `%` (e.g., `${$index + 1}`, `${$item.turnover / 100000000}`).

## 3. Component Catalog (`view.type`)
- **Layout**:
  - `Stack`: `orientation` (`vertical` | `horizontal`), `spacing`, `padding`, `children`.
  - `Wrap`: Flow wrap panel for pill tags or quick action chips (`spacing`, `padding`, `children`).
  - `Spacer`: Flexible layout spacer (`height` or stretches inside horizontal `Grid`/`Stack`).
  - `ModuleStack`: User-reorderable modular stack bound to a `"type": "moduleList"` setting (`bind`: `"settings.modules"`).
  - `Grid`: `columns` (e.g. `"1*,Auto"`, `"1*,1*"`), `rows`, `spacing`, `children` (with `column`, `row`; multi-item grids auto-flow into implicit rows when `rows`/`row` are omitted).
  - `Tabs`: Multi-page segmented container (`bind`: `"state.activeTab"`, `children` where each tab item specifies `title`, `value`, optional `icon`, and `children`).
  - `Card`: Borderless glass micro-surface with `tone` (`default` | `subtle` | `accent` | `success` | `warning` | `danger`, supports `${...}` expressions), `padding`, optional `onClick` (interactive row/card click with hover highlight), `children`.
  - `Expander`: Native progressive-disclosure collapsible section with `title`, optional `subtitle`, `defaultExpanded` (`true`|`false`), optional `bind` (`"state.expanded"`), `tone`, and `children`.
  - `Scroll`: Vertical scroll container around `children`.
  - `List`: Persistent collection view specified by `items` (collection name), optional `filter` expression, `emptyState` (`icon`, `title`, `subtitle`), `itemTemplate`, and `hoverActions`.
- **Controls**:
  - `Text`: `text`, `style` (`caption` | `body` | `bodyStrong` | `subtitle` | `title` | `hero` | `mono`), `color` (`default` | `secondary` | `muted` | `accent` | `violet` | `emerald` | `cyan` | `success` | `warning` | `danger` | `#RRGGBB`, supports `${...}` expressions!), `maxLines`.
  - `Input`: `placeholder`, `bind` (`"state.draftText"`), `onSubmit` (actions triggered on Enter).
  - `TextArea`: Multi-line native text input with `placeholder`, `bind`, `minHeight`, `maxHeight`, and `onSubmit` (triggered on `Ctrl+Enter`).
  - `Button`: `icon` (Segoe Fluent Icons char/hex or Emoji), `text`, `variant` (`standard` | `accent` | `subtle` | `ghost` | `danger`), `tooltip`, `onClick`.
  - `IconButton`: Compact 24px/28px square icon action button (`icon`, `size`, `variant`: `subtle`|`accent`|`danger`, `tooltip`, `onClick`) ideal for inline bars and `hoverActions`.
  - `Toggle`: Native Windows 11 `ToggleSwitch` with `title` (label), `bind` (`"state.flagKey"`), and optional `onClick` follow-up actions.
  - `CheckBox`: Compact native `CheckBox` row with `bind` or `value`, `text`, `strikethrough` (`true`|`false`), and `onToggle` / `onChange`.
  - `Select`: Native `ComboBox` dropdown selector with optional `title`, `bind` (`"state.category"`), `options` (`[{ "value": "...", "label": "..." }]`), and optional `onChange`.
  - `Slider`: Native horizontal `Slider` with optional `title`, `bind` OR live two-way `value` expression (e.g. `"${$device.volume}"`), `min`, `max`, `step`, `unit` (e.g. `"m"`, `"%"`), and optional `onChange` (`${$value}` = live slider value; never add a redundant submit button next to `Slider`).
  - `Image`: Rounded local/SMTC/HTTPS image view (`src`, `width`, `height`, `stretch`: `uniform`|`uniformToFill`|`fill`, `cornerRadius`).
  - `RingGauge`: Circular KPI gauge with centered metric (`progress`/`value`, `max`, `title`, `subtitle`, `unit`, `size`, `color`).
  - `BarList`: Ranked horizontal proportion bar list bound to `collection` (`titleField`, `valueField`, `subtitleField`, `unit`, `maxItems`, `color`).
  - `NumberBox`: Native `NumberBox` with inline spin buttons, optional `title`, `bind`, `min`, `max`, `step`, and optional `onChange`.
  - `ProgressRing`: Native Windows 11 `ProgressRing` (`size`, `value` 0–100, `indeterminate` boolean expression).
  - `Segmented`: Pill segmented selector bound to `bind` (`"state.activeTag"`), `options` (`[{ "value": "...", "label": "..." }]`), optional `onChange` actions (`$value` = newly selected option).
  - `Badge`: Semantic pill tag with `text` and `tone` (`accent` | `subtle` | `muted` | `emerald` | `violet` | `cyan` | `success` | `warning` | `danger`, supports `${...}` expressions!).
- **High-Craft Semantic, Composite & Micro-Chart Blocks**:
  - `CalendarGrid`: Interactive 7x6 native monthly calendar with month switching, lunar/festival subtitles, `bind` (`"state.selectedDate"`), and event dots from `collection` (`dateField` default `"date"`).
  - `DropZone`: Native visual drag-and-drop + click-to-browse zone (`icon`, `title`, `subtitle`, `format` e.g. `".png,.jpg,.webp"`, `onDrop` actions).
  - `ControlTile`: Windows 11 Quick Settings toggle tile (`icon`, `title`, `subtitle`, `bind` or `value` active boolean expression, `onClick` actions).
  - `Sparkline`: Vector trend chart with soft area fill (`collection` + `valueField` OR `sparkline` comma-separated series, `title`, `unit`, `height`, `color`, `showArea`, `showLatest`).
  - `HeatmapGrid`: GitHub-style daily habit/activity intensity grid (`collection`, `valueField`, optional `dateField`, `days`, `size`, `color`, `title`).
  - `StatCard`: Metric card with `title`, `value`, `subtitle`, `progress`, `sparkline` (`"$sys.cpu.history"` / `"$sys.memory.history"` / `"$sys.gpu.history"`), `color`, `warningThreshold`, `dangerThreshold`.
  - `GpuCard`, `ProcessList`, `PomodoroCard`, `CountdownHero`, `CountdownList`, `TimeProgressCard`, `AiFocusCard`, `AiRadarList`, `AiTokensCard`, `AiTrendCard`.
  - `ProgressRow`: Labeled progress bar row with `title`, `subtitle`, `value`, `progress`, `warningThreshold`, `dangerThreshold`.
  - `KeyValueRow`: Compact metric/info row with `icon`, `title`, `value`.
  - `FileChip`: Interactive file attachment pill (`fileName`, `filePath`, `storageMode`).

## 4. Declarative Actions
- `state.set`: `{ "type": "state.set", "key": "draftText", "value": "" }`
- `state.toggle`: `{ "type": "state.toggle", "key": "flagKey" }`
- `state.increment`: `{ "type": "state.increment", "key": "counterKey", "value": "1" }`
- `collection.prepend` / `collection.append`: `{ "type": "collection.prepend", "collection": "logs", "guard": "${state.draftText != ''}", "item": { "text": "${state.draftText}" } }`
- `collection.update`: `{ "type": "collection.update", "collection": "tasks", "targetId": "${$item.id}", "item": { "done": "${$item.done == 'true' ? 'false' : 'true'}" } }`
- `collection.remove`: `{ "type": "collection.remove", "collection": "logs", "targetId": "${$item.id}" }`
- `collection.clear`: `{ "type": "collection.clear", "collection": "logs" }`
- `collection.exportMarkdown`: `{ "type": "collection.exportMarkdown", "collection": "logs" }`
- `file.transform`: Zero-dependency native local converter (`png` | `jpg` | `webp` | `bmp` | `ico` | `csvToJson` | `jsonToCsv` | `jsonPretty` | `jsonMinify` | `mdToHtml` | `mdToTxt` | `base64Encode` | `base64Decode` | `sha256` | `md5`), populating `$transform.outputPath`, `$transform.outputName`, `$transform.sizeText`, `$transform.resultText`, `state.transformStatus`, `state.transformOutput`.
- `text.transform`: Pure in-memory text processor (`format`: `jsonPretty` | `jsonMinify` | `urlEncode` | `urlDecode` | `base64Encode` | `base64Decode` | `timestampToDate` | `dateToTimestamp` | `uuid` | `upper` | `lower` | `trim` | `wordCount` | `sha256` | `md5`, `text`, output `key`, optional `mode`: `"copy"`).
- `launcher.open`: Safe workflow & protocol launcher (`targetId`/`path`/`url`: standard folders `downloads`|`desktop`|`documents`|`pictures`, whitelisted URIs `vscode://`, `obsidian://`, `ms-screenclip:`, `ms-calculator:`, `https://`, or existing local path).
- `file.pick`: Opens native file picker (`format`: `".png,.jpg"`) and chains `then` with `$drop.*` populated.
- `file.open` / `file.reveal`: `{ "type": "file.open", "path": "${$item.filePath}" }`
- `system.control`: Executes safe Windows control (`targetId`/`key`: `volume.set` | `volume.step` | `volume.muteToggle` | `brightness.set` | `brightness.step` | `audio.output` | `media.playPause` | `media.next` | `media.previous` | `power.keepAwakeToggle` | `power.lock` | `recycleBin.empty` | `radio.wifiToggle` | `radio.bluetoothToggle`, optional `value` supporting `${$value}`).
- `system.openSetting`: Opens `ms-settings:` URI (`key` or `url`, e.g. `"ms-settings:network-wifi"`).
- `reminder.notify` / `toast.show`: Sends Windows 11 system Toast notification (`title`, `message`) + widget banner.
- `url.open`: `{ "type": "url.open", "url": "${$item.url}" }` (opens `https://` link in user's browser)
- `source.refresh`: `{ "type": "source.refresh", "targetId": "feed" }` (triggers immediate manual refresh of `rss` / `httpJson` / `weather` / `deviceState` sources)
- `ai.run`: Runs a fast non-thinking structured AI micro-task inside the widget using DeskBox's global AI provider and maps the JSON output into `state` and/or `collections`:
  `{ "type": "ai.run", "guard": "${state.draft != ''}", "prompt": "Summarize and extract actionable tasks:\n${state.draft}", "stateMap": { "summary": "summary" }, "collection": "items", "mode": "prepend", "itemsPath": "items", "fieldMap": { "title": "title", "tag": "tag", "done": "done" }, "maxItems": 6, "then": { "type": "state.set", "key": "draft", "value": "" } }`
  Automatically updates `state.aiStatus` (`"idle"` | `"running"` | `"error"`), `state.aiError`, and `state.aiUpdatedAt` (`"HH:mm"`). On failure or missing API key, `then` is skipped so user input in `state.draft` is preserved.
- `clipboard.copy`: `{ "type": "clipboard.copy", "text": "..." }`
- `script.run`: `{ "type": "script.run", "fn": "step", "arg": "1" }` — invokes exported synchronous ES2023 function `step(ctx, arg)` in sidecar `logic.js` within DeskBox's offline QuickJS sandbox (no network/DOM/filesystem, <= 50ms CPU, <= 4MB RAM). When `logic.js` is used, declare `"script": { "entry": "logic.js", "tickIntervalMs": 0 }` in `manifest.json` and export `onInit(ctx)` (required cold-start projection for `$computed.*`), plus optional `onSourceData(ctx, sourceId, rawText)` and visibility-aware `onTick(ctx, nowUnixMs)`.
- `pomodoro.*`, `countdown.*`, `ai.*` built-in domain actions.

## 5. Agent MCP Tools, CLI & Bundled Reference Files
- **MCP Tools (`DeskBox.exe --mcp`)**:
  - `deskbox_get_widget_spec`: Read the live runtime specification, Tier-0 capability directory, and optional JSON Schema.
  - `deskbox_get_capability_spec`: Search or inspect atomic capability modules with exact tokens and Golden JSON snippets.
  - `deskbox_list_widgets`: List all widgets, or pass `{ "widgetId": "<id>" }` to inspect one widget's live `state`, `displayMode`, `collectionCounts`, and `sampleItems`.
  - `deskbox_validate_manifest`: Validate `manifest.json` + optional `logicJs` + optional `locales` map.
  - `deskbox_upsert_widget`: Validate and STAGE a desktop widget (`manifestJson`; optional `logicJs`, `locales`, and `resizeToDefault`). Returns a `stageId` without changing the desktop. Only after user confirmation, call again with `commit: true`, the same `stageId`, and the exact same `manifestJson` to write it to the desktop (re-committing the same `stageId` is idempotent).
  - `deskbox_capture_widget_preview`: Capture a real native WinUI 3 PNG screenshot (`mode`: `"expanded"` | `"capsule"` | `"live"`).
  - `deskbox_push_widget_data`: Push live state/collection updates (e.g., Ambient Agent HUD).
- **Bundled Reference Files in This Skill**:
  - [`scripts/ensure-deskbox.ps1`](scripts/ensure-deskbox.ps1) — Detects DeskBox installation/running status, outputs MCP command JSON, and supports `-Install -StartHost` (with SHA-256 verification) after user confirmation.
  - [`references/API_REFERENCE.md`](references/API_REFERENCE.md) — Complete Single-Source-of-Truth API Reference for all atomic capabilities and Golden JSON snippets.
  - [`references/manifest.schema.json`](references/manifest.schema.json) — Draft 2020-12 JSON Schema for DeskBox Custom Widget `manifest.json`.
