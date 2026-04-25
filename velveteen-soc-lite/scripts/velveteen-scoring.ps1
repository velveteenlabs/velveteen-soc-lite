<#
Velveteen SOC Lite - Summary Generator

Generates:
- TXT summary (analyst quick view)
- HTML dashboard (visual overview)

Auto-opens both.
#>

param(
    [string]$ReportDir = "$env:USERPROFILE\Desktop\Velveteen-SOC-Reports"
)

$reports = Get-ChildItem $ReportDir -Filter *.txt -ErrorAction SilentlyContinue

$totalScore = 0
$high = 0
$suspicious = 0
$review = 0

foreach ($file in $reports) {
    $content = Get-Content $file.FullName -ErrorAction SilentlyContinue

    foreach ($line in $content) {
        if ($line -match "\[HIGH\]") { $totalScore += 3; $high++ }
        elseif ($line -match "\[SUSPICIOUS\]") { $totalScore += 2; $suspicious++ }
        elseif ($line -match "\[REVIEW\]") { $totalScore += 1; $review++ }
    }
}

# Risk level
if ($totalScore -ge 8) { $risk = "HIGH RISK" }
elseif ($totalScore -ge 4) { $risk = "MODERATE RISK" }
else { $risk = "LOW RISK" }

# === TXT OUTPUT ===
$txtOutput = @"
===============================
Velveteen SOC Summary
===============================
Total Score: $totalScore
Risk Level : $risk

Breakdown:
HIGH       : $high
SUSPICIOUS : $suspicious
REVIEW     : $review

Reports Analyzed: $($reports.Count)
===============================
"@

$txtPath = Join-Path $ReportDir "Velveteen-Summary.txt"
$txtOutput | Out-File $txtPath -Encoding UTF8

# === HTML OUTPUT ===
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
    padding: 20px;
    border-radius: 10px;
}
h1 {
    color: $color;
}
.box {
    margin-top: 15px;
    padding: 10px;
    border: 1px solid #30363d;
    border-radius: 5px;
}
</style>
</head>
<body>
<div class="container">
<h1>Velveteen SOC Summary</h1>

<div class="box">
<strong>Risk Level:</strong> $risk<br>
<strong>Total Score:</strong> $totalScore
</div>

<div class="box">
<strong>Breakdown:</strong><br>
HIGH: $high<br>
SUSPICIOUS: $suspicious<br>
REVIEW: $review
</div>

<div class="box">
<strong>Reports Analyzed:</strong> $($reports.Count)
</div>

</div>
</body>
</html>
"@

$htmlPath = Join-Path $ReportDir "Velveteen-Summary.html"
$html | Out-File $htmlPath -Encoding UTF8

# === OPEN BOTH ===
Start-Process $txtPath
Start-Process $htmlPath

Write-Host "Summary generated:"
Write-Host $txtPath
Write-Host $htmlPath -ForegroundColor Green
