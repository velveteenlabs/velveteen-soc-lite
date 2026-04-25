# Velveteen SOC Lite

Velveteen SOC Lite is a lightweight PowerShell toolkit for Windows endpoint triage and local host monitoring.

It provides a small SOC-style workflow for:

- real-time suspicious process alerts
- process-to-network connection mapping
- startup, scheduled task, and service persistence review
- driver and kernel-adjacent inspection
- post-boot baseline capture

This toolkit is designed for defensive security, student labs, portfolio demonstrations, and endpoint investigation practice.

It does not remove files, kill processes, or modify system settings by default.

## Example Workflow

1. Run BootBaseline after system startup
2. Run PersistenceScan to identify auto-start mechanisms
3. Launch ProcessSentinel for real-time monitoring
4. Use NetTrace to correlate active network connections
5. Investigate suspicious drivers with DriverInspector

## Purpose

This toolkit demonstrates a lightweight, analyst-driven approach to endpoint triage without requiring enterprise EDR tooling.

It is designed to:
- replicate core SOC workflows
- improve visibility on standalone Windows hosts
- support learning, labs, and portfolio demonstrations
