// =============================================================================
// Silicon Black Box Recorder — Trace RAM
// trace_ram.sv
//
// Simple-dual-port SRAM model.
//   Port A : Write (always enabled)
//   Port B : Read  (registered output — pipeline stage)
//
// Targets Xilinx/Intel BRAM inference.
// Do NOT add reset logic to the array — BRAM primitives have no array reset.
// Read latency = 1 cycle (registered output mode).
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;

module trace_ram #(
  parameter int unsigned DATA_W = 64,            // Word width
  parameter int unsigned DEPTH  = TRACE_DEPTH    // Number of entries
) (
  // Write port
  input  wire                          clk_a,
  input  wire                          we_a,
  input  wire  [$clog2(DEPTH)-1:0]     addr_a,
  input  wire  [DATA_W-1:0]            wdata_a,

  // Read port
  input  wire                          clk_b,
  input  wire                          re_b,
  input  wire  [$clog2(DEPTH)-1:0]     addr_b,
  output logic [DATA_W-1:0]            rdata_b
);

  (* ram_style = "block" *)
  logic [DATA_W-1:0] mem [0:DEPTH-1];

  // Write
  always_ff @(posedge clk_a)
    if (we_a) mem[addr_a] <= wdata_a;

  // Read (registered)
  always_ff @(posedge clk_b)
    if (re_b) rdata_b <= mem[addr_b];

endmodule : trace_ram

`default_nettype wire
