# DeskBox Custom Widget Capability & API Reference (`Schema v1`)

> Generated from the DeskBox runtime capability registry. Reference `@module-id` or use **Capabilities** in Studio to attach exact contracts to the prompt context, or edit `manifest.json` directly for 200ms hot-reload.

## Architecture & Layout Conventions
- **No Duplicate Inner Header**: The host window chrome already renders the widget icon, title, collapse toggle, and context menu. Do not place a duplicate static header bar at the top of `view`.
- **Consistent Bento Hierarchy**: Keep sibling functional sections visually uniform (`Card` with `tone: "subtle"` or `Divider`-separated rows; max 2 nested `Card` levels). Multi-item `Grid` containers auto-flow into implicit rows when `rows`/`row` are omitted.
- **Direct Live Controls**: `Slider`, `Toggle`, and `Segmented` dispatch `onChange` immediately via `${$value}`; avoid redundant confirmation buttons next to live controls.

## Data Sources

### 🌤️ Weather Forecast (`@weather`)
Zero-key weather service providing live conditions, UV/wind metrics, and a 7-day forecast.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "weather", "targetCollection": "forecast" }` | Source | Declares built-in weather source; inherits host city when omitted |
| `${$weather.city} / ${$weather.tempText} / ${$weather.condition}` | Token | City name, formatted temperature (22°C), and condition |
| `${$weather.icon} / ${$weather.rangeText} / ${$weather.feelsLikeText}` | Token | Weather icon, daily temperature range, and feels-like text |
| `${$weather.humidity} / ${$weather.wind} / ${$weather.precipProb} / ${$weather.uv}` | Token | Humidity, wind speed, precipitation probability, and UV index |
| `$item.weekday / $item.icon / $item.low / $item.high` | Collection | 7-day forecast item fields in collections.forecast |

```json
{
  "sources": [{ "type": "weather", "city": "${$settings.city}", "targetCollection": "forecast" }],
  "collections": { "forecast": { "maxItems": 7 } },
  "view": {
    "type": "Card",
    "tone": "subtle",
    "children": [
      { "type": "Text", "text": "${$weather.icon} ${$weather.city} · ${$weather.tempText}", "style": "title" },
      { "type": "Text", "text": "${$weather.condition}  ${$weather.rangeText} · Humidity ${$weather.humidity}", "style": "caption", "color": "secondary" }
    ]
  }
}
```

### 📊 Hardware Monitor (`@system-metrics`)
Low-overhead telemetry for CPU, RAM, GPU/VRAM, Disk, Network speed, Battery, and Top Processes.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "systemMetrics", "intervalMs": 2000 }` | Source | Subscribes to live hardware telemetry |
| `${$sys.cpu.percent} / ${$sys.memory.percent} / ${$sys.memory.summaryText}` | Token | CPU %, RAM %, and formatted memory summary |
| `${$sys.gpu.name} / ${$sys.gpu.percent} / ${$sys.gpu.vramSummary}` | Token | GPU name, core utilization %, and VRAM summary |
| `${$sys.net.downText} / ${$sys.net.upText} / ${$sys.net.summaryText}` | Token | Live download/upload network speed |
| `${$sys.disk.percent} / ${$sys.disk.freeGb} / ${$sys.battery.statusText} / ${$sys.uptime.text}` | Token | Primary disk %, free GB, battery status, and uptime |
| `StatCard / GpuCard / ProcessList` | Component | Built-in KPI card, GPU card, and top-process list |

```json
{
  "sources": [{ "type": "systemMetrics", "intervalMs": 2000 }],
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      {
        "type": "Grid",
        "columns": "*,*",
        "spacing": 8,
        "children": [
          { "type": "StatCard", "title": "CPU", "value": "${$sys.cpu.percent}", "unit": "%", "progress": "${$sys.cpu.percent}", "sparkline": "cpu", "color": "accent" },
          { "type": "StatCard", "title": "RAM", "value": "${$sys.memory.percent}", "unit": "%", "subtitle": "${$sys.memory.compactText}", "progress": "${$sys.memory.percent}", "sparkline": "memory", "color": "cyan" }
        ]
      },
      { "type": "GpuCard" }
    ]
  }
}
```

