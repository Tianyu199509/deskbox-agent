# DeskBox Custom Widget Capability Registry (API Reference — Flat `schemaVersion: 1`)

> Auto-generated from DeskBox's Single-Source-of-Truth `capability-registry.json` (**12 Domain Capability Packs** / **37 atomic capabilities**).
> All examples use the canonical pure-flat `schemaVersion: 1` Element Graph (`root` + `elements` + `popovers` + semantic icon names). When connected to DeskBox MCP, query live contracts on demand via `deskbox_get_capability_spec`.

## 12 Domain Capability Packs

Pass any Domain Pack ID or atomic capability slug to `deskbox_get_capability_spec` (`capabilityId`) for compact runtime contracts and Golden JSON snippets:

| Domain Pack ID | Title | Atomic Capabilities | Scope |
| :--- | :--- | :--- | :--- |
| `layout-and-overlays` | Layout, Overlays & Shells / 布局容器、弹窗与壳层 | `visual-containers`, `popover-and-markdown`, `rich-controls-and-shells` | Stack/Grid/ZStack/Card/Tabs/SelectorBar/SplitView/FlipView/Expander/ModuleStack/Popover/Markdown/RichText/CodeBlock/InfoBar/TeachingTip |
| `lists-and-collections` | Lists, Collections & DropZone / 集合存储、列表与拖放 | `collections-lists`, `drop-zone` | collections CRUD/filter/reorder/inlineEdit/exportMarkdown, List, ItemsGrid, DropZone, FileChip |
| `forms-and-inputs` | Forms, Inputs & Control Tiles / 表单输入、滑块与磁贴控件 | `forms-inputs`, `advanced-inputs-and-styling`, `control-tile` | Input/TextArea/AutoSuggestInput/Select/Segmented/RadioGroup/CheckBox/Toggle/Slider/NumberBox/Rating/DatePicker/TimePicker/ColorPicker/ControlTile |
| `charts-and-canvas` | Charts, Gauges & Vector Canvas / 图表、仪表盘与矢量画布 | `micro-charts`, `data-charts-and-tables`, `vector-canvas` | Canvas 2.0 interactive vector surface, Chart(line/bar/area), DonutChart, Table, Sparkline, BarList, RingGauge, RadialGauge, HeatmapGrid, StatCard |
| `calendar-and-time` | Calendar, Clock, Countdown & Pomodoro / 日历、世界时钟、倒数日与番茄钟 | `calendar`, `calendar-grid`, `world-clock`, `countdown`, `pomodoro` | CalendarGrid, calendar lunar/festivals, clock tz(), countdown milestones, pomodoro timer |
| `local-files-and-cli` | Local Files, Transforms, Launcher & CLI / 本地文件读写、转换、启动与命令行 | `local-files-and-commands`, `file-transform`, `quick-launcher` | fileText, localFolder, file.writeText(relative path+onComplete), file.listDir/manage/open/reveal/pick/transform, text.transform, launcher.open, command/command.run |
| `network-and-feeds` | HTTP, RSS, Weather & AI Micro-Tasks / 网络接口、RSS、天气与 AI 微任务 | `http-and-rss-feeds`, `interactive-http`, `weather`, `ai-run`, `ai-monitor` | httpJson, rss, http.request, weather forecast, ai.run embedded AI micro-tasks, aiMonitor quota |
| `system-and-device` | System Metrics, Drives & Device Controls / 系统遥测、磁盘、设备状态与控制 | `system-metrics`, `storage-drives`, `device-state`, `system-control`, `display-and-audio` | systemMetrics($sys.*), storageDrives($drives.*), deviceState($device.*), system.control, system.openSetting, volume/brightness controls |
| `media-and-audio` | Media Player, Audio & Now Playing / 音视频播放、白噪音与系统音乐 | `native-media-and-audio`, `music-now-playing` | MediaPlayer, audio.play/pause/stop/setVolume/cue (white/pink/brown/rain noise), music SMTC now-playing |
| `productivity-and-workspace` | Todo, Clipboard & Notifications / 待办联动、剪贴板与通知提醒 | `todo-progress-summary`, `clipboard-workspace`, `notifications-reminders` | todo sync & actions, clipboard text/image capture, reminder.notify system toasts & toast.show |
| `script-sandbox` | QuickJS ES2023 Script Sandbox / QuickJS ES2023 脚本沙箱 | `script-sandbox` | logic.js (onInit/onTick/onSourceData/script.run), ctx.state/computed/collections/ui/env/dispatch, async job callbacks |
| `settings-and-secrets` | Widget Settings & DPAPI Secret Vault / 组件配置面板与加密密钥库 | `widget-settings`, `secret-vault` | settings (toggle/choice/text/number/file/folder/moduleList/secret), ${$settings.*}, ${$secrets.*} DPAPI secret vault |

## Data Sources (`DataSource`)

### `weather` — 🌤️ Weather Forecast / 天气预报

