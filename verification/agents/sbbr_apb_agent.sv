`ifndef SBBR_APB_AGENT_SV
`define SBBR_APB_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_apb_seq_item.sv"
`include "sbbr_apb_driver.sv"
`include "sbbr_apb_monitor.sv"

class sbbr_apb_agent extends uvm_agent;
  `uvm_component_utils(sbbr_apb_agent)

  sbbr_apb_driver  driver;
  sbbr_apb_monitor monitor;
  uvm_sequencer #(sbbr_apb_seq_item) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = sbbr_apb_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = sbbr_apb_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(sbbr_apb_seq_item)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : sbbr_apb_agent

`endif
