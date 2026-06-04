// =============================================================================
// Silicon Black Box Recorder — APB Slave Interface
// apb_slave.sv
//
// AMBA APB3 compliant slave.
// Exposes all SBBR configuration and status registers.
// Provides streaming read access to circular trace buffer contents.
//
// Register map defined in sbbr_pkg.sv.
// Write-1-to-clear semantics on FAULT_STATUS register.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;
import fault_types_pkg::*;

module apb_slave (
  // APB bus
  input  wire                     pclk,
  input  wire                     presetn,
  input  wire [APB_ADDR_W-1:0]    paddr,
  input  wire                     psel,
  input  wire                     penable,
  input  wire                     pwrite,
  input  wire [APB_DATA_W-1:0]    pwdata,
  output logic [APB_DATA_W-1:0]   prdata,
  output logic                    pready,
  output logic                    pslverr,

  // Connections to internal subsystems
  // --- Status inputs ---
  input  wire                     snapshot_valid,
  input  fault_meta_t             snapshot_meta,
  input  wire [TRACE_ADDR_W-1:0]  trace_head,
  input  wire [TRACE_ADDR_W-1:0]  trace_tail,
  input  wire [TIMESTAMP_WIDTH-1:0] current_ts,

  // --- Trace data stream ---
  input  wire                     trace_rd_valid,
  input  wire [63:0]              trace_rd_data,
  output logic                    trace_rd_en,

  // --- Control outputs ---
  output logic                    sw_clear,         // Snapshot release
  output logic [1:0]              cfg_min_severity,
  output logic [7:0]              cfg_rate_limit,
  output logic [15:0]             cfg_rate_window,
  output logic                    cfg_delta_en,
  output logic                    cfg_dedup_en,
  output logic                    cfg_zero_sup_en,
  output logic [7:0]              cfg_debounce_cycles,

  // --- Fault clear ---
  output logic [NUM_FAULT_SOURCES-1:0] fault_clear_o
);

  // ---------------------------------------------------------------------------
  // Internal register file
  // ---------------------------------------------------------------------------
  logic [APB_DATA_W-1:0] reg_control;
  logic [APB_DATA_W-1:0] reg_status;

  // APB handshake — always single-cycle (no wait states)
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

  // ---------------------------------------------------------------------------
  // Write logic
  // ---------------------------------------------------------------------------
  logic apb_wr;
  assign apb_wr = psel && penable && pwrite;

  always_ff @(posedge pclk) begin
    if (!presetn) begin
      reg_control        <= 32'h0000_0101; // Default: SEV_INFO, delta+dedup on
      fault_clear_o      <= '0;
      sw_clear           <= 1'b0;
    end else begin
      // Clear pulse signals
      fault_clear_o <= '0;
      sw_clear      <= 1'b0;

      if (apb_wr) begin
        case (paddr)
          REG_CONTROL: begin
            reg_control <= pwdata;
          end
          REG_FAULT_STATUS: begin
            // Write-1-to-clear
            fault_clear_o <= pwdata[NUM_FAULT_SOURCES-1:0];
          end
          REG_SNAPSHOT_INFO: begin
            // Writing any value to SNAPSHOT_INFO releases snapshot
            sw_clear <= 1'b1;
          end
          default: ; // Ignore writes to read-only registers
        endcase
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Configuration decode from CONTROL register
  // ---------------------------------------------------------------------------
  assign cfg_min_severity    = reg_control[1:0];
  assign cfg_rate_limit      = reg_control[15:8];
  assign cfg_rate_window     = reg_control[31:16];
  assign cfg_delta_en        = reg_control[2];
  assign cfg_dedup_en        = reg_control[3];
  assign cfg_zero_sup_en     = reg_control[4];
  assign cfg_debounce_cycles = 8'h04; // Fixed for now; extend CONTROL reg if needed

  // ---------------------------------------------------------------------------
  // Read logic
  // ---------------------------------------------------------------------------
  always_ff @(posedge pclk) begin
    if (!presetn) begin
      prdata    <= '0;
      trace_rd_en <= 1'b0;
    end else begin
      trace_rd_en <= 1'b0;

      if (psel && !pwrite) begin
        case (paddr)
          REG_STATUS: begin
            prdata <= {30'b0, snapshot_valid, 1'b0};
          end
          REG_FAULT_STATUS: begin
            prdata <= {{(32-NUM_FAULT_SOURCES){1'b0}},
                       snapshot_meta.active_faults};
          end
          REG_TRACE_HEAD: begin
            prdata <= {{(32-TRACE_ADDR_W){1'b0}}, trace_head};
          end
          REG_TRACE_TAIL: begin
            prdata <= {{(32-TRACE_ADDR_W){1'b0}}, trace_tail};
          end
          REG_SNAPSHOT_INFO: begin
            prdata <= {{(32-NUM_FAULT_SOURCES){1'b0}},
                       snapshot_meta.active_faults};
          end
          REG_TS_LOW: begin
            prdata <= current_ts[31:0];
          end
          REG_TS_HIGH: begin
            prdata <= {{(32-16){1'b0}}, current_ts[47:32]};
          end
          REG_TRACE_DATA: begin
            // 64-bit word returned in two consecutive reads (low word first)
            trace_rd_en <= 1'b1;
            prdata       <= trace_rd_valid ? trace_rd_data[31:0] : 32'hDEAD_BEEF;
          end
          REG_CONTROL: begin
            prdata <= reg_control;
          end
          default: prdata <= 32'h0;
        endcase
      end
    end
  end

endmodule : apb_slave

`default_nettype wire
