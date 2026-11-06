<#
.SYNOPSIS
Detects whether DeskBox (v1.6.0+) is installed and running on Windows, resolves the exact MCP command,
and optionally downloads, SHA256-verifies, installs, and starts DeskBox from the official GitHub Release.

.DESCRIPTION
Designed for AI Agents (Claude Code, Codex, Cursor, VS Code Copilot, Windsurf, Trae, Antigravity, OpenCode).
- Run without flags to inspect installation status and get the exact MCP command JSON.
- Run with -StartHost to start the DeskBox desktop host if installed but not running.
- Run with -Install -StartHost (ONLY after asking user confirmation) to download the latest official
  DeskBox installer for the current CPU architecture (x64/arm64), verify its SHA-256 checksum,
  install it silently, start the desktop host, and output the MCP configuration JSON.
#>
[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$StartHost,
    [switch]$OpenReleasePage
)

$ErrorActionPreference = 'Stop'
$DeskBoxAppId = '{5E052824-3456-427E-9759-3BCAE078A1D3}_is1'
$GitHubRepo = 'Tianyu199509/DeskBox'
$LatestReleaseApi = "https://api.github.com/repos/$GitHubRepo/releases/latest"
$ReleasesHtmlUrl = "https://github.com/$GitHubRepo/releases/latest"

function Find-DeskBoxInstallation {
    # 1. Check running DeskBox process first
    $runningProc = Get-Process -Name 'DeskBox' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and (Test-Path $_.Path) } |
        Select-Object -First 1
    if ($runningProc) {
        $path = $runningProc.Path
        $isStore = $path -like '*\WindowsApps\*'
        return @{
            Installed = $true
            Channel   = if ($isStore) { 'store' } else { 'direct' }
            ExePath   = $path
        }
    }

    # 2. Check Microsoft Store App Execution Alias + AppxPackage
    $aliasPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\deskbox.exe'
    $appx = Get-AppxPackage -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*DeskBox*' -or $_.PackageFamilyName -like '*DeskBox*' } |
        Select-Object -First 1
    if ($appx -and (Test-Path $aliasPath)) {
        return @{
            Installed = $true
            Channel   = 'store'
            ExePath   = $aliasPath
        }
    }

    # 3. Check Inno Setup Uninstall Registry (handles custom installation directories)
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$DeskBoxAppId",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$DeskBoxAppId",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$DeskBoxAppId"
    )
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            $props = Get-ItemProperty -LiteralPath $regPath -ErrorAction SilentlyContinue
            if ($props -and $props.InstallLocation) {
                $candidate = Join-Path $props.InstallLocation.TrimEnd('\') 'DeskBox.exe'
                if (Test-Path $candidate) {
                    return @{
                        Installed = $true
                        Channel   = 'direct'
                        ExePath   = $candidate
                    }
                }
            }
        }
    }

    # 4. Check standard Direct install directories
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\DeskBox\DeskBox.exe'),
        (Join-Path $env:ProgramFiles 'DeskBox\DeskBox.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return @{
                Installed = $true
                Channel   = 'direct'
                ExePath   = $candidate
            }
        }
    }

    return @{
        Installed = $false
        Channel   = 'none'
        ExePath   = $null
    }
}

function Get-ExeVersionInfo([string]$exePath) {
    try {
        $vi = (Get-Item -LiteralPath $exePath).VersionInfo
        if ($vi -and $vi.ProductVersion) {
            $clean = ($vi.ProductVersion -split '\+')[0].Trim()
            return $clean
        }
    } catch { }
    return 'unknown'
}

function Test-McpSupported([string]$exePath) {
    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $psi = New-Object System.Diagnostics.ProcessStartInfo($exePath, '--mcp')
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = $utf8NoBom
        $p = [System.Diagnostics.Process]::Start($psi)
        $payload = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' + "`n" +
                   '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"deskbox_list_widgets","arguments":{}}}' + "`n"
        $bytes = $utf8NoBom.GetBytes($payload)
        $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
        $p.StandardInput.BaseStream.Flush()
        $p.StandardInput.Close()
        $out = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit(4000) | Out-Null
        $lines = $out -split "`r?`n" | Where-Object { $_ -ne '' }
        if ($lines.Count -ge 1) {
            $initDoc = $lines[0] | ConvertFrom-Json
            $mcpOk = [bool]($initDoc.result.serverInfo.name -eq 'deskbox')
            $pipeOnline = $false
            if ($lines.Count -ge 2) {
                $callDoc = $lines[1] | ConvertFrom-Json
                $pipeOnline = ($callDoc.result.isError -eq $false)
            }
            return @{
                McpSupported = $mcpOk
                PipeOnline   = $pipeOnline
            }
        }
    } catch { }
    return @{
        McpSupported = $false
        PipeOnline   = $false
    }
}

