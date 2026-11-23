---
name: deskbox-widget
description: Design, create, visually verify, stage-and-commit, and push live telemetry to native WinUI 3 Custom Widgets (manifest.json) in DeskBox on Windows 10 (2004+) & Windows 11. Automatically detects or installs DeskBox if missing.
---

# DeskBox Native Custom Widget Developer Guide (AI Agent Skill)

## 0. Environment Check & Auto-Bootstrap (When DeskBox or MCP Is Missing)

Before designing or modifying a widget, check whether the `deskbox` MCP tools (`deskbox_get_widget_spec`, `deskbox_validate_manifest`, `deskbox_upsert_widget`, etc.) are available in your current session:

1. **If `deskbox` MCP tools are already available**:
   - Call `deskbox_get_widget_spec` (`detail: "compact"`) first to read the current runtime specification (the running DeskBox server is always the single source of truth).
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

1. **Runtime Specification & Studio Context First**: Call `deskbox_get_widget_spec` (pass `detail: "compact"` for a ~3 KB token-lean index, or `detail: "full"` for the complete guide) before designing or changing a widget. Call `deskbox_get_studio_context` when collaborating with an open Widget Workshop session to inspect the active draft and selected node path. Use `deskbox_get_capability_spec` for any of the 12 Domain Capability Packs or 37 atomic capabilities (or consult [`references/API_REFERENCE.md`](references/API_REFERENCE.md) and [`references/manifest.schema.json`](references/manifest.schema.json) when offline).
2. **Read & Validate**: Read the existing widget before changing it. Validate the manifest (+ optional `logicJs` and `locales`) with `deskbox_validate_manifest`.
3. **Stage-by-Default (`deskbox_upsert_widget`, annotated `destructiveHint: true`)**: Calling `deskbox_upsert_widget` without `commit: true` validates the bundle, creates a pending stage (and refreshes the open Workshop preview if focused), and returns a `stageId` **without changing the desktop**. Prefer incremental operations (`upsertElements`, `removeElements`, `patchRoot`, `removeRootKeys`, `scriptHunks`) when editing an existing widget. You can inspect a staged bundle visually BEFORE committing via `deskbox_capture_widget_preview` with `{ "stageId": "<stageId>" }`. Present the proposed result for user review.
4. **Explicit Confirmation, Native Host Approval & Idempotent Commit**: Only after the user confirms, call `deskbox_upsert_widget` with `{ "commit": true, "stageId": "<stageId>" }` (`manifestJson` may be omitted on `stageId`-only commits; inline manifest edits `upsertElements`/`removeElements`/`patchRoot`/`removeRootKeys` and `scriptHunks` are rejected on `commit: true` — stage a fresh preview first). Commits that overwrite an existing widget, clear existing data, or declare scripts / privileged capabilities trigger DeskBox's **native host approval dialog** (initial focus on Deny, 60-second auto-deny timeout). If declined or timed out, the tool returns `{ "committed": false, "staged": true, "requiresHostApproval": true, "stageId": "..." }` and preserves the staged bundle — **never auto-retry without a fresh user request**. Concurrent replays while a commit is in flight return `CommitInProgress` (three-state lease); reusing a completed `stageId` is idempotent (`idempotent: true`). External overwrites that change the executable surface automatically revoke positive privileged overrides (`CommandExecution` is never implicitly granted). Editing a file inside a Workshop draft workspace refreshes the preview only; never assume a file save is a desktop commit.
5. **Visual Preview & Live Telemetry**: Use `deskbox_capture_widget_preview` (`widgetId` or pending `stageId`, `mode`: `"expanded"` | `"capsule"` | `"live"`, optional `theme`: `"dark"` | `"light"`) to inspect a live or staged widget when appropriate. Use `deskbox_push_widget_data` only when the user asks for live state/event updates.

---

## 1. Architecture, Canonical Flat Element Graph & Fluent 2 Design Rules

DeskBox Custom Widgets render **100% native WinUI 3 Fluent 2 controls** from a single declarative `manifest.json` file located at:
- Direct install: `%LOCALAPPDATA%\DeskBox\data\custom-widgets\<widgetId>\manifest.json`
- Microsoft Store install: `%USERPROFILE%\DeskBox\.appdata\data\custom-widgets\<widgetId>\manifest.json`
(with optional sidecar `logic.js` for isolated QuickJS ES2023 pure computation and optional `locales/<culture>.json` + `locales/_meta.json` directory for multi-locale copy).

