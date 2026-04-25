<#
Velveteen SOC Lite - NetTrace

SAFETY NOTE:
If you suspect an active compromise, avoid saving new scripts directly onto the suspected host.
Prefer copying/pasting into an elevated PowerShell session, running from trusted removable media, or executing from a known-good admin workstation.

This tool is read-only by default.
It collects local network/process telemetry and writes a text report for analyst review.
#>

[CmdletBinding()]
param(
    [ValidateSet("Established", "Listen", "All")]
    [string]$State = "Established",

    [switch]$IncludeLocalhost,

    [string]$OutputDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$report = Join-Path $OutputDir "Velveteen-NetTrace_$timestamp.txt"

function Write-Report {
    param([string]$Text)
    $Text | Out-File -FilePath $report -Append -Encoding UTF8
}

function Get-ProcessInfoSafe {
    param([int]$ProcessId)

    try {
        $proc = Get-Process -Id $ProcessId -ErrorAction Stop
        $cim  = Get-CimInstance Win32_Process -Filter "ProcessId=$ProcessId" -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            ProcessName = $proc.ProcessName
            Path        = $cim.ExecutablePath
            CommandLine = $cim.CommandLine
        }
    }
    catch {
        [PSCustomObject]@{
            ProcessName = "Unknown/AccessDenied"
            Path        = $null
            CommandLine = $null
        }
    }
}

"============================================================" | Out-File $report -Encoding UTF8
"Velveteen NetTrace Report" | Out-File $report -Append -Encoding UTF8
"Generated: $(Get-Date)" | Out-File $report -Append -Encoding UTF8
"Host: $env:COMPUTERNAME" | Out-File $report -Append -Encoding UTF8
"User: $env:USERNAME" | Out-File $report -Append -Encoding UTF8
"============================================================" | Out-File $report -Append -Encoding UTF8

Write-Report ""
Write-Report "SAFETY NOTE:"
Write-Report "If you suspect active compromise, avoid saving new scripts directly onto the suspected host."
Write-Report "Prefer copy/paste execution, trusted removable media, or a known-good admin workstation."
Write-Report ""

Write-Report "--- ACTIVE TCP CONNECTIONS ---"

if ($State -eq "All") {
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
}
else {
    $connections = Get-NetTCPConnection -State $State -ErrorAction SilentlyContinue
}

$results = foreach ($conn in $connections) {
    if (-not $IncludeLocalhost) {
        if (
            $conn.RemoteAddress -eq "127.0.0.1" -or
            $conn.RemoteAddress -eq "::1" -or
            $conn.LocalAddress -eq "127.0.0.1" -or
            $conn.LocalAddress -eq "::1"
        ) {
            continue
        }
    }

    $info = Get-ProcessInfoSafe -ProcessId $conn.OwningProcess

    [PSCustomObject]@{
        Time          = Get-Date
        State         = $conn.State
        Process       = $info.ProcessName
        PID           = $conn.OwningProcess
        LocalAddress  = $conn.LocalAddress
        LocalPort     = $conn.LocalPort
        RemoteAddress = $conn.RemoteAddress
        RemotePort    = $conn.RemotePort
        Path          = $info.Path
        CommandLine   = $info.CommandLine
    }
}

$results |
Sort-Object Process, RemoteAddress, RemotePort |
Format-Table Process, PID, State, LocalAddress, LocalPort, RemoteAddress, RemotePort -AutoSize |
Out-String |
Out-File $report -Append -Encoding UTF8

Write-Report ""
Write-Report "--- PROCESS CONNECTION SUMMARY ---"

$results |
Group-Object Process |
Sort-Object Count -Descending |
Select-Object Count, Name |
Format-Table -AutoSize |
Out-String |
Out-File $report -Append -Encoding UTF8

Write-Report ""
Write-Report "--- FULL DETAILS ---"

$results |
Format-List * |
Out-String |
Out-File $report -Append -Encoding UTF8

Write-Report ""
Write-Report "Report saved to: $report"

Write-Host "Velveteen NetTrace complete."
Write-Host "Report saved to: $report" -ForegroundColor Green

Start-Process notepad.exe $report