- **Summary**: Zero-key weather service providing live conditions, UV/wind metrics, and a 7-day forecast.
- **Expression Namespaces**: `$weather.`
- **Sources / Actions**: `weather`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "weather", "targetCollection": "forecast" }` | `Source` | Declares built-in weather source; inherits host city when omitted |
| `${$weather.city} / ${$weather.tempText} / ${$weather.condition}` | `Token` | City name, formatted temperature (22°C), and condition |
| `${$weather.icon} / ${$weather.rangeText} / ${$weather.feelsLikeText}` | `Token` | Weather icon, daily temperature range, and feels-like text |
| `${$weather.humidity} / ${$weather.wind} / ${$weather.precipProb} / ${$weather.uv}` | `Token` | Humidity, wind speed, precipitation probability, and UV index |
| `$item.weekday / $item.icon / $item.low / $item.high` | `Collection` | 7-day forecast item fields in collections.forecast |

**Golden JSON Snippet:**

```json
{
  "settings": [
    {
      "key": "city",
      "type": "text",
      "label": "城市",
      "default": "北京"
    }
  ],
  "sources": [
    {
      "type": "weather",
      "city": "${$settings.city}",
      "targetCollection": "forecast"
    }
  ],
  "collections": {
    "forecast": {
      "maxItems": 7
    }
  },
  "root": "weather_card",
  "elements": {
    "weather_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "weather_headline",
        "weather_details"
      ]
    },
    "weather_headline": {
      "type": "Text",
      "text": "${$weather.icon} ${$weather.city} · ${$weather.tempText}",
      "style": "title"
    },
    "weather_details": {
      "type": "Text",
      "text": "${$weather.condition}  ${$weather.rangeText} · 湿度 ${$weather.humidity}",
      "style": "caption",
      "color": "secondary"
    }
  }
}
```

### `system-metrics` — 📊 Hardware Monitor / 硬件监控

- **Summary**: Low-overhead telemetry for CPU, RAM, GPU/VRAM, Disk, Network speed, Battery, and Top Processes.
- **Expression Namespaces**: `$sys.`
- **Sources / Actions**: `systemMetrics`
- **UI Elements**: `StatCard`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "systemMetrics", "intervalMs": 2000 }` | `Source` | Subscribes to live hardware telemetry |
| `${$sys.cpu.percent} / ${$sys.memory.percent} / ${$sys.memory.summaryText}` | `Token` | CPU %, RAM %, and formatted memory summary |
| `${$sys.gpu.name} / ${$sys.gpu.percent} / ${$sys.gpu.vramSummary}` | `Token` | GPU name, core utilization %, and VRAM summary |
| `${$sys.net.downText} / ${$sys.net.upText} / ${$sys.net.summaryText}` | `Token` | Live download/upload network speed |
| `${$sys.disk.percent} / ${$sys.disk.freeGb} / ${$sys.battery.statusText} / ${$sys.uptime.text}` | `Token` | Primary disk %, free GB, battery status, and uptime |
| `StatCard / ${$sys.topProcesses}` | `Component` | Built-in KPI card with sparkline plus virtual top-process collection for BarList / List |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "systemMetrics",
      "intervalMs": 2000
    }
  ],
  "root": "metrics_root",
  "elements": {
    "metrics_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "kpi_grid",
        "gpu_card"
      ]
    },
    "kpi_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "cpu_stat",
        "ram_stat"
      ]
    },
    "cpu_stat": {
      "type": "StatCard",
      "title": "CPU",
      "value": "${$sys.cpu.percent}",
      "unit": "%",
      "progress": "${$sys.cpu.percent}",
      "sparkline": "cpu",
      "color": "accent"
    },
    "ram_stat": {
      "type": "StatCard",
      "title": "RAM",
      "value": "${$sys.memory.percent}",
      "unit": "%",
      "subtitle": "${$sys.memory.compactText}",
      "progress": "${$sys.memory.percent}",
      "sparkline": "memory",
      "color": "cyan"
    },
    "gpu_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "gpu_row"
      ]
    },
    "gpu_row": {
      "type": "ProgressRow",
      "title": "${$sys.gpu.name}",
      "subtitle": "${$sys.gpu.vramSummary}",
      "value": "${$sys.gpu.percent}%",
      "progress": "${$sys.gpu.percent}"
    }
  }
}
```

### `storage-drives` — 💾 Storage Drives / 磁盘空间

- **Summary**: Lists all mounted local drives with volume label, used percentage, and free/total GB.
- **Expression Namespaces**: `$drives.`
- **Sources / Actions**: `storageDrives`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "storageDrives", "targetCollection": "drives" }` | `Source` | Polls mounted local volumes into targetCollection |
| `${$drives.count} / ${$drives.summary} / ${$drives.primaryPercent}` | `Token` | Mounted drive count, summary string, and primary drive % |
| `$item.name / $item.label / $item.percent / $item.freeGb / $item.summary` | `Collection` | Per-drive fields in collections.drives |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "storageDrives",
      "targetCollection": "drives",
      "intervalMs": 15000
    }
  ],
  "collections": {
    "drives": {
      "maxItems": 16
    }
  },
  "root": "drives_card",
  "elements": {
    "drives_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "drives_bars"
      ]
    },
    "drives_bars": {
      "type": "BarList",
      "collection": "drives",
      "titleField": "title",
      "valueField": "percent",
      "subtitleField": "summary",
      "unit": "%",
      "color": "accent"
    }
  }
}
```

### `world-clock` — 🌍 World Clock / 世界时钟

- **Summary**: Provides 1-second UTC/Unix clock tokens plus timezone helpers: `tz(zoneId, format, offsetHours)`, `tzDiffLabel()`, `tzWorkState()`, and `tzCity()`.
- **Expression Namespaces**: `$clock.`, `tz(`, `tzDiffLabel(`, `tzWorkState(`, `tzCity(`
- **Sources / Actions**: `clock`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "clock", "intervalMs": 1000 }` | `Source` | Enables live clock tick updates |
| `${tz('America/New_York', 'HH:mm')} / ${tz('Europe/London', 'HH:mm:ss')}` | `Function` | Formats current time in any IANA timezone or UTC offset |
| `${tz('Europe/London', 'HH:mm', 6)}` | `Function` | Offset overload shifts now by N hours (0.5 steps supported) for meeting scrubbers; DST stays accurate |
| `${tzDiffLabel('Europe/London', 0)}` | `Function` | Localized diff + cross-day label such as "behind 7h · yesterday" across 13 locales |
| `${tzWorkState('Asia/Tokyo', '09-18', 0)}` | `Function` | Returns work / edge / sleep for the zone's wall clock given a work window, powering status lights |
| `${tzCity('Asia/Shanghai')}` | `Function` | Localized display names for 24 built-in business cities across 13 locales |
| `${$clock.fullTime} / ${$clock.utcTime} / ${$clock.localOffset} / ${$clock.unixSeconds}` | `Token` | Local time, UTC time, UTC offset, and Unix seconds |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "clock",
      "intervalMs": 1000
    }
  ],
  "root": "clock_grid",
  "elements": {
    "clock_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "beijing_card",
        "newyork_card",
        "london_card",
        "tokyo_card"
      ]
    },
    "beijing_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "beijing_label",
        "beijing_time"
      ]
    },
    "beijing_label": {
      "type": "Text",
      "text": "北京 (UTC+8)",
      "style": "caption",
      "color": "secondary"
    },
    "beijing_time": {
      "type": "Text",
      "text": "${tz('Asia/Shanghai', 'HH:mm:ss')}",
      "style": "title"
    },
    "newyork_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "newyork_label",
        "newyork_time"
      ]
    },
    "newyork_label": {
      "type": "Text",
      "text": "纽约 (EST/EDT)",
      "style": "caption",
      "color": "secondary"
    },
    "newyork_time": {
      "type": "Text",
      "text": "${tz('America/New_York', 'HH:mm:ss')}",
      "style": "title"
    },
    "london_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "london_label",
        "london_time"
      ]
    },
    "london_label": {
      "type": "Text",
      "text": "伦敦 (GMT/BST)",
      "style": "caption",
      "color": "secondary"
    },
    "london_time": {
      "type": "Text",
      "text": "${tz('Europe/London', 'HH:mm:ss')}",
      "style": "title"
    },
    "tokyo_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "tokyo_label",
        "tokyo_time"
      ]
    },
    "tokyo_label": {
      "type": "Text",
      "text": "东京 (JST)",
      "style": "caption",
      "color": "secondary"
    },
    "tokyo_time": {
      "type": "Text",
      "text": "${tz('Asia/Tokyo', 'HH:mm:ss', 6)} · ${tzDiffLabel('Asia/Tokyo', 6)} · ${tzWorkState('Asia/Tokyo', '09-18', 6)}",
      "style": "title"
    }
  }
}
```

### `ai-monitor` — 🤖 AI Quota Monitor / AI 用量监控

- **Summary**: Aggregates local Claude Code / Codex token logs and queries cloud provider balances.
- **Expression Namespaces**: `$ai.`
- **Sources / Actions**: `aiMonitor`, `ai.refresh`, `ai.selectProvider`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "aiMonitor", "intervalMs": 60000 }` | `Source` | Enables local token log parser and balance polling |
| `${$ai.todayTokens} / ${$ai.todayCost} / ${$ai.monthTokens} / ${$ai.monthCost}` | `Token` | Daily and monthly token counts and estimated cost |
| `${$ai.focus.name} / ${$ai.focus.value} / ${$ai.focus.subtext}` | `Token` | Focused provider name, balance value, and subtitle |
| `${$ai.providers} / ${$ai.daily28} / ${$ai.dailyTrend} / __ai_credentials` | `Collection` | Virtual provider ledger, 28-day activity capsules, 14-day trend collections, plus built-in DPAPI credential flyout |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "aiMonitor",
      "intervalMs": 60000
    }
  ],
  "root": "ai_monitor_root",
  "elements": {
    "ai_monitor_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "focus_card",
        "tokens_stat",
        "providers_bars"
      ]
    },
    "focus_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "focus_progress_row"
      ]
    },
    "focus_progress_row": {
      "type": "ProgressRow",
      "title": "${$ai.focus.name}",
      "subtitle": "${$ai.focus.subtext}",
      "value": "${$ai.focus.value}",
      "progress": "${$ai.focus.progress}"
    },
    "tokens_stat": {
      "type": "StatCard",
      "title": "Tokens",
      "value": "${$ai.todayTokens}",
      "subtitle": "${$ai.todayCost}"
    },
    "providers_bars": {
      "type": "BarList",
      "items": "${$ai.providers}",
      "titleField": "name",
      "valueField": "percent",
      "subtitleField": "value",
      "unit": "%"
    }
  }
}
```

### `calendar` — 🗓️ Lunar & Calendar / 日历与节气

- **Summary**: Built-in Gregorian date, Chinese Lunar Ganzhi, solar terms, and festival tokens.
- **Expression Namespaces**: `$calendar.`
- **Sources / Actions**: `calendar`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `${$calendar.date} / ${$calendar.monthTitle} / ${$calendar.weekday}` | `Token` | Current ISO date, month header, and weekday |
| `${$calendar.lunar} / ${$calendar.lunarTitle} / ${$calendar.festival}` | `Token` | Lunar day, Ganzhi year/month, and festival/solar-term |
| `${$calendar.subtitle} / ${$calendar.weekOfYear}` | `Token` | Smart subtitle (festival or lunar) and ISO week number |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "calendar",
      "intervalMs": 60000
    }
  ],
  "root": "calendar_header",
  "elements": {
    "calendar_header": {
      "type": "Stack",
      "spacing": 2,
      "children": [
        "gregorian_text",
        "lunar_text"
      ]
    },
    "gregorian_text": {
      "type": "Text",
      "text": "${$calendar.monthTitle} · ${$calendar.weekday}",
      "style": "subtitle"
    },
    "lunar_text": {
      "type": "Text",
      "text": "${$calendar.lunarTitle} ${$calendar.festival}",
      "style": "caption",
      "color": "accent"
    }
  }
}
```

### `countdown` — 🎂 Countdowns / 纪念日与倒数日

- **Summary**: Solar & Lunar recurring birthday/anniversary countdown engine with Windows Toast reminders.
- **Expression Namespaces**: `$countdown.`
- **Sources / Actions**: `countdown`, `countdown.upsert`, `countdown.pin`, `countdown.delete`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "countdown", "intervalMs": 60000 }` | `Source` | Enables recurring countdown calculation and daily reminders |
| `${$countdown.items} / ${$countdown.progressBars} / countdown.upsert` | `Collection` | Virtual countdown & time-progress collections plus declarative add/edit action |
| `${$countdown.hero.title} / ${$countdown.hero.days} / ${$countdown.hero.subtitle}` | `Token` | Pinned event title, remaining days, and date subtitle |
| `${$countdown.work.*} / ${$countdown.holiday.*}` | `Token` | Work-hour progress (BeforeWork/Working/AfterWork) and next China statutory holiday countdown (built-in 2025-2027 schedule) |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "countdown",
      "intervalMs": 60000
    }
  ],
  "collections": {
    "events": {
      "maxItems": 100
    }
  },
  "root": "countdown_root",
  "elements": {
    "countdown_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "hero_card",
        "events_list"
      ]
    },
    "hero_card": {
      "type": "Card",
      "tone": "accent",
      "children": [
        "hero_title",
        "hero_subtitle"
      ]
    },
    "hero_title": {
      "type": "Text",
      "text": "${$countdown.hero.title} · ${$countdown.hero.days}d",
      "style": "title"
    },
    "hero_subtitle": {
      "type": "Text",
      "text": "${$countdown.hero.subtitle}",
      "style": "caption",
      "color": "secondary"
    },
    "events_list": {
      "type": "List",
      "items": "${$countdown.items}",
      "itemTemplate": "event_row"
    },
    "event_row": {
      "type": "KeyValueRow",
      "label": "${$item.emoji} ${$item.title}",
      "value": "${$item.days}d"
    }
  }
}
```

### `pomodoro` — 🍅 Pomodoro & Sedentary Guard / 番茄专注与久坐守护