- **Canonical `"schemaVersion": 1` Flat Element Graph**: Every widget declares `"schemaVersion": 1`, `"root": "<rootElemId>"` (e.g. `"main"`), and a flat `"elements": { "<elemId>": { "type": "...", ... } }` dictionary. Containers store child element IDs as string arrays (`"children": ["header_row", "body_list"]`), and composite references (`itemTemplate`, `pane`, `actionButton`, `hoverActions[*]`, `popovers.<id>.root`) point to element IDs in `"elements"`.
- **Zero WebView2 / Zero HTML**: Every element in `elements` maps to native WinUI 3 controls (`StackPanel`, `Grid`, `Border`, `TextBlock`, `TextBox`, `Button`, `ToggleSwitch`, `ProgressRing`, `Polyline` sparkline, `Canvas`, etc.) and inherits DeskBox's Windows 11 Mica/Acrylic backdrop, theme palette, and compact capsule animations.
- **Windows 11 Native Restraint & No Duplicate Header**: DeskBox's host window already provides a translucent glass surface and renders the top header bar (`icon`, `name`, collapse toggle, and context menu). **NEVER add a duplicate static widget-title header bar at the top of the root element (`elements[root]`)**. Keep sibling sections visually consistent (`Card` with `tone`: `"subtle"` or `"default"`, max 2 nested `Card` levels), size `defaultSize.height` so all initial sections fit without vertical clipping (use `Tabs` or `popovers` when combining 3+ panels), and keep root `padding` balanced (`"10"` or `"12"`) with `spacing` at `6`–`10`.
- **Dual-Surface Continuity, Emoji & Semantic Icons**: Always set `"id"` to `"custom.<kebab-slug>"` (`deskbox.*` is reserved for official built-in presets), set top-level `"icon"` and `"capsule.glyph"` to a single expressive Unicode Emoji matching the widget's purpose (e.g., `"💧"`, `"📝"`, `"📊"`, `"🎯"`, `"🚀"`, `"🤖"`, `"📰"`, `"🔥"`), and on UI buttons/icons use semantic icon names (`add`, `edit`, `delete`, `export`, `folder`, `play`, `pause`, `stop`, `refresh`, `save`, `copy`, `search`, `filter`, `check`, `close`, `settings`, `download`, `upload`, `volume`, `mute`, `pin`, `sparkles`, `calendar`, `clock`, `bell`, `external-link`, `more`) rather than raw PUA hex codes. Define a `"capsule"` block (`title`, `summary`, `badge`, optional `badgeIsWarning`, `progress`, `enableBounceOnUpdate`, and 1-click `primaryAction`: `{ "icon": "add", "tooltip": "...", "onClick": ... }`) so the collapsed desktop capsule displays live status and supports quick actions.
- **12 Domain Capability Packs**: Query `deskbox_get_capability_spec` by Domain Pack ID (`layout-and-overlays`, `lists-and-collections`, `forms-and-inputs`, `charts-and-canvas`, `calendar-and-time`, `local-files-and-cli`, `network-and-feeds`, `system-and-device`, `media-and-audio`, `productivity-and-workspace`, `script-sandbox`, `settings-and-secrets`) or any of the 37 atomic capability slugs for exact tokens, schemas, and Golden JSON snippets.
- **Copy Language Strategy**: For user-created widgets, write clean single-language plain strings matching the user's requested/input language (or active DeskBox UI language). Never place an inline `"i18n"` block inside `manifest.json`; when multi-language support is needed, store per-locale dictionaries in `locales/<culture>.json` (`{ "title": "...", "fmt": "{0} items" }`) alongside `locales/_meta.json`, and reference `${$i18n.title}`, parameterized `${t('fmt', state.count)}`, or `ctx.t('title')` inside `logic.js`.

---

## 2. Expression Syntax (`${...}`) & Declarative Data Sources (`sources`)

