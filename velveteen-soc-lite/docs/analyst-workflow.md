# Analyst Workflow

This toolkit is designed to simulate a SOC-style endpoint investigation workflow on a standalone Windows host.

---

## Step 1: Establish Baseline

Run:

.\Velveteen-BootBaseline.ps1

Purpose:

* Capture system state after boot
* Identify expected processes, services, drivers
* Establish a reference point for comparison

---

## Step 2: Identify Persistence

Run:

.\Velveteen-PersistenceScan.ps1

Focus on:

* Startup entries
* Scheduled tasks
* Services
* WMI persistence

Goal:

* Identify mechanisms that allow code to survive reboot

---

## Step 3: Monitor Live Activity

Run:

.\Velveteen-ProcessSentinel.ps1

Purpose:

* Observe real-time process creation
* Detect suspicious execution patterns
* Identify LOLBins (living-off-the-land binaries)

---

## Step 4: Correlate Network Activity

Run:

.\Velveteen-NetTrace.ps1

Focus on:

* Which processes are communicating externally
* Unexpected outbound connections
* Unknown remote IPs

Goal:

* Link process behavior to network activity

---

## Step 5: Inspect Drivers

Run:

.\Velveteen-DriverInspector.ps1

Focus on:

* Unsigned drivers
* Drivers outside expected directories
* Unusual kernel-level components

Goal:

* Identify low-level persistence or abuse

---

## Step 6: Generate Summary

Run:

.\Velveteen-Summary.ps1

Purpose:

* Aggregate findings across modules
* Assign overall risk level
* Provide analyst decision support

---

## Key Principle

Do not rely on a single finding.

Always:

* Correlate across modules
* Validate context
* Compare against baseline
* Look for patterns, not isolated events

---

## Investigation Flow Summary

Baseline → Persistence → Live Activity → Network → Drivers → Summary

---

## Analyst Mindset

This toolkit supports investigation, not automation.

The analyst should:

* Interpret findings
* Validate assumptions
* Avoid overreacting to low-confidence signals
* Focus on meaningful patterns and anomalies