### 💾 Storage Drives (`@storage-drives`)
Lists all mounted local drives with volume label, used percentage, and free/total GB.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "storageDrives", "targetCollection": "drives" }` | Source | Polls mounted local volumes into targetCollection |
| `${$drives.count} / ${$drives.summary} / ${$drives.primaryPercent}` | Token | Mounted drive count, summary string, and primary drive % |
| `$item.name / $item.label / $item.percent / $item.freeGb / $item.summary` | Collection | Per-drive fields in collections.drives |

```json
{
  "sources": [{ "type": "storageDrives", "targetCollection": "drives", "intervalMs": 15000 }],
  "collections": { "drives": { "maxItems": 16 } },
  "view": {
    "type": "Card",
    "tone": "subtle",
    "children": [
      {
        "type": "BarList",
        "collection": "drives",
        "titleField": "title",
        "valueField": "percent",
        "subtitleField": "summary",
        "unit": "%",
        "color": "accent"
      }
    ]
  }
}
```

### 🌍 World Clock (`@world-clock`)
Provides 1-second UTC/Unix clock tokens plus timezone helpers: `tz(zoneId, format, offsetHours)`, `tzDiffLabel()`, `tzWorkState()`, and `tzCity()`.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "clock", "intervalMs": 1000 }` | Source | Enables live clock tick updates |
| `${tz('America/New_York', 'HH:mm')} / ${tz('Europe/London', 'HH:mm:ss')}` | Function | Formats current time in any IANA timezone or UTC offset |
| `${tz('Europe/London', 'HH:mm', 6)}` | Function | Offset overload shifts now by N hours (0.5 steps supported) for meeting scrubbers; DST stays accurate |
| `${tzDiffLabel('Europe/London', 0)}` | Function | Localized diff + cross-day label such as "behind 7h · yesterday" across 13 locales |
| `${tzWorkState('Asia/Tokyo', '09-18', 0)}` | Function | Returns work / edge / sleep for the zone's wall clock given a work window, powering status lights |
| `${tzCity('Asia/Shanghai')}` | Function | Localized display names for 24 built-in business cities across 13 locales |
| `${$clock.fullTime} / ${$clock.utcTime} / ${$clock.localOffset} / ${$clock.unixSeconds}` | Token | Local time, UTC time, UTC offset, and Unix seconds |

```json
{
  "sources": [{ "type": "clock", "intervalMs": 1000 }],
  "view": {
    "type": "Grid",
    "columns": "*,*",
    "spacing": 8,
    "children": [
      { "type": "Card", "tone": "subtle", "children": [{ "type": "Text", "text": "Beijing (UTC+8)", "style": "caption", "color": "secondary" }, { "type": "Text", "text": "${tz('Asia/Shanghai', 'HH:mm:ss')}", "style": "title" }] },
      { "type": "Card", "tone": "subtle", "children": [{ "type": "Text", "text": "New York (EST/EDT)", "style": "caption", "color": "secondary" }, { "type": "Text", "text": "${tz('America/New_York', 'HH:mm:ss')}", "style": "title" }] },
      { "type": "Card", "tone": "subtle", "children": [{ "type": "Text", "text": "London (GMT/BST)", "style": "caption", "color": "secondary" }, { "type": "Text", "text": "${tz('Europe/London', 'HH:mm:ss')}", "style": "title" }] },
      { "type": "Card", "tone": "subtle", "children": [{ "type": "Text", "text": "Tokyo (JST)", "style": "caption", "color": "secondary" }, { "type": "Text", "text": "${tz('Asia/Tokyo', 'HH:mm:ss', 6)} · ${tzDiffLabel('Asia/Tokyo', 6)} · ${tzWorkState('Asia/Tokyo', '09-18', 6)}", "style": "title" }] }
    ]
  }
}
```

### 🤖 AI Quota Monitor (`@ai-monitor`)
Aggregates local Claude Code / Codex token logs and queries cloud provider balances.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "aiMonitor", "intervalMs": 60000 }` | Source | Enables local token log parser and balance polling |
| `${$ai.todayTokens} / ${$ai.todayCost} / ${$ai.monthTokens} / ${$ai.monthCost}` | Token | Daily and monthly token counts and estimated cost |
| `${$ai.focus.name} / ${$ai.focus.value} / ${$ai.focus.subtext}` | Token | Focused provider name, balance value, and subtitle |
| `AiFocusCard / AiTokensCard / AiRadarList / AiTrendCard` | Component | Built-in quota card, token summary, radar list, and trend card |

```json
{
  "sources": [{ "type": "aiMonitor", "intervalMs": 60000 }],
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      { "type": "AiFocusCard" },
      { "type": "AiTokensCard" },
      { "type": "AiRadarList" }
    ]
  }
}
```

### 🗓️ Lunar & Calendar (`@calendar`)
Built-in Gregorian date, Chinese Lunar Ganzhi, solar terms, and festival tokens.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `${$calendar.date} / ${$calendar.monthTitle} / ${$calendar.weekday}` | Token | Current ISO date, month header, and weekday |
| `${$calendar.lunar} / ${$calendar.lunarTitle} / ${$calendar.festival}` | Token | Lunar day, Ganzhi year/month, and festival/solar-term |
| `${$calendar.subtitle} / ${$calendar.weekOfYear}` | Token | Smart subtitle (festival or lunar) and ISO week number |

```json
{
  "sources": [{ "type": "calendar", "intervalMs": 60000 }],
  "view": {
    "type": "Stack",
    "spacing": 2,
    "children": [
      { "type": "Text", "text": "${$calendar.monthTitle} · ${$calendar.weekday}", "style": "subtitle" },
      { "type": "Text", "text": "${$calendar.lunarTitle} ${$calendar.festival}", "style": "caption", "color": "accent" }
    ]
  }
}
```

### 🎂 Countdowns (`@countdown`)
Solar & Lunar recurring birthday/anniversary countdown engine with Windows Toast reminders.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "countdown", "intervalMs": 60000 }` | Source | Enables recurring countdown calculation and daily reminders |
| `CountdownHero / CountdownList / TimeProgressCard` | Component | Pinned hero card, interactive countdown list, and progress card |
| `${$countdown.hero.title} / ${$countdown.hero.days} / ${$countdown.hero.subtitle}` | Token | Pinned event title, remaining days, and date subtitle |
| `${$countdown.work.*} / ${$countdown.holiday.*}` | Token | Work-hour progress (BeforeWork/Working/AfterWork) and next China statutory holiday countdown (built-in 2025-2027 schedule) |