- **Summary**: Drift-free Focus / Break timer plus a sedentary guardian mode with keyboard/mouse idle auto-reset and rotating micro-break reminders.
- **Expression Namespaces**: `$pomodoro.`
- **Sources / Actions**: `pomodoro`, `pomodoro.toggle`, `pomodoro.reset`, `pomodoro.skip`, `pomodoro.sedentaryConfirm`, `pomodoro.sedentarySnooze`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "pomodoro", "intervalMs": 1000 }` | `Source` | Enables 1-second Pomodoro timer sync |
| `RadialGauge + ${$pomodoro.remainingText} / ${$pomodoro.progressPercent}` | `Component` | Compose custom focus & sedentary guardian dials with RadialGauge and $pomodoro.* tokens |
| `pomodoro.toggle / pomodoro.reset / pomodoro.skip / pomodoro.extend` | `Action` | Start/pause, reset, skip phase, or extend session |
| `pomodoro.sedentaryConfirm / pomodoro.sedentarySnooze` | `Action` | Confirm you stood up and restart the round, or snooze the sedentary reminder by 15 minutes |
| `${$pomodoro.mode} / ${$pomodoro.satMinutes} / ${$pomodoro.microAction} / ${$pomodoro.healthSummary}` | `Token` | Active rhythm mode, continuous sitting minutes, rotating micro-break tip, and today's health summary |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "pomodoro",
      "intervalMs": 1000
    }
  ],
  "root": "pomodoro_card",
  "elements": {
    "pomodoro_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "pomodoro_gauge",
        "pomodoro_toggle_btn"
      ]
    },
    "pomodoro_gauge": {
      "type": "RadialGauge",
      "value": "${$pomodoro.progressPercent}",
      "max": 100,
      "title": "${$pomodoro.remainingText}",
      "subtitle": "${$pomodoro.phaseLabel}",
      "size": 148,
      "color": "accent"
    },
    "pomodoro_toggle_btn": {
      "type": "Button",
      "text": "${$pomodoro.primaryActionText}",
      "variant": "accent",
      "onClick": {
        "type": "pomodoro.toggle"
      }
    }
  }
}
```

### `device-state` — 🎛️ Device & Media State / 设备与媒体状态

- **Summary**: Reads live volume, brightness, Wi-Fi/Bluetooth, SMTC media track/cover, and Keep-Awake state.
- **Expression Namespaces**: `$device.`
- **Sources / Actions**: `deviceState`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "deviceState", "intervalMs": 3000 }` | `Source` | Subscribes to live device & SMTC media state |
| `${$device.volume} / ${$device.muted} / ${$device.audioDeviceName}` | `Token` | Master volume 0-100, mute flag, and audio output device |
| `${$device.brightness} / ${$device.brightnessText}` | `Token` | Display brightness 0-100 and status text |
| `${$device.wifiEnabled} / ${$device.bluetoothEnabled} / ${$device.keepAwake}` | `Token` | Wi-Fi, Bluetooth, and Keep-Awake toggle states |
| `${$device.mediaTitle} / ${$device.mediaArtist} / ${$device.mediaToggleIcon} / ${$device.mediaCover}` | `Token` | SMTC media title, artist, play/pause glyph, and cover path |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "deviceState",
      "intervalMs": 3000
    }
  ],
  "root": "media_card",
  "elements": {
    "media_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "media_row"
      ]
    },
    "media_row": {
      "type": "Grid",
      "columns": "Auto,*,Auto,Auto,Auto",
      "spacing": 8,
      "children": [
        "media_cover",
        "media_meta",
        "prev_track_btn",
        "play_pause_btn",
        "next_track_btn"
      ]
    },
    "media_cover": {
      "type": "Image",
      "column": 0,
      "src": "${$device.mediaCover}",
      "width": 36,
      "height": 36,
      "cornerRadius": 6,
      "when": "${$device.mediaCover != ''}"
    },
    "media_meta": {
      "type": "Stack",
      "column": 1,
      "spacing": 2,
      "children": [
        "media_title",
        "media_artist"
      ]
    },
    "media_title": {
      "type": "Text",
      "text": "${$device.mediaTitle}",
      "style": "bodyStrong",
      "maxLines": 1
    },
    "media_artist": {
      "type": "Text",
      "text": "${$device.mediaArtist != '' ? $device.mediaArtist : $device.mediaStatus}",
      "style": "caption",
      "color": "secondary",
      "maxLines": 1
    },
    "prev_track_btn": {
      "type": "IconButton",
      "column": 2,
      "icon": "skip-previous",
      "size": 28,
      "onClick": {
        "type": "system.control",
        "targetId": "media.previous"
      }
    },
    "play_pause_btn": {
      "type": "IconButton",
      "column": 3,
      "icon": "${$device.mediaToggleIcon}",
      "size": 28,
      "variant": "accent",
      "onClick": {
        "type": "system.control",
        "targetId": "media.playPause"
      }
    },
    "next_track_btn": {
      "type": "IconButton",
      "column": 4,
      "icon": "skip-next",
      "size": 28,
      "onClick": {
        "type": "system.control",
        "targetId": "media.next"
      }
    }
  }
}
```

### `http-and-rss-feeds` — 🌐 HTTP JSON & RSS / 网络接口与 RSS

- **Summary**: Fetches REST JSON & RSS/Atom feeds with disk caching and optional auth headers.
- **Sources / Actions**: `httpJson`, `rss`, `source.refresh`, `refreshSource`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "rss", "url": "https://...", "targetCollection": "items" }` | `Source` | Parses RSS/Atom feeds into title, summary, link, pubDate |
| `{ "type": "httpJson", "url": "...", "itemsPath": "$.data" }` | `Source` | Fetches JSON APIs with scalar stateMap or array itemsPath/fieldMap |
| `{ "type": "source.refresh", "targetId": "feed" }` | `Action` | Immediately refreshes a specific or all data sources (supports targetId / sourceId) |

**Golden JSON Snippet:**

```json
{
  "collections": {
    "items": {
      "maxItems": 20
    }
  },
  "sources": [
    {
      "id": "zhihu",
      "type": "httpJson",
      "url": "https://news-at.zhihu.com/api/4/news/latest",
      "intervalMs": 600000,
      "targetCollection": "items",
      "itemsPath": "$.stories",
      "fieldMap": {
        "title": "title",
        "url": "url",
        "sub": "hint"
      }
    }
  ],
  "root": "feed_list",
  "elements": {
    "feed_list": {
      "type": "List",
      "items": "items",
      "itemTemplate": "feed_item_btn"
    },
    "feed_item_btn": {
      "type": "Button",
      "variant": "subtle",
      "text": "${$item.rank}. ${$item.title}",
      "onClick": {
        "type": "url.open",
        "url": "${$item.url}"
      }
    }
  }
}
```

### `music-now-playing` — 🎵 Now Playing Media / 正在播放媒体

- **Summary**: Read-only Windows SMTC media session snapshot with track, artist, cover art, progress, and playback status.
- **Expression Namespaces**: `$music.`
- **Sources / Actions**: `music`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `${$music.title} / ${$music.artist} / ${$music.album}` | `Token` | Active track title, artist, and album name (empty when idle) |
| `${$music.isPlaying} / ${$music.hasSession} / ${$music.status}` | `Token` | Boolean playback flag, session availability, and status (`playing` / `paused` / `idle`) |
| `${$music.positionText} / ${$music.durationText} / ${$music.progressPercent} / ${$music.positionSeconds} / ${$music.durationSeconds}` | `Token` | Formatted position (`mm:ss`), duration (`mm:ss`), 0-100 progress percentage, and raw seconds |
| `${$music.coverPath} / ${$music.sourceApp}` | `Token` | Cached local album cover path (bindable to `Image.src`) and source player identifier |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "music",
      "intervalMs": 1000
    }
  ],
  "root": "now_playing_card",
  "elements": {
    "now_playing_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "track_title",
        "track_meta",
        "track_progress"
      ]
    },
    "track_title": {
      "type": "Text",
      "text": "${$music.title ?? 'Idle'}",
      "style": "subtitle",
      "maxLines": 1
    },
    "track_meta": {
      "type": "Text",
      "text": "${$music.artist} · ${$music.positionText} / ${$music.durationText}",
      "style": "caption",
      "color": "secondary"
    },
    "track_progress": {
      "type": "ProgressBar",
      "progress": "${$music.progressPercent}",
      "max": 100,
      "color": "accent"
    }
  }
}
```

### `todo-progress-summary` — ✅ Todo Progress Snapshot / 待办事项快照

- **Summary**: Read-only privacy-safe snapshot of DeskBox native Todo counts, completion rate, overdue count, and active task items.
- **Expression Namespaces**: `$todo.`
- **Sources / Actions**: `todo`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `${$todo.pendingCount} / ${$todo.completedCount} / ${$todo.totalCount}` | `Token` | Pending, completed, and total task counts (excludes deleted items and private notes) |
| `${$todo.todayPendingCount} / ${$todo.overdueCount} / ${$todo.importantPendingCount}` | `Token` | Due-today pending count, overdue count, and starred important pending count |
| `${$todo.completionPercent} / ${$todo.nextTaskTitle} / ${$todo.nextTaskDueText}` | `Token` | 0-100 completion percentage, highest-priority pending task title, and due date text |
| `collections.todos (${$item.title}, ${$item.dueDate}, ${$item.isOverdue})` | `Collection` | Privacy-safe task rows projected into `todos` collection (`title`, `done`, `important`, `dueDate`, `priority`, `listName`) |

**Golden JSON Snippet:**

```json
{
  "collections": {
    "todos": {
      "maxItems": 12
    }
  },
  "sources": [
    {
      "type": "todo",
      "targetCollection": "todos",
      "maxItems": 12,
      "intervalMs": 30000
    }
  ],
  "root": "todo_root",
  "elements": {
    "todo_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "todo_summary_stat",
        "todo_list"
      ]
    },
    "todo_summary_stat": {
      "type": "StatCard",
      "title": "${$todo.summary}",
      "value": "${$todo.completionPercent}%",
      "progress": "${$todo.completionPercent}"
    },
    "todo_list": {
      "type": "List",
      "items": "todos",
      "titleField": "title",
      "subtitleField": "dueDate",
      "itemTemplate": "todo_item_row"
    },
    "todo_item_row": {
      "type": "Grid",
      "columns": "1*,Auto",
      "spacing": 8,
      "children": [
        "todo_item_title",
        "todo_item_due"
      ]
    },
    "todo_item_title": {
      "type": "Text",
      "column": 0,
      "text": "${$item.title}",
      "style": "body",
      "maxLines": 1
    },
    "todo_item_due": {
      "type": "Text",
      "column": 1,
      "text": "${$item.dueDate}",
      "style": "caption",
      "color": "secondary"
    }
  }
}
```

