<#
Velveteen SOC Lite - DriverInspector

SAFETY NOTE:
If you suspect an active compromise, avoid saving scripts directly to the system.
Prefer copy/paste execution or trusted media.

This tool is read-only.
It enumerates system drivers, reviews driver registry entries, checks file signatures,
and highlights drivers that may deserve analyst review.
#>

[CmdletBinding()]
param(
    [string]$OutputDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$report = Join-Path $OutputDir "Velveteen-DriverInspector_$timestamp.txt"

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

function Normalize-DriverPath {
    param([string]$PathName)

    if ([string]::IsNullOrWhiteSpace($PathName)) {
        return $null
    }

    $clean = $PathName.Trim('"')

    if ($clean.StartsWith("\??\")) {
        $clean = $clean.Replace("\??\", "")
    }

    if ($clean.StartsWith("System32\")) {
        $clean = Join-Path $env:WINDIR $clean
    }

    if ($clean.StartsWith("\SystemRoot\")) {
        $clean = $clean.Replace("\SystemRoot", $env:WINDIR)
    }

    if ($clean.StartsWith("system32\", [System.StringComparison]::OrdinalIgnoreCase)) {
        $clean = Join-Path $env:WINDIR $clean
    }

    return $clean
}

function Get-DriverSeverity {
    param(
        [string]$Name,
        [string]$Path,
        [string]$SignatureStatus,
        [string]$StartMode,
        [bool]$Exists
    )

    if (-not $Exists) {
        return "REVIEW"
    }

    if ($SignatureStatus -match "NotSigned|HashMismatch|UnknownError|NotTrusted") {
        return "HIGH"
    }

    if ($Path -match "\\AppData\\|\\Temp\\|\\Users\\Public\\|\\Downloads\\") {
        return "HIGH"
    }

    if ($Path -match "\\ProgramData\\") {
        return "REVIEW"
    }

    if ($StartMode -match "Boot|System" -and $Path -notmatch "\\Windows\\System32\\|\\Windows\\system32\\") {
        return "SUSPICIOUS"
    }

    return $null
}

"============================================================" | Out-File $report -Encoding UTF8
"Velveteen Driver Inspector Report" | Out-File $report -Append
"Generated: $(Get-Date)" | Out-File $report -Append
"Host: $env:COMPUTERNAME" | Out-File $report -Append
"User: $env:USERNAME" | Out-File $report -Append
"============================================================" | Out-File $report -Append

Write-Report ""
Write-Report "SAFETY NOTE:"
Write-Report "This tool is read-only. Do not remove drivers based only on one finding."
Write-Report "Validate signatures, paths, service config, vendor context, and behavior first."

Start-Process notepad.exe $report

Write-Section "System Drivers"

$drivers = Get-CimInstance Win32_SystemDriver | Sort-Object Name

$driverResults = foreach ($driver in $drivers) {
    $normalizedPath = Normalize-DriverPath $driver.PathName
    $exists = $false
    $sigStatus = "NotChecked"
    $signer = $null
    $hash = $null

    if ($normalizedPath -and (Test-Path $normalizedPath)) {
        $exists = $true

        try {
            $sig = Get-AuthenticodeSignature $normalizedPath
            $sigStatus = $sig.Status
            $signer = $sig.SignerCertificate.Subject
        }
        catch {
            $sigStatus = "SignatureCheckError"
        }

        try {
            $hash = (Get-FileHash $normalizedPath -Algorithm SHA256).Hash
        }
        catch {
            $hash = "HashError"
        }
    }

    $severity = Get-DriverSeverity `
        -Name $driver.Name `
        -Path $normalizedPath `
        -SignatureStatus $sigStatus `
        -StartMode $driver.StartMode `
        -Exists $exists

    [PSCustomObject]@{
        Severity        = $severity
        Name            = $driver.Name
        DisplayName     = $driver.DisplayName
        State           = $driver.State
        Started         = $driver.Started
        StartMode       = $driver.StartMode
        ServiceType     = $driver.ServiceType
        Path            = $normalizedPath
        Exists          = $exists
        SignatureStatus = $sigStatus
        Signer          = $signer
        SHA256          = $hash
    }
}

$driverResults |
Format-Table Name, State, Started, StartMode, SignatureStatus, Path -Wrap |
Out-String |
Out-File $report -Append

Write-Section "Driver Findings"

$findings = $driverResults | Where-Object { $_.Severity }

if ($findings) {
    $findings |
    Sort-Object Severity, Name |
    Format-Table Severity, Name, StartMode, SignatureStatus, Path -Wrap |
    Out-String |
    Out-File $report -Append

    Write-Report ""
    Write-Report "--- Detailed Findings ---"

    foreach ($finding in $findings) {
        Write-Report ""
        Write-Report "[$($finding.Severity)] $($finding.Name)"
        Write-Report "DisplayName     : $($finding.DisplayName)"
        Write-Report "State           : $($finding.State)"
        Write-Report "Started         : $($finding.Started)"
        Write-Report "StartMode       : $($finding.StartMode)"
        Write-Report "Path            : $($finding.Path)"
        Write-Report "Exists          : $($finding.Exists)"
        Write-Report "SignatureStatus : $($finding.SignatureStatus)"
        Write-Report "Signer          : $($finding.Signer)"
        Write-Report "SHA256          : $($finding.SHA256)"
    }
}
else {
    Write-Report "No driver findings matched review/high-risk heuristics."
}

Write-Section "Driver Registry Entries"

try {
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" |
    ForEach-Object {
        $svc = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue

        if ($svc.Type -eq 1 -or $svc.Type -eq 2) {
            [PSCustomObject]@{
                ServiceName  = Split-Path $_.Name -Leaf
                Type         = $svc.Type
                Start        = $svc.Start
                ErrorControl = $svc.ErrorControl
                ImagePath    = $svc.ImagePath
                DisplayName  = $svc.DisplayName
            }
        }
    } |
    Sort-Object ServiceName |
    Format-Table ServiceName, Start, Type, ImagePath -Wrap |
    Out-String |
    Out-File $report -Append
}
catch {
    Write-Report "Error reading driver registry entries: $($_.Exception.Message)"
}

Write-Section "PnP Driver Packages"

try {
    pnputil /enum-drivers | Out-File $report -Append -Encoding UTF8
}
catch {
    Write-Report "Error running pnputil: $($_.Exception.Message)"
}

Write-Section "Analyst Notes"

Write-Report @"
Severity guide:

REVIEW:
- Driver path missing
- Driver loaded from ProgramData
- Worth validating, not automatically malicious

SUSPICIOUS:
- Boot/System driver outside expected Windows driver paths
- Requires deeper validation

HIGH:
- Unsigned or invalid signature
- Driver from Temp, AppData, Downloads, or Users\Public
- Strong candidate for urgent investigation

Common false positives:
- Hardware monitoring tools
- OEM control utilities
- Antivirus drivers
- VPN drivers
- Anti-cheat drivers
- Virtualization drivers

Recommended validation:
1. Check signature chain
2. Check SHA256 hash consistency
3. Inspect registry service config
4. Correlate with installed software
5. Check process/network behavior
6. Avoid deleting drivers blindly
"@

Write-Report ""
Write-Report "Report saved to: $report"

Write-Host "Velveteen DriverInspector complete."
Write-Host "Report saved to: $report" -ForegroundColor Green

Start-Process notepad.exe $report
