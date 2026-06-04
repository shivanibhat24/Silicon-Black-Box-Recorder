// =============================================================================
// Silicon Black Box Recorder — PLL Behavioral Model
// pll_model.sv
//
// Simulates a PLL lock/unlock monitor.
// Models lock acquisition delay, unlock events, and clock failure detection.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;

module pll_model #(
  parameter int unsigned SOURCE_ID       = 8'h03,
  parameter int unsigned LOCK_CYCLES     = 100      // Cycles to acquire lock
) (
  input  wire                          clk,
  input  wire                          rst_n,
  input  wire [TIMESTAMP_WIDTH-1:0]    timestamp,

  // Stimulus
  input  wire                          pll_enable,       // Enable PLL
  input  wire                          force_unlock,     // Force an unlock event
  input  wire                          force_clk_fail,   // Force clock failure

  // Telemetry output
  output logic                         evt_valid,
  output event_pkt_t                   evt_pkt,

  // Fault outputs
  output logic                         fault_pll_unlock,
  output logic                         fault_clk_fail
);

  logic [7:0]  lock_cnt;
  logic        locked_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      evt_valid        <= 1'b0;
      evt_pkt          <= '0;
      fault_pll_unlock <= 1'b0;
      fault_clk_fail   <= 1'b0;
      lock_cnt         <= '0;
      locked_q         <= 1'b0;
    end else begin
      evt_valid <= 1'b0;

      // Lock acquisition
      if (pll_enable && !locked_q && !force_unlock) begin
        if (lock_cnt >= LOCK_CYCLES) begin
          locked_q               <= 1'b1;
          fault_pll_unlock       <= 1'b0;
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= SEV_INFO;
          evt_pkt.event_type     <= EVT_PLL_LOCK;
          evt_pkt.payload        <= '0;
        end else begin
          lock_cnt <= lock_cnt + 1;
        end
      end

      // Forced unlock
      if (force_unlock && locked_q) begin
        locked_q               <= 1'b0;
        lock_cnt               <= '0;
        fault_pll_unlock       <= 1'b1;
        evt_valid              <= 1'b1;
        evt_pkt.timestamp      <= timestamp;
        evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
        evt_pkt.severity       <= SEV_FATAL;
        evt_pkt.event_type     <= EVT_PLL_UNLOCK;
        evt_pkt.payload        <= '0;
      end

      // Clock failure
      if (force_clk_fail) begin
        fault_clk_fail         <= 1'b1;
        evt_valid              <= 1'b1;
        evt_pkt.timestamp      <= timestamp;
        evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
        evt_pkt.severity       <= SEV_FATAL;
        evt_pkt.event_type     <= EVT_CLK_FAIL;
        evt_pkt.payload        <= '0;
      end else begin
        fault_clk_fail <= 1'b0;
      end

      // PLL disabled
      if (!pll_enable) begin
        locked_q  <= 1'b0;
        lock_cnt  <= '0;
      end
    end
  end

endmodule : pll_model

`default_nettype wire