## UI Components (`Component`)

### `visual-containers` — 🗂️ Tabs, Image & Gauges / 分页、图片与仪表

- **Summary**: Provides stateful `Tabs`, rounded `Image`, `RingGauge`, and proportional `BarList` charts.
- **UI Elements**: `Tabs`, `Image`, `RingGauge`, `RadialGauge`, `BarList`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `Tabs` | `Component` | Segmented tab container rendering only the active tab |
| `Image` | `Component` | Renders local attachments, album art, or HTTPS images |
| `RingGauge / BarList` | `Component` | Circular KPI gauge and ranked horizontal proportion bars |

**Golden JSON Snippet:**

```json
{
  "state": {
    "tab": "gauge"
  },
  "sources": [
    {
      "type": "systemMetrics",
      "intervalMs": 2000
    }
  ],
  "root": "metrics_tabs",
  "elements": {
    "metrics_tabs": {
      "type": "Tabs",
      "bind": "state.tab",
      "children": [
        "tab_gauge",
        "tab_proc"
      ]
    },
    "tab_gauge": {
      "type": "Stack",
      "title": "核心负载",
      "value": "gauge",
      "icon": "line-chart",
      "children": [
        "gauge_grid"
      ]
    },
    "gauge_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "cpu_gauge",
        "ram_gauge"
      ]
    },
    "cpu_gauge": {
      "type": "RingGauge",
      "progress": "${$sys.cpu.percent}",
      "title": "CPU",
      "unit": "%",
      "color": "accent"
    },
    "ram_gauge": {
      "type": "RingGauge",
      "progress": "${$sys.memory.percent}",
      "title": "RAM",
      "subtitle": "${$sys.memory.compactText}",
      "unit": "%",
      "color": "cyan"
    },
    "tab_proc": {
      "type": "Stack",
      "title": "高占进程",
      "value": "proc",
      "icon": "list",
      "children": [
        "proc_bars"
      ]
    },
    "proc_bars": {
      "type": "BarList",
      "items": "${$sys.topProcesses}",
      "titleField": "name",
      "valueField": "memoryMb",
      "subtitleField": "memoryText",
      "maxItems": 5,
      "color": "cyan"
    }
  }
}
```

### `calendar-grid` — 📅 Month Calendar Grid / 月历网格

- **Summary**: Interactive 7x6 month matrix with lunar subtitles, date selection, and event dots.
- **Required Dependencies**: `calendar`
- **UI Elements**: `CalendarGrid`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "CalendarGrid", "bind": "state.selectedDate" }` | `Component` | Interactive month grid updating bound state key on click |
| `collection / dateField` | `Property` | Highlights days that have matching records in the collection |

**Golden JSON Snippet:**

```json
{
  "state": {
    "selectedDate": "",
    "draft": ""
  },
  "collections": {
    "events": {
      "maxItems": 200
    }
  },
  "sources": [
    {
      "type": "calendar",
      "intervalMs": 60000
    }
  ],
  "root": "calendar_layout",
  "elements": {
    "calendar_layout": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "month_grid",
        "event_list"
      ]
    },
    "month_grid": {
      "type": "CalendarGrid",
      "bind": "state.selectedDate",
      "collection": "events",
      "dateField": "date"
    },
    "event_list": {
      "type": "List",
      "items": "events",
      "filter": "${state.selectedDate == '' || $item.date == state.selectedDate}",
      "emptyState": {
        "icon": "calendar",
        "title": "当日暂无日程",
        "subtitle": "点击上方日期可切换查看"
      },
      "itemTemplate": "event_row"
    },
    "event_row": {
      "type": "Text",
      "text": "• ${$item.title} (${$item.date})"
    }
  }
}
```

### `drop-zone` — 📥 File Drop Zone / 文件拖放区

- **Summary**: Single/multi-file drop & file/folder picker surface populating `$drop.*` and `ctx.event.files`.
- **Expression Namespaces**: `$drop.`
- **Sources / Actions**: `file.pick`
- **UI Elements**: `DropZone`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "DropZone", "title": "拖入文件", "format": ".png,.jpg", "onDrop": [...] }` | `Component` | File drop & browse surface; passes full `ctx.event.files` batch to `script.run` |
| `${$drop.name} / ${$drop.path} / ${$drop.ext} / ${$drop.sizeText} / ${$drop.sizeBytes} / ${$drop.count} / ${$drop.text}` | `Token` | File name, full path, extension, formatted size, byte count, batch count, and first 8KB text |
| `{ "type": "file.pick", "mode": "file\|folder", "multiple": true, "accept": ".mp4,.mov" }` | `Action` | Opens native single/multi-file or folder picker and chains `then` or `onComplete(ctx, res)` |

**Golden JSON Snippet:**

```json
{
  "state": {
    "targetFormat": "webp"
  },
  "collections": {
    "history": {
      "maxItems": 30
    }
  },
  "root": "image_drop_zone",
  "elements": {
    "image_drop_zone": {
      "type": "DropZone",
      "icon": "gallery",
      "title": "拖入图片或点击选择文件",
      "subtitle": "本地转换为目标格式，源文件保持不变",
      "onDrop": [
        {
          "type": "file.transform",
          "path": "${$drop.path}",
          "format": "${state.targetFormat}",
          "then": [
            {
              "type": "collection.prepend",
              "collection": "history",
              "item": {
                "name": "${$transform.outputName}",
                "path": "${$transform.outputPath}",
                "size": "${$transform.sizeText}"
              }
            }
          ]
        }
      ]
    }
  }
}
```

### `control-tile` — 🎚️ Quick Control Tile / 快捷控制磁贴

- **Summary**: Windows 11 Quick Settings tile with icon, title, live subtitle, and active accent fill.
- **Required Dependencies**: `device-state`, `system-control`
- **UI Elements**: `ControlTile`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "ControlTile", "title": "Wi-Fi", "value": "${$device.wifiEnabled}" }` | `Component` | Displays active accent fill when value is true; dispatches onClick |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "deviceState",
      "intervalMs": 3000
    }
  ],
  "root": "control_grid",
  "elements": {
    "control_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "wifi_tile",
        "bluetooth_tile",
        "keep_awake_tile",
        "recycle_bin_tile"
      ]
    },
    "wifi_tile": {
      "type": "ControlTile",
      "icon": "wifi",
      "title": "Wi-Fi",
      "subtitle": "${$device.wifiStatus}",
      "value": "${$device.wifiEnabled}",
      "onClick": {
        "type": "system.control",
        "targetId": "radio.wifiToggle"
      }
    },
    "bluetooth_tile": {
      "type": "ControlTile",
      "icon": "bluetooth",
      "title": "蓝牙",
      "subtitle": "${$device.bluetoothStatus}",
      "value": "${$device.bluetoothEnabled}",
      "onClick": {
        "type": "system.control",
        "targetId": "radio.bluetoothToggle"
      }
    },
    "keep_awake_tile": {
      "type": "ControlTile",
      "icon": "sun",
      "title": "屏幕常亮",
      "subtitle": "${$device.keepAwakeStatus}",
      "value": "${$device.keepAwake}",
      "onClick": {
        "type": "system.control",
        "targetId": "power.keepAwakeToggle"
      }
    },
    "recycle_bin_tile": {
      "type": "ControlTile",
      "icon": "delete",
      "title": "回收站",
      "subtitle": "${$device.recycleBinStatus}",
      "value": "${$device.recycleBinCount != '0'}",
      "onClick": {
        "type": "system.control",
        "targetId": "recycleBin.empty"
      }
    }
  }
}
```

### `micro-charts` — 📈 Sparkline & Heatmap / 趋势线与热力图

- **Summary**: Vector area sparklines, daily activity heatmaps, and progress indicators.
- **UI Elements**: `Sparkline`, `HeatmapGrid`, `ProgressBar`, `ProgressRing`, `ProgressRow`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `Sparkline` | `Component` | Smooth vector trend line & area bound to a collection |
| `HeatmapGrid` | `Component` | Aggregates daily records into an intensity heatmap |
| `ProgressBar / ProgressRing / ProgressRow` | `Component` | Theme-aware linear and radial progress indicators |

**Golden JSON Snippet:**

```json
{
  "collections": {
    "checkins": {
      "maxItems": 120
    }
  },
  "root": "checkin_heatmap",
  "elements": {
    "checkin_heatmap": {
      "type": "HeatmapGrid",
      "title": "近 28 天记录热力分布",
      "collection": "checkins",
      "valueField": "score",
      "days": 28,
      "color": "success"
    }
  }
}
```

### `forms-inputs` — ⌨️ Inputs & Controls / 表单与交互控件

- **Summary**: Text inputs, selects, segmented pills, checkboxes, toggles, and two-way sliders.
- **Sources / Actions**: `state.set`, `state.toggle`, `state.increment`
- **UI Elements**: `Input`, `TextArea`, `Select`, `Segmented`, `CheckBox`, `Toggle`, `Slider`, `NumberBox`, `IconButton`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `Input / TextArea` | `Component` | Two-way state-bound text input dispatching `onSubmit` |
| `Select / Segmented` | `Component` | Dropdown or segmented pill selector |
| `Slider / Toggle / NumberBox` | `Component` | Dispatches `onChange` immediately with `${$value}` |

