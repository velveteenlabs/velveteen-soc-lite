# Velveteen SOC Lite

Velveteen SOC Lite is a lightweight PowerShell-based endpoint investigation toolkit that simulates a basic SOC-style workflow on a standalone Windows host.

It provides visibility into:
- process activity
- network connections
- persistence mechanisms
- system drivers
- post-boot system state

The toolkit is designed for:
- cybersecurity students
- CTI / SOC portfolio projects
- lab environments
- defensive security learning

---

## 🔍 Features

- Real-time process monitoring (ProcessSentinel)
- Process-to-network correlation (NetTrace)
- Persistence analysis (startup, services, tasks, WMI)
- Driver and kernel-level inspection
- Post-boot baseline capture
- Risk scoring and summary generation
- TXT + HTML reporting

---

## 🧰 Toolkit Modules

| Script | Description |
|------|--------|
| `Velveteen-ProcessSentinel.ps1` | Real-time process monitoring and alerting |
| `Velveteen-NetTrace.ps1` | Maps active network connections to processes |
| `Velveteen-PersistenceScan.ps1` | Detects common persistence mechanisms |
| `Velveteen-DriverInspector.ps1` | Enumerates and evaluates system drivers |
| `Velveteen-BootBaseline.ps1` | Captures system state after boot |
| `Velveteen-Summary.ps1` | Aggregates findings and generates risk score |

---

## ⚡ Quick Start

```powershell
cd scripts

# Run individual modules
.\Velveteen-BootBaseline.ps1
.\Velveteen-PersistenceScan.ps1
.\Velveteen-ProcessSentinel.ps1
.\Velveteen-NetTrace.ps1
.\Velveteen-DriverInspector.ps1

# Generate summary
.\Velveteen-Summary.ps1
