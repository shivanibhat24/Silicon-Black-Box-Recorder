# 🗃️ Silicon Black Box Recorder (SBBR)

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Verification: UVM & Cocotb](https://img.shields.io/badge/Verification-UVM%20%7C%20Cocotb-blue)
![Language: SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-green)

The **Silicon Black Box Recorder (SBBR)** is a comprehensive, configurable, and robust IP core designed for post-mortem analysis and real-time monitoring of complex System-on-Chip (SoC) environments. Much like a flight recorder for silicon, it aggregates, prioritizes, timestamps, and compresses critical system events (such as voltage droops, PLL unlock errors, and thermal warnings) into an internal trace memory, allowing engineers to diagnose fatal system faults reliably.

---

## 🏗️ Architecture Overview

The SBBR comprises several key micro-architectural components written in SystemVerilog:

- **Top Level (`sbbr_top.sv`)**: Integrates all sub-modules and provides the top-level interfaces (APB, Sensor inputs).
- **APB Slave (`apb_slave.sv`)**: An AMBA APB interface for configuring limits, checking statuses, and reading out traced snapshots.
- **Timestamp Generator (`timestamp_generator.sv`)**: Maintains a monotonically increasing timestamp, ensuring precise chronological tracing.
- **Event Aggregator (`event_aggregator.sv`)**: Funnels multiple sensor inputs and events into a single unified event bus.
- **Event Prioritizer (`event_prioritizer.sv`)**: Arbitrates between concurrent events based on configured severity, ensuring critical errors are never lost.
- **Fault Manager (`fault_manager.sv`)**: Monitors limits and rules, issuing fatal interrupts and snapshot trigger commands upon detecting critical system failures.
- **Trace Compressor (`trace_compressor.sv`)**: Performs delta-compression and zero-suppression to maximize the efficiency of the trace memory footprint.
- **Trace RAM & Circular Buffer (`trace_ram.sv`, `circular_trace_buffer.sv`)**: Stores the compressed event traces in a circular fashion until a snapshot freeze occurs.
- **Snapshot Controller (`snapshot_controller.sv`)**: Freezes the trace buffer upon fault detection to preserve the exact sequence of events leading up to the failure.

---

## 🧪 Verification Environment

This repository features a dual-methodology verification approach to ensure the highest quality IP:

### 1. Cocotb (Python-based Integration Testing)
Located in `verification/tests/`, the Cocotb testbench tests the end-to-end functionality of the RTL modules using Python. It injects faults, monitors APB readbacks, and verifies snapshot behavior over time.

### 2. UVM (Universal Verification Methodology)
Located in `verification/`, the SystemVerilog UVM environment provides constrained-random stimulus, functional coverage, and automated checking.
- **Agents (`agents/`)**: Includes the `sbbr_apb_agent` for APB bus transactions and the `sbbr_sensor_agent` to drive and monitor simulated sensor data.
- **Sequences (`sequences/`)**: Contains base, configuration, and fault-injection sequences for both APB and Sensor agents.
- **Scoreboard (`scoreboards/`)**: Checks data integrity between the sensor input monitors and APB readout monitors.
- **Coverage (`coverage/`)**: A UVM subscriber (`sbbr_coverage.sv`) containing covergroups mapping the functional coverage of APB registers and sensor states.
- **Assertions (`assertions/`)**: SystemVerilog Assertions (`sbbr_assertions.sv`) bound to the RTL to ensure rigorous protocol-level compliance (e.g., APB handshakes) and system-level guarantees.

---

## 🚀 Getting Started

### Prerequisites
- **Icarus Verilog (`iverilog`)** or another SystemVerilog simulator (e.g., Verilator, VCS, Xcelium)
- **Python 3.x** and `cocotb` for the Python tests
- **UVM 1.2** library for the SystemVerilog UVM tests

### Running the Tests

A unified `Makefile` is provided in the repository root to easily select your testing methodology.

**Run Cocotb Tests:**
To run all Python integration tests using Icarus Verilog:
```bash
make test-cocotb
```

**Run UVM Tests:**
To compile and run the full SystemVerilog UVM testbench:
```bash
make test-uvm
```
*(Note: Ensure your simulator path and UVM library are correctly configured in the environment before running UVM).*

**Clean Up:**
To remove generated waveform files (`.vcd`, `.fst`) and compilation artifacts:
```bash
make clean
```

---

## 📂 Directory Structure

```text
Silicon-Black-Box-Recorder-main/
├── rtl/               # SystemVerilog RTL design source code
├── verification/      # UVM testbench environment
│   ├── agents/        # UVM APB and Sensor Agents
│   ├── assertions/    # SystemVerilog Assertions (SVA)
│   ├── coverage/      # UVM Coverage (Covergroups)
│   ├── scoreboards/   # UVM Scoreboard
│   ├── sequences/     # UVM Sequences
│   ├── tb/            # UVM Top, Environment, and Interfaces
│   └── tests/         # Cocotb Python Integration Tests
├── models/            # Behavioral models for sensors and PLLs
├── scripts/           # Useful scripts for CI/CD and automation
├── docs/              # Additional project documentation
└── Makefile           # Root Makefile for test execution
```