**Golden JSON Snippet:**

```json
{
  "state": {
    "draft": ""
  },
  "collections": {
    "items": {
      "maxItems": 100
    }
  },
  "root": "quick_add_row",
  "elements": {
    "quick_add_row": {
      "type": "Grid",
      "columns": "*,Auto",
      "spacing": 6,
      "children": [
        "draft_input",
        "add_item_btn"
      ]
    },
    "draft_input": {
      "type": "Input",
      "column": 0,
      "bind": "state.draft",
      "placeholder": "输入新条目…"
    },
    "add_item_btn": {
      "type": "IconButton",
      "column": 1,
      "icon": "add",
      "variant": "accent",
      "onClick": {
        "type": "collection.prepend",
        "guard": "${state.draft != ''}",
        "collection": "items",
        "item": {
          "title": "${state.draft}"
        },
        "then": [
          {
            "type": "state.set",
            "key": "draft",
            "value": ""
          }
        ]
      }
    }
  }
}
```

### `collections-lists` — 📋 Data Lists / 数据列表

- **Summary**: Persisted record collections with filtering, row hover actions, and Markdown export.
- **Expression Namespaces**: `collections.`, `$item.`
- **Sources / Actions**: `collection.prepend`, `collection.append`, `collection.update`, `collection.remove`, `collection.clear`, `collection.exportMarkdown`
- **UI Elements**: `List`, `FileChip`, `EmptyState`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `collections: { "items": { "maxItems": 200 } }` | `Schema` | Declares persistent collection schema in manifest root |
| `${$item.id} / ${$item.rank} / ${$item.timeText} / ${$item.dateText}` | `Token` | Built-in item ID, 1-based rank, and timestamp tokens |
| `collection.prepend / collection.update / collection.remove / collection.clear` | `Action` | Collection add, update, remove, and clear actions |

**Golden JSON Snippet:**

```json
{
  "collections": {
    "items": {
      "maxItems": 200
    }
  },
  "root": "task_list",
  "elements": {
    "task_list": {
      "type": "List",
      "items": "items",
      "itemTemplate": "task_checkbox"
    },
    "task_checkbox": {
      "type": "CheckBox",
      "value": "${$item.done}",
      "text": "${$item.title}",
      "strikethrough": true,
      "onToggle": {
        "type": "collection.update",
        "collection": "items",
        "targetId": "${$item.id}",
        "item": {
          "done": "${$item.done != true}"
        }
      }
    }
  }
}
```

### `vector-canvas` — 🎨 Vector Canvas & Shapes / 矢量画布与几何图形

- **Summary**: Pure native 2D vector drawing surface supporting static or script-computed shapes, SVG paths, rotation, and hit-test clicks.
- **UI Elements**: `Canvas`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `Canvas (viewBox, elements, elementsSource, onItemClick)` | `Component` | Supports `viewBox` coordinate scaling, static `elements`, or dynamic `${$computed.shapes}` JSON array |
| `kind: rect \| circle \| ellipse \| line \| polyline \| polygon \| path \| text` | `Property` | Supports `fill`, `stroke`, `strokeWidth`, `opacity`, `rotation`, SVG `d` path commands, and text alignment |

**Golden JSON Snippet:**

```json
{
  "root": "canvas_root",
  "elements": {
    "canvas_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "children": [
        "gauge_canvas"
      ]
    },
    "gauge_canvas": {
      "type": "Canvas",
      "height": 160,
      "viewBox": "0 0 200 160",
      "elements": [
        {
          "id": "ring",
          "kind": "circle",
          "cx": 100,
          "cy": 80,
          "r": 60,
          "stroke": "#38BDF8",
          "strokeWidth": 6,
          "fill": "transparent"
        },
        {
          "id": "needle",
          "kind": "line",
          "x1": 100,
          "y1": 80,
          "x2": 100,
          "y2": 32,
          "stroke": "#F59E0B",
          "strokeWidth": 3,
          "rotation": 45,
          "cx": 100,
          "cy": 80
        },
        {
          "kind": "text",
          "x": 100,
          "y": 115,
          "text": "75%",
          "fontSize": 16,
          "fontWeight": "bold",
          "fill": "#38BDF8",
          "textAnchor": "middle"
        }
      ]
    }
  }
}
```

### `data-charts-and-tables` — 📊 Multi-Series Charts & Data Tables / 多维图表与数据表格

- **Summary**: Multi-column sortable data tables, donut charts, and multi-series line, bar, and area charts.
- **Required Dependencies**: `collections-lists`
- **UI Elements**: `Table`, `DonutChart`, `Chart`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `Table (collection, columns, sortable, striped, onRowClick)` | `Component` | Multi-column native table with header click sorting, striped rows, and `onRowClick` (`$item.*`) |
| `DonutChart (collection, titleField, valueField, centerTitle, centerValue)` | `Component` | Proportional donut ring chart with center KPI callout, optional `colorField`, and legend |
| `Chart (chartKind: line\|bar\|area, collection, xField, series)` | `Component` | Multi-series Cartesian chart supporting `line`, `bar`, and `area` modes with gridlines and legend |

**Golden JSON Snippet:**

```json
{
  "collections": {
    "metrics": {
      "maxItems": 30
    }
  },
  "root": "analytics_root",
  "elements": {
    "analytics_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "spacing": 10,
      "children": [
        "metrics_chart",
        "metrics_table"
      ]
    },
    "metrics_chart": {
      "type": "Chart",
      "chartKind": "line",
      "collection": "metrics",
      "xField": "day",
      "height": 130,
      "series": [
        {
          "field": "actual",
          "label": "Actual",
          "color": "#3B82F6"
        },
        {
          "field": "target",
          "label": "Target",
          "color": "#10B981"
        }
      ]
    },
    "metrics_table": {
      "type": "Table",
      "collection": "metrics",
      "columns": [
        {
          "key": "day",
          "header": "Day",
          "width": "1*"
        },
        {
          "key": "actual",
          "header": "Actual",
          "width": "1*",
          "align": "right"
        }
      ]
    }
  }
}
```

### `popover-and-markdown` — 💬 Popover Overlays & Markdown View / 轻量浮层与 Markdown 富文本

- **Summary**: Acrylic anchored popover overlays and native GitHub-Flavored Markdown rendering with interactive task lists.
- **Sources / Actions**: `popover.open`, `popover.close`, `popover.toggle`
- **UI Elements**: `Popover`, `Markdown`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `popovers / Button.popover / popover.open\|close\|toggle` | `Action` | Declare named overlays in root `popovers` and trigger via `Button.popover`, `Popover`, or `popover.*` actions |
| `Markdown (text, bind, onChange)` | `Component` | Renders headings, lists, code blocks, quotes, tables, and interactive `- [x]` task toggles when `bind` is set |

**Golden JSON Snippet:**

```json
{
  "state": {
    "notes": "### Quick Notes\n- [x] Ship native widgets\n- [ ] Review metrics"
  },
  "popovers": {
    "editNotes": {
      "width": 300,
      "height": 220,
      "placement": "bottom",
      "root": "edit_notes_body"
    }
  },
  "root": "notes_root",
  "elements": {
    "notes_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "spacing": 8,
      "children": [
        "edit_notes_btn",
        "notes_markdown"
      ]
    },
    "edit_notes_btn": {
      "type": "Button",
      "text": "Edit Markdown",
      "icon": "edit",
      "popover": "editNotes"
    },
    "notes_markdown": {
      "type": "Markdown",
      "bind": "state.notes"
    },
    "edit_notes_body": {
      "type": "Stack",
      "padding": "12",
      "spacing": 8,
      "children": [
        "notes_editor",
        "close_editor_btn"
      ]
    },
    "notes_editor": {
      "type": "TextArea",
      "bind": "state.notes",
      "minHeight": 130
    },
    "close_editor_btn": {
      "type": "Button",
      "text": "Done",
      "variant": "accent",
      "onClick": {
        "type": "popover.close",
        "popoverId": "editNotes"
      }
    }
  }
}
```

### `advanced-inputs-and-styling` — 🎛️ Advanced Inputs & Semantic Styling / 高级表单控件与语义视觉微调

- **Summary**: Date/time pickers, auto-suggest input, color picker, radio groups, star ratings, and host-harmonized semantic accents and sizing.
- **UI Elements**: `DatePicker`, `TimePicker`, `AutoSuggestInput`, `ColorPicker`, `RadioGroup`, `Rating`, `RawStyling`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `DatePicker / TimePicker / AutoSuggestInput / ColorPicker / RadioGroup / Rating` | `Component` | Two-way `bind` + live `onChange` (`${$value}`) native WinUI 3 input controls |
| `background / linearGradient / textColor / borderColor / borderWidth / cornerRadius` | `Property` | Host unifies container glass surfaces and corner radii; supports semantic tones, chromatic accents, sizing, opacity, and elevation |

**Golden JSON Snippet:**

```json
{
  "state": {
    "dueDate": "2026-12-31",
    "accentHex": "#38BDF8",
    "priority": 3
  },
  "root": "controls_root",
  "elements": {
    "controls_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "spacing": 8,
      "children": [
        "surface_card",
        "target_date_picker",
        "accent_color_picker",
        "priority_rating"
      ]
    },
    "surface_card": {
      "type": "Card",
      "tone": "subtle",
      "borderColor": "${state.accentHex}",
      "borderWidth": 1,
      "children": [
        "surface_label"
      ]
    },
    "surface_label": {
      "type": "Text",
      "text": "Host-Unified Card Surface",
      "style": "bodyStrong"
    },
    "target_date_picker": {
      "type": "DatePicker",
      "title": "Target Date",
      "bind": "state.dueDate"
    },
    "accent_color_picker": {
      "type": "ColorPicker",
      "title": "Accent",
      "bind": "state.accentHex",
      "presets": [
        "#38BDF8",
        "#10B981",
        "#F59E0B"
      ]
    },
    "priority_rating": {
      "type": "Rating",
      "title": "Priority",
      "bind": "state.priority",
      "max": 5
    }
  }
}
```