```json
{
  "sources": [{ "type": "countdown", "intervalMs": 60000 }],
  "collections": { "events": { "maxItems": 100 } },
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      { "type": "CountdownHero" },
      { "type": "CountdownList" }
    ]
  }
}
```

### 🍅 Pomodoro & Sedentary Guard (`@pomodoro`)
Drift-free Focus / Break timer plus a sedentary guardian mode with keyboard/mouse idle auto-reset and rotating micro-break reminders.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "pomodoro", "intervalMs": 1000 }` | Source | Enables 1-second Pomodoro timer sync |
| `PomodoroCard` | Component | Complete native Pomodoro card with ring gauge and controls (auto-switches to the guardian dial in sedentary mode) |
| `pomodoro.toggle / pomodoro.reset / pomodoro.skip / pomodoro.extend` | Action | Start/pause, reset, skip phase, or extend session |
| `pomodoro.sedentaryConfirm / pomodoro.sedentarySnooze` | Action | Confirm you stood up and restart the round, or snooze the sedentary reminder by 15 minutes |
| `${$pomodoro.mode} / ${$pomodoro.satMinutes} / ${$pomodoro.microAction} / ${$pomodoro.healthSummary}` | Token | Active rhythm mode, continuous sitting minutes, rotating micro-break tip, and today's health summary |

```json
{
  "sources": [{ "type": "pomodoro", "intervalMs": 1000 }],
  "view": { "type": "PomodoroCard" }
}
```

### 🎛️ Device & Media State (`@device-state`)
Reads live volume, brightness, Wi-Fi/Bluetooth, SMTC media track/cover, and Keep-Awake state.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "deviceState", "intervalMs": 3000 }` | Source | Subscribes to live device & SMTC media state |
| `${$device.volume} / ${$device.muted} / ${$device.audioDeviceName}` | Token | Master volume 0-100, mute flag, and audio output device |
| `${$device.brightness} / ${$device.brightnessText}` | Token | Display brightness 0-100 and status text |
| `${$device.wifiEnabled} / ${$device.bluetoothEnabled} / ${$device.keepAwake}` | Token | Wi-Fi, Bluetooth, and Keep-Awake toggle states |
| `${$device.mediaTitle} / ${$device.mediaArtist} / ${$device.mediaToggleIcon} / ${$device.mediaCover}` | Token | SMTC media title, artist, play/pause glyph, and cover path |

```json
{
  "sources": [{ "type": "deviceState", "intervalMs": 3000 }],
  "view": {
    "type": "Card",
    "tone": "subtle",
    "children": [
      {
        "type": "Grid",
        "columns": "Auto,*,Auto,Auto,Auto",
        "spacing": 8,
        "children": [
          { "type": "Image", "column": 0, "src": "${$device.mediaCover}", "width": 36, "height": 36, "cornerRadius": 6, "visible": "${$device.mediaCover != ''}" },
          { "type": "Stack", "column": 1, "spacing": 2, "children": [{ "type": "Text", "text": "${$device.mediaTitle}", "style": "bodyStrong", "maxLines": 1 }, { "type": "Text", "text": "${$device.mediaArtist != '' ? $device.mediaArtist : $device.mediaStatus}", "style": "caption", "color": "secondary", "maxLines": 1 }] },
          { "type": "IconButton", "column": 2, "icon": "\uE892", "size": 28, "onClick": { "type": "system.control", "targetId": "media.previous" } },
          { "type": "IconButton", "column": 3, "icon": "${$device.mediaToggleIcon}", "size": 28, "variant": "accent", "onClick": { "type": "system.control", "targetId": "media.playPause" } },
          { "type": "IconButton", "column": 4, "icon": "\uE893", "size": 28, "onClick": { "type": "system.control", "targetId": "media.next" } }
        ]
      }
    ]
  }
}
```

