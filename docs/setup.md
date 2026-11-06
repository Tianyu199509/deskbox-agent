# 各客户端接入与配置指南

本指南介绍如何在主流 AI 编程客户端中配置 DeskBox 本地 MCP 服务，以及如何按需安装配套的 `deskbox-widget` Skill。

---

## 一、确认你的启动命令

在配置前，请先确认你安装的 DeskBox 渠道（也可直接在 **DeskBox 设置 → AI 与智能体 → 外部 Agent 生态 → 通用配置** 中一键复制）：

1. **Microsoft Store 商店版**：
   - 可执行程序：`deskbox.exe`
   - 启动参数：`--mcp`
   - 完整命令：`deskbox.exe --mcp`
2. **独立安装包 / 便携版（Direct）**：
   - 可执行程序：`C:\Users\<用户名>\AppData\Local\Programs\DeskBox\DeskBox.exe`（若自定义了安装目录，请以实际路径为准；切勿指向 `DeskBox.Settings.exe`）
   - 启动参数：`--mcp`
   - 完整命令：`"C:\Users\<用户名>\AppData\Local\Programs\DeskBox\DeskBox.exe" --mcp`

> 下文示例默认使用 `deskbox.exe`（Store 版）。若你使用独立安装包，请将 `"deskbox.exe"` 替换为你的 `DeskBox.exe` 完整路径。

---

## 二、按客户端添加 MCP 服务

### 1. Claude Code (CLI)

在终端执行官方命令添加：

```powershell
# Store 版
claude mcp add --transport stdio deskbox -- deskbox.exe --mcp

# 独立安装包（将路径替换为本机 DeskBox.exe 真实路径）
claude mcp add --transport stdio deskbox -- "C:\Users\<用户名>\AppData\Local\Programs\DeskBox\DeskBox.exe" --mcp
```

添加后可在 Claude Code 中输入 `/mcp` 检查 `deskbox` 状态。

---

### 2. OpenAI Codex (CLI / Desktop)

使用命令行注册：

```powershell
# Store 版
codex mcp add deskbox -- deskbox.exe --mcp

# 独立安装包
codex mcp add deskbox -- "C:\Users\<用户名>\AppData\Local\Programs\DeskBox\DeskBox.exe" --mcp
```

或者手动在 `~/.codex/config.toml` 中追加（参见 [`examples/mcp.codex.toml`](../examples/mcp.codex.toml)）：

```toml
[mcp_servers.deskbox]
command = "deskbox.exe"
args = ["--mcp"]
```

> 若使用独立安装包，请注意在 TOML 双引号字符串中转义反斜杠（例如 `"C:\\Users\\<用户名>\\AppData\\Local\\Programs\\DeskBox\\DeskBox.exe"`）或使用单引号字面量字符串。

---

### 3. Cursor

打开 `~/.cursor/mcp.json`（全局）或项目根目录下的 `.cursor/mcp.json`，在 `mcpServers` 中添加 `deskbox`（参见 [`examples/mcp.standard.json`](../examples/mcp.standard.json)）：

```json
{
  "mcpServers": {
    "deskbox": {
      "command": "deskbox.exe",
      "args": [
        "--mcp"
      ]
    }
  }
}
```

保存后在 **Cursor Settings → MCP** 中确认 `deskbox` 已启用并加载 7 个工具。

---

### 4. VS Code (GitHub Copilot Agent Mode)

在工作区 `.vscode/mcp.json` 或用户级 `mcp.json` 中添加（参见 [`examples/mcp.vscode.json`](../examples/mcp.vscode.json)）：

```json
{
  "servers": {
    "deskbox": {
      "type": "stdio",
      "command": "deskbox.exe",
      "args": [
        "--mcp"
      ]
    }
  }
}
```

---

### 5. Windsurf / Trae / Claude Desktop / Antigravity

在对应客户端的 MCP 配置文件中添加标准 `mcpServers` 条目（参见 [`examples/mcp.standard.json`](../examples/mcp.standard.json)）：

```json
{
  "mcpServers": {
    "deskbox": {
      "command": "deskbox.exe",
      "args": [
        "--mcp"
      ]
    }
  }
}
```

---

### 6. OpenCode

在项目或用户级 `opencode.json` 中添加（参见 [`examples/mcp.opencode.json`](../examples/mcp.opencode.json)）：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "deskbox": {
      "type": "local",
      "command": [
        "deskbox.exe",
        "--mcp"
      ],
      "enabled": true
    }
  }
}
```

---

## 三、安装配套 Skill（可选）

DeskBox 的 MCP 服务已内置 `instructions` 并在运行时提供 `deskbox_get_widget_spec`，因此 **不安装 Skill 也能正常创建和修改小组件**。

如果你的客户端支持本地 `SKILL.md`，可以将本仓库中的 [`skills/deskbox-widget/SKILL.md`](../skills/deskbox-widget/SKILL.md) 复制到客户端对应的 Skill 目录，以强化“先读实时规范 → 默认暂存 → 确认后提交”的工作流：

| 客户端 | 推荐放置路径 |
|---|---|
| **Codex** | `~/.codex/skills/deskbox-widget/SKILL.md` |
| **Claude Code** | `~/.claude/skills/deskbox-widget/SKILL.md` |
| **Cursor** | `~/.cursor/skills/deskbox-widget/SKILL.md` |
| **Antigravity** | `~/.gemini/config/skills/deskbox-widget/SKILL.md` |

PowerShell 一键下载示例（以 Codex 为例）：

```powershell
$targetDir = Join-Path $HOME '.codex\skills\deskbox-widget'
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Tianyu199509/deskbox-agent/main/skills/deskbox-widget/SKILL.md' -OutFile (Join-Path $targetDir 'SKILL.md')
```

---

## 四、验证接入是否成功

配置完成后，向你的 AI 客户端发送以下只读指令进行验证：

> 请调用 `deskbox_get_widget_spec` 检查 DeskBox MCP 是否连接成功，只需报告工具是否可用，不要创建或修改任何桌面小组件。
