`ifndef SBBR_SCOREBOARD_SV
`define SBBR_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_apb_seq_item.sv"
`include "sbbr_sensor_seq_item.sv"

class sbbr_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(sbbr_scoreboard)

  uvm_tlm_analysis_fifo #(sbbr_apb_seq_item)    apb_fifo;
  uvm_tlm_analysis_fifo #(sbbr_sensor_seq_item) sensor_fifo;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_fifo    = new("apb_fifo", this);
    sensor_fifo = new("sensor_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    sbbr_apb_seq_item    apb_tx;
    sbbr_sensor_seq_item sensor_tx;

    forever begin
      // This is a placeholder for actual complex checking logic
      // In a real scenario, you would model the SBBR trace memory here
      // and compare it against reads from the APB interface.
      apb_fifo.get(apb_tx);
      `uvm_info("SCOREBOARD", $sformatf("Observed APB Access: Addr=0x%0h Write=%0b", apb_tx.paddr, apb_tx.pwrite), UVM_LOW)
    end
  endtask

endclass : sbbr_scoreboard

`endif
