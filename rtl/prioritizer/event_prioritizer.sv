// =============================================================================
// Silicon Black Box Recorder — Event Prioritization Engine
// event_prioritizer.sv
//
// Filters incoming events by minimum severity.
// Rate-limits low-priority (INFO/WARNING) events to prevent buffer flooding.
// CRITICAL and FATAL events always pass through immediately.
//
// Registers (written via a simple CSR interface):
//   min_severity    — drop events below this level
//   rate_limit_cnt  — max INFO/WARNING events per rate_window cycles
//   rate_window     — window size in clock cycles
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;

module event_prioritizer (
  input  wire          clk,
  input  wire          rst_n,

  // Upstream (from aggregator)
  input  wire          in_valid,
  input  event_pkt_t   in_event,
  output logic         in_ready,

  // Downstream (to compressor)
  output logic         out_valid,
  output event_pkt_t   out_event,
  input  wire          out_ready,

  // CSR configuration
  input  wire [1:0]    cfg_min_severity,   // SEV_INFO=0 to SEV_FATAL=3
  input  wire [7:0]    cfg_rate_limit,     // Max low-pri events per window
  input  wire [15:0]   cfg_rate_window     // Window length in cycles
);

  // ---------------------------------------------------------------------------
  // Rate limiting: token-bucket style counter
  // ---------------------------------------------------------------------------
  logic [15:0] window_cnt;   // Counts down from cfg_rate_window
  logic [7:0]  token_cnt;    // How many low-pri events remain this window

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      window_cnt <= '0;
      token_cnt  <= cfg_rate_limit;
    end else begin
      if (window_cnt == '0) begin
        window_cnt <= cfg_rate_window;
        token_cnt  <= cfg_rate_limit;
      end else begin
        window_cnt <= window_cnt - 1;
        // Consume a token when a low-pri event passes
        if (in_valid && out_ready && in_event.severity <= SEV_WARNING &&
            in_event.severity >= cfg_min_severity && token_cnt != '0)
          token_cnt <= token_cnt - 1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Filter logic
  // ---------------------------------------------------------------------------
  logic severity_pass;
  logic rate_pass;
  logic accept;

  always_comb begin
    severity_pass = (in_event.severity >= severity_t'(cfg_min_severity));
    // High priority always bypass rate limiter
    rate_pass     = (in_event.severity >= SEV_CRITICAL) || (token_cnt != '0);
    accept        = in_valid && severity_pass && rate_pass;
  end

  // ---------------------------------------------------------------------------
  // Output skid buffer
  // ---------------------------------------------------------------------------
  logic        buf_valid;
  event_pkt_t  buf_event;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      buf_valid <= 1'b0;
      buf_event <= '0;
    end else if (!buf_valid || out_ready) begin
      buf_valid <= accept;
      buf_event <= in_event;
    end
  end

  assign out_valid = buf_valid;
  assign out_event = buf_event;
  assign in_ready  = !buf_valid || out_ready;

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------
`ifdef SBBR_ASSERT_ON
  // FATAL events must never be dropped by severity filter
  assert property (@(posedge clk) disable iff (!rst_n)
    (in_valid && (in_event.severity == SEV_FATAL))
    |-> (severity_pass && rate_pass));
`endif

endmodule : event_prioritizer

`default_nettype wire
