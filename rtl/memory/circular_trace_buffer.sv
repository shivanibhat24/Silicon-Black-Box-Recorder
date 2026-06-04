// =============================================================================
// Silicon Black Box Recorder — Circular Trace Buffer
// circular_trace_buffer.sv
//
// Wraps trace_ram into a circular FIFO with:
//   • Head/tail pointer management
//   • Overwrite-on-full semantics (oldest entry overwritten)
//   • Fault-triggered freeze: write pointer locks, reads still served
//   • Status outputs for APB registers
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;

module circular_trace_buffer #(
  parameter int unsigned DATA_W = 64,
  parameter int unsigned DEPTH  = TRACE_DEPTH
) (
  input  wire                          clk,
  input  wire                          rst_n,

  // Write interface (from compressor)
  input  wire                          wr_valid,
  input  wire  [DATA_W-1:0]            wr_data,
  output logic                         wr_ready,

  // Read interface (from APB slave or snapshot controller)
  input  wire                          rd_en,
  output logic [DATA_W-1:0]            rd_data,
  output logic                         rd_valid,

  // Freeze control
  input  wire                          freeze,     // Assert to freeze recording

  // Status
  output logic [TRACE_ADDR_W-1:0]      head_ptr,   // Oldest valid entry
  output logic [TRACE_ADDR_W-1:0]      tail_ptr,   // Next write location
  output logic                         buf_full,
  output logic                         buf_empty
);

  localparam int AW = TRACE_ADDR_W;

  // ---------------------------------------------------------------------------
  // Pointer registers
  // ---------------------------------------------------------------------------
  logic [AW-1:0] head_q, tail_q;
  logic           full_q, empty_q;
  logic           frozen;

  // Read address tracks head for sequential drain
  logic [AW-1:0] rd_ptr;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      head_q  <= '0;
      tail_q  <= '0;
      full_q  <= 1'b0;
      empty_q <= 1'b1;
      frozen  <= 1'b0;
      rd_ptr  <= '0;
    end else begin
      // Freeze is sticky
      if (freeze) frozen <= 1'b1;

      // Write
      if (wr_valid && !frozen) begin
        // If full, advance head to discard oldest
        if (full_q)
          head_q <= head_q + 1'b1;

        tail_q  <= tail_q + 1'b1;
        empty_q <= 1'b0;
        full_q  <= (tail_q + 1'b1 == head_q);
      end

      // Read (sequential drain starting at head)
      if (rd_en && !empty_q) begin
        rd_ptr  <= rd_ptr + 1'b1;
        if (rd_ptr + 1'b1 == tail_q) empty_q <= 1'b1;
        full_q  <= 1'b0;
      end
    end
  end

  assign head_ptr = head_q;
  assign tail_ptr = tail_q;
  assign buf_full  = full_q;
  assign buf_empty = empty_q;
  assign wr_ready  = !frozen;

  // ---------------------------------------------------------------------------
  // RAM instantiation
  // ---------------------------------------------------------------------------
  trace_ram #(
    .DATA_W (DATA_W),
    .DEPTH  (DEPTH)
  ) u_ram (
    .clk_a   (clk),
    .we_a    (wr_valid && !frozen),
    .addr_a  (tail_q),
    .wdata_a (wr_data),
    .clk_b   (clk),
    .re_b    (rd_en),
    .addr_b  (rd_ptr),
    .rdata_b (rd_data)
  );

  // rd_valid delayed by one cycle (RAM registered output)
  always_ff @(posedge clk) rd_valid <= rd_en && !empty_q;

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------
`ifdef SBBR_ASSERT_ON
  // No writes must occur after freeze
  assert property (@(posedge clk) disable iff (!rst_n)
    (frozen) |-> !(wr_valid && !wr_ready));

  // Buffer pointers remain within bounds
  assert property (@(posedge clk) disable iff (!rst_n)
    (head_q < DEPTH && tail_q < DEPTH));
`endif

endmodule : circular_trace_buffer

`default_nettype wire