- `state.<key>`: Reads reactive state defined in `"state"`.
- `$settings.<key>`: Reads user-configurable preferences defined in `"settings"`.
- `$i18n.<key>` / `t('<key>', arg0, ...)`: Reads localized copy (and formats `{0}`, `{1}` positional arguments) from optional `locales/<culture>.json` dictionaries (live-switched with DeskBox UI language, falling back to `en-US` / `zh-CN`).
- `$computed.<key>`: Reads ephemeral in-memory scalar or JSON array values computed by optional `logic.js` (never written to `store.json`; array keys can also bind to `List.items`, `BarList.collection`, and `Sparkline.collection` as `"$computed.<listKey>"`).
- `collections.<name>.count` / `collections.<name>.todayCount` / `collections.<name>.latest.<field>`: Reads persistent collection aggregates (initial records may also be declared in `collections.<name>.seedItems`).
- `$item.<field>` / `$index` (0-based) / `$rank` (1-based: `"1"`, `"2"`, `"3"`, ideal for rankings and leaderboards) / `$value` (selected option value inside `Segmented.onChange`): Inside a `List`'s `itemTemplate` or `hoverActions`, reads the current record (`id`, `timeText`, `dateText`, `isToday`, plus custom fields).
- `$drop.name` / `$drop.path` / `$drop.mode` / `$drop.text`: Inside `onDrop.action`, reads dropped file metadata (`$drop.text` safely extracts up to 8 KB of plain text when the user drops `.txt`, `.md`, `.csv`, `.json`, `.log`, `.yml`, `.xml`, `.ini`, or `.toml` files — ideal for drag-to-summarize micro-agent widgets).
- **Host Telemetry & Native Sources**:
  - `$weather.*` (`$weather.city`, `$weather.temp`, `$weather.tempText`, `$weather.condition`, `$weather.icon`, `$weather.rangeText`, `$weather.humidity`, `$weather.wind`, `$weather.uv`, `$weather.sunrise`, `$weather.sunset`) + 7-day `forecast` collection (`$item.dayLabel`, `$item.icon`, `$item.condition`, `$item.high`, `$item.low`, `$item.precipProb`) when `"sources": [{ "type": "weather", "city": "${$settings.city ?? ''}", "targetCollection": "forecast", "intervalMs": 1800000 }]` (zero API key required!).
  - `$calendar.*` (`$calendar.today`, `$calendar.monthTitle`, `$calendar.weekday`, `$calendar.lunar`, `$calendar.lunarTitle`, `$calendar.festival`, `$calendar.subtitle`, `$calendar.selectedDate`) when `"sources": [{ "type": "calendar", "intervalMs": 60000 }]`.
  - `$clock.*` (`$clock.fullTime`, `$clock.utcTime`, `$clock.localOffset`, `$clock.unixSeconds`, `$clock.iso`) + multi-timezone function `tz('<zoneId>', '<format>')` (e.g. `${tz('America/New_York', 'HH:mm')}`) when `"sources": [{ "type": "clock", "intervalMs": 1000 }]`.
  - `$device.*` (`$device.volume`, `$device.volumeText`, `$device.muted`, `$device.brightness`, `$device.brightnessText`, `$device.audioDeviceName`, `$device.wifiEnabled`, `$device.wifiStatus`, `$device.bluetoothEnabled`, `$device.bluetoothStatus`, `$device.keepAwake`, `$device.mediaPlaying`, `$device.mediaStatus`, `$device.mediaToggleIcon`, `$device.mediaCover`, `$device.mediaTitle`, `$device.mediaArtist`, `$device.mediaSummary`, `$device.recycleBinCount`, `$device.recycleBinStatus`) when `"sources": [{ "type": "deviceState", "intervalMs": 2000 }]`.
  - `$drives.*` (`$drives.count`, `$drives.summary`, `$drives.primaryPercent`) + `drives` collection (`$item.name`, `$item.title`, `$item.percent`, `$item.freeGb`, `$item.totalGb`, `$item.summary`) when `"sources": [{ "type": "storageDrives", "targetCollection": "drives", "intervalMs": 15000 }]`.
  - `$clipboard.*` (`$clipboard.text`, `$clipboard.preview`, `$clipboard.length`, `$clipboard.lines`, `$clipboard.kind`, `$clipboard.kindLabel`) when `"sources": [{ "type": "clipboard", "intervalMs": 2000 }]`.
  - `$music.*` (`$music.hasSession`, `$music.isPlaying`, `$music.status` `playing`|`paused`|`idle`, `$music.title`, `$music.artist`, `$music.album`, `$music.sourceApp`, `$music.coverPath`, `$music.positionText`, `$music.durationText`, `$music.positionSeconds`, `$music.durationSeconds`, `$music.progressPercent`; plus `ctx.env.music` in `logic.js`) when `"sources": [{ "type": "music", "intervalMs": 1000 }]`.
  - `$todo.*` (`$todo.pendingCount`, `$todo.completedCount`, `$todo.totalCount`, `$todo.todayPendingCount`, `$todo.todayCompletedCount`, `$todo.overdueCount`, `$todo.importantPendingCount`, `$todo.completionPercent`, `$todo.nextTaskTitle`, `$todo.nextTaskDueText`, `$todo.summary`; plus privacy-safe rows in `collections.todos` with `$item.title`, `$item.done`, `$item.important`, `$item.dueDate`, `$item.priority`, `$item.listName`, `$item.isOverdue` and `ctx.env.todo` in `logic.js`) when `"sources": [{ "type": "todo", "targetCollection": "todos", "maxItems": 12, "intervalMs": 30000 }]`.
  - `$sys.*` (`$sys.cpu.percent`, `$sys.cpu.history`, `$sys.memory.percent`, `$sys.memory.summaryText`, `$sys.memory.history`, `$sys.gpu.name`, `$sys.gpu.percent`, `$sys.gpu.history`, `$sys.gpu.vramSummary`, `$sys.gpu.vramPercent`, `$sys.disk.selectedName`, `$sys.disk.selectedPercent`, `$sys.disk.selectedFreeGb`, `$sys.net.downText`, `$sys.net.upText`, `$sys.uptime.text`, `$sys.battery.statusText`) when `"sources": [{ "type": "systemMetrics", "intervalMs": 2000 }]`.
  - `$pomodoro.*` when `"sources": [{ "type": "pomodoro", "intervalMs": 1000 }]`.
  - `$countdown.*` (supports solar + 1901–2100 Chinese lunar recurring birthdays/anniversaries via `"calendarType": "lunar"`, `"recurrence": "yearly"`, payday weekend rules, count-up milestones, `${$countdown.work.percent}` work-hour progress, and `${$countdown.holiday.days}` next China statutory holiday countdown) when `"sources": [{ "type": "countdown", "intervalMs": 60000 }]`.
  - `$ai.*` when `"sources": [{ "type": "aiMonitor", "intervalMs": 60000 }]`.
