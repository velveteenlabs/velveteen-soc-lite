<#
Velveteen SOC Lite - PersistenceScan

SAFETY NOTE:
If you suspect an active compromise, avoid saving scripts directly to the system.
Prefer copy/paste execution or trusted media.

This tool is read-only.
It reviews common Windows persistence locations and writes a TXT report.
#>

[CmdletBinding()]
param(
    [string]$OutputDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$report = Join-Path $OutputDir "Velveteen-PersistenceScan_$timestamp.txt"

function Write-Report {
    param([string]$Text)
    $Text | Out-File -FilePath $report -Append -Encoding UTF8
}

function Write-Section {
    param([string]$Title)
    Write-Report ""
    Write-Report "============================================================"
    Write-Report $Title
    Write-Report "============================================================"
}

"============================================================" | Out-File $report -Encoding UTF8
"Velveteen Persistence Scan Report" | Out-File $report -Append
"Generated: $(Get-Date)" | Out-File $report -Append
"Host: $env:COMPUTERNAME" | Out-File $report -Append
"User: $env:USERNAME" | Out-File $report -Append
"============================================================" | Out-File $report -Append

Write-Report ""
Write-Report "SAFETY NOTE:"
Write-Report "This tool is read-only. Do not remove persistence entries without validation."
Write-Report ""

Start-Process notepad.exe $report

# Suspicious patterns
$suspiciousPathPattern = "AppData|Temp|Users\\Public|Downloads|ProgramData"
$suspiciousCmdPattern  = "powershell|cmd|wscript|cscript|mshta|rundll32|regsvr32|bitsadmin|certutil|curl|wget|EncodedCommand|IEX|DownloadString|Invoke-WebRequest"

Write-Section "Startup Commands"

try {
    $startup = Get-CimInstance Win32_StartupCommand | Select Name, Command, Location, User

    if ($startup) {
        $startup | Format-Table -AutoSize | Out-String | Out-File $report -Append

        Write-Section "Startup Commands - Findings"
        foreach ($item in $startup) {
            if ($item.Command -match $suspiciousPathPattern -or $item.Command -match $suspiciousCmdPattern) {
                Write-Report "[REVIEW] $($item.Name)"
                Write-Report "Location: $($item.Location)"
                Write-Report "Command : $($item.Command)"
                Write-Report ""
            }
        }
    }
    else {
        Write-Report "No startup commands found."
    }
}
catch {
    Write-Report "Error collecting startup commands: $($_.Exception.Message)"
}

Write-Section "Registry Run Keys"

$runPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $runPaths) {
    Write-Report ""
    Write-Report "Path: $path"

    if (Test-Path $path) {
        try {
            $props = Get-ItemProperty -Path $path

            $props.PSObject.Properties |
            Where-Object { $_.Name -notmatch "^PS" } |
            ForEach-Object {
                $line = "$($_.Name) -> $($_.Value)"
                Write-Report $line

                if ($_.Value -match $suspiciousPathPattern -or $_.Value -match $suspiciousCmdPattern) {
                    Write-Report "  [REVIEW] Suspicious path or command pattern"
                }
            }
        }
        catch {
            Write-Report "Unable to read: $($_.Exception.Message)"
        }
    }
    else {
        Write-Report "Not found."
    }
}

Write-Section "Scheduled Tasks - Non-Microsoft or Scripted Actions"

