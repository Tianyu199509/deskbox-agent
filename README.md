# DeskBox Agent & MCP Setup Guide

Official setup documentation, auto-bootstrap script, full capability reference, JSON Schema, and companion Skill for connecting AI Agents (**Claude Code**, **OpenAI Codex**, **Cursor**, **VS Code Copilot**, **Windsurf**, **Trae**, **Antigravity**, **OpenCode**) to [DeskBox](https://github.com/Tianyu199509/DeskBox) (`v1.6.0+`).

---

## 场景 A：已安装 DeskBox（推荐：设置页一键复制口令）

1. 打开 **DeskBox 设置 → AI 与智能体 → 外部 Agent 生态**。
2. 点击 **复制口令**（DeskBox 会自动按当前安装渠道填入正确的启动命令）。
3. 将口令粘贴发给你的 AI 客户端，让其按官方方式完成配置与只读验证。

| 安装渠道 | 启动命令 | 说明 |
|---|---|---|
| **Microsoft Store 版** | `deskbox.exe --mcp` | 通过 Windows 应用执行别名（App Execution Alias）启动，升级版本后路径无需更改 |
| **独立安装包 / 便携版** | `"C:\Users\<用户名>\AppData\Local\Programs\DeskBox\DeskBox.exe" --mcp` | 请在 DeskBox 设置页点击 **复制口令** 或 **通用配置** 获取本机真实路径 |

---

## 场景 B：电脑尚未安装 DeskBox（让 AI 自动检测并引导安装部署）

如果你是通过 AI 制作桌面小组件了解到本仓库、电脑上还没安装 DeskBox，可以直接将下面这段口令发给你的 AI Agent（或安装本仓库的 `deskbox-widget` Skill）：

```text
请读取 https://github.com/Tianyu199509/deskbox-agent 并帮我配置 DeskBox 桌面小组件开发环境：
1. 安装配套 Skill（skills/deskbox-widget），并运行其中的 scripts/ensure-deskbox.ps1 检测我电脑上是否已安装 DeskBox (v1.6.0+)。
2. 如果检测到尚未安装（installed: false）或版本过旧，请先向我确认，确认后运行 `ensure-deskbox.ps1 -Install -StartHost` 从官方 GitHub Release 下载匹配当前架构的安装包（自动校验 SHA-256）、完成安装并启动 DeskBox。
3. 根据脚本输出的 mcpCommand 与 mcpArgs，用当前客户端官方支持的方式注册名为 `deskbox` 的 stdio MCP 服务（保留已有配置，不代写信任记录）。
4. 完成后调用 `deskbox_get_widget_spec` 验证连接并向我汇报结果。
```

### `ensure-deskbox.ps1` 自动检测与部署脚本说明

位于 [`skills/deskbox-widget/scripts/ensure-deskbox.ps1`](skills/deskbox-widget/scripts/ensure-deskbox.ps1)，供 AI Agent 或用户直接执行：

- **仅检测环境（无副作用）**：
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File skills/deskbox-widget/scripts/ensure-deskbox.ps1
  ```
  自动按 **运行中进程 → Microsoft Store 应用执行别名 (`deskbox.exe`) → Inno Setup 注册表 (`{5E052824-3456-427E-9759-3BCAE078A1D3}_is1`，支持自定义安装目录) → 默认安装路径** 的顺序定位 `DeskBox.exe`，并通过 `--mcp` 探测协议与命名管道状态，输出标准 JSON。
- **未安装时自动下载、校验 SHA-256、安装并启动（需用户确认后执行）**：
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File skills/deskbox-widget/scripts/ensure-deskbox.ps1 -Install -StartHost
  ```

---

## 核心特性与安全边界

- **单一 `stdio` 入口**：不开启任何本地 HTTP / TCP 监听端口，由客户端按需拉起 `--mcp` 子进程，通过当前登录用户的命名管道（Named Pipe）与桌面宿主通信。
- **不代写第三方客户端配置**：DeskBox 不会在后台扫描或改写你的客户端配置文件、Skill 目录或信任记录。
- **内置运行时权威规范 + 仓库完整离线参考**：MCP 服务内置 `instructions` 与 `deskbox_get_widget_spec`；同时本仓库完整收录了 19 个原子能力参考手册（[`API_REFERENCE.md`](skills/deskbox-widget/references/API_REFERENCE.md)）与 [`manifest.schema.json`](skills/deskbox-widget/references/manifest.schema.json)。
- **默认暂存（Stage-by-Default）**：`deskbox_upsert_widget` 在未传 `commit: true` 时仅做校验与暂存并返回 `stageId`，不会直接改动桌面；只有你确认后，Agent 才会使用同一 `stageId` 提交上桌。

---

## MCP 工具一览（v1.6.0）

| 工具名 | 是否需要桌面宿主在线 | 说明 |
|---|---|---|
| `deskbox_get_widget_spec` | 否（支持离线调用） | 读取当前版本的完整自定义小组件规范与可选 JSON Schema |
| `deskbox_get_capability_spec` | 否（支持离线调用） | 按 `capabilityId` 或关键词查询原子能力契约与金标准 JSON 示例 |
| `deskbox_validate_manifest` | 否（支持离线调用） | 校验 `manifest.json` 语法、节点结构、QuickJS 脚本与多语言包 |
| `deskbox_list_widgets` | 是 | 列出当前桌面小组件及工作区路径，或传入 `widgetId` 检查实时状态 |
| `deskbox_upsert_widget` | 是 | 默认暂存（返回 `stageId`，不改桌面）；传入 `commit: true` + `stageId` 后正式提交上桌（相同内容重复提交幂等） |
| `deskbox_capture_widget_preview` | 是 | 截取指定小组件的真实 WinUI 3 渲染预览图（支持展开态 / 胶囊态） |
| `deskbox_push_widget_data` | 是 | 向桌面小组件（如 AI 状态看板）推送实时状态与事件流 |

---

## 仓库目录结构

- **[`skills/deskbox-widget/`](skills/deskbox-widget/)**
  - **[`SKILL.md`](skills/deskbox-widget/SKILL.md)**：完整 AI Agent 技能包（含环境自检引导、Stage-by-Default 安全工作流、Fluent 2 设计规范、`${...}` 表达式语法、10 类原生数据源、全量控件目录与 Action 字典）。
  - **[`scripts/ensure-deskbox.ps1`](skills/deskbox-widget/scripts/ensure-deskbox.ps1)**：DeskBox 环境检测、SHA-256 校验下载安装与宿主启动脚本。
  - **[`references/API_REFERENCE.md`](skills/deskbox-widget/references/API_REFERENCE.md)**：全量原子能力契约与 Golden JSON 代码片段参考手册。
  - **[`references/manifest.schema.json`](skills/deskbox-widget/references/manifest.schema.json)**：Draft 2020-12 小组件 `manifest.json` JSON Schema。
- **[`docs/`](docs/)**
  - **[`docs/setup.md`](docs/setup.md)**：Claude Code、Codex、Cursor、VS Code、Windsurf、Trae、OpenCode 配置步骤与 Skill 安装方法。
  - **[`docs/troubleshooting.md`](docs/troubleshooting.md)**：Store 执行别名检查、宿主未运行错误、WSL2 调用说明、暂存与提交机制排查。
  - **[`docs/remove.md`](docs/remove.md)**：如何临时停用 MCP、移除配套 Skill 或彻底移除 DeskBox MCP 配置。
- **[`examples/`](examples/)**
  - **MCP 配置文件示例**：[`mcp.standard.json`](examples/mcp.standard.json)、[`mcp.vscode.json`](examples/mcp.vscode.json)、[`mcp.codex.toml`](examples/mcp.codex.toml)、[`mcp.opencode.json`](examples/mcp.opencode.json)。
  - **完整小组件 `manifest.json` 黄金示例（[`examples/widgets/`](examples/widgets/)）**：
    - [`agent-hud.manifest.json`](examples/widgets/agent-hud.manifest.json) — AI 智能体实时状态看板（HUD）
    - [`sys-pulse.manifest.json`](examples/widgets/sys-pulse.manifest.json) — 硬件性能脉搏监控（CPU / 内存 / GPU / 磁盘）
    - [`news-rss.manifest.json`](examples/widgets/news-rss.manifest.json) — 实时 RSS 科技资讯聚合器
    - [`dev-toolbox.manifest.json`](examples/widgets/dev-toolbox.manifest.json) — 开发者本地转换与快捷工具箱