### `rich-controls-and-shells` — 💎 Full-Bleed Stage & Rich Native Controls / 全出血舞台与进阶原生组件

- **Summary**: Host-managed chrome & full-bleed stage layouts plus ZStack, ItemsGrid, SelectorBar, FlipView, SplitView, SplitButton, ContextMenu, InfoBar, TeachingTip, RichText, CodeBlock, and RadialGauge.
- **Sources / Actions**: `tip.open`, `tip.close`, `tip.toggle`
- **UI Elements**: `ZStack`, `ItemsGrid`, `SelectorBar`, `FlipView`, `SplitView`, `SplitButton`, `DropDownButton`, `InfoBadge`, `InfoBar`, `TeachingTip`, `RichText`, `CodeBlock`, `RadialGauge`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `chrome: "standard" \| "immersive" & radialGradient` | `Manifest` | Host unifies title-bar chrome and dragging via user settings (omit chrome); supports padding:"0" full-bleed stages and radial gradients |
| `ZStack / ItemsGrid / SelectorBar / FlipView / SplitView` | `Component` | Overlay stack, uniform grid repeater, Fluent selector bar, swipe carousel, and master-detail split pane |
| `SplitButton / DropDownButton / menuItems (ContextMenu)` | `Component` | Primary + flyout split button, dropdown menu button, and universal right-click MenuFlyout |
| `InfoBadge / InfoBar / TeachingTip / RichText / CodeBlock / RadialGauge` | `Component` | Notification badge, inline alert bar, anchored callout tip, multi-span rich text, copyable code block, and arc gauge |

**Golden JSON Snippet:**

```json
{
  "state": {
    "speed": 68
  },
  "root": "stage_overlay",
  "elements": {
    "stage_overlay": {
      "type": "ZStack",
      "padding": "0",
      "children": [
        "stage_body"
      ]
    },
    "stage_body": {
      "type": "Stack",
      "padding": "14",
      "spacing": 8,
      "children": [
        "boost_gauge",
        "powercfg_code"
      ]
    },
    "boost_gauge": {
      "type": "RadialGauge",
      "bind": "state.speed",
      "min": 0,
      "max": 100,
      "unit": "%",
      "title": "Boost",
      "showTicks": true,
      "tickStep": 10,
      "animateChange": true,
      "isInteractive": true,
      "size": 96,
      "color": "cyan"
    },
    "powercfg_code": {
      "type": "CodeBlock",
      "text": "powercfg /list",
      "language": "pwsh",
      "copyable": true
    }
  }
}
```

### `native-media-and-audio` — 🎧 Native Media Player & Multi-Track Audio / 原生音视频播放与环境白噪音

- **Summary**: Pure native WinRT MediaPlayerElement plus multi-track ambient soundscapes (white/pink/brown/rain) and synthesized UI audio cues.
- **Sources / Actions**: `audio.cue`, `audio.play`, `audio.pause`, `audio.stop`, `audio.setVolume`, `audio.stopAll`
- **UI Elements**: `MediaPlayer`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `MediaPlayer (src, poster, autoPlay, loop, muted, volume, showTransport)` | `Component` | Hardware-decoded native video/audio player that auto-suspends when widget is hidden |
| `audio.cue (cue: complete \| tick \| pop \| soft \| alert \| bell)` | `Action` | Plays zero-asset in-memory synthesized UI/timer cues |
| `audio.play / pause / stop / setVolume / stopAll (noise:white\|pink\|brown\|rain)` | `Action` | Multi-track playback and live volume mixing for ambient `noise:*` loops or local/HTTPS audio |

**Golden JSON Snippet:**

```json
{
  "state": {
    "rainVol": 65,
    "brownVol": 40
  },
  "root": "soundscape_card",
  "elements": {
    "soundscape_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "rain_volume_slider",
        "playback_actions_grid"
      ]
    },
    "rain_volume_slider": {
      "type": "Slider",
      "title": "Rain",
      "bind": "state.rainVol",
      "min": 0,
      "max": 100,
      "unit": "%",
      "onChange": {
        "type": "audio.setVolume",
        "trackId": "rain",
        "value": "${$value}"
      }
    },
    "playback_actions_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "play_rain_btn",
        "stop_all_btn"
      ]
    },
    "play_rain_btn": {
      "type": "Button",
      "text": "Play Rain",
      "variant": "accent",
      "onClick": {
        "type": "audio.play",
        "trackId": "rain",
        "src": "noise:rain",
        "loop": true,
        "volume": "${state.rainVol}"
      }
    },
    "stop_all_btn": {
      "type": "Button",
      "text": "Stop All",
      "onClick": {
        "type": "audio.stopAll"
      }
    }
  }
}
```

## Declarative Actions (`Action`)

### `display-and-audio` — 🔆 Volume, Brightness & Media / 音量、亮度与媒体

- **Summary**: Two-way live sliders for master volume and display brightness, plus media transport and audio output switching.
- **Required Dependencies**: `device-state`
- **Expression Namespaces**: `$device.brightness`, `$device.media`, `$device.audioDevice`
- **Sources / Actions**: `system.control`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `brightness.set / brightness.step` | `Command` | Sets display brightness (0-100) via LCD/DDC-CI using `${$value}` |
| `volume.set / volume.muteToggle / audio.output` | `Command` | Adjusts master volume, toggles mute, or opens audio output selector |
| `media.playPause / media.previous / media.next` | `Command` | Controls active SMTC media session; bind icon to `${$device.mediaToggleIcon}` |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "deviceState",
      "intervalMs": 3000
    }
  ],
  "root": "audio_display_card",
  "elements": {
    "audio_display_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "volume_slider",
        "brightness_slider",
        "audio_output_row"
      ]
    },
    "volume_slider": {
      "type": "Slider",
      "title": "系统音量",
      "value": "${$device.volume}",
      "min": 0,
      "max": 100,
      "step": 2,
      "unit": "%",
      "onChange": {
        "type": "system.control",
        "targetId": "volume.set",
        "value": "${$value}"
      }
    },
    "brightness_slider": {
      "type": "Slider",
      "title": "屏幕亮度",
      "value": "${$device.brightness}",
      "min": 0,
      "max": 100,
      "step": 5,
      "unit": "%",
      "onChange": {
        "type": "system.control",
        "targetId": "brightness.set",
        "value": "${$value}"
      }
    },
    "audio_output_row": {
      "type": "KeyValueRow",
      "label": "音频输出",
      "value": "${$device.audioDeviceName}"
    }
  }
}
```

### `clipboard-workspace` — 📋 Clipboard & Text Transform / 剪贴板与文本转换

- **Summary**: Inspects live clipboard text (JWT, JSON, Unicode escapes, timestamps) and runs 25 local in-memory formatting, encoding, timestamp, and hash operations.
- **Expression Namespaces**: `$clipboard.`
- **Sources / Actions**: `clipboard`, `text.transform`, `clipboard.copy`, `clipboard.captureImage`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `sources: [{ "type": "clipboard", "intervalMs": 2000 }]` | `Source` | Subscribes to system clipboard plain-text and bitmap availability (`${$clipboard.hasImage}`) |
| `${$clipboard.preview} / ${$clipboard.kindLabel} / ${$clipboard.length} / ${$clipboard.lines} / ${$clipboard.hasImage}` | `Token` | Single-line preview, content type label, char length, line count, and clipboard bitmap flag |
| `{ "type": "clipboard.captureImage", "key": "lastShot", "onComplete": "onShotSaved" }` | `Action` | Captures clipboard bitmap/DIB to a local PNG file and returns `{ path, name, width, height, sizeBytes }` (`LocalFileAccess`) |
| `{ "type": "text.transform", "format": "jsonPretty", "key": "output", "mode": "copy" }` | `Action` | Transforms text in-memory into `state.<key>` with optional clipboard copy |
| `jsonPretty / jsonMinify / urlEncode / base64Encode / timestampToDate / uuid / sha256` | `Enum` | 25 built-in deterministic text transform formats |
| `jwtDecode / unicodeEscape / unicodeUnescape / jsonEscape / jsonUnescape / uuidNoDash / jsonPretty4 / dateToTimestampMs` | `Enum` | Offline JWT decode with exp/nbf diagnostics (`${$transform.jwtState}`), CJK Unicode escape round-trips, JSON string escapes, and no-dash UUIDs |
| `${jwtdecode($clipboard.text)} / ${unicodeunescape(state.draft)} / ${uuid('upper')}` | `Function` | The same operators are callable inline inside string interpolation expressions (offline, zero-reflection); failures return an empty string |

**Golden JSON Snippet:**

```json
{
  "state": {
    "input": "",
    "output": ""
  },
  "sources": [
    {
      "type": "clipboard",
      "intervalMs": 2000
    }
  ],
  "root": "clipboard_root",
  "elements": {
    "clipboard_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "clipboard_card",
        "raw_input",
        "transform_actions_grid",
        "output_text"
      ]
    },
    "clipboard_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "clipboard_summary_row",
        "clipboard_preview_text"
      ]
    },
    "clipboard_summary_row": {
      "type": "KeyValueRow",
      "label": "当前剪贴板 (${$clipboard.kindLabel})",
      "value": "${$clipboard.length} 字符"
    },
    "clipboard_preview_text": {
      "type": "Text",
      "text": "${$clipboard.preview}",
      "style": "caption",
      "color": "secondary",
      "maxLines": 2
    },
    "raw_input": {
      "type": "TextArea",
      "bind": "state.input",
      "placeholder": "输入待处理文本（留空则直接处理剪贴板内容）…"
    },
    "transform_actions_grid": {
      "type": "Grid",
      "columns": "*,*,*",
      "spacing": 6,
      "children": [
        "json_pretty_btn",
        "base64_encode_btn",
        "timestamp_btn"
      ]
    },
    "json_pretty_btn": {
      "type": "Button",
      "text": "JSON 格式化",
      "onClick": {
        "type": "text.transform",
        "format": "jsonPretty",
        "text": "${state.input != '' ? state.input : $clipboard.text}",
        "key": "output",
        "mode": "copy"
      }
    },
    "base64_encode_btn": {
      "type": "Button",
      "text": "Base64 编码",
      "onClick": {
        "type": "text.transform",
        "format": "base64Encode",
        "text": "${state.input != '' ? state.input : $clipboard.text}",
        "key": "output",
        "mode": "copy"
      }
    },
    "timestamp_btn": {
      "type": "Button",
      "text": "时间戳转换",
      "onClick": {
        "type": "text.transform",
        "format": "timestampToDate",
        "text": "${state.input != '' ? state.input : $clipboard.text}",
        "key": "output",
        "mode": "copy"
      }
    },
    "output_text": {
      "type": "Text",
      "text": "${state.output}",
      "style": "mono",
      "maxLines": 6,
      "when": "${state.output != ''}"
    }
  }
}
```

### `quick-launcher` — 🚀 Quick Launcher / 快捷启动器

- **Summary**: Opens standard user folders, whitelisted app URI protocols, and local files/folders safely.
- **Sources / Actions**: `launcher.open`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `downloads / desktop / documents / pictures / userprofile` | `Folder` | Opens standard user folders via `targetId` |
| `vscode:// / cursor:// / obsidian:// / ms-screenclip: / ms-calculator:` | `URI` | Invokes whitelisted app and Windows utility URI schemes |
| `{ "type": "launcher.open", "path": "D:/Projects" }` | `Action` | Opens an existing local folder or file with consent protection |

