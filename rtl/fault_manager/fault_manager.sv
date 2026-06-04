// =============================================================================
// Silicon Black Box Recorder — Fault Manager
// fault_manager.sv
//
// Monitors digital fault signals from mixed-signal sensor models.
// Features:
//   • Per-source configurable debounce counters (prevents glitch triggers)
//   • Sticky fault latches (set until explicit SW clear)
//   • Priority-encoded first-fault capture
//   • fault_vector_o asserted as long as any fault is active
//   • fatal_o pulses one cycle when a FATAL condition first fires
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import fault_types_pkg::*;

module fault_manager (
  input  wire                clk,
  input  wire                rst_n,

  // Raw fault inputs from sensor models / monitors
  input  wire                fault_voltage_droop,  // FLT_VOLTAGE_DROOP
  input  wire                fault_overcurrent,    // FLT_OVERCURRENT
  input  wire                fault_overtemp,       // FLT_OVERTEMP
  input  wire                fault_pll_unlock,     // FLT_PLL_UNLOCK
  input  wire                fault_clk_fail,       // FLT_CLK_FAIL
  input  wire                fault_watchdog,       // FLT_WATCHDOG
  input  wire                fault_sensor_fault,   // FLT_SENSOR_FAULT
  input  wire                fault_user,           // FLT_USER

  // Timestamp for annotation
  input  wire [TIMESTAMP_WIDTH-1:0] timestamp,

  // Debounce configuration (common for now; could be per-source)
  input  wire [7:0]          cfg_debounce_cycles,  // 0 = no debounce

  // SW clear — writing 1 to each bit clears the corresponding sticky latch
  input  wire [NUM_FAULT_SOURCES-1:0] fault_clear,

  // Outputs
  output fault_vector_t      fault_vector_o,       // Active fault bits
  output logic               any_fault_o,          // OR of all fault bits
  output logic               fatal_o,              // First-fault pulse
  output fault_meta_t        fault_meta_o          // Snapshot metadata
);

  // ---------------------------------------------------------------------------
  // Gather raw inputs into an array for loop-friendly processing
  // ---------------------------------------------------------------------------
  logic [NUM_FAULT_SOURCES-1:0] raw_faults;

  assign raw_faults = {
    fault_user,
    fault_sensor_fault,
    fault_watchdog,
    fault_clk_fail,
    fault_pll_unlock,
    fault_overtemp,
    fault_overcurrent,
    fault_voltage_droop
  };

  // ---------------------------------------------------------------------------
  // Per-source debounce counters
  // ---------------------------------------------------------------------------
  logic [7:0]  deb_cnt [NUM_FAULT_SOURCES];
  logic        deb_out [NUM_FAULT_SOURCES];  // Debounced fault (level)

  genvar g;
  generate
    for (g = 0; g < NUM_FAULT_SOURCES; g++) begin : gen_deb
      always_ff @(posedge clk) begin
        if (!rst_n) begin
          deb_cnt[g] <= '0;
          deb_out[g] <= 1'b0;
        end else if (raw_faults[g]) begin
          if (deb_cnt[g] >= cfg_debounce_cycles) begin
            deb_out[g] <= 1'b1;
          end else begin
            deb_cnt[g] <= deb_cnt[g] + 1;
          end
        end else begin
          deb_cnt[g] <= '0;
          deb_out[g] <= 1'b0;
        end
      end
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Sticky latches
  // ---------------------------------------------------------------------------
  fault_vector_t sticky_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      sticky_q <= '0;
    end else begin
      for (int i = 0; i < NUM_FAULT_SOURCES; i++) begin
        if (deb_out[i])
          sticky_q[i] <= 1'b1;
        else if (fault_clear[i])
          sticky_q[i] <= 1'b0;
      end
    end
  end

  assign fault_vector_o = sticky_q;
  assign any_fault_o    = |sticky_q;

  // ---------------------------------------------------------------------------
  // First-fault pulse: rising edge of any_fault_o
  // ---------------------------------------------------------------------------
  logic any_fault_d1;
  always_ff @(posedge clk) any_fault_d1 <= any_fault_o;
  assign fatal_o = any_fault_o && !any_fault_d1;

  // ---------------------------------------------------------------------------
  // Fault metadata capture
  // ---------------------------------------------------------------------------
  logic [7:0] fault_count_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      fault_meta_o.fault_timestamp <= '0;
      fault_meta_o.fault_count     <= '0;
      fault_meta_o.snapshot_valid  <= 1'b0;
      fault_count_q                <= '0;
    end else begin
      if (fatal_o) begin
        fault_meta_o.fault_timestamp <= timestamp;
        fault_meta_o.snapshot_valid  <= 1'b1;
        fault_count_q                <= fault_count_q + 1;
      end
      fault_meta_o.fault_count  <= fault_count_q;
      fault_meta_o.active_faults <= sticky_q;
    end
  end

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------
`ifdef SBBR_ASSERT_ON
  // fatal_o must be at most one cycle wide
  assert property (@(posedge clk) disable iff (!rst_n)
    (fatal_o) |=> !fatal_o || !$past(any_fault_d1, 1));

  // Cleared fault must deassert sticky bit next cycle
  assert property (@(posedge clk) disable iff (!rst_n)
    ∀ i ∈ [0:NUM_FAULT_SOURCES-1]: (fault_clear[i] && !deb_out[i])
    |=> !sticky_q[i]);
`endif

endmodule : fault_manager

`default_nettype wire