### 🌐 HTTP JSON & RSS (`@http-and-rss-feeds`)
Fetches REST JSON & RSS/Atom feeds with disk caching and optional auth headers.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "rss", "url": "https://...", "targetCollection": "items" }` | Source | Parses RSS/Atom feeds into title, summary, link, pubDate |
| `{ "type": "httpJson", "url": "...", "itemsPath": "$.data" }` | Source | Fetches JSON APIs with scalar stateMap or array itemsPath/fieldMap |
| `{ "type": "source.refresh" }` | Action | Immediately refreshes data sources |

```json
{
  "collections": { "items": { "maxItems": 20 } },
  "sources": [
    {
      "id": "zhihu",
      "type": "httpJson",
      "url": "https://news-at.zhihu.com/api/4/news/latest",
      "intervalMs": 600000,
      "targetCollection": "items",
      "itemsPath": "$.stories",
      "fieldMap": { "title": "title", "url": "url", "sub": "hint" }
    }
  ],
  "view": {
    "type": "List",
    "items": "items",
    "itemTemplate": {
      "type": "Button",
      "variant": "subtle",
      "text": "${$item.rank}. ${$item.title}",
      "onClick": { "type": "url.open", "url": "${$item.url}" }
    }
  }
}
```

## UI Components

### 🗂️ Tabs, Image & Gauges (`@visual-containers`)
Provides stateful `Tabs`, rounded `Image`, `RingGauge`, and proportional `BarList` charts.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `Tabs` | Component | Segmented tab container rendering only the active tab |
| `Image` | Component | Renders local attachments, album art, or HTTPS images |
| `RingGauge / BarList` | Component | Circular KPI gauge and ranked horizontal proportion bars |

```json
{
  "state": { "tab": "gauge" },
  "sources": [{ "type": "systemMetrics", "intervalMs": 2000 }],
  "view": {
    "type": "Tabs",
    "bind": "state.tab",
    "children": [
      {
        "title": "Core Load",
        "value": "gauge",
        "icon": "\uE9D9",
        "children": [
          {
            "type": "Grid",
            "columns": "*,*",
            "spacing": 8,
            "children": [
              { "type": "RingGauge", "progress": "${$sys.cpu.percent}", "title": "CPU", "unit": "%", "color": "accent" },
              { "type": "RingGauge", "progress": "${$sys.memory.percent}", "title": "RAM", "subtitle": "${$sys.memory.compactText}", "unit": "%", "color": "cyan" }
            ]
          }
        ]
      },
      {
        "title": "Top Processes",
        "value": "proc",
        "icon": "\uE9F5",
        "children": [
          { "type": "ProcessList", "maxItems": 5, "mode": "memory" }
        ]
      }
    ]
  }
}
```

### 📅 Month Calendar Grid (`@calendar-grid`)
Interactive 7x6 month matrix with lunar subtitles, date selection, and event dots.
- **Required modules**: `calendar`

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "CalendarGrid", "bind": "state.selectedDate" }` | Component | Interactive month grid updating bound state key on click |
| `collection / dateField` | Property | Highlights days that have matching records in the collection |

```json
{
  "state": { "selectedDate": "", "draft": "" },
  "collections": { "events": { "maxItems": 200 } },
  "sources": [{ "type": "calendar", "intervalMs": 60000 }],
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      { "type": "CalendarGrid", "bind": "state.selectedDate", "collection": "events", "dateField": "date" },
      {
        "type": "List",
        "items": "events",
        "filter": "${state.selectedDate == '' || $item.date == state.selectedDate}",
        "emptyState": { "icon": "\uE787", "title": "No events today", "subtitle": "Click a date above to switch views" },
        "itemTemplate": { "type": "Text", "text": "• ${$item.title} (${$item.date})" }
      }
    ]
  }
}
```

### 📥 File Drop Zone (`@drop-zone`)
File input surface supporting desktop drag-and-drop and click-to-browse picker.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "DropZone", "title": "拖入文件", "onDrop": [...] }` | Component | File drop & browse surface executing onDrop per file |
| `${$drop.name} / ${$drop.path} / ${$drop.ext} / ${$drop.sizeText} / ${$drop.text}` | Token | File name, full path, extension, size, and first 8KB text |

```json
{
  "type": "DropZone",
  "icon": "\uE8B9",
  "title": "Drop an image or click to choose a file",
  "subtitle": "Converts locally to the target format; source files are untouched",
  "onDrop": [
    {
      "type": "file.transform",
      "path": "${$drop.path}",
      "format": "${state.targetFormat}",
      "then": [
        {
          "type": "collection.prepend",
          "collection": "history",
          "item": { "name": "${$transform.outputName}", "path": "${$transform.outputPath}", "size": "${$transform.sizeText}" }
        }
      ]
    }
  ]
}
```

### 🎚️ Quick Control Tile (`@control-tile`)
Windows 11 Quick Settings tile with icon, title, live subtitle, and active accent fill.
- **Required modules**: `device-state`, `system-control`

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "ControlTile", "title": "Wi-Fi", "value": "${$device.wifiEnabled}" }` | Component | Displays active accent fill when value is true; dispatches onClick |

