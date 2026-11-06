# DeskBox Agent & MCP Setup Guide

Official setup documentation, configuration examples, and companion Skill for connecting AI Agents (**Claude Code**, **OpenAI Codex**, **Cursor**, **VS Code Copilot**, **Windsurf**, **Trae**, **Antigravity**, **OpenCode**) to [DeskBox](https://github.com/Tianyu199509/DeskBox) (`v1.6.0+`).

> **Note:** The MCP server itself (`--mcp` over `stdio`) ships directly inside the DeskBox Windows application. This repository only contains setup guides, configuration examples, and the optional workflow Skill.

---

## 快速接入（推荐：一键复制口令）

1. 打开 **DeskBox 设置 → AI 与智能体 → 外部 Agent 生态**。
2. 点击 **复制口令**（DeskBox 会自动按当前安装渠道填入正确的启动命令）。
3. 将口令直接粘贴发给你正在使用的 AI 客户端（Claude Code、Codex、Cursor、VS Code、Trae、Windsurf 等），让其按客户端官方方式完成配置与只读校验。

### 启动命令规则

| 安装渠道 | 启动命令 | 说明 |
|---|---|---|
| **Microsoft Store 版** | `deskbox.exe --mcp` | 通过 Windows 应用执行别名（App Execution Alias）启动，升级版本后路径无需更改 |
| **独立安装包 / 便携版** | `"C:\Users\<用户名>\AppData\Local\Programs\DeskBox\DeskBox.exe" --mcp` | 请在 DeskBox 设置页点击 **复制口令** 或 **通用配置** 获取本机真实路径 |

---

## 核心特性与设计边界

- **单一 `stdio` 入口**：不开启任何本地 HTTP / TCP 监听端口，由客户端按需拉起 `--mcp` 子进程，通过當前登录用户的命名管道（Named Pipe）与桌面宿主通信。
- **不代写第三方客户端配置**：DeskBox 不会在后台扫描或改写你的客户端配置文件、Skill 目录或信任记录。
- **内置运行时权威规范（Skill 可选）**：MCP `initialize` 响应内置 `instructions`，且提供只读工具 `deskbox_get_widget_spec` 与 `deskbox_get_capability_spec`。即使不安装本地 Skill 或处于离线环境，Agent 也能直接读取完整组件规范。
- **默认暂存（Stage-by-Default）**：`deskbox_upsert_widget` 在未传 `commit: true` 时仅做校验与暂存并返回 `stageId`，不会直接改动桌面；只有你确认后，Agent 才会使用同一 `stageId` 提交上桌。

---

## MCP 工具一览（v1.6.0）

| 工具名 | 是否需要桌面宿主在线 | 说明 |
|---|---|---|
| `deskbox_get_widget_spec` | 否（支持离线调用） | 读取当前版本的完整自定义小组件规范与可选 JSON Schema |
| `deskbox_get_capability_spec` | 否（支持离线调用） | 按 `capabilityId` 或关键词查询 19 个原子能力契约与金标准 JSON 示例 |
| `deskbox_validate_manifest` | 否（支持离线调用） | 校验 `manifest.json` 语法、节点结构与绑定表达式 |
| `deskbox_list_widgets` | 是 | 列出当前桌面小组件及工作区路径，或传入 `widgetId` 检查实时状态 |
| `deskbox_upsert_widget` | 是 | 默认暂存（返回 `stageId`，不改桌面）；传入 `commit: true` + `stageId` 后正式提交上桌（相同内容重复提交幂等） |
| `deskbox_capture_widget_preview` | 是 | 截取指定小组件的真实 WinUI 3 渲染预览图（支持深色/浅色主题对比） |
| `deskbox_push_widget_data` | 是 | 向桌面小组件（如 AI 状态看板）推送实时状态与事件流 |

---

## 目录索引

- **[各客户端配置指南 (`docs/setup.md`)](docs/setup.md)**：Claude Code、Codex、Cursor、VS Code、Windsurf、Trae、OpenCode 配置步骤与可选 Skill 安装方法。
- **[常见问题与排障 (`docs/troubleshooting.md`)](docs/troubleshooting.md)**：Store 执行别名检查、宿主未运行错误、WSL2 调用说明、暂存与提交机制排查。
- **[停用与移除说明 (`docs/remove.md`)](docs/remove.md)**：如何临时停用 MCP、移除配套 Skill 或彻底移除 DeskBox MCP 配置。
- **[配套 Skill (`skills/deskbox-widget/SKILL.md`)](skills/deskbox-widget/SKILL.md)**：轻量化工作流引导文件（权威规范始终以运行时 `deskbox_get_widget_spec` 为准）。
- **[配置文件示例 (`examples/`)](examples/)**：
  - [`examples/mcp.standard.json`](examples/mcp.standard.json) — Claude Desktop / Cursor / Windsurf / Trae 通用 JSON
  - [`examples/mcp.vscode.json`](examples/mcp.vscode.json) — VS Code (`mcp.json`)
  - [`examples/mcp.codex.toml`](examples/mcp.codex.toml) — OpenAI Codex (`~/.codex/config.toml`)
  - [`examples/mcp.opencode.json`](examples/mcp.opencode.json) — OpenCode (`opencode.json`)
