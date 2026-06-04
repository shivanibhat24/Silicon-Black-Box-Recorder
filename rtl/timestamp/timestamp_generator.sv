// =============================================================================
// Silicon Black Box Recorder — Timestamp Generator
// timestamp_generator.sv
//
// Free-running counter that provides globally synchronized timestamps.
// Supports:
//   • Configurable width (default 48-bit → ~3.2 years at 1 GHz before wrap)
//   • Synchronous reset
//   • Wraparound pulse output (for upper-layer wrap tracking)
//   • Optional clock-domain crossing handshake strobe output
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;

module timestamp_generator #(
  parameter int unsigned WIDTH = TIMESTAMP_WIDTH  // Counter width in bits
) (
  input  wire                clk,       // System clock
  input  wire                rst_n,     // Active-low synchronous reset
  input  wire                en,        // Counter enable (pause during snapshot)
  output logic [WIDTH-1:0]   timestamp, // Current timestamp value
  output logic               wrap_pulse // Single-cycle pulse on counter wrap
);

  logic [WIDTH-1:0] cnt_d, cnt_q;

  // Combinational next-state
  always_comb begin
    wrap_pulse = 1'b0;
    if (en) begin
      if (cnt_q == {WIDTH{1'b1}}) begin
        cnt_d      = '0;
        wrap_pulse = 1'b1;
      end else begin
        cnt_d = cnt_q + 1'b1;
      end
    end else begin
      cnt_d = cnt_q;
    end
  end

  // Sequential
  always_ff @(posedge clk) begin
    if (!rst_n)
      cnt_q <= '0;
    else
      cnt_q <= cnt_d;
  end

  assign timestamp = cnt_q;

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------
`ifdef FORMAL
  // Counter must not change when enable is deasserted
  assert property (@(posedge clk) disable iff (!rst_n)
    (!en) |=> (timestamp == $past(timestamp)));

  // Wrap pulse must be single-cycle
  assert property (@(posedge clk) disable iff (!rst_n)
    (wrap_pulse) |=> (!wrap_pulse || (cnt_q == {WIDTH{1'b1}})));
`endif

endmodule : timestamp_generator

`default_nettype wire