```json
{
  "sources": [{ "type": "deviceState", "intervalMs": 3000 }],
  "view": {
    "type": "Grid",
    "columns": "*,*",
    "spacing": 8,
    "children": [
      { "type": "ControlTile", "icon": "\uE701", "title": "Wi-Fi", "subtitle": "${$device.wifiStatus}", "value": "${$device.wifiEnabled}", "onClick": { "type": "system.control", "targetId": "radio.wifiToggle" } },
      { "type": "ControlTile", "icon": "\uE702", "title": "Bluetooth", "subtitle": "${$device.bluetoothStatus}", "value": "${$device.bluetoothEnabled}", "onClick": { "type": "system.control", "targetId": "radio.bluetoothToggle" } },
      { "type": "ControlTile", "icon": "\uEA80", "title": "Keep Awake", "subtitle": "${$device.keepAwakeStatus}", "value": "${$device.keepAwake}", "onClick": { "type": "system.control", "targetId": "power.keepAwakeToggle" } },
      { "type": "ControlTile", "icon": "\uE74D", "title": "Recycle Bin", "subtitle": "${$device.recycleBinStatus}", "value": "${$device.recycleBinCount != '0'}", "onClick": { "type": "system.control", "targetId": "recycleBin.empty" } }
    ]
  }
}
```

### 📈 Sparkline & Heatmap (`@micro-charts`)
Vector area sparklines, daily activity heatmaps, and progress indicators.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `Sparkline` | Component | Smooth vector trend line & area bound to a collection |
| `HeatmapGrid` | Component | Aggregates daily records into an intensity heatmap |
| `ProgressBar / ProgressRing / ProgressRow` | Component | Theme-aware linear and radial progress indicators |

```json
{
  "type": "HeatmapGrid",
  "title": "Activity over the last 28 days",
  "collection": "checkins",
  "valueField": "score",
  "days": 28,
  "color": "success"
}
```

### ⌨️ Inputs & Controls (`@forms-inputs`)
Text inputs, selects, segmented pills, checkboxes, toggles, and two-way sliders.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `Input / TextArea` | Component | Two-way state-bound text input dispatching `onSubmit` |
| `Select / Segmented` | Component | Dropdown or segmented pill selector |
| `Slider / Toggle / NumberBox` | Component | Dispatches `onChange` immediately with `${$value}` |

```json
{
  "type": "Grid",
  "columns": "*,Auto",
  "spacing": 6,
  "children": [
    { "type": "Input", "column": 0, "bind": "state.draft", "placeholder": "Type a new entry…" },
    { "type": "IconButton", "column": 1, "icon": "\uE710", "variant": "accent", "onClick": { "type": "collection.prepend", "guard": "${state.draft != ''}", "collection": "items", "item": { "title": "${state.draft}" }, "then": [{ "type": "state.set", "key": "draft", "value": "" }] } }
  ]
}
```

### 📋 Data Lists (`@collections-lists`)
Persisted record collections with filtering, row hover actions, and Markdown export.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `collections: { "items": { "maxItems": 200 } }` | Schema | Declares persistent collection schema in manifest root |
| `${$item.id} / ${$item.rank} / ${$item.timeText} / ${$item.dateText}` | Token | Built-in item ID, 1-based rank, and timestamp tokens |
| `collection.prepend / collection.update / collection.remove / collection.clear` | Action | Collection add, update, remove, and clear actions |

```json
{
  "type": "List",
  "items": "items",
  "itemTemplate": {
    "type": "CheckBox",
    "value": "${$item.done}",
    "text": "${$item.title}",
    "strikethrough": true,
    "onToggle": { "type": "collection.update", "collection": "items", "targetId": "${$item.id}", "item": { "done": "${$item.done == 'true' ? 'false' : 'true'}" } }
  }
}
```

## Actions

### 🔆 Volume, Brightness & Media (`@display-and-audio`)
Two-way live sliders for master volume and display brightness, plus media transport and audio output switching.
- **Required modules**: `device-state`

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `brightness.set / brightness.step` | Command | Sets display brightness (0-100) via LCD/DDC-CI using `${$value}` |
| `volume.set / volume.muteToggle / audio.output` | Command | Adjusts master volume, toggles mute, or opens audio output selector |
| `media.playPause / media.previous / media.next` | Command | Controls active SMTC media session; bind icon to `${$device.mediaToggleIcon}` |

```json
{
  "sources": [{ "type": "deviceState", "intervalMs": 3000 }],
  "view": {
    "type": "Card",
    "tone": "subtle",
    "children": [
      { "type": "Slider", "title": "System Volume", "value": "${$device.volume}", "min": 0, "max": 100, "step": 2, "unit": "%", "onChange": { "type": "system.control", "targetId": "volume.set", "value": "${$value}" } },
      { "type": "Slider", "title": "Screen Brightness", "value": "${$device.brightness}", "min": 0, "max": 100, "step": 5, "unit": "%", "onChange": { "type": "system.control", "targetId": "brightness.set", "value": "${$value}" } },
      {
        "type": "KeyValueRow",
        "label": "Audio Output",
        "value": "${$device.audioDeviceName}"
      }
    ]
  }
}
```