- **Encrypted Secret Vault (`"type": "secret"`), Per-Widget Permissions, Network (`rss`, `httpJson`, `http.request`, interval >= 15000 ms), Local File (`fileText`, `file.writeText`), & Command (`command`, `command.run`, Direct build only)**:
  - Declare `{ "key": "apiKey", "type": "secret", "label": "API Key" }` in `"settings"` to store per-widget tokens in Windows DPAPI (`widget-secrets.json`, never saved to `store.json` or exported in `.dbxwidget`) and reference `${$secrets.apiKey}` inside `httpJson.headers` (e.g., `"headers": { "Authorization": "Bearer ${$secrets.apiKey}" }`). DeskBox automatically renders an inline setup banner when unconfigured!
  - **RSS 2.0 / Atom 1.0 (`"type": "rss"`)**: Ideal for news, blogs, GitHub releases, Hacker News (`https://hnrss.org/frontpage`), SSPai (`https://sspai.com/feed`), IT之家 (`https://www.ithome.com/rss/`), GCores (`https://www.gcores.com/rss`), etc.
    Example: `{ "id": "feed", "type": "rss", "url": "https://www.ithome.com/rss/", "targetCollection": "articles", "intervalMs": 900000, "maxItems": 15 }`
    Automatically populates `targetCollection` items with `$item.title`, `$item.summary`, `$item.url`, `$item.publishedAt`, `$item.category`, `$item.author`, and updates `state.feedTitle`, `state.feedCount`, `state.topHeadline`, `state.sourceStatus` (`"idle"` | `"loading"` | `"ok"` | `"auth_required"` | `"error"`), `state.sourceError`, `state.sourceUpdatedAt` (`"HH:mm"`).
  - **Public or Authenticated JSON API (`"type": "httpJson"`)**: Supports `url`, optional `headers` (`${$secrets.*}`), `stateMap`, `targetCollection`, `itemsPath`, `fieldMap`, `maxItems` (call `deskbox_get_capability_spec` with `http-and-rss-feeds` for verified zero-key V2EX, Zhihu, Hacker News Algolia, Open-Meteo, FX, and CoinGecko endpoints).
    Example: `{ "id": "api", "type": "httpJson", "url": "https://api.example.com/v1/list?sort=${state.tab}", "intervalMs": 300000, "stateMap": { "total": "data.total" }, "targetCollection": "rows", "itemsPath": "data.items", "fieldMap": { "title": "name", "pct": "changePct", "url": "html_url" }, "maxItems": 15 }`
- Operators supported inside `${...}`: `??` (fallback), `? :` (ternary), `||`, `&&`, `==`, `!=`, `>=`, `<=`, `>`, `<`, and numeric arithmetic `+`, `-`, `*`, `/`, `%` (e.g., `${$index + 1}`, `${$item.turnover / 100000000}`).

---

## 3. Component Catalog (`elements.<id>.type`)

- **Layout** (containers reference child element IDs via `"children": ["id1", "id2"]`, and `itemTemplate` / `pane` / `actionButton` / `hoverActions` reference element IDs in `"elements"`):
  - `Stack`: `orientation` (`vertical` | `horizontal`), `spacing`, `padding`, `children` (element ID array).
  - `Wrap`: Flow wrap panel for pill tags or quick action chips (`spacing`, `padding`, `children`).
  - `Spacer`: Flexible layout spacer (`height` or stretches inside horizontal `Grid`/`Stack`).
  - `ModuleStack`: User-reorderable modular stack bound to a `"type": "moduleList"` setting (`bind`: `"settings.modules"`, child elements declare optional `"compactPair": true` to pair two consecutive narrow cards side-by-side in 2 columns).
  - `Grid`: `columns` (track list like `"1*,Auto"`, `"1*,1*"`, track count like `"5"` -> 5 equal `*` cols, or dynamic `${...}` expression), `rows`, `spacing`, `children` (each child element sets `column`, `row`, `columnSpan`, `rowSpan`; multi-item grids auto-flow into implicit rows when `rows`/`row` are omitted; children whose explicit `column >= columns` are automatically collapsed).
  - `Tabs`: Multi-page segmented container (`bind`: `"state.activeTab"`, `children` element IDs where each tab element specifies `title`, `value`, optional `icon`, and `children`).
  - `Card`: Borderless glass micro-surface with `tone` (`default` | `subtle` | `accent` | `success` | `warning` | `danger`, supports `${...}` expressions), `padding`, optional `onClick` (interactive row/card click with hover highlight), `children`.
  - `Expander`: Native progressive-disclosure collapsible section with `title`, optional `subtitle`, `defaultExpanded` (`true`|`false`), optional `bind` (`"state.expanded"`), `tone`, and `children`.
  - `Scroll`: Vertical scroll container around `children`.
  - `List`: Persistent collection view specified by `items` (collection name), optional `filter` expression, `emptyState` (`icon`, `title`, `subtitle`), `itemTemplate` (element ID string), and `hoverActions` (element ID string array).
