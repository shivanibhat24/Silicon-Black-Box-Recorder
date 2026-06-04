// =============================================================================
// Silicon Black Box Recorder — Top-Level Integration
// sbbr_top.sv
//
// Instantiates and interconnects every subsystem:
//   Timestamp Generator → Event Aggregator → Event Prioritizer →
//   Trace Compressor → Circular Trace Buffer
//       ↑                                          ↓
//   Fault Manager → Snapshot Controller → APB Slave
//
// External interfaces:
//   • N raw telemetry source ports (valid + event_pkt_t per source)
//   • 8 raw fault indicator inputs from mixed-signal sensor models
//   • APB3 bus (pclk shared with system clock in this integration)
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import event_types_pkg::*;
import fault_types_pkg::*;

module sbbr_top #(
  parameter int unsigned NUM_SOURCES = 7
) (
  // -------------------------------------------------------------------------
  // Clocks & Reset
  // -------------------------------------------------------------------------
  input  wire                              clk,
  input  wire                              rst_n,

  // -------------------------------------------------------------------------
  // Telemetry source inputs (from mixed-signal models / monitors)
  // -------------------------------------------------------------------------
  input  wire  [NUM_SOURCES-1:0]           src_valid,
  input  event_pkt_t                       src_events [NUM_SOURCES],

  // -------------------------------------------------------------------------
  // Raw fault signals (active-high, directly from sensor models)
  // -------------------------------------------------------------------------
  input  wire                              fault_voltage_droop,
  input  wire                              fault_overcurrent,
  input  wire                              fault_overtemp,
  input  wire                              fault_pll_unlock,
  input  wire                              fault_clk_fail,
  input  wire                              fault_watchdog,
  input  wire                              fault_sensor_fault,
  input  wire                              fault_user,

  // -------------------------------------------------------------------------
  // APB3 Bus
  // -------------------------------------------------------------------------
  input  wire [APB_ADDR_W-1:0]             paddr,
  input  wire                              psel,
  input  wire                              penable,
  input  wire                              pwrite,
  input  wire [APB_DATA_W-1:0]             pwdata,
  output logic [APB_DATA_W-1:0]            prdata,
  output logic                             pready,
  output logic                             pslverr
);

  // =========================================================================
  // Internal wires
  // =========================================================================

  // Timestamp
  logic [TIMESTAMP_WIDTH-1:0]  global_ts;
  logic                        ts_wrap;

  // Aggregator → Prioritizer
  logic                        agg_out_valid;
  event_pkt_t                  agg_out_event;
  logic                        agg_out_ready;
  logic [31:0]                 agg_drop_count;

  // Prioritizer → Compressor
  logic                        pri_out_valid;
  event_pkt_t                  pri_out_event;
  logic                        pri_out_ready;
  logic                        pri_in_ready;

  // Compressor → Circular Buffer
  logic                        comp_out_valid;
  logic [63:0]                 comp_out_word;
  logic                        comp_out_ready;
  logic                        comp_in_ready;

  // Circular buffer status
  logic [TRACE_ADDR_W-1:0]     buf_head;
  logic [TRACE_ADDR_W-1:0]     buf_tail;
  logic                        buf_full;
  logic                        buf_empty;

  // Fault manager outputs
  fault_vector_t               fault_vector;
  logic                        any_fault;
  logic                        fatal_pulse;
  fault_meta_t                 fault_meta;

  // Snapshot controller
  logic                        buf_freeze;
  logic                        snapshot_valid;
  fault_meta_t                 snapshot_meta;

  // APB ↔ subsystem control/status
  logic                        sw_clear;
  logic [1:0]                  cfg_min_severity;
  logic [7:0]                  cfg_rate_limit;
  logic [15:0]                 cfg_rate_window;
  logic                        cfg_delta_en;
  logic                        cfg_dedup_en;
  logic                        cfg_zero_sup_en;
  logic [7:0]                  cfg_debounce_cycles;
  logic [NUM_FAULT_SOURCES-1:0] fault_clear;

  // Trace read path (APB → buffer)
  logic                        trace_rd_en;
  logic [63:0]                 trace_rd_data;
  logic                        trace_rd_valid;

  // =========================================================================
  // 1. Timestamp Generator
  // =========================================================================
  timestamp_generator #(
    .WIDTH (TIMESTAMP_WIDTH)
  ) u_timestamp (
    .clk        (clk),
    .rst_n      (rst_n),
    .en         (!buf_freeze),    // Pause counter when snapshot is active
    .timestamp  (global_ts),
    .wrap_pulse (ts_wrap)
  );

  // =========================================================================
  // 2. Event Aggregation Fabric
  // =========================================================================
  event_aggregator #(
    .NUM_SOURCES (NUM_SOURCES)
  ) u_aggregator (
    .clk        (clk),
    .rst_n      (rst_n),
    .src_valid  (src_valid),
    .src_events (src_events),
    .out_valid  (agg_out_valid),
    .out_event  (agg_out_event),
    .out_ready  (agg_out_ready),
    .drop_count (agg_drop_count)
  );

  // =========================================================================
  // 3. Event Prioritization Engine
  // =========================================================================
  event_prioritizer u_prioritizer (
    .clk              (clk),
    .rst_n            (rst_n),
    .in_valid         (agg_out_valid),
    .in_event         (agg_out_event),
    .in_ready         (agg_out_ready),
    .out_valid        (pri_out_valid),
    .out_event        (pri_out_event),
    .out_ready        (pri_out_ready),
    .cfg_min_severity (cfg_min_severity),
    .cfg_rate_limit   (cfg_rate_limit),
    .cfg_rate_window  (cfg_rate_window)
  );

  // =========================================================================
  // 4. Trace Compression Engine
  // =========================================================================
  trace_compressor u_compressor (
    .clk            (clk),
    .rst_n          (rst_n),
    .in_valid       (pri_out_valid),
    .in_event       (pri_out_event),
    .in_ready       (pri_out_ready),
    .out_valid      (comp_out_valid),
    .out_word       (comp_out_word),
    .out_ready      (comp_out_ready),
    .cfg_delta_en   (cfg_delta_en),
    .cfg_dedup_en   (cfg_dedup_en),
    .cfg_zero_sup_en(cfg_zero_sup_en)
  );

  // =========================================================================
  // 5. Circular Trace Buffer
  // =========================================================================
  circular_trace_buffer #(
    .DATA_W (64),
    .DEPTH  (TRACE_DEPTH)
  ) u_trace_buf (
    .clk      (clk),
    .rst_n    (rst_n),
    .wr_valid (comp_out_valid),
    .wr_data  (comp_out_word),
    .wr_ready (comp_out_ready),
    .rd_en    (trace_rd_en),
    .rd_data  (trace_rd_data),
    .rd_valid (trace_rd_valid),
    .freeze   (buf_freeze),
    .head_ptr (buf_head),
    .tail_ptr (buf_tail),
    .buf_full (buf_full),
    .buf_empty(buf_empty)
  );

  // =========================================================================
  // 6. Fault Manager
  // =========================================================================
  fault_manager u_fault_mgr (
    .clk                  (clk),
    .rst_n                (rst_n),
    .fault_voltage_droop  (fault_voltage_droop),
    .fault_overcurrent    (fault_overcurrent),
    .fault_overtemp       (fault_overtemp),
    .fault_pll_unlock     (fault_pll_unlock),
    .fault_clk_fail       (fault_clk_fail),
    .fault_watchdog       (fault_watchdog),
    .fault_sensor_fault   (fault_sensor_fault),
    .fault_user           (fault_user),
    .timestamp            (global_ts),
    .cfg_debounce_cycles  (cfg_debounce_cycles),
    .fault_clear          (fault_clear),
    .fault_vector_o       (fault_vector),
    .any_fault_o          (any_fault),
    .fatal_o              (fatal_pulse),
    .fault_meta_o         (fault_meta)
  );

  // =========================================================================
  // 7. Snapshot Controller
  // =========================================================================
  snapshot_controller u_snapshot (
    .clk            (clk),
    .rst_n          (rst_n),
    .fault_trigger  (fatal_pulse),
    .fault_meta_in  (fault_meta),
    .buf_freeze     (buf_freeze),
    .sw_clear       (sw_clear),
    .snapshot_valid  (snapshot_valid),
    .snapshot_meta   (snapshot_meta)
  );

  // =========================================================================
  // 8. APB Slave Interface
  // =========================================================================
  apb_slave u_apb (
    .pclk               (clk),
    .presetn             (rst_n),
    .paddr               (paddr),
    .psel                (psel),
    .penable             (penable),
    .pwrite              (pwrite),
    .pwdata              (pwdata),
    .prdata              (prdata),
    .pready              (pready),
    .pslverr             (pslverr),
    .snapshot_valid      (snapshot_valid),
    .snapshot_meta       (snapshot_meta),
    .trace_head          (buf_head),
    .trace_tail          (buf_tail),
    .current_ts          (global_ts),
    .trace_rd_valid      (trace_rd_valid),
    .trace_rd_data       (trace_rd_data),
    .trace_rd_en         (trace_rd_en),
    .sw_clear            (sw_clear),
    .cfg_min_severity    (cfg_min_severity),
    .cfg_rate_limit      (cfg_rate_limit),
    .cfg_rate_window     (cfg_rate_window),
    .cfg_delta_en        (cfg_delta_en),
    .cfg_dedup_en        (cfg_dedup_en),
    .cfg_zero_sup_en     (cfg_zero_sup_en),
    .cfg_debounce_cycles (cfg_debounce_cycles),
    .fault_clear_o       (fault_clear)
  );

endmodule : sbbr_top

`default_nettype wire
