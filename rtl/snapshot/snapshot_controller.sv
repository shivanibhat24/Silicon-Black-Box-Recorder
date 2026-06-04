// =============================================================================
// Silicon Black Box Recorder — Snapshot Controller
// snapshot_controller.sv
//
// Upon receiving a fatal fault trigger:
//   1. Asserts freeze to the circular buffer (stops overwriting)
//   2. Latches fault metadata into a readable register bank
//   3. Exposes an extraction-done status bit
//   4. On SW clear, releases freeze and resets for the next capture session
//
// State machine:
//   ARMED → TRIGGERED (on fault) → FROZEN (freeze asserted) → READY
//   READY → ARMED (on sw_clear)
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import fault_types_pkg::*;

module snapshot_controller (
  input  wire            clk,
  input  wire            rst_n,

  // From fault manager
  input  wire            fault_trigger,    // Single-cycle pulse on first fault
  input  fault_meta_t    fault_meta_in,

  // Buffer control
  output logic           buf_freeze,       // Hold high to freeze buffer writes

  // SW control
  input  wire            sw_clear,         // Write 1 to release snapshot

  // Status outputs (to APB)
  output logic           snapshot_valid,   // Snapshot data is ready
  output fault_meta_t    snapshot_meta     // Latched fault metadata
);

  typedef enum logic [1:0] {
    ST_ARMED     = 2'b00,
    ST_TRIGGERED = 2'b01,
    ST_FROZEN    = 2'b10,
    ST_READY     = 2'b11
  } snap_state_t;

  snap_state_t state_q, state_d;

  // ---------------------------------------------------------------------------
  // FSM
  // ---------------------------------------------------------------------------
  always_comb begin
    state_d = state_q;
    case (state_q)
      ST_ARMED:     if (fault_trigger)                    state_d = ST_TRIGGERED;
      ST_TRIGGERED:                                        state_d = ST_FROZEN;
      ST_FROZEN:                                           state_d = ST_READY;
      ST_READY:     if (sw_clear)                          state_d = ST_ARMED;
      default:                                             state_d = ST_ARMED;
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) state_q <= ST_ARMED;
    else        state_q <= state_d;
  end

  // ---------------------------------------------------------------------------
  // Freeze: assert from TRIGGERED onwards, release on SW clear
  // ---------------------------------------------------------------------------
  assign buf_freeze = (state_q == ST_TRIGGERED) ||
                      (state_q == ST_FROZEN)    ||
                      (state_q == ST_READY);

  // ---------------------------------------------------------------------------
  // Metadata latch
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      snapshot_meta  <= '0;
      snapshot_valid <= 1'b0;
    end else begin
      if (state_q == ST_TRIGGERED) begin
        snapshot_meta  <= fault_meta_in;
        snapshot_valid <= 1'b1;
      end
      if (sw_clear) begin
        snapshot_meta  <= '0;
        snapshot_valid <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------
`ifdef SBBR_ASSERT_ON
  // Snapshot metadata must be valid when state is READY
  assert property (@(posedge clk) disable iff (!rst_n)
    (state_q == ST_READY) |-> snapshot_valid);

  // buf_freeze must be asserted whenever state != ARMED
  assert property (@(posedge clk) disable iff (!rst_n)
    (state_q != ST_ARMED) |-> buf_freeze);
`endif

endmodule : snapshot_controller

`default_nettype wire
