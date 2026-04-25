<#
Velveteen SOC Lite - Summary Generator

Generates:
- TXT summary
- HTML dashboard

Auto-opens both.

Scoring:
HIGH        = 5
SUSPICIOUS  = 2
REVIEW      = 0.25

This reduces alert fatigue by separating low-confidence review items
from stronger suspicious/high-risk findings.
#>

param(
    [string]$ReportDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
}

$reports = Get-ChildItem $ReportDir -Filter *.txt -ErrorAction SilentlyContinue |
Where-Object { $_.Name -notmatch "Velveteen-Summary" }

$totalScore = 0.0
$high = 0
$suspicious = 0
$review = 0

foreach ($file in $reports) {
    $content = Get-Content $file.FullName -ErrorAction SilentlyContinue

    foreach ($line in $content) {
        if ($line -match "\[HIGH\]") {
            $totalScore += 5
            $high++
        }
        elseif ($line -match "\[SUSPICIOUS\]") {
            $totalScore += 2
            $suspicious++
        }
        elseif ($line -match "\[REVIEW\]") {
            $totalScore += 0.25
            $review++
        }
    }
}

$totalScore = [math]::Round($totalScore, 2)

if ($totalScore -ge 10) {
    $risk = "HIGH RISK"
}
elseif ($totalScore -ge 4) {
    $risk = "MODERATE RISK"
}
else {
    $risk = "LOW RISK"
}

$txtOutput = @"
===============================
Velveteen SOC Summary
===============================
Generated: $(Get-Date)
Report Directory: $ReportDir

Risk Level : $risk
Total Score: $totalScore

Breakdown:
HIGH       : $high
SUSPICIOUS : $suspicious
REVIEW     : $review

Scoring Model:
HIGH       = 5
SUSPICIOUS = 2
REVIEW     = 0.25

Reports Analyzed: $($reports.Count)

Analyst Note:
REVIEW findings are low-confidence observations and should not be treated as direct evidence of compromise.
===============================
"@

$txtPath = Join-Path $ReportDir "Velveteen-Summary.txt"
$txtOutput | Out-File $txtPath -Encoding UTF8

$color = switch ($risk) {
    "HIGH RISK" { "#ff4d4d" }
    "MODERATE RISK" { "#ffcc00" }
    "LOW RISK" { "#66cc66" }
}

$html = @"
<html>
<head>
<title>Velveteen SOC Summary</title>
<style>
body {
    font-family: Consolas, monospace;
    background-color: #0d1117;
    color: #c9d1d9;
    padding: 20px;
}
.container {
    border: 1px solid #30363d;
    padding: 24px;
    border-radius: 12px;
    max-width: 850px;
}
h1 {
    color: $color;
}
.box {
    margin-top: 16px;
    padding: 14px;
    border: 1px solid #30363d;
    border-radius: 8px;
    background-color: #161b22;
}
.badge {
    color: #0d1117;
    background-color: $color;
    padding: 6px 10px;
    border-radius: 6px;
    font-weight: bold;
}
small {
    color: #8b949e;
}
</style>
</head>
<body>
<div class="container">
<h1>Velveteen SOC Summary</h1>

<div class="box">
<span class="badge">$risk</span><br><br>
<strong>Total Score:</strong> $totalScore<br>
<strong>Generated:</strong> $(Get-Date)<br>
<strong>Reports Analyzed:</strong> $($reports.Count)
</div>

<div class="box">
<strong>Finding Breakdown</strong><br><br>
HIGH: $high<br>
SUSPICIOUS: $suspicious<br>
REVIEW: $review
</div>

<div class="box">
<strong>Scoring Model</strong><br><br>
HIGH = 5<br>
SUSPICIOUS = 2<br>
REVIEW = 0.25<br><br>
<small>REVIEW findings are low-confidence observations intended for analyst triage, not direct evidence of compromise.</small>
</div>

<div class="box">
<strong>Report Directory</strong><br>
$ReportDir
</div>

</div>
</body>
</html>
"@

$htmlPath = Join-Path $ReportDir "Velveteen-Summary.html"
$html | Out-File $htmlPath -Encoding UTF8

Start-Process $txtPath
Start-Process $htmlPath

Write-Host "Velveteen summary generated:"
Write-Host $txtPath
Write-Host $htmlPath -ForegroundColor Green
