// =============================================================================
// Silicon Black Box Recorder — Workload Generator
// workload_generator.sv
//
// Generates synthetic telemetry events to stress-test the event pipeline.
// Configurable burst size, inter-event spacing, and event type distribution.
// Used as a traffic source in verification to exercise buffer wraparound,
// compression, and rate-limiting logic.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;

module workload_generator #(
  parameter int unsigned SOURCE_ID     = 8'h06,
  parameter int unsigned BURST_LEN     = 16,       // Events per burst
  parameter int unsigned INTERVAL      = 8         // Cycles between events in burst
) (
  input  wire                          clk,
  input  wire                          rst_n,
  input  wire [TIMESTAMP_WIDTH-1:0]    timestamp,

  // Control
  input  wire                          start,          // Pulse to begin burst
  input  wire [3:0]                    event_type_sel, // Event type to generate
  input  wire [1:0]                    severity_sel,   // Severity to apply
  input  wire [EVENT_PAYLOAD_W-1:0]    payload_pattern,// Pattern for payload

  // Output
  output logic                         evt_valid,
  output event_pkt_t                   evt_pkt,
  output logic                         busy
);

  logic [7:0]  burst_cnt;
  logic [7:0]  interval_cnt;
  logic        active;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      evt_valid    <= 1'b0;
      evt_pkt      <= '0;
      burst_cnt    <= '0;
      interval_cnt <= '0;
      active       <= 1'b0;
    end else begin
      evt_valid <= 1'b0;

      if (start && !active) begin
        active       <= 1'b1;
        burst_cnt    <= BURST_LEN[7:0];
        interval_cnt <= '0;
      end

      if (active) begin
        if (interval_cnt == '0) begin
          // Emit event
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= severity_t'(severity_sel);
          evt_pkt.event_type     <= event_type_sel;
          evt_pkt.payload        <= payload_pattern;
          interval_cnt           <= INTERVAL[7:0];
          burst_cnt              <= burst_cnt - 1;

          if (burst_cnt == 1) begin
            active <= 1'b0;
          end
        end else begin
          interval_cnt <= interval_cnt - 1;
        end
      end
    end
  end

  assign busy = active;

endmodule : workload_generator

`default_nettype wire