**Golden JSON Snippet:**

```json
{
  "root": "launcher_grid",
  "elements": {
    "launcher_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "downloads_btn",
        "documents_btn",
        "screenshot_btn",
        "calculator_btn"
      ]
    },
    "downloads_btn": {
      "type": "Button",
      "text": "下载目录",
      "icon": "download",
      "onClick": {
        "type": "launcher.open",
        "targetId": "downloads"
      }
    },
    "documents_btn": {
      "type": "Button",
      "text": "文档目录",
      "icon": "file",
      "onClick": {
        "type": "launcher.open",
        "targetId": "documents"
      }
    },
    "screenshot_btn": {
      "type": "Button",
      "text": "屏幕截图",
      "icon": "camera",
      "onClick": {
        "type": "launcher.open",
        "targetId": "ms-screenclip:"
      }
    },
    "calculator_btn": {
      "type": "Button",
      "text": "计算器",
      "icon": "calculator",
      "onClick": {
        "type": "launcher.open",
        "targetId": "ms-calculator:"
      }
    }
  }
}
```

### `file-transform` — 🔄 File Converter / 文件格式转换

- **Summary**: Offline local image converter (PNG/JPG/WebP/ICO + resize) and CSV/JSON/Markdown/SHA256 file processor.
- **Required Dependencies**: `drop-zone`
- **Expression Namespaces**: `$transform.`
- **Sources / Actions**: `file.transform`, `file.pick`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "file.transform", "path": "${$drop.path}", "format": "webp" }` | `Action` | Non-destructively converts input file and populates `$transform.*` |
| `png / jpg / webp / ico / csvToJson / jsonToCsv / mdToHtml / sha256` | `Enum` | Supported image, structured data, and checksum formats |
| `${$transform.outputPath} / ${$transform.outputName} / ${$transform.sizeText} / ${$transform.resultText}` | `Token` | Output path, file name, formatted size, and result/hash text |

**Golden JSON Snippet:**

```json
{
  "state": {
    "format": "webp"
  },
  "collections": {
    "outputs": {
      "maxItems": 30
    }
  },
  "root": "converter_root",
  "elements": {
    "converter_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "format_selector",
        "image_drop_zone",
        "outputs_list"
      ]
    },
    "format_selector": {
      "type": "Segmented",
      "bind": "state.format",
      "options": [
        {
          "value": "png",
          "label": "PNG"
        },
        {
          "value": "jpg",
          "label": "JPG"
        },
        {
          "value": "webp",
          "label": "WebP"
        },
        {
          "value": "ico",
          "label": "ICO"
        }
      ]
    },
    "image_drop_zone": {
      "type": "DropZone",
      "icon": "gallery",
      "title": "拖入图片或点击选择",
      "subtitle": "自动转为 ${state.format} 并保存在原目录",
      "onDrop": [
        {
          "type": "file.transform",
          "path": "${$drop.path}",
          "format": "${state.format}",
          "then": [
            {
              "type": "collection.prepend",
              "collection": "outputs",
              "item": {
                "name": "${$transform.outputName}",
                "path": "${$transform.outputPath}"
              }
            }
          ]
        }
      ]
    },
    "outputs_list": {
      "type": "List",
      "items": "outputs",
      "itemTemplate": "output_chip"
    },
    "output_chip": {
      "type": "FileChip",
      "fileName": "${$item.name}",
      "filePath": "${$item.path}"
    }
  }
}
```

### `system-control` — ⚙️ System Toggles & Settings / 系统开关与设置

- **Summary**: Toggles Wi-Fi, Bluetooth, Keep-Awake, locks workstation, empties Recycle Bin, or opens Windows Settings pages.
- **Required Dependencies**: `device-state`
- **Sources / Actions**: `system.control`, `system.openSetting`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `radio.wifiToggle / radio.bluetoothToggle` | `Command` | Toggles Wi-Fi or Bluetooth radio with ms-settings fallback |
| `power.keepAwakeToggle / power.lock / recycleBin.empty` | `Command` | Toggles Keep-Awake, locks PC, or empties Recycle Bin |
| `{ "type": "system.openSetting", "targetId": "display" }` | `Action` | Opens whitelisted Windows Settings page or Task Manager |

**Golden JSON Snippet:**

```json
{
  "sources": [
    {
      "type": "deviceState",
      "intervalMs": 3000
    }
  ],
  "root": "control_root",
  "elements": {
    "control_root": {
      "type": "Stack",
      "spacing": 8,
      "children": [
        "toggles_grid",
        "volume_slider"
      ]
    },
    "toggles_grid": {
      "type": "Grid",
      "columns": "*,*",
      "spacing": 8,
      "children": [
        "wifi_tile",
        "keep_awake_tile"
      ]
    },
    "wifi_tile": {
      "type": "ControlTile",
      "icon": "wifi",
      "title": "Wi-Fi",
      "subtitle": "${$device.wifiStatus}",
      "value": "${$device.wifiEnabled}",
      "onClick": {
        "type": "system.control",
        "targetId": "radio.wifiToggle"
      }
    },
    "keep_awake_tile": {
      "type": "ControlTile",
      "icon": "sun",
      "title": "屏幕常亮",
      "subtitle": "${$device.keepAwakeStatus}",
      "value": "${$device.keepAwake}",
      "onClick": {
        "type": "system.control",
        "targetId": "power.keepAwakeToggle"
      }
    },
    "volume_slider": {
      "type": "Slider",
      "title": "系统音量",
      "value": "${$device.volume}",
      "min": 0,
      "max": 100,
      "step": 2,
      "unit": "%",
      "onChange": {
        "type": "system.control",
        "targetId": "volume.set",
        "value": "${$value}"
      }
    }
  }
}
```

### `ai-run` — ✨ In-Widget AI Task / AI 文本处理

- **Summary**: Runs structured AI prompts inside the widget and maps JSON fields into state or collections.
- **Sources / Actions**: `ai.run`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "ai.run", "prompt": "...", "collection": "items", "fieldMap": {...} }` | `Action` | Runs single-flight structured AI task with status tracking and input preservation |
| `${state.aiStatus} / ${state.aiError} / ${state.aiUpdatedAt}` | `Token` | Execution status, error message, and last completion time |

**Golden JSON Snippet:**

```json
{
  "state": {
    "draft": ""
  },
  "collections": {
    "tasks": {
      "maxItems": 100
    }
  },
  "root": "extract_tasks_btn",
  "elements": {
    "extract_tasks_btn": {
      "type": "Button",
      "text": "拆解待办事项",
      "icon": "sparkles",
      "variant": "accent",
      "onClick": {
        "type": "ai.run",
        "guard": "${state.draft != ''}",
        "prompt": "将以下内容拆解为可执行待办事项(items: title)：\n${state.draft}",
        "collection": "tasks",
        "itemsPath": "items",
        "fieldMap": {
          "title": "title"
        },
        "then": [
          {
            "type": "state.set",
            "key": "draft",
            "value": ""
          }
        ]
      }
    }
  }
}
```

### `notifications-reminders` — 🔔 Notifications & Toasts / 通知与轻提示

