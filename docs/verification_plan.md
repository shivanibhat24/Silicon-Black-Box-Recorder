# SBBR Verification Plan

## Methodology

Cocotb-based verification using Icarus Verilog (iverilog) as the simulator. Tests written in Python, driving the DUT via VPI through cocotb's coroutine framework.

## Test Modules

### 1. Timestamp Generator (`test_timestamp_generator.py`)
- Verify counter increments on each enabled clock
- Verify counter holds when enable is deasserted
- Verify wrap_pulse fires at counter overflow
- Verify synchronous reset clears counter

### 2. Event Aggregator (`test_event_aggregator.py`)
- Single-source event pass-through
- Multi-source arbitration (highest index wins)
- Back-pressure / drop counting
- Reset behavior

### 3. Event Prioritizer (`test_event_prioritizer.py`)
- Severity filtering at each threshold level
- Rate limiting of low-priority events
- FATAL events bypass all filters
- Configuration via CSR inputs

### 4. Trace Compressor (`test_trace_compressor.py`)
- Delta-timestamp encoding correctness
- Duplicate suppression and repeat counting
- Zero-payload suppression
- Mixed compression mode scenarios

### 5. Circular Trace Buffer (`test_circular_trace_buffer.py`)
- Basic write/read operations
- Buffer wraparound (overwrite oldest)
- Freeze on fault — no further writes
- Pointer validity after wraparound

### 6. Fault Manager (`test_fault_manager.py`)
- Individual fault source detection
- Debounce counter behavior
- Sticky latch set/clear
- First-fault (fatal_o) pulse
- Multi-fault scenarios

### 7. Snapshot Controller (`test_snapshot_controller.py`)
- FSM state transitions: ARMED → TRIGGERED → FROZEN → READY
- buf_freeze assertion timing
- Metadata latch correctness
- SW clear returns to ARMED

### 8. SBBR Top Integration (`test_sbbr_top.py`)
- End-to-end: event injection → trace capture → fault → freeze → APB readback
- APB register read/write verification
- Multi-fault injection scenarios

## Coverage Goals
- All fault types exercised
- All severity levels exercised
- Buffer wraparound conditions
- Compression mode combinations
- Simultaneous multi-source events
