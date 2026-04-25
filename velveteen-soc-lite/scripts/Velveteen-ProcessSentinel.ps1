<#
Velveteen SOC Lite - ProcessSentinel

SAFETY NOTE:
If you suspect an active compromise, avoid saving scripts directly to the system.
Prefer copy/paste execution or trusted media.

This tool is read-only.
It monitors process activity and logs findings for analyst review.
#>

[CmdletBinding()]
param(
    [int]$IntervalSeconds = 2,
    [string]$OutputDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

# === Setup ===
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$report = Join-Path $OutputDir "Velveteen-ProcessSentinel_$timestamp.txt"

function Write-Report {
    param([string]$Text)
    $Text | Out-File -FilePath $report -Append -Encoding UTF8
}

# === Header ===
"============================================================" | Out-File $report -Encoding UTF8
"Velveteen Process Sentinel Report" | Out-File $report -Append
"Generated: $(Get-Date)" | Out-File $report -Append
"Host: $env:COMPUTERNAME" | Out-File $report -Append
"============================================================" | Out-File $report -Append

Write-Report ""
Write-Report "Monitoring processes in real-time..."
Write-Report "Press CTRL+C to stop."
Write-Report ""

Start-Process notepad.exe $report

# === Detection Logic ===
$lolbins = @("powershell","cmd","wscript","cscript","mshta","rundll32","regsvr32")

$seen = @{}

function Get-Severity {
    param($name, $path, $cmd)

    # HIGH severity patterns
    if ($cmd -match "EncodedCommand|FromBase64String|IEX|DownloadString|Invoke-WebRequest") {
        return "HIGH"
    }

    # Suspicious if running from user-writable paths
    if ($path -match "Users\\|AppData\\|Temp\\") {
        return "SUSPICIOUS"
    }

    # REVIEW if LOLBin but no clear abuse
    foreach ($bin in $lolbins) {
        if ($name -match $bin) {
            return "REVIEW"
        }
    }

    return $null
}

# === Monitor Loop ===
while ($true) {
    Get-CimInstance Win32_Process | ForEach-Object {

        if (-not $seen.ContainsKey($_.ProcessId)) {

            $seen[$_.ProcessId] = $true

            $name = $_.Name
            $path = $_.ExecutablePath
            $cmd  = $_.CommandLine

            $severity = Get-Severity $name $path $cmd

            if ($severity) {

                $output = @"
[$severity] Process Observation
Time: $(Get-Date)
Name: $name
PID: $($_.ProcessId)
Path: $path
CommandLine: $cmd
--------------------------------------------
"@

                switch ($severity) {
                    "HIGH" { Write-Host $output -ForegroundColor Red }
                    "SUSPICIOUS" { Write-Host $output -ForegroundColor Yellow }
                    "REVIEW" { Write-Host $output -ForegroundColor Cyan }
                }

                Write-Report $output
            }
        }
    }

    Start-Sleep -Seconds $IntervalSeconds
}
