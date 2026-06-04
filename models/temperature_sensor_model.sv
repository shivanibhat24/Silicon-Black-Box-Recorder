// =============================================================================
// Silicon Black Box Recorder — Temperature Sensor Behavioral Model
// temperature_sensor_model.sv
//
// Simulates a temperature sensor with warning and critical thresholds.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;

module temperature_sensor_model #(
  parameter int unsigned SOURCE_ID      = 8'h02,
  parameter int unsigned WARN_TEMP_C    = 85,
  parameter int unsigned CRIT_TEMP_C    = 105
) (
  input  wire                          clk,
  input  wire                          rst_n,
  input  wire [TIMESTAMP_WIDTH-1:0]    timestamp,

  // Stimulus
  input  wire [15:0]                   temperature_c,    // Temperature in °C
  input  wire                          sample_valid,

  // Telemetry output
  output logic                         evt_valid,
  output event_pkt_t                   evt_pkt,

  // Fault output
  output logic                         fault_overtemp
);

  logic warn_latch, crit_latch;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      evt_valid      <= 1'b0;
      evt_pkt        <= '0;
      fault_overtemp <= 1'b0;
      warn_latch     <= 1'b0;
      crit_latch     <= 1'b0;
    end else begin
      evt_valid <= 1'b0;

      if (sample_valid) begin
        // Critical overtemp
        if (temperature_c >= CRIT_TEMP_C && !crit_latch) begin
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= SEV_FATAL;
          evt_pkt.event_type     <= EVT_OVERTEMP;
          evt_pkt.payload        <= {16'b0, temperature_c};
          fault_overtemp         <= 1'b1;
          crit_latch             <= 1'b1;
        end
        // Warning
        else if (temperature_c >= WARN_TEMP_C && !warn_latch) begin
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= SEV_WARNING;
          evt_pkt.event_type     <= EVT_TEMP_WARNING;
          evt_pkt.payload        <= {16'b0, temperature_c};
          fault_overtemp         <= 1'b0;
          warn_latch             <= 1'b1;
        end
        // Nominal
        else if (temperature_c < WARN_TEMP_C) begin
          warn_latch     <= 1'b0;
          crit_latch     <= 1'b0;
          fault_overtemp <= 1'b0;
        end
      end
    end
  end

endmodule : temperature_sensor_model

`default_nettype wire
