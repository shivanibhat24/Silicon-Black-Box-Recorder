# SBBR Architecture

## Overview

Silicon Black Box Recorder (SBBR) is a post-silicon diagnostics and observability subsystem. It captures the sequence of events leading to failures in complex SoCs, accelerators, and mixed-signal systems.

## Data Flow

```
Telemetry Sources (7 monitors)
        │
        ▼
Event Aggregation Fabric ─── fixed-priority arbitration
        │
        ▼
Event Prioritization Engine ── severity filter + rate limiter
        │
        ▼
Trace Compression Engine ──── delta-TS / dedup / zero-suppression
        │
        ▼
Circular Trace Buffer ──────── 1024-deep × 64-bit SRAM ring
        │
        ▼
Fault Manager ──────────────── debounced fault detection → fault vector
        │
        ▼
Snapshot Controller ────────── freeze buffer + capture metadata
        │
        ▼
APB Slave Interface ────────── firmware register access
```

## Clock Domains

All RTL currently operates in a single clock domain (`clk`). The timestamp generator supports future multi-domain extensions.

## Key Parameters

| Parameter        | Default | Description                          |
|------------------|---------|--------------------------------------|
| TIMESTAMP_WIDTH  | 48      | Global counter width                 |
| EVENT_PAYLOAD_W  | 32      | Payload bits per event               |
| SOURCE_ID_W      | 8       | Source identifier width              |
| TRACE_DEPTH      | 1024    | Circular buffer entry count          |
| APB_ADDR_W       | 12      | APB address bus width                |
| APB_DATA_W       | 32      | APB data bus width                   |