try {
    $tasks = Get-ScheduledTask | ForEach-Object {
        $task = $_
        $actions = $task.Actions | ForEach-Object {
            "$($_.Execute) $($_.Arguments)"
        }

        [PSCustomObject]@{
            TaskName = $task.TaskName
            TaskPath = $task.TaskPath
            State    = $task.State
            Actions  = ($actions -join "; ")
        }
    }

    $interestingTasks = $tasks | Where-Object {
        $_.TaskPath -notmatch "\\Microsoft\\Windows\\" -or
        $_.Actions -match $suspiciousCmdPattern -or
        $_.Actions -match $suspiciousPathPattern
    }

    if ($interestingTasks) {
        $interestingTasks |
        Sort-Object TaskPath, TaskName |
        Format-Table TaskName, TaskPath, State, Actions -Wrap |
        Out-String |
        Out-File $report -Append

        Write-Section "Scheduled Tasks - Findings"
        foreach ($task in $interestingTasks) {
            if ($task.Actions -match $suspiciousCmdPattern -or $task.Actions -match $suspiciousPathPattern) {
                Write-Report "[REVIEW] $($task.TaskPath)$($task.TaskName)"
                Write-Report "Actions: $($task.Actions)"
                Write-Report ""
            }
        }
    }
    else {
        Write-Report "No non-Microsoft or scripted scheduled tasks found."
    }
}
catch {
    Write-Report "Error collecting scheduled tasks: $($_.Exception.Message)"
}

Write-Section "Auto-Start Services"

try {
    $services = Get-CimInstance Win32_Service |
    Where-Object { $_.StartMode -eq "Auto" } |
    Select Name, DisplayName, State, PathName, StartName

    $services |
    Sort-Object Name |
    Format-Table Name, State, StartName, PathName -Wrap |
    Out-String |
    Out-File $report -Append

    Write-Section "Auto-Start Services - Findings"

    foreach ($svc in $services) {
        if ($svc.PathName -match $suspiciousPathPattern -or $svc.PathName -match $suspiciousCmdPattern) {
            Write-Report "[REVIEW] $($svc.Name) - $($svc.DisplayName)"
            Write-Report "Path: $($svc.PathName)"
            Write-Report "Runs As: $($svc.StartName)"
            Write-Report ""
        }
    }
}
catch {
    Write-Report "Error collecting services: $($_.Exception.Message)"
}

Write-Section "Startup Folders"

$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)

foreach ($folder in $startupFolders) {
    Write-Report ""
    Write-Report "Folder: $folder"

    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Force -ErrorAction SilentlyContinue |
        Select FullName, Length, LastWriteTime |
        Format-Table -AutoSize |
        Out-String |
        Out-File $report -Append
    }
    else {
        Write-Report "Not found."
    }
}

Write-Section "WMI Event Consumers"

try {
    Write-Report "--- Event Filters ---"
    Get-WmiObject -Namespace root\subscription -Class __EventFilter -ErrorAction SilentlyContinue |
    Select Name, EventNamespace, Query |
    Format-List |
    Out-String |
    Out-File $report -Append

    Write-Report "--- CommandLine Consumers ---"
    Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -ErrorAction SilentlyContinue |
    Select Name, CommandLineTemplate |
    Format-List |
    Out-String |
    Out-File $report -Append

    Write-Report "--- ActiveScript Consumers ---"
    Get-WmiObject -Namespace root\subscription -Class ActiveScriptEventConsumer -ErrorAction SilentlyContinue |
    Select Name, ScriptingEngine, ScriptText |
    Format-List |
    Out-String |
    Out-File $report -Append

    Write-Report "--- Filter Bindings ---"
    Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue |
    Select Filter, Consumer |
    Format-List |
    Out-String |
    Out-File $report -Append
}
catch {
    Write-Report "Error collecting WMI persistence data: $($_.Exception.Message)"
}

Write-Section "Analyst Notes"

Write-Report @"
Review does not mean malicious.

Common false positives:
- Updaters
- Game launchers
- Browser helpers
- OEM utilities
- Antivirus services

Higher concern:
- Auto-start entries from Temp, AppData, Downloads, or Users\Public
- Scheduled tasks launching PowerShell, mshta, regsvr32, rundll32, wscript, or certutil
- WMI CommandLineEventConsumer or ActiveScriptEventConsumer entries
- Services with unclear names running from user-writable paths
"@

Write-Report ""
Write-Report "Report saved to: $report"

Write-Host "Velveteen PersistenceScan complete."
Write-Host "Report saved to: $report" -ForegroundColor Green
Start-Process notepad.exe $report
