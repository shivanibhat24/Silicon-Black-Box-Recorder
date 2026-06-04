// =============================================================================
// Silicon Black Box Recorder — Event Aggregation Fabric
// event_aggregator.sv
//
// Accepts parallel valid-strobe inputs from N telemetry sources.
// Arbitrates (fixed priority, highest source_id wins ties in the same cycle)
// and emits a single canonical event_pkt_t per clock to the prioritizer.
//
// Back-pressure: if the downstream is not ready the event is dropped and
// a drop counter increments. The drop count is exported for status registers.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;

module event_aggregator #(
  parameter int unsigned NUM_SOURCES = 7  // Number of telemetry sources
) (
  input  wire                                   clk,
  input  wire                                   rst_n,

  // Per-source valid / event input
  input  wire  [NUM_SOURCES-1:0]                src_valid,
  input  wire  event_pkt_t                      src_events [NUM_SOURCES],

  // Downstream (to prioritizer)
  output logic                                  out_valid,
  output event_pkt_t                            out_event,
  input  wire                                   out_ready,

  // Status
  output logic [31:0]                           drop_count
);

  // ---------------------------------------------------------------------------
  // Arbitration: highest-index source with a valid asserted wins
  // (higher index == higher urgency by convention in the source map)
  // ---------------------------------------------------------------------------
  logic                sel_valid;
  event_pkt_t          sel_event;
  logic [NUM_SOURCES-1:0] grant;

  always_comb begin
    sel_valid = 1'b0;
    sel_event = '0;
    grant     = '0;
    for (int i = 0; i < NUM_SOURCES; i++) begin
      if (src_valid[i]) begin
        sel_valid = 1'b1;
        sel_event = src_events[i];
        grant[i]  = 1'b1;   // overwrites lower — last winner is highest index
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Output register — holds event until downstream accepts
  // ---------------------------------------------------------------------------
  logic        buf_valid;
  event_pkt_t  buf_event;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      buf_valid <= 1'b0;
      buf_event <= '0;
    end else begin
      if (!buf_valid || out_ready) begin
        buf_valid <= sel_valid;
        buf_event <= sel_event;
      end
    end
  end

  assign out_valid = buf_valid;
  assign out_event = buf_event;

  // ---------------------------------------------------------------------------
  // Drop counter: new event arrives while buffer is full
  // ---------------------------------------------------------------------------
  logic [31:0] drop_cnt_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      drop_cnt_q <= '0;
    end else begin
      if (sel_valid && buf_valid && !out_ready)
        drop_cnt_q <= drop_cnt_q + 1;
    end
  end

  assign drop_count = drop_cnt_q;

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------
`ifdef SBBR_ASSERT_ON
  // Output must hold until accepted
  assert property (@(posedge clk) disable iff (!rst_n)
    (out_valid && !out_ready) |=> out_valid);
`endif

endmodule : event_aggregator

`default_nettype wire
