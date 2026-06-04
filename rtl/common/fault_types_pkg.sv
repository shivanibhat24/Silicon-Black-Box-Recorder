// =============================================================================
// Silicon Black Box Recorder — Fault Types Package
// fault_types_pkg.sv
// =============================================================================

`ifndef FAULT_TYPES_PKG_SV
`define FAULT_TYPES_PKG_SV

package fault_types_pkg;

  // Number of independently tracked fault sources
  parameter int unsigned NUM_FAULT_SOURCES = 8;

  // Fault source bit indices within the fault vector
  typedef enum int unsigned {
    FLT_VOLTAGE_DROOP  = 0,
    FLT_OVERCURRENT    = 1,
    FLT_OVERTEMP       = 2,
    FLT_PLL_UNLOCK     = 3,
    FLT_CLK_FAIL       = 4,
    FLT_WATCHDOG       = 5,
    FLT_SENSOR_FAULT   = 6,
    FLT_USER           = 7
  } fault_src_e;

  // Composite fault vector — one hot or multi-hot
  typedef logic [NUM_FAULT_SOURCES-1:0] fault_vector_t;

  // Fault metadata captured at snapshot time
  typedef struct packed {
    fault_vector_t  active_faults;        // Which faults were set
    logic [47:0]    fault_timestamp;      // Timestamp of first fault assertion
    logic [7:0]     fault_count;          // Total fault events since reset
    logic           snapshot_valid;       // Indicates snapshot data is coherent
  } fault_meta_t;

endpackage : fault_types_pkg

`endif // FAULT_TYPES_PKG_SV
