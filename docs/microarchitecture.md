# SBBR Microarchitecture

## Timestamp Generator

- Free-running counter, configurable width (default 48-bit)
- Synchronous reset, enable-gated (pauses during snapshot freeze)
- Wraparound pulse for upper-layer tracking

## Event Aggregator

- Accepts N parallel valid-strobe inputs from telemetry sources
- Fixed-priority arbitration (highest source_id index wins)
- Single-slot output buffer with back-pressure
- Drop counter for congestion monitoring

## Event Prioritizer

- Severity-based filter: programmable minimum severity threshold
- Token-bucket rate limiter for INFO/WARNING events
- CRITICAL and FATAL events always pass through immediately
- Configurable window size and token count via CSR

## Trace Compressor

- Delta-timestamp encoding: 48-bit → 16-bit delta (saturates at 0xFFFF)
- Duplicate event suppression: back-to-back identical events → repeat count
- Zero-payload suppression: omits 32-bit payload when all zeros
- FSM: IDLE → EMIT_NORMAL → IDLE (or dedup accumulation path)

## Circular Trace Buffer

- Wraps `trace_ram` (simple-dual-port SRAM) into a ring buffer
- Head/tail pointer management with overwrite-on-full
- Fault-triggered freeze: sticky, locks write pointer
- Read path for sequential drain via APB

## Fault Manager

- 8 independent fault sources with per-source debounce counters
- Sticky fault latches (cleared by SW via APB write-1-to-clear)
- First-fault pulse generation (rising edge of any_fault)
- Fault metadata capture: timestamp, count, active faults

## Snapshot Controller

- FSM: ARMED → TRIGGERED → FROZEN → READY → ARMED
- Asserts `buf_freeze` from TRIGGERED through READY
- Latches fault metadata on TRIGGERED
- SW clear releases freeze and resets to ARMED

## APB Slave

- AMBA APB3 compliant, single-cycle access (no wait states)
- Register map: STATUS, CONTROL, FAULT_STATUS, TRACE_HEAD, TRACE_TAIL, SNAPSHOT_INFO, TS_LOW, TS_HIGH, TRACE_DATA
- Write-1-to-clear on FAULT_STATUS
- Streaming read port for trace data extraction
