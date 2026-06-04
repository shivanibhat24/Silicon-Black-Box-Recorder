// =============================================================================
// Silicon Black Box Recorder — Event Types Package
// event_types_pkg.sv
// =============================================================================

`ifndef EVENT_TYPES_PKG_SV
`define EVENT_TYPES_PKG_SV

package event_types_pkg;

  // 4-bit event type field — must fit in event_pkt_t.event_type
  typedef enum logic [3:0] {
    EVT_VOLTAGE_NOMINAL   = 4'h0,  // Voltage within spec
    EVT_VOLTAGE_DROOP     = 4'h1,  // Voltage below lower threshold
    EVT_VOLTAGE_SURGE     = 4'h2,  // Voltage above upper threshold
    EVT_OVERCURRENT       = 4'h3,  // Current exceeded limit
    EVT_OVERTEMP          = 4'h4,  // Temperature exceeded threshold
    EVT_TEMP_WARNING      = 4'h5,  // Temperature approaching limit
    EVT_PLL_LOCK          = 4'h6,  // PLL acquired lock
    EVT_PLL_UNLOCK        = 4'h7,  // PLL lost lock
    EVT_CLK_FAIL          = 4'h8,  // Clock stopped / frequency anomaly
    EVT_WATCHDOG_TIMEOUT  = 4'h9,  // Watchdog timer expired
    EVT_POWER_STATE_CHG   = 4'hA,  // Power state transition (P-state / C-state)
    EVT_FW_CHECKPOINT     = 4'hB,  // Firmware reached named checkpoint
    EVT_SENSOR_FAULT      = 4'hC,  // Sensor read CRC error or out-of-range
    EVT_RESET_ASSERTED    = 4'hD,  // System or domain reset assertion
    EVT_ECC_ERROR         = 4'hE,  // (future) ECC correctable/uncorrectable
    EVT_USER_DEFINED      = 4'hF   // Firmware-defined custom event
  } event_type_e;

endpackage : event_types_pkg

`endif // EVENT_TYPES_PKG_SV