function Install-LatestDeskBox {
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
    $headers = @{ 'User-Agent' = 'DeskBox-Agent-Bootstrap/1.6' }
    $release = Invoke-RestMethod -Uri $LatestReleaseApi -Headers $headers -TimeoutSec 20

    $exeAsset = $release.assets |
        Where-Object { $_.name -match "^DeskBox_Setup_.*_${arch}\.exe$" } |
        Select-Object -First 1
    $shaAsset = $release.assets |
        Where-Object { $_.name -eq "$($exeAsset.name).sha256" } |
        Select-Object -First 1

    if (-not $exeAsset) {
        throw "Could not find installer asset for architecture '$arch' in release $($release.tag_name)."
    }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "deskbox-bootstrap-$([Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    try {
        $installerPath = Join-Path $tempDir $exeAsset.name
        Invoke-WebRequest -Uri $exeAsset.browser_download_url -Headers $headers -OutFile $installerPath -TimeoutSec 180

        # Verify SHA-256 checksum before executing installer
        $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedHash = $null
        if ($exeAsset.digest -and $exeAsset.digest -match '^sha256:([0-9a-fA-F]{64})$') {
            $expectedHash = $Matches[1].ToLowerInvariant()
        } elseif ($shaAsset) {
            $shaText = Invoke-RestMethod -Uri $shaAsset.browser_download_url -Headers $headers -TimeoutSec 15
            if ($shaText -match '([0-9a-fA-F]{64})') {
                $expectedHash = $Matches[1].ToLowerInvariant()
            }
        }

        if (-not $expectedHash) {
            throw "Refusing to run installer without a verifiable SHA-256 checksum from official release metadata."
        }
        if ($actualHash -ne $expectedHash) {
            throw "SHA-256 mismatch for $($exeAsset.name): expected $expectedHash, got $actualHash."
        }

        $proc = Start-Process -FilePath $installerPath -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -Wait -PassThru
        if ($proc.ExitCode -ne 0) {
            throw "DeskBox installer exited with code $($proc.ExitCode)."
        }
    } finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($OpenReleasePage) {
    Start-Process $ReleasesHtmlUrl | Out-Null
}

$info = Find-DeskBoxInstallation

if (-not $info.Installed -and $Install) {
    Install-LatestDeskBox
    $info = Find-DeskBoxInstallation
}

if (-not $info.Installed) {
    $result = [ordered]@{
        installed       = $false
        channel         = 'none'
        version         = $null
        mcpSupported    = $false
        exePath         = $null
        mcpCommand      = $null
        mcpArgs         = @('--mcp')
        mcpCommandLine  = $null
        hostRunning     = $false
        pipeOnline      = $false
        releasesUrl     = $ReleasesHtmlUrl
        nextAction      = 'DeskBox is not installed on this PC. Ask the user for confirmation first, then run this script with -Install -StartHost to download, SHA256-verify, install, and launch DeskBox automatically, or pass -OpenReleasePage for manual installation.'
    }
    $result | ConvertTo-Json -Depth 4
    exit 0
}

$probe = Test-McpSupported -exePath $info.ExePath
$hostRunning = [bool](Get-Process -Name 'DeskBox' -ErrorAction SilentlyContinue)

if ($StartHost -and -not $probe.PipeOnline) {
    if ($info.Channel -eq 'store') {
        Start-Process 'deskbox.exe' | Out-Null
    } else {
        Start-Process -FilePath $info.ExePath | Out-Null
    }

    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 500
        $probe = Test-McpSupported -exePath $info.ExePath
        if ($probe.PipeOnline) {
            $hostRunning = $true
            break
        }
    }
}

$mcpCommand = if ($info.Channel -eq 'store') { 'deskbox.exe' } else { $info.ExePath }
$mcpCommandLine = if ($info.Channel -eq 'store') { 'deskbox.exe --mcp' } else { "`"$($info.ExePath)`" --mcp" }
$version = Get-ExeVersionInfo -exePath $info.ExePath

$nextAction = if (-not $probe.McpSupported) {
    'Installed DeskBox version is older than v1.6.0 and does not support --mcp. Ask the user for confirmation, then run this script with -Install -StartHost to upgrade to the latest release.'
} elseif (-not $probe.PipeOnline) {
    'DeskBox is installed and supports --mcp, but the desktop host is not running. Run this script with -StartHost or start DeskBox so live desktop widget tools (deskbox_list_widgets, deskbox_upsert_widget, deskbox_capture_widget_preview) are online.'
} else {
    'DeskBox and its Named Pipe host are online. Register the MCP server using mcpCommand and mcpArgs, then call deskbox_get_widget_spec.'
}

$result = [ordered]@{
    installed       = $true
    channel         = $info.Channel
    version         = $version
    mcpSupported    = [bool]$probe.McpSupported
    exePath         = $info.ExePath
    mcpCommand      = $mcpCommand
    mcpArgs         = @('--mcp')
    mcpCommandLine  = $mcpCommandLine
    hostRunning     = $hostRunning
    pipeOnline      = [bool]$probe.PipeOnline
    hostPid         = $probe.HostPid
    nextAction      = $nextAction
}

$result | ConvertTo-Json -Depth 4