- **Controls**:
  - `Text`: `text`, `style` (`caption` | `body` | `bodyStrong` | `subtitle` | `title` | `hero` | `mono`), `color` (`default` | `secondary` | `muted` | `accent` | `violet` | `emerald` | `cyan` | `success` | `warning` | `danger` | `#RRGGBB`, supports `${...}` expressions!), `maxLines`. `style: "hero"` gets an automatic 150ms opacity change-highlight pulse when its text changes; set `animateChange: true` for the same pulse on any other `Text` style.
  - `Input`: `placeholder`, `bind` (`"state.draftText"`), `onSubmit` (actions triggered on Enter).
  - `TextArea`: Multi-line native text input with `placeholder`, `bind`, `minHeight`, `maxHeight`, and `onSubmit` (triggered on `Ctrl+Enter`).
  - `Button`: `icon` (semantic icon name like `"add"`, `"edit"`, `"delete"`, `"export"`, `"folder"`, `"play"`, `"pause"`, `"refresh"`, or Emoji), `text`, `variant` (`standard` | `accent` | `subtle` | `ghost` | `danger`), `tooltip`, `onClick`.
  - `IconButton`: Compact 24px/28px square icon action button (`icon` semantic name or Emoji, `size`, `variant`: `subtle`|`accent`|`danger`, `tooltip`, `onClick`) ideal for inline bars and `hoverActions`.
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
  - `DropZone`: Native visual drag-and-drop + click-to-browse zone (`icon`, `title`, `subtitle`, `accept` `"files" | "text" | "items" | "any"` or file extensions `".png,.jpg,.webp"` (alias `format`), `onDrop` actions; receives DeskBox Todo/QuickCapture drags, text/URLs, and files via `ctx.event = { kind, text, items, files }` or `${$event.kind}`, `${$event.title}`, `${$event.text}`).
  - `ControlTile`: Windows 11 Quick Settings toggle tile (`icon`, `title`, `subtitle`, `bind` or `value` active boolean expression, `onClick` actions).
  - `Sparkline`: Vector trend chart with soft area fill (`collection` + `valueField` OR `sparkline` comma-separated series, `title`, `unit`, `height`, `color`, `showArea`, `showLatest`).
  - `HeatmapGrid`: GitHub-style daily habit/activity intensity grid (`collection`, `valueField`, optional `dateField`, `days`, `size`, `color`, `title`).
  - `StatCard`: Metric card with `title`, `value`, `subtitle`, `progress`, `sparkline` (`"$sys.cpu.history"` / `"$sys.memory.history"` / `"$sys.gpu.history"`), `color`, `warningThreshold`, `dangerThreshold`.
  - `ZStack`, `ItemsGrid`, `SelectorBar`, `FlipView`, `SplitView`: Overlay z-stack, responsive uniform grid repeater, Fluent selector bar, swipe carousel, and collapsible pane split view.
  - `SplitButton`, `DropDownButton`, & universal right-click menus: Primary + flyout menu button and dropdown menu button use `menuItems` for their own flyout; on any other node `contextMenu` (alias `menuItems`) attaches a native right-click `MenuFlyout`, and `contextMenu` wins when both are present.
  - `InfoBadge`, `InfoBar`, `TeachingTip`, `RichText`, `CodeBlock`, `RadialGauge`, `MediaPlayer`: Notification badge, inline alert bar, anchored callout (`tip.open|close|toggle`), multi-span rich text, copyable code block, arc gauge, and native WinRT video/audio player.
  - `ProgressRow`: Labeled progress bar row with `title`, `subtitle`, `value`, `progress`, `warningThreshold`, `dangerThreshold`.
  - `KeyValueRow`: Compact metric/info row with `icon`, `title`, `value`.
  - `FileChip`: Interactive file attachment pill (`fileName`, `filePath`, `storageMode`).
  - `Popover` & Root `popovers`: Define `"popovers": { "detail": { "title": "...", "width": 300, "height": 240, "placement": "bottom", "root": "detail_root" } }` where `"root"` references an element ID inside `"elements"`, and open via `Button` (`"popover": "detail"`), `Popover` node (`"popoverId": "detail"`), or actions `popover.open` / `popover.close` / `popover.toggle`.
  - `Markdown`: Native GFM renderer (`text`, optional `bind` + `onChange` for interactive `- [x]` task list toggles).
  - `Table`: Multi-column data grid (`collection`/`items`, `columns`: `[{ "key": "...", "header": "...", "width": "1*", "align": "left|right|center" }]`, `sortable`, `striped`, `onRowClick`).
  - `DonutChart` & Multi-Series `Chart`: `DonutChart` (`collection`, `titleField`, `valueField`, `colorField`, `centerTitle`, `centerValue`, `showLegend`); `Chart` (`chartKind`: `line`|`bar`|`area`, `collection`, `xField`, `series`: `[{ "field": "...", "label": "...", "color": "#..." }]`, `showLegend`, `showGrid`).
  - `Canvas`: Pure native 2D vector surface (`viewBox`, static `elements` or dynamic `elementsSource`: `"${$computed.shapes}"` supporting `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `path` SVG `d`, `text`, `rotation`, and `onItemClick`/`onClick` passing `{ id, x, y }`).
  - `DatePicker`, `TimePicker`, `AutoSuggestInput`, `ColorPicker`, `RadioGroup`, `Rating`: Rich native WinUI 3 inputs bound via `bind`/`value` + `onChange`.
  - **Host-Unified Glass, Typography & Chromatic Accents**: Layout containers (`Stack`, `Grid`, `Card`, `Scroll`, `Tabs`) inherit DeskBox's host Mica/Acrylic backdrop and unified corner radius — style surfaces via `Card.tone`, `Text.style`, and semantic `color` tokens (avoid opaque container overrides and neutral hardcoded `#FFFFFF`/`#E2E8F0` text colors so Light & Dark themes stay legible). Chromatic colors/gradients apply to gauges, charts, borders/accents, and `Canvas` vector shapes; nodes also support `margin`, `minWidth`, `maxWidth`, `maxHeight`, `fontWeight`, `fontFamily` (`mono`), `opacity`, `shadow` (`none` | `sm` | `md`), `aspectRatio`, and `List` `allowReorder`/`onReorder` & `inlineEditField`/`onInlineCommit`.

---

## 4. Declarative Actions

- `state.set`: `{ "type": "state.set", "key": "draftText", "value": "" }`
- `state.toggle`: `{ "type": "state.toggle", "key": "flagKey" }`
- `state.increment`: `{ "type": "state.increment", "key": "counterKey", "value": "1" }`
- `collection.prepend` / `collection.append`: `{ "type": "collection.prepend", "collection": "logs", "guard": "${state.draftText != ''}", "item": { "text": "${state.draftText}" } }`
- `collection.update`: `{ "type": "collection.update", "collection": "tasks", "targetId": "${$item.id}", "item": { "done": "${$item.done != true}" } }`
- `collection.remove`: `{ "type": "collection.remove", "collection": "logs", "targetId": "${$item.id}" }`
- `collection.clear`: `{ "type": "collection.clear", "collection": "logs" }`
- `collection.reorder`: `{ "type": "collection.reorder", "collection": "tasks", "fromIndex": 0, "toIndex": 2 }`
- `collection.exportMarkdown`: `{ "type": "collection.exportMarkdown", "collection": "logs" }`
- `file.transform`: Zero-dependency native local converter (`png` | `jpg` | `webp` | `bmp` | `ico` | `csvToJson` | `jsonToCsv` | `jsonPretty` | `jsonMinify` | `mdToHtml` | `mdToTxt` | `base64Encode` | `base64Decode` | `sha256` | `md5`), populating `$transform.outputPath`, `$transform.outputName`, `$transform.sizeText`, `$transform.resultText`, `state.transformStatus`, `state.transformOutput`.
- `text.transform`: Pure in-memory text processor (`format`: `jsonPretty` | `jsonMinify` | `urlEncode` | `urlDecode` | `base64Encode` | `base64Decode` | `timestampToDate` | `dateToTimestamp` | `uuid` | `upper` | `lower` | `trim` | `wordCount` | `sha256` | `md5`, `text`, output `key`, optional `mode`: `"copy"`).
- `launcher.open`: Safe workflow & protocol launcher (`targetId`/`path`/`url`: standard folders `downloads`|`desktop`|`documents`|`pictures`, whitelisted URIs `vscode://`, `obsidian://`, `ms-screenclip:`, `ms-calculator:`, `https://`, or existing local path).
- `file.pick`: Opens native file or folder picker (`mode`: `"file"` | `"folder"`, `multiple`: `true`, `accept` / `format`: `".png,.jpg"`) and chains `then` or `onComplete(ctx, res)` with `$drop.*` and `ctx.event.files` populated.
- `file.listDir`: Scans a local directory (`path`, `pattern`: `"*.mp4;*.mov"`, `recursive`: `false`, `maxItems`: `200`, optional `targetCollection`, `onComplete`), returning `res.data = [{ name, path, ext, sizeBytes, sizeText, modifiedIso, isDirectory }]` (`LocalFileAccess`).
- `file.manage`: Safely copies, moves, renames, or recycles local files (`op`: `"copy"` | `"move"` | `"rename"` | `"recycle"` via Windows Recycle Bin — permanent deletion is forbidden; `path`, `destination`, `onComplete`, `LocalFileAccess`).
- `file.writeText` & `fileText` source: Watch or write UTF-8/Markdown/JSON local files (`path`, `text`, `append`, gated by per-widget `LocalFileAccess` permission).
- `clipboard.captureImage`: Captures clipboard bitmap/DIB screenshot to a local PNG (`path` optional directory, `key` state key, `onComplete` receiving `{ path, name, width, height, sizeBytes, sizeText }`, `LocalFileAccess`).
- `file.open` / `file.reveal`: `{ "type": "file.open", "path": "${$item.filePath}" }`
- `system.control`: Executes safe Windows control (`targetId`/`key`: `volume.set` | `volume.step` | `volume.muteToggle` | `brightness.set` | `brightness.step` | `audio.output` | `media.playPause` | `media.next` | `media.previous` | `power.keepAwakeToggle` | `power.lock` | `recycleBin.empty` | `radio.wifiToggle` | `radio.bluetoothToggle`, optional `value` supporting `${$value}`).
- `system.openSetting`: Opens `ms-settings:` URI (`key` or `url`, e.g. `"ms-settings:network-wifi"`).
- `reminder.notify` / `toast.show`: Sends Windows 11 system Toast notification (`title`, `message`) + widget banner.
- `url.open`: `{ "type": "url.open", "url": "${$item.url}" }` (opens `https://` link in user's browser).
- `source.refresh`: `{ "type": "source.refresh", "targetId": "feed" }` (alias `"sourceId": "feed"`; omit ID to refresh all `rss` / `httpJson` / `weather` / `deviceState` / `music` / `todo` sources immediately).
- `http.request`: Interactive REST/Webhook call (`id`, `jobKey`, `method`: `GET|POST|PUT|PATCH|DELETE`, `url`, `headers` with `${$secrets.*}`, `body`, `stateMap`, `collection`, and `onComplete` / `export function onHttpResponse(ctx, res)` receiving unified `res = { id, jobKey, type, ok, status, text, data, error, timedOut, cancelled, durationMs, meta }`).
- `job.cancel`: `{ "type": "job.cancel", "jobKey": "<keyOr*>" }` — cancels a running background async job (or `"*"` to cancel all active jobs for this widget).
- `command.run` & `command` source (Direct build only; disabled in Microsoft Store edition): Execute local CLI processes (`id`, `jobKey`, `executable`, `arguments`, `workingDirectory`, `longRunning`: `true` enabling 3-minute output-silence watchdog instead of 30s short cap, `onProgress(ctx, p)` throttled `4Hz`, and `onComplete` / `onCommandResult(ctx, res)` receiving unified `{ id, jobKey, type, ok, status, text, data: { exitCode, stdout, stderr }, error, timedOut, cancelled, durationMs, meta }`, gated by `CommandExecution` permission).
- `ai.run`: Runs a fast non-thinking structured AI micro-task inside the widget using DeskBox's global AI provider and maps the JSON output into `state` and/or `collections`:
  `{ "type": "ai.run", "guard": "${state.draft != ''}", "prompt": "Summarize and extract actionable tasks:\n${state.draft}", "stateMap": { "summary": "summary" }, "collection": "items", "mode": "prepend", "itemsPath": "items", "fieldMap": { "title": "title", "tag": "tag", "done": "done" }, "maxItems": 6, "then": { "type": "state.set", "key": "draft", "value": "" } }`
  Automatically updates `state.aiStatus` (`"idle"` | `"running"` | `"error"`), `state.aiError`, and `state.aiUpdatedAt` (`"HH:mm"`). On failure or missing API key, `then` is skipped so user input in `state.draft` is preserved.
- `clipboard.copy`: `{ "type": "clipboard.copy", "text": "..." }`
- `popover.open` / `popover.close` / `popover.toggle`: `{ "type": "popover.toggle", "popoverId": "detail" }`
- `script.run`: `{ "type": "script.run", "fn": "step", "arg": "1" }` (or structured `"args": { ... }` -> `ctx.args`) — invokes exported synchronous ES2023 function `step(ctx, arg)` in sidecar `logic.js` within DeskBox's offline QuickJS sandbox (no network/DOM/filesystem, <= 50ms CPU, <= 4MB RAM). `ctx.state` natively persists structured JSON (`boolean`, `number`, `string`, `array`, `object`) in `store.json` without `JSON.stringify`. `ctx.collections` exposes `get(key)`, `add/append(key, item)`, `prepend(key, item)`, `update(key, id, patch)`, `remove(key, id)`, `clear(key)`, `set(key, items)`; `ctx.ui` exposes `toast(msg)`, `copy(text)`, `notify(title, msg)`, `refreshSource(id)`; `ctx.dispatch(actionOrArray)` dispatches up to 16 follow-up actions; `ctx.event` exposes UI & batch drop payloads (`{ id, x, y, value, fromIndex, toIndex, files }`); `ctx.env` exposes `locale`, `idleSeconds`, `dayType`, `isHoliday`, `isWorkday`, `holidayName`, `weather`, `clipboard`, `transform`, `clockZones`, `sys`, `device`, `music`, `todo` (note that `ctx.sources` does NOT exist). Always guard `ctx.args?.foo` and `ctx.event?.item` with optional chaining because exported handlers are dry-run validated at compile time. Declare `"script": { "entry": "logic.js", "tickIntervalMs": 0 }` and export `onInit(ctx)` (required cold-start projection for `$computed.*`), plus optional `onSourceData(ctx, sourceId, rawText)` and visibility-aware `onTick(ctx, nowUnixMs)`.
- `todo.add|toggle|remove|cyclePriority|clearCompleted`, `pomodoro.*`, `countdown.upsert|pin|delete`, `ai.*`, `tip.open|close|toggle`, `audio.cue|play|pause|stop|setVolume|stopAll` built-in domain & native audio actions.

---

## 5. Agent MCP Tools, CLI & Bundled Reference Files

- **MCP Tools (`DeskBox.exe --mcp`)**:
  - `deskbox_get_studio_context`: Read-only snapshot of the active Widget Workshop session (`hostOnline`, `isOpen`, `page`, `isEditMode`, `targetWidgetId`, `widgetId`, `manifestId`, `widgetName`, `activePreviewCulture`, `isCapsuleViewport`, `hasUnsavedChanges`, `revisionCount`, `pinnedCapabilities`, `selectedNode` `{ path, nodeType, label }`, `pendingPreviewStageId`, `briefMarkdown`, `hasLogicJs`, `manifestJson`, `logicJs`, `locales`).
  - `deskbox_get_widget_spec`: Read the live runtime specification (`detail`: `"compact"` for fast ~3 KB quick index or `"full"` for complete guide, plus optional `includeSchema`).
  - `deskbox_get_capability_spec`: Search or inspect any of the 12 Domain Capability Packs or 37 atomic capability modules with exact tokens, verified public endpoints, and Golden JSON snippets.
  - `deskbox_list_widgets`: List all widgets (gracefully falls back to disk scan when offline), or pass `{ "widgetId": "<id>" }` to inspect one widget's live `state`, `displayMode`, `collectionCounts`, and `sampleItems`.
  - `deskbox_validate_manifest`: Validate `manifest.json` + optional `logicJs` (including QuickJS compilation & `onInit` dry-run) + optional `locales` map.
  - `deskbox_upsert_widget`: Annotated `destructiveHint: true`. Validate and STAGE a desktop widget (`manifestJson` — canonical `"schemaVersion": 1` Flat Element Graph with `root`, `elements`, `popovers[*].root`, and semantic icon names — or incremental `upsertElements` / `removeElements` / `patchRoot` / `removeRootKeys` / `scriptHunks` `[{ search, replace }]`; optional `logicJs`, `locales`, `widgetId`, `resizeToDefault`, and `confirmDataLoss`). Returns a `stageId` without changing the desktop. Only after user confirmation, call again with `{ "commit": true, "stageId": "<stageId>" }` (`manifestJson` optional; inline edits/`scriptHunks` disallowed on commit) to write it to the desktop — overwrite, data-loss, or script/privileged commits also require native DeskBox host approval (Deny default, 60s timeout; declined/timed-out returns `requiresHostApproval: true` and keeps the stage). Protected by a three-state commit lease; re-committing a completed `stageId` is idempotent.
  - `deskbox_capture_widget_preview`: Capture a real native WinUI 3 PNG screenshot for a live `widgetId` or pending `stageId` (`mode`: `"expanded"` | `"capsule"` | `"live"`, optional `theme`: `"dark"` | `"light"`).
  - `deskbox_push_widget_data`: Push live state/collection updates (e.g., Ambient Agent HUD).
- **CLI Subcommands (`DeskBox.exe widget <subcommand>`)**:
  - `DeskBox.exe widget list`
  - `DeskBox.exe widget get --id <widgetId>`
  - `DeskBox.exe widget validate --file manifest.json [--logic logic.js] [--locales-dir locales]` (sibling `logic.js` & `locales/` auto-detected)
  - `DeskBox.exe widget apply --file manifest.json [--id <widgetId>] [--logic logic.js] [--locales-dir locales]` (stages first and prints `stageId`; confirm with `DeskBox.exe widget apply --commit --stage-id <stageId>`)
  - `DeskBox.exe widget preview (--id <widgetId> | --stage-id <stageId>) --out preview.png [--mode expanded|capsule|live] [--theme dark|light]`
  - `DeskBox.exe widget push --id <widgetId> --set statusText="Running" --set progress=65 --append events:text="Build succeeded"`
- **Bundled Reference Files in This Skill**:
  - [`scripts/ensure-deskbox.ps1`](scripts/ensure-deskbox.ps1) — Detects DeskBox installation/running status, outputs MCP command JSON, and supports `-Install -StartHost` (with SHA-256 verification) after user confirmation.
  - [`references/API_REFERENCE.md`](references/API_REFERENCE.md) — Complete Single-Source-of-Truth API Reference for all 12 Domain Capability Packs and 37 atomic capabilities with flat `schemaVersion: 1` Golden JSON snippets.
  - [`references/manifest.schema.json`](references/manifest.schema.json) — Draft 2020-12 JSON Schema for DeskBox Custom Widget flat `schemaVersion: 1` `manifest.json`.
