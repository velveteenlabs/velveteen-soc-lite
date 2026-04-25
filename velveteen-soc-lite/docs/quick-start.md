# Velveteen SOC Lite Documentation

---

# 📄 docs/quick-start.md

## Quick Start

### Requirements

* Windows 10/11
* PowerShell 5.1+
* No external dependencies

---

### Running the Toolkit

Open PowerShell and navigate to the scripts folder:

cd scripts

Run individual modules:

.\Velveteen-BootBaseline.ps1
.\Velveteen-PersistenceScan.ps1
.\Velveteen-ProcessSentinel.ps1
.\Velveteen-NetTrace.ps1
.\Velveteen-DriverInspector.ps1

Generate summary:

.\Velveteen-Summary.ps1

---

### Output Location

All reports are saved to:

Desktop\Velveteen-SOC-Reports

Each script:

* creates a .txt report
* automatically opens it
* logs findings for review

---

### Notes

* Scripts are read-only
* No system changes are made
* Administrator privileges recommended

---

# 📄 docs/analyst-workflow.md

## Analyst Workflow

This toolkit simulates a SOC-style investigation flow.

---

### Step 1: Establish Baseline

Run:

.\Velveteen-BootBaseline.ps1

Purpose:

* capture system state after boot
* identify expected processes, services, drivers

---

### Step 2: Identify Persistence

Run:

.\Velveteen-PersistenceScan.ps1

Focus:

* startup entries
* scheduled tasks
* services
* WMI persistence

---

### Step 3: Monitor Live Activity

Run:

.\Velveteen-ProcessSentinel.ps1

Purpose:

* observe real-time process creation
* identify suspicious execution patterns

---

### Step 4: Correlate Network Activity

Run:

.\Velveteen-NetTrace.ps1

Focus:

* unexpected external connections
* unusual processes communicating externally

---

### Step 5: Inspect Drivers

Run:

.\Velveteen-DriverInspector.ps1

Focus:

* unsigned drivers
* drivers outside system directories
* unusual kernel components

---

### Step 6: Generate Summary

Run:

.\Velveteen-Summary.ps1

Purpose:

* aggregate findings
* assign risk level
* guide analyst focus

---

### Key Principle

Do not rely on a single finding.

Always:

* correlate across modules
* validate context
* separate signal from noise

---

# 📄 docs/findings-guide.md

## Findings Guide

This explains how to interpret results.

---

### Severity Levels

#### HIGH

Strong indicators of malicious activity.

Examples:

* encoded PowerShell
* execution from Temp/AppData
* unsigned drivers

Action:
→ investigate immediately

---

#### SUSPICIOUS

Requires investigation.

Examples:

* unusual persistence
* unknown network connections
* odd service paths

Action:
→ correlate and validate

---

#### REVIEW

Low-confidence observation.

Examples:

* cmd / PowerShell usage
* updater activity
* browser helpers

Action:
→ only investigate if correlated

---

### Important Concept

REVIEW ≠ malicious

---

### Common False Positives

* antivirus
* game launchers
* browser extensions
* OEM utilities
* updaters

---

### What to Validate

1. file path
2. signature
3. command line
4. parent process
5. network activity
6. frequency

---

### Analyst Mindset

Focus on:

* patterns
* correlation
* deviation from baseline

This toolkit supports analysis—it does not replace it.