- **Summary**: Sends Windows 11 Action Center toast notifications or subtle in-widget feedback banners.
- **Sources / Actions**: `reminder.notify`, `toast.show`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "type": "reminder.notify", "text": "标题", "message": "内容" }` | `Action` | Sends a native Windows 11 Action Center notification |
| `{ "type": "toast.show", "message": "已保存" }` | `Action` | Shows a lightweight in-widget feedback banner |

**Golden JSON Snippet:**

```json
{
  "root": "test_reminder_btn",
  "elements": {
    "test_reminder_btn": {
      "type": "Button",
      "text": "发送测试提醒",
      "icon": "bell",
      "onClick": {
        "type": "reminder.notify",
        "text": "定时提醒",
        "message": "预设提醒时间已到。"
      }
    }
  }
}
```

### `script-sandbox` — ⚡ Private Sandboxed Script / 私有计算脚本沙箱

- **Summary**: Runs an isolated offline ES2023 module (logic.js) in QuickJS for custom algorithms, state machines, and API payload parsing.
- **Expression Namespaces**: `$computed.`
- **Sources / Actions**: `script`, `script.run`, `job.cancel`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `script: { "entry": "logic.js", "tickIntervalMs": 0 }` | `Manifest` | Declares the isolated QuickJS ES2023 script entry and optional tick interval (>= 1000ms, auto-hibernates when hidden) |
| `{ "type": "script.run", "fn": "step", "arg": "1", "args": { ... } }` | `Action` | Invokes an exported synchronous function in logic.js with `ctx.args`, `ctx.event`, and `ctx.dispatch` |
| `ctx.state (structured JSON) & ${$computed.<key>}` | `Token` | `ctx.state` natively persists structured JSON (`boolean`, `number`, `string`, `array`, `object`); `${$computed.<key>}` holds ephemeral projections |
| `onInit(ctx) \| onSourceData(ctx, id, raw) \| onTick(ctx, nowMs) \| onComplete(ctx, res) \| onProgress(ctx, p)` | `Hook` | Lifecycle hooks and unified async job progress/result callbacks with `job.cancel` |

**Golden JSON Snippet:**

```json
{
  "script": {
    "entry": "logic.js",
    "tickIntervalMs": 0
  },
  "capsule": {
    "title": "Focus Score",
    "summary": "${$computed.summary}",
    "badge": "${$computed.score}",
    "primaryAction": {
      "icon": "add",
      "tooltip": "Log session",
      "onClick": {
        "type": "script.run",
        "fn": "recordSession",
        "arg": "25"
      }
    }
  },
  "root": "focus_summary",
  "elements": {
    "focus_summary": {
      "type": "Text",
      "text": "${$computed.summary}"
    }
  }
}
```

### `interactive-http` — 🌐 Interactive HTTP & Webhooks / 交互式 HTTP 请求与 Webhook

- **Summary**: Interactive GET/POST/PUT/PATCH/DELETE requests, DPAPI secret headers, LAN endpoints, and script callbacks.
- **Required Dependencies**: `secret-vault`
- **Sources / Actions**: `http.request`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `http.request (id, jobKey, method, url, headers, body, stateMap, collection, onComplete)` | `Action` | Sends an interactive HTTP request and updates `state.httpStatus` (`loading\|ok\|error`) and `state.httpError` |
| `export function onHttpResponse(ctx, res)` | `Callback` | Callback receiving unified `{ id, jobKey, type, ok, status, text, data, error, timedOut, cancelled, durationMs, meta }` |

**Golden JSON Snippet:**

```json
{
  "state": {
    "msg": "",
    "lastResult": "--"
  },
  "settings": [
    {
      "key": "webhookToken",
      "type": "secret",
      "label": "Webhook Token",
      "default": ""
    }
  ],
  "root": "webhook_root",
  "elements": {
    "webhook_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "spacing": 8,
      "children": [
        "payload_input",
        "send_webhook_btn",
        "echo_result_text"
      ]
    },
    "payload_input": {
      "type": "Input",
      "placeholder": "Payload message...",
      "bind": "state.msg"
    },
    "send_webhook_btn": {
      "type": "Button",
      "text": "Send Webhook",
      "variant": "accent",
      "onClick": {
        "type": "http.request",
        "method": "POST",
        "url": "https://httpbin.org/post",
        "headers": {
          "Authorization": "Bearer ${$secrets.webhookToken}"
        },
        "body": {
          "message": "${state.msg}"
        },
        "stateMap": {
          "lastResult": "json.message"
        }
      }
    },
    "echo_result_text": {
      "type": "Text",
      "text": "Echo: ${state.lastResult}",
      "style": "caption",
      "color": "secondary"
    }
  }
}
```

### `local-files-and-commands` — 🖥️ Local Files & CLI Commands / 本地文件读写与命令行集成

- **Summary**: Permission-gated local file watching/writing, directory listing, Recycle-Bin-safe file management, and streaming CLI execution with progress & cancellation.
- **Sources / Actions**: `fileText`, `localFolder`, `file.writeText`, `file.listDir`, `file.manage`, `command`, `command.run`, `job.cancel`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `source: fileText / actions: file.writeText \| file.listDir \| file.manage` | `Action` | Watch/write UTF-8 files, scan directories (`file.listDir`), or copy/move/rename/recycle files via OS Recycle Bin (`LocalFileAccess`) |
| `source: command / actions: command.run (longRunning, onProgress, onComplete) \| job.cancel` | `Action` | Runs local CLI processes with optional `longRunning: true` idle-stall watchdog, `4Hz` `onProgress` streaming, unified `res` callback, and `job.cancel` (`CommandExecution`) |

**Golden JSON Snippet:**

```json
{
  "state": {
    "noteContent": "# Scratchpad"
  },
  "settings": [
    {
      "key": "notePath",
      "type": "text",
      "label": "Markdown File Path",
      "default": "%USERPROFILE%\\Documents\\deskbox-note.md"
    }
  ],
  "sources": [
    {
      "id": "localNote",
      "type": "fileText",
      "path": "${$settings.notePath}",
      "stateKey": "noteContent",
      "intervalMs": 5000
    }
  ],
  "root": "note_sync_root",
  "elements": {
    "note_sync_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "spacing": 8,
      "children": [
        "note_editor",
        "save_note_btn"
      ]
    },
    "note_editor": {
      "type": "TextArea",
      "bind": "state.noteContent",
      "minHeight": 100
    },
    "save_note_btn": {
      "type": "Button",
      "text": "Save to File",
      "variant": "accent",
      "onClick": {
        "type": "file.writeText",
        "path": "${$settings.notePath}",
        "text": "${state.noteContent}",
        "append": false
      }
    }
  }
}
```

## Configuration & Security (`ConfigAndSecurity`)

### `secret-vault` — 🔐 Encrypted API Secrets / API 密钥凭据

- **Summary**: Stores API keys encrypted via Windows DPAPI; automatically excluded when exporting `.dbxwidget` packages.
- **Required Dependencies**: `http-and-rss-feeds`
- **Expression Namespaces**: `$secrets.`
- **Sources / Actions**: `secret`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `settings: [{ "key": "apiKey", "type": "secret", "label": "API Key" }]` | `Setting` | Declares a DPAPI-encrypted secret setting with setup prompt |
| `headers: { "Authorization": "Bearer ${$secrets.apiKey}" }` | `Header` | Injects secret into same-origin `httpJson` request headers |

**Golden JSON Snippet:**

```json
{
  "settings": [
    {
      "key": "apiKey",
      "type": "secret",
      "label": "SiliconFlow API Key"
    }
  ],
  "sources": [
    {
      "id": "balance",
      "type": "httpJson",
      "url": "https://api.siliconflow.cn/v1/user/info",
      "headers": {
        "Authorization": "Bearer ${$secrets.apiKey}"
      },
      "intervalMs": 300000,
      "stateMap": {
        "balance": "$.data.totalBalance",
        "name": "$.data.name"
      }
    }
  ],
  "root": "balance_card",
  "elements": {
    "balance_card": {
      "type": "Card",
      "tone": "subtle",
      "children": [
        "balance_text"
      ]
    },
    "balance_text": {
      "type": "Text",
      "text": "账户可用余额：¥ ${state.balance ?? '--'}",
      "style": "title"
    }
  }
}
```

### `widget-settings` — 🛠️ Widget Settings / 右键设置项

- **Summary**: Adds user-configurable choice, toggle, text, and numeric options to the widget context menu.
- **Expression Namespaces**: `$settings.`, `settings.`
- **UI Elements**: `ModuleStack`

| Token / Property / Signature | Kind | Description |
| :--- | :--- | :--- |
| `{ "key": "city", "type": "text", "label": "城市", "default": "北京" }` | `Setting` | Supports choice, toggle, text, number, file, folder, moduleList, and secret setting types |
| `${$settings.city}` | `Token` | Reads the user's configured setting value in views or sources |

**Golden JSON Snippet:**

```json
{
  "state": {
    "todayCount": 1200
  },
  "settings": [
    {
      "key": "modules",
      "type": "moduleList",
      "label": "显示模块与排序",
      "default": "overview:1,chart:1",
      "options": [
        {
          "value": "overview",
          "label": "今日概览"
        },
        {
          "value": "chart",
          "label": "趋势卡片"
        }
      ]
    },
    {
      "key": "dailyGoal",
      "type": "number",
      "label": "每日目标",
      "default": 2000
    },
    {
      "key": "compactMode",
      "type": "toggle",
      "label": "紧凑模式",
      "default": false
    }
  ],
  "root": "settings_root",
  "elements": {
    "settings_root": {
      "type": "Stack",
      "padding": "12,10,12,12",
      "children": [
        "modules_stack"
      ]
    },
    "modules_stack": {
      "type": "ModuleStack",
      "bind": "settings.modules",
      "spacing": 8,
      "children": [
        "overview",
        "chart"
      ]
    },
    "overview": {
      "type": "StatCard",
      "title": "今日累计",
      "value": "${state.todayCount}",
      "progress": "${state.todayCount * 100 / $settings.dailyGoal}"
    },
    "chart": {
      "type": "Card",
      "tone": "subtle",
      "when": "${$settings.compactMode != true}",
      "children": [
        "chart_caption"
      ]
    },
    "chart_caption": {
      "type": "Text",
      "text": "趋势详情",
      "style": "caption",
      "color": "secondary"
    }
  }
}
```
