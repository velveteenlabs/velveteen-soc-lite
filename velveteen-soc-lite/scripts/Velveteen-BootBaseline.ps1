<#
Velveteen SOC Lite - BootBaseline

SAFETY NOTE:
If you suspect an active compromise, avoid saving scripts directly to the system.
Prefer copy/paste execution or trusted media.

This tool is read-only.
It captures a post-boot system baseline and writes a TXT report for comparison.
#>

[CmdletBinding()]
param(
    [int]$DelaySeconds = 30,
    [string]$OutputDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$report = Join-Path $OutputDir "Velveteen-BootBaseline_$timestamp.txt"

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
"Velveteen Boot Baseline Report" | Out-File $report -Append
"Generated: $(Get-Date)" | Out-File $report -Append
"Host: $env:COMPUTERNAME" | Out-File $report -Append
"User: $env:USERNAME" | Out-File $report -Append
"DelaySeconds: $DelaySeconds" | Out-File $report -Append
"============================================================" | Out-File $report -Append

Write-Report ""
Write-Report "Waiting $DelaySeconds seconds for post-boot services to settle..."
Start-Sleep -Seconds $DelaySeconds

Start-Process notepad.exe $report

Write-Section "System Info"

Get-ComputerInfo |
Select CsName, WindowsProductName, WindowsVersion, OsBuildNumber, OsArchitecture, BiosManufacturer, BiosVersion |
Format-List |
Out-String |
Out-File $report -Append

Write-Section "Boot Time"

Get-CimInstance Win32_OperatingSystem |
Select LastBootUpTime, LocalDateTime |
Format-List |
Out-String |
Out-File $report -Append

Write-Section "Running Processes"

Get-CimInstance Win32_Process |
Select ProcessId, ParentProcessId, Name, ExecutablePath, CommandLine |
Sort-Object Name |
Format-Table -Wrap |
Out-String |
Out-File $report -Append

Write-Section "Established Network Connections"

Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
ForEach-Object {
    $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Process       = $p.ProcessName
        PID           = $_.OwningProcess
        LocalAddress  = $_.LocalAddress
        LocalPort     = $_.LocalPort
        RemoteAddress = $_.RemoteAddress
        RemotePort    = $_.RemotePort
        State         = $_.State
    }
} |
Sort-Object Process, RemoteAddress |
Format-Table -AutoSize |
Out-String |
Out-File $report -Append

Write-Section "Listening Ports"

Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
ForEach-Object {
    $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Process      = $p.ProcessName
        PID          = $_.OwningProcess
        LocalAddress = $_.LocalAddress
        LocalPort    = $_.LocalPort
    }
} |
Sort-Object LocalPort |
Format-Table -AutoSize |
Out-String |
Out-File $report -Append

Write-Section "Auto-Start Services"

Get-CimInstance Win32_Service |
Where-Object { $_.StartMode -eq "Auto" } |
Select Name, DisplayName, State, StartName, PathName |
Sort-Object Name |
Format-Table -Wrap |
Out-String |
Out-File $report -Append

Write-Section "Startup Commands"

Get-CimInstance Win32_StartupCommand |
Select Name, Command, Location, User |
Format-Table -Wrap |
Out-String |
Out-File $report -Append

Write-Section "Scheduled Tasks - Non-Microsoft"

Get-ScheduledTask |
Where-Object { $_.TaskPath -notmatch "\\Microsoft\\Windows\\" } |
Select TaskName, TaskPath, State |
Sort-Object TaskPath, TaskName |
Format-Table -AutoSize |
Out-String |
Out-File $report -Append

Write-Section "System Drivers - Running"

Get-CimInstance Win32_SystemDriver |
Where-Object { $_.Started -eq $true } |
Select Name, DisplayName, State, StartMode, PathName |
Sort-Object Name |
Format-Table -Wrap |
Out-String |
Out-File $report -Append

Write-Section "Firewall Profiles"

Get-NetFirewallProfile |
Select Name, Enabled, DefaultInboundAction, DefaultOutboundAction, LogAllowed, LogBlocked, LogFileName |
Format-Table -AutoSize |
Out-String |
Out-File $report -Append

Write-Section "RDP and WinRM"

try {
    Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections |
    Select fDenyTSConnections |
    Format-List |
    Out-String |
    Out-File $report -Append
}
catch {
    Write-Report "Unable to read RDP setting: $($_.Exception.Message)"
}

Get-Service WinRM -ErrorAction SilentlyContinue |
Select Name, Status, StartType |
Format-Table -AutoSize |
Out-String |
Out-File $report -Append

Write-Section "WMI Event Consumers"

Get-WmiObject -Namespace root\subscription -Class __EventFilter -ErrorAction SilentlyContinue |
Select Name, EventNamespace, Query |
Format-List |
Out-String |
Out-File $report -Append

Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -ErrorAction SilentlyContinue |
Select Name, CommandLineTemplate |
Format-List |
Out-String |
Out-File $report -Append

Get-WmiObject -Namespace root\subscription -Class ActiveScriptEventConsumer -ErrorAction SilentlyContinue |
Select Name, ScriptingEngine, ScriptText |
Format-List |
Out-String |
Out-File $report -Append

Write-Section "Analyst Notes"

Write-Report @"
Use this report as a known-good or post-boot comparison snapshot.

High-value comparison points:
- New auto-start services
- New scheduled tasks
- New startup commands
- New running drivers
- New listening ports
- New unknown process-to-network connections
- Changes in firewall profile state

This script is read-only and does not modify the system.
"@

Write-Report ""
Write-Report "Report saved to: $report"

Write-Host "Velveteen BootBaseline complete."
Write-Host "Report saved to: $report" -ForegroundColor Green
Start-Process notepad.exe $report
