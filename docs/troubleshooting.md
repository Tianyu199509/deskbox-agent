# 常见问题与排障指南

---

## 1. 提示找不到 `deskbox.exe` 命令（Store 版）

- **原因**：`deskbox.exe` 是 Microsoft Store 包声明的 Windows 应用执行别名（`uap5:AppExecutionAlias`）。如果你安装的是独立安装包（`.exe` 安装器），或者系统关闭了该别名，直接运行 `deskbox.exe` 会提示找不到命令。
- **排查步骤**：
  1. 若你使用的是 **独立安装包 / 便携版**，请打开 **DeskBox 设置 → AI 与智能体 → 外部 Agent 生态 → 通用配置**，复制完整的 `DeskBox.exe` 路径配置。
  2. 若你使用的是 **Microsoft Store 版**，请打开 Windows **设置 → 应用 → 高级应用设置 → 应用执行别名**，确认 **DeskBox (`deskbox.exe`)** 处于开启状态。
  3. 在 PowerShell 中运行 `Get-Command deskbox.exe` 验证路径是否解析到 `%LOCALAPPDATA%\Microsoft\WindowsApps\deskbox.exe`。

---

## 2. 工具调用返回“DeskBox 桌面宿主未运行”（Host Not Running）

DeskBox 的 7 个 MCP 工具分为两类：

- **可离线执行的纯规范/校验工具**（无需桌面宿主运行）：
  - `deskbox_get_widget_spec`
  - `deskbox_get_capability_spec`
  - `deskbox_validate_manifest`
- **需要桌面宿主在线的工具**（通过当前用户命名管道通信）：
  - `deskbox_list_widgets`
  - `deskbox_upsert_widget`
  - `deskbox_capture_widget_preview`
  - `deskbox_push_widget_data`

当后面 4 个工具返回宿主未运行时：
1. 请确认 DeskBox 桌面程序已启动（系统托盘中有 DeskBox 图标）。
2. 请确认启动 AI 客户端的 Windows 账户权限与运行 DeskBox 的账户一致（不要一个在普通权限、一个在管理员提权会话下运行，否则命名管道会话隔离会导致无法互通）。
3. 你可以在 **DeskBox 设置 → AI 与智能体 → 外部 Agent 生态 → 通用配置** 中点击 **本机服务自检**，检查 `MCP stdio` 与 `Named Pipe` 是否均显示绿灯。

---

## 3. 配置后客户端没有反应，或指向了 `DeskBox.Settings.exe`

- DeskBox 的设置界面运行在独立的伴生进程 `DeskBox.Settings.exe` 中，而 MCP 服务入口位于主程序 `DeskBox.exe`。
- 请确保 MCP 配置中的 `command` 指向 `DeskBox.exe`（或 Store 别名 `deskbox.exe`），**不要**指向 `DeskBox.Settings.exe`。
- 使用 DeskBox 设置页内置的 **复制口令** 或 **通用配置** 按钮时，应用已自动将路径解析为主程序 `DeskBox.exe`。

---

## 4. 调用了 `deskbox_upsert_widget` 但桌面上没有出现新小组件

- 这是预期设计：`deskbox_upsert_widget` 采用 **默认暂存（Stage-by-Default）** 机制。
- 当未传入 `commit: true` 时，工具只校验并暂存小组件配置，返回 `stageId` 供你预览确认，桌面不会发生任何变化。
- 当你向 Agent 确认效果后，Agent 传入 `commit: true` 及对应的 `stageId` 和完整 `manifestJson`，小组件才会正式安装并刷新到桌面上。

---

## 5. 从 WSL2 中调用 DeskBox MCP

- 如果你的 Agent 运行在 Windows 11 的 WSL2 环境中，需要通过 WSL 的 Windows 互操作机制直接调用 Windows 侧的 `DeskBox.exe`（因为命名管道位于 Windows 宿主侧）：
  - **独立安装包示例**：`/mnt/c/Users/<Windows用户名>/AppData/Local/Programs/DeskBox/DeskBox.exe --mcp`
  - **Store 版示例**：`/mnt/c/Users/<Windows用户名>/AppData/Local/Microsoft/WindowsApps/deskbox.exe --mcp`
- 若旧版 WSL 执行 `WindowsApps` 下的应用执行别名重解析点报错，建议在 WSL 内使用独立安装包路径，或在 Windows 原生终端中运行客户端。