### 📋 Clipboard & Text Transform (`@clipboard-workspace`)
Inspects live clipboard text (JWT, JSON, Unicode escapes, timestamps) and runs 25 local in-memory formatting, encoding, timestamp, and hash operations.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `sources: [{ "type": "clipboard", "intervalMs": 2000 }]` | Source | Subscribes to system clipboard plain-text metadata |
| `${$clipboard.preview} / ${$clipboard.kindLabel} / ${$clipboard.length} / ${$clipboard.lines}` | Token | Single-line preview, content type label (JSON / JWT / Unicode escape / URL / timestamp / Base64), char length, and line count |
| `{ "type": "text.transform", "format": "jsonPretty", "key": "output", "mode": "copy" }` | Action | Transforms text in-memory into `state.<key>` with optional clipboard copy |
| `jsonPretty / jsonMinify / urlEncode / base64Encode / timestampToDate / uuid / sha256` | Enum | 25 built-in deterministic text transform formats |
| `jwtDecode / unicodeEscape / unicodeUnescape / jsonEscape / jsonUnescape / uuidNoDash / jsonPretty4 / dateToTimestampMs` | Enum | Offline JWT decode with exp/nbf diagnostics (`${$transform.jwtState}`), CJK Unicode escape round-trips, JSON string escapes, and no-dash UUIDs |
| `${jwtdecode($clipboard.text)} / ${unicodeunescape(state.draft)} / ${uuid('upper')}` | Function | The same operators are callable inline inside string interpolation expressions (offline, zero-reflection); failures return an empty string |

```json
{
  "state": { "input": "", "output": "" },
  "sources": [{ "type": "clipboard", "intervalMs": 2000 }],
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      {
        "type": "Card",
        "tone": "subtle",
        "children": [
          { "type": "KeyValueRow", "label": "Clipboard (${$clipboard.kindLabel})", "value": "${$clipboard.length} chars" },
          { "type": "Text", "text": "${$clipboard.preview}", "style": "caption", "color": "secondary", "maxLines": 2 }
        ]
      },
      { "type": "TextArea", "bind": "state.input", "placeholder": "Enter text to process (leave empty to use the clipboard)…" },
      {
        "type": "Grid",
        "columns": "*,*,*",
        "spacing": 6,
        "children": [
          { "type": "Button", "text": "Format JSON", "onClick": { "type": "text.transform", "format": "jsonPretty", "text": "${state.input != '' ? state.input : $clipboard.text}", "key": "output", "mode": "copy" } },
          { "type": "Button", "text": "Base64 Encode", "onClick": { "type": "text.transform", "format": "base64Encode", "text": "${state.input != '' ? state.input : $clipboard.text}", "key": "output", "mode": "copy" } },
          { "type": "Button", "text": "Timestamp Convert", "onClick": { "type": "text.transform", "format": "timestampToDate", "text": "${state.input != '' ? state.input : $clipboard.text}", "key": "output", "mode": "copy" } }
        ]
      },
      { "type": "Text", "text": "${state.output}", "style": "mono", "maxLines": 6, "visible": "${state.output != ''}" }
    ]
  }
}
```

### 🚀 Quick Launcher (`@quick-launcher`)
Opens standard user folders, whitelisted app URI protocols, and local files/folders safely.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `downloads / desktop / documents / pictures / userprofile` | Folder | Opens standard user folders via `targetId` |
| `vscode:// / cursor:// / obsidian:// / ms-screenclip: / ms-calculator:` | URI | Invokes whitelisted app and Windows utility URI schemes |
| `{ "type": "launcher.open", "path": "D:/Projects" }` | Action | Opens an existing local folder or file with consent protection |

```json
{
  "view": {
    "type": "Grid",
    "columns": "*,*",
    "spacing": 8,
    "children": [
      { "type": "Button", "text": "Downloads", "icon": "\uE896", "onClick": { "type": "launcher.open", "targetId": "downloads" } },
      { "type": "Button", "text": "Documents", "icon": "\uE8A5", "onClick": { "type": "launcher.open", "targetId": "documents" } },
      { "type": "Button", "text": "Screenshot", "icon": "\uE70F", "onClick": { "type": "launcher.open", "targetId": "ms-screenclip:" } },
      { "type": "Button", "text": "Calculator", "icon": "\uE8EF", "onClick": { "type": "launcher.open", "targetId": "ms-calculator:" } }
    ]
  }
}
```

