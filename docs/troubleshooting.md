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

DeskBox 的 8 个 MCP 工具分为两类：

- **可离线执行或自动降级的只读/校验工具**（无需桌面宿主运行）：
  - `deskbox_get_widget_spec`
  - `deskbox_get_capability_spec`
  - `deskbox_validate_manifest`
  - `deskbox_get_studio_context`（离线时返回 `hostOnline: false` 降级响应）
  - `deskbox_list_widgets`（离线时自动降级为磁盘只读扫描 `status: "offline-disk-scan"`）
- **需要桌面宿主在线的工具**（通过当前用户命名管道通信）：
  - `deskbox_upsert_widget`
  - `deskbox_capture_widget_preview`
  - `deskbox_push_widget_data`

当后面 3 个工具返回宿主未运行时：
1. 请确认 DeskBox 桌面程序已启动（系统托盘中有 DeskBox 图标）。
2. 请确认启动 AI 客户端的 Windows 账户权限与运行 DeskBox 的账户一致（不要一个在普通权限、一个在管理员提权会话下运行，否则命名管道会话隔离会导致无法互通）。
3. 你可以在 **DeskBox 设置 → AI 与智能体 → 外部 Agent 生态 → 通用配置** 中点击 **本机服务自检**，检查 `MCP stdio` 与 `Named Pipe` 是否均显示绿灯。

---

## 3. 配置后客户端没有反应，或参数写成了伴侣进程模式

- DeskBox 1.6.0 将主宿主、设置中心（`--settings`）、格子工坊（`--studio`）与 MCP 桥接（`--mcp`）统一收敛在同一个可执行程序 `DeskBox.exe` 中（旧开发期独立 `DeskBox.Settings.exe` 已移除）。
- 请确保 MCP 配置中的 `command` 指向 `DeskBox.exe`（或 Store 别名 `deskbox.exe`），且 `args` 为 `["--mcp"]`（切勿指向其它旧版辅助可执行文件或传入 `--settings` / `--studio`）。
- 使用 DeskBox 设置页内置的 **复制口令** 或 **通用配置** 按钮时，应用已自动生成匹配当前渠道的正确配置。
- 若使用 Store 版且禁用了应用执行别名，MCP 工具需要拉起宿主时也会尝试通过 `deskbox://startup` 协议兜底唤起；仍建议开启 `deskbox.exe` 别名以保证 `stdio` 入口可用。

---

## 4. 调用了 `deskbox_upsert_widget` 但桌面上没有出现新小组件，或返回 `requiresHostApproval: true`

- **默认暂存（Stage-by-Default）**：当未传入 `commit: true` 时，工具只校验并暂存小组件配置，返回 `stageId` 供你预览确认（也可以用 `deskbox_capture_widget_preview` 传入 `stageId` 在提交前截预览图），桌面不会发生任何变化。
- **原生宿主审批门禁（Host Approval）**：当你确认后，Agent 传入 `{ "commit": true, "stageId": "<stageId>" }` 提交上桌（注意 `commit: true` 时禁止同时携带 `upsertElements` / `scriptHunks` 等内联编辑，须先重新暂存）。如果本次提交涉及 **覆盖已有小组件、清空现有数据，或包含脚本 / 高危能力**，DeskBox 会弹出原生的桌面审批确认窗（默认焦点在「拒绝」，60 秒无响应自动拒绝）。
  - 如果你点击了拒绝或弹窗超时，工具会返回 `committed: false, staged: true, requiresHostApproval: true`，**暂存包会保留**，Agent 不得自动静默重试，需等你再次明确指示。
  - 提交采用三态租约防重入：同一 `stageId` 正在审批或落盘时并发重放会返回 `CommitInProgress`；落盘完成后重放同一 `stageId` 则幂等返回成功（`idempotent: true`）。
- **外部修改后的权限过期**：外部 Agent 覆盖已有小组件并改动了可执行面（`logic.js` 或高危节点）时，原有的高危能力覆写（局域网/本地文件/命令执行）会自动吊销，需在 DeskBox 中重新授权；`CommandExecution` 永不隐式授予。

---

## 5. 从 WSL2 中调用 DeskBox MCP

- 如果你的 Agent 运行在 Windows 11 的 WSL2 环境中，需要通过 WSL 的 Windows 互操作机制直接调用 Windows 侧的 `DeskBox.exe`（因为命名管道位于 Windows 宿主侧）：
  - **独立安装包示例**：`/mnt/c/Users/<Windows用户名>/AppData/Local/Programs/DeskBox/DeskBox.exe --mcp`
  - **Store 版示例**：`/mnt/c/Users/<Windows用户名>/AppData/Local/Microsoft/WindowsApps/deskbox.exe --mcp`
- 若旧版 WSL 执行 `WindowsApps` 下的应用执行别名重解析点报错，建议在 WSL 内使用独立安装包路径，或在 Windows 原生终端中运行客户端。
