`ifndef SBBR_SENSOR_MONITOR_SV
`define SBBR_SENSOR_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_sensor_seq_item.sv"

class sbbr_sensor_monitor extends uvm_monitor;
  `uvm_component_utils(sbbr_sensor_monitor)

  virtual sbbr_if vif;
  uvm_analysis_port #(sbbr_sensor_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sbbr_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  task run_phase(uvm_phase phase);
    sbbr_sensor_seq_item item;
    
    forever begin
      @vif.mon_cb;
      item = sbbr_sensor_seq_item::type_id::create("item");
      item.ext_voltage     = vif.mon_cb.ext_voltage;
      item.ext_current     = vif.mon_cb.ext_current;
      item.ext_temperature = vif.mon_cb.ext_temperature;
      item.ext_pll_lock    = vif.mon_cb.ext_pll_lock;
      item.ext_pll_error   = vif.mon_cb.ext_pll_error;
      ap.write(item);
    end
  endtask

endclass : sbbr_sensor_monitor

`endif