### 🔄 File Converter (`@file-transform`)
Offline local image converter (PNG/JPG/WebP/ICO + resize) and CSV/JSON/Markdown/SHA256 file processor.
- **Required modules**: `drop-zone`

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "file.transform", "path": "${$drop.path}", "format": "webp" }` | Action | Non-destructively converts input file and populates `$transform.*` |
| `png / jpg / webp / ico / csvToJson / jsonToCsv / mdToHtml / sha256` | Enum | Supported image, structured data, and checksum formats |
| `${$transform.outputPath} / ${$transform.outputName} / ${$transform.sizeText} / ${$transform.resultText}` | Token | Output path, file name, formatted size, and result/hash text |

```json
{
  "state": { "format": "webp" },
  "collections": { "outputs": { "maxItems": 30 } },
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      {
        "type": "Segmented",
        "bind": "state.format",
        "options": [
          { "value": "png", "label": "PNG" },
          { "value": "jpg", "label": "JPG" },
          { "value": "webp", "label": "WebP" },
          { "value": "ico", "label": "ICO" }
        ]
      },
      {
        "type": "DropZone",
        "icon": "\uE8B9",
        "title": "Drop an image or click to browse",
        "subtitle": "Auto-converts to ${state.format} and saves next to the original",
        "onDrop": [
          {
            "type": "file.transform",
            "path": "${$drop.path}",
            "format": "${state.format}",
            "then": [
              { "type": "collection.prepend", "collection": "outputs", "item": { "name": "${$transform.outputName}", "path": "${$transform.outputPath}" } }
            ]
          }
        ]
      },
      {
        "type": "List",
        "items": "outputs",
        "itemTemplate": { "type": "FileChip", "fileName": "${$item.name}", "filePath": "${$item.path}" }
      }
    ]
  }
}
```

### ⚙️ System Toggles & Settings (`@system-control`)
Toggles Wi-Fi, Bluetooth, Keep-Awake, locks workstation, empties Recycle Bin, or opens Windows Settings pages.
- **Required modules**: `device-state`

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `radio.wifiToggle / radio.bluetoothToggle` | Command | Toggles Wi-Fi or Bluetooth radio with ms-settings fallback |
| `power.keepAwakeToggle / power.lock / recycleBin.empty` | Command | Toggles Keep-Awake, locks PC, or empties Recycle Bin |
| `{ "type": "system.openSetting", "targetId": "display" }` | Action | Opens whitelisted Windows Settings page or Task Manager |

```json
{
  "sources": [{ "type": "deviceState", "intervalMs": 3000 }],
  "view": {
    "type": "Stack",
    "spacing": 8,
    "children": [
      {
        "type": "Grid",
        "columns": "*,*",
        "spacing": 8,
        "children": [
          { "type": "ControlTile", "icon": "\uE701", "title": "Wi-Fi", "subtitle": "${$device.wifiStatus}", "value": "${$device.wifiEnabled}", "onClick": { "type": "system.control", "targetId": "radio.wifiToggle" } },
          { "type": "ControlTile", "icon": "\uEA80", "title": "Keep Awake", "subtitle": "${$device.keepAwakeStatus}", "value": "${$device.keepAwake}", "onClick": { "type": "system.control", "targetId": "power.keepAwakeToggle" } }
        ]
      },
      { "type": "Slider", "title": "System Volume", "value": "${$device.volume}", "min": 0, "max": 100, "step": 2, "unit": "%", "onChange": { "type": "system.control", "targetId": "volume.set", "value": "${$value}" } }
    ]
  }
}
```

### ✨ In-Widget AI Task (`@ai-run`)
Runs structured AI prompts inside the widget and maps JSON fields into state or collections.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "ai.run", "prompt": "...", "collection": "items", "fieldMap": {...} }` | Action | Runs single-flight structured AI task with status tracking and input preservation |
| `${state.aiStatus} / ${state.aiError} / ${state.aiUpdatedAt}` | Token | Execution status, error message, and last completion time |

```json
{
  "type": "Button",
  "text": "Break down a to-do",
  "icon": "\uE945",
  "variant": "accent",
  "onClick": {
    "type": "ai.run",
    "guard": "${state.draft != ''}",
    "prompt": "Break the following content into actionable to-do items (items: title):
${state.draft}",
    "collection": "tasks",
    "itemsPath": "items",
    "fieldMap": { "title": "title" },
    "then": [{ "type": "state.set", "key": "draft", "value": "" }]
  }
}
```

