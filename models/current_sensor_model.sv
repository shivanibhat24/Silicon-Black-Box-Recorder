// =============================================================================
// Silicon Black Box Recorder — Current Sensor Behavioral Model
// current_sensor_model.sv
//
// Simulates a current monitor for overcurrent detection.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;

module current_sensor_model #(
  parameter int unsigned SOURCE_ID       = 8'h01,
  parameter int unsigned OVERCURRENT_TH  = 5000     // mA threshold
) (
  input  wire                          clk,
  input  wire                          rst_n,
  input  wire [TIMESTAMP_WIDTH-1:0]    timestamp,

  // Stimulus
  input  wire [15:0]                   current_ma,
  input  wire                          sample_valid,

  // Telemetry output
  output logic                         evt_valid,
  output event_pkt_t                   evt_pkt,

  // Fault output
  output logic                         fault_overcurrent
);

  logic oc_latch;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      evt_valid         <= 1'b0;
      evt_pkt           <= '0;
      fault_overcurrent <= 1'b0;
      oc_latch          <= 1'b0;
    end else begin
      evt_valid <= 1'b0;

      if (sample_valid) begin
        if (current_ma > OVERCURRENT_TH && !oc_latch) begin
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= SEV_CRITICAL;
          evt_pkt.event_type     <= EVT_OVERCURRENT;
          evt_pkt.payload        <= {16'b0, current_ma};
          fault_overcurrent      <= 1'b1;
          oc_latch               <= 1'b1;
        end else if (current_ma <= OVERCURRENT_TH) begin
          oc_latch          <= 1'b0;
          fault_overcurrent <= 1'b0;
        end
      end
    end
  end

endmodule : current_sensor_model

`default_nettype wire
