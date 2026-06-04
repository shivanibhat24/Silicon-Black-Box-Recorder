`ifndef SBBR_SENSOR_AGENT_SV
`define SBBR_SENSOR_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_sensor_seq_item.sv"
`include "sbbr_sensor_driver.sv"
`include "sbbr_sensor_monitor.sv"

class sbbr_sensor_agent extends uvm_agent;
  `uvm_component_utils(sbbr_sensor_agent)

  sbbr_sensor_driver  driver;
  sbbr_sensor_monitor monitor;
  uvm_sequencer #(sbbr_sensor_seq_item) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = sbbr_sensor_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = sbbr_sensor_driver::type_id::create("driver", this);
      sequencer = uvm_sequencer#(sbbr_sensor_seq_item)::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : sbbr_sensor_agent

`endif