### 🔔 Notifications & Toasts (`@notifications-reminders`)
Sends Windows 11 Action Center toast notifications or subtle in-widget feedback banners.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "type": "reminder.notify", "text": "标题", "message": "内容" }` | Action | Sends a native Windows 11 Action Center notification |
| `{ "type": "toast.show", "message": "已保存" }` | Action | Shows a lightweight in-widget feedback banner |

```json
{
  "type": "Button",
  "text": "Send a test reminder",
  "icon": "\uEA8F",
  "onClick": { "type": "reminder.notify", "text": "Scheduled reminder", "message": "Your preset reminder time is up." }
}
```

### ⚡ Private Sandboxed Script (`@script-sandbox`)
Runs an isolated offline ES2023 module (logic.js) in QuickJS for custom algorithms, state machines, and API payload parsing.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `script: { "entry": "logic.js", "tickIntervalMs": 0 }` | Manifest | Declares the isolated QuickJS ES2023 script entry and optional tick interval (>= 250ms, auto-hibernates when hidden) |
| `{ "type": "script.run", "fn": "step", "arg": "1" }` | Action | Invokes an exported synchronous function in logic.js with an optional argument |
| `${$computed.<key>}` | Token | Binds an ephemeral script-computed scalar or JSON array (never persisted to store.json; supports List, BarList, and Sparkline) |
| `onInit(ctx) | onSourceData(ctx, id, raw) | onTick(ctx)` | Hook | Lifecycle hooks: cold-start state projection, raw HTTP/RSS payload transformation, and visibility-aware tick |

```json
{
  "script": { "entry": "logic.js", "tickIntervalMs": 0 },
  "capsule": {
    "title": "Focus Score",
    "summary": "${$computed.summary}",
    "badge": "${$computed.score}",
    "primaryAction": {
      "icon": "\uE710",
      "tooltip": "Log session",
      "onClick": { "type": "script.run", "fn": "recordSession", "arg": "25" }
    }
  }
}
```

## Config & Security

### 🔐 Encrypted API Secrets (`@secret-vault`)
Stores API keys encrypted via Windows DPAPI; automatically excluded when exporting `.dbbox` packages.
- **Required modules**: `http-and-rss-feeds`

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `settings: [{ "key": "apiKey", "type": "secret", "label": "API Key" }]` | Setting | Declares a DPAPI-encrypted secret setting with setup prompt |
| `headers: { "Authorization": "Bearer ${$secrets.apiKey}" }` | Header | Injects secret into same-origin `httpJson` request headers |

```json
{
  "settings": [
    { "key": "apiKey", "type": "secret", "label": "SiliconFlow API Key" }
  ],
  "sources": [
    {
      "id": "balance",
      "type": "httpJson",
      "url": "https://api.siliconflow.cn/v1/user/info",
      "headers": { "Authorization": "Bearer ${$secrets.apiKey}" },
      "intervalMs": 300000,
      "stateMap": { "balance": "$.data.totalBalance", "name": "$.data.name" }
    }
  ],
  "view": {
    "type": "Card",
    "tone": "subtle",
    "children": [
      { "type": "Text", "text": "Available balance: ¥ ${state.balance ?? '--'}", "style": "title" }
    ]
  }
}
```

### 🛠️ Widget Settings (`@widget-settings`)
Adds user-configurable choice, toggle, text, and numeric options to the widget context menu.

| Signature / Token / Property | Kind | Specification |
| :--- | :--- | :--- |
| `{ "key": "city", "type": "text", "label": "城市", "default": "北京" }` | Setting | Supports choice, toggle, text, number, and secret setting types |
| `${$settings.city}` | Token | Reads the user's configured setting value in views or sources |

```json
{
  "settings": [
    {
      "key": "modules",
      "type": "moduleList",
      "label": "${$i18n.setModules}",
      "default": "overview:1,chart:1",
      "options": [
        { "value": "overview", "label": "${$i18n.modOverview}" },
        { "value": "chart", "label": "${$i18n.modChart}" }
      ]
    },
    {
      "key": "dailyGoal",
      "type": "number",
      "label": "${$i18n.setGoal}",
      "default": "2000"
    },
    {
      "key": "compactMode",
      "type": "toggle",
      "label": "${$i18n.setCompact}",
      "default": "false"
    }
  ],
  "view": {
    "type": "Stack",
    "padding": "12,10,12,12",
    "children": [
      {
        "type": "ModuleStack",
        "bind": "settings.modules",
        "spacing": 8,
        "children": [
          {
            "id": "overview",
            "type": "StatCard",
            "title": "${$i18n.todayTitle}",
            "value": "${state.todayCount}",
            "progress": "${state.todayCount * 100 / $settings.dailyGoal}"
          },
          {
            "id": "chart",
            "type": "Card",
            "tone": "subtle",
            "visible": "${$settings.compactMode != 'true'}",
            "children": []
          }
        ]
      }
    ]
  }
}
```

## Expression Syntax & Context Variables
- **Operators**: Wrap expressions in `${...}`; supports null-coalescing `??`, ternary `? :`, comparisons `== != > >= < <=`, logical `&& || !`, and numeric arithmetic.
- **Event Payload `${$value}`**: Inside `onChange` / `onToggle` of `Slider`, `Toggle`, `Segmented`, `Select`, `CheckBox`, and `NumberBox`, `${$value}` resolves to the control's new value.
- **Timezone Function `tz('<zoneId>', '<format>')`**: Supports IANA/Windows timezone IDs (`Asia/Shanghai`, `America/New_York`, `Europe/London`, `Asia/Tokyo`), UTC offsets (`UTC+8`, `UTC-5`), and standard format patterns (`HH:mm:ss`).

