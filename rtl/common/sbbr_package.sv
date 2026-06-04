// =============================================================================
// Silicon Black Box Recorder — Global Package
// sbbr_pkg.sv
//
// Central parameter and typedef definitions shared across all RTL blocks.
// =============================================================================

`ifndef SBBR_PKG_SV
`define SBBR_PKG_SV

package sbbr_pkg;

  // ---------------------------------------------------------------------------
  // Global parameters
  // ---------------------------------------------------------------------------
  parameter int unsigned TIMESTAMP_WIDTH   = 48;   // Bits in global timestamp counter
  parameter int unsigned EVENT_PAYLOAD_W   = 32;   // Bits of raw payload per event
  parameter int unsigned SOURCE_ID_W       = 8;    // Bits for telemetry source identifier
  parameter int unsigned TRACE_DEPTH       = 1024; // Number of event slots in circular buffer
  parameter int unsigned TRACE_ADDR_W      = $clog2(TRACE_DEPTH);
  parameter int unsigned APB_ADDR_W        = 12;   // APB address bus width
  parameter int unsigned APB_DATA_W        = 32;   // APB data bus width

  // ---------------------------------------------------------------------------
  // Event severity levels
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    SEV_INFO     = 2'b00,
    SEV_WARNING  = 2'b01,
    SEV_CRITICAL = 2'b10,
    SEV_FATAL    = 2'b11
  } severity_t;

  // ---------------------------------------------------------------------------
  // Canonical event packet transmitted through the aggregation fabric
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [TIMESTAMP_WIDTH-1:0]  timestamp;   // Capture time (global counter value)
    logic [SOURCE_ID_W-1:0]      source_id;   // Originating monitor ID
    severity_t                   severity;    // Classification
    logic [3:0]                  event_type;  // Defined in event_types_pkg
    logic [EVENT_PAYLOAD_W-1:0]  payload;     // Source-specific payload bits
  } event_pkt_t;

  // Derived: total width of a packed event packet
  localparam int unsigned EVENT_PKT_W = TIMESTAMP_WIDTH + SOURCE_ID_W + 2 + 4 + EVENT_PAYLOAD_W;

  // ---------------------------------------------------------------------------
  // APB register address map (word-addressed, 4-byte aligned)
  // ---------------------------------------------------------------------------
  localparam logic [APB_ADDR_W-1:0] REG_STATUS        = 12'h000;
  localparam logic [APB_ADDR_W-1:0] REG_CONTROL       = 12'h004;
  localparam logic [APB_ADDR_W-1:0] REG_FAULT_STATUS  = 12'h008;
  localparam logic [APB_ADDR_W-1:0] REG_TRACE_HEAD    = 12'h00C;
  localparam logic [APB_ADDR_W-1:0] REG_TRACE_TAIL    = 12'h010;
  localparam logic [APB_ADDR_W-1:0] REG_SNAPSHOT_INFO = 12'h014;
  localparam logic [APB_ADDR_W-1:0] REG_TS_LOW        = 12'h018; // Timestamp[31:0]
  localparam logic [APB_ADDR_W-1:0] REG_TS_HIGH       = 12'h01C; // Timestamp[47:32]
  localparam logic [APB_ADDR_W-1:0] REG_TRACE_DATA    = 12'h020; // Streaming read port

endpackage : sbbr_pkg

`endif // SBBR_PKG_SV
