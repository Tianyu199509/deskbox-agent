# 停用与移除说明

DeskBox（`v1.6.0+`）不会在后台修改任何第三方 AI 客户端的配置文件、Skill 目录或信任记录。你可以随时在客户端中单独停用 MCP、移除配套 Skill 或彻底移除配置。

---

## 一、三者的区别

| 操作 | 作用范围 | 对桌面已有小组件的影响 |
|---|---|---|
| **1. 临时停用 MCP 服务** | 客户端当前会话不再启动 `DeskBox.exe --mcp`，也不暴露 `deskbox_*` 工具 | 无影响，桌面小组件正常运行 |
| **2. 移除 `deskbox-widget` Skill** | 删除客户端本地的 `SKILL.md` 工作流提示；若 MCP 仍启用，客户端依然可通过 `deskbox_get_widget_spec` 使用工具 | 无影响 |
| **3. 彻底移除 DeskBox MCP 配置** | 从客户端配置文件中删除 `deskbox` 条目 | 无影响，桌面小组件保留在本地 |

---

## 二、按客户端彻底移除 MCP 配置

### 1. Claude Code (CLI)

```powershell
claude mcp remove deskbox
```

### 2. OpenAI Codex

```powershell
codex mcp remove deskbox
```

或打开 `~/.codex/config.toml`，删除 `[mcp_servers.deskbox]` 段落。

### 3. Cursor / Windsurf / Trae / Claude Desktop / Antigravity

打开对应客户端的 MCP 配置文件（如 `~/.cursor/mcp.json`），删除 `mcpServers` 下的 `"deskbox"` 对象并保存。

### 4. VS Code

打开 `.vscode/mcp.json` 或用户级 `mcp.json`，删除 `servers` 下的 `"deskbox"` 对象并保存。

### 5. OpenCode

打开 `opencode.json`，删除 `mcp` 下的 `"deskbox"` 对象并保存。

---

## 三、移除可选的本地 Skill

如果你此前手动安装过 `deskbox-widget` Skill，直接删除对应目录即可：

```powershell
# 按需删除已安装的客户端 Skill 目录
Remove-Item -Recurse -Force "$HOME\.codex\skills\deskbox-widget" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$HOME\.claude\skills\deskbox-widget" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$HOME\.cursor\skills\deskbox-widget" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$HOME\.gemini\config\skills\deskbox-widget" -ErrorAction SilentlyContinue
```
