// =============================================================================
// Silicon Black Box Recorder — Voltage Sensor Behavioral Model
// voltage_sensor_model.sv
//
// Simulates a voltage rail monitor for verification.
// Generates event_pkt_t when voltage crosses programmable thresholds.
// Supports droop, surge, and nominal conditions.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;

module voltage_sensor_model #(
  parameter int unsigned SOURCE_ID   = 8'h00,
  parameter int unsigned NOMINAL_MV  = 900,      // Nominal voltage in mV
  parameter int unsigned DROOP_TH_MV = 810,      // Low threshold
  parameter int unsigned SURGE_TH_MV = 990       // High threshold
) (
  input  wire                          clk,
  input  wire                          rst_n,
  input  wire [TIMESTAMP_WIDTH-1:0]    timestamp,

  // Stimulus control (from testbench)
  input  wire [15:0]                   voltage_mv,       // Simulated voltage
  input  wire                          sample_valid,      // Pulse to sample

  // Telemetry output
  output logic                         evt_valid,
  output event_pkt_t                   evt_pkt,

  // Fault output
  output logic                         fault_droop
);

  logic droop_q, surge_q;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      evt_valid   <= 1'b0;
      evt_pkt     <= '0;
      fault_droop <= 1'b0;
      droop_q     <= 1'b0;
      surge_q     <= 1'b0;
    end else begin
      evt_valid <= 1'b0;

      if (sample_valid) begin
        // Droop detection
        if (voltage_mv < DROOP_TH_MV && !droop_q) begin
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= SEV_CRITICAL;
          evt_pkt.event_type     <= EVT_VOLTAGE_DROOP;
          evt_pkt.payload        <= {16'b0, voltage_mv};
          fault_droop            <= 1'b1;
          droop_q                <= 1'b1;
        end
        // Surge detection
        else if (voltage_mv > SURGE_TH_MV && !surge_q) begin
          evt_valid              <= 1'b1;
          evt_pkt.timestamp      <= timestamp;
          evt_pkt.source_id      <= SOURCE_ID[SOURCE_ID_W-1:0];
          evt_pkt.severity       <= SEV_WARNING;
          evt_pkt.event_type     <= EVT_VOLTAGE_SURGE;
          evt_pkt.payload        <= {16'b0, voltage_mv};
          fault_droop            <= 1'b0;
          surge_q                <= 1'b1;
        end
        // Nominal — clear latches
        else if (voltage_mv >= DROOP_TH_MV && voltage_mv <= SURGE_TH_MV) begin
          droop_q     <= 1'b0;
          surge_q     <= 1'b0;
          fault_droop <= 1'b0;
        end
      end
    end
  end

endmodule : voltage_sensor_model

`default_nettype wire
