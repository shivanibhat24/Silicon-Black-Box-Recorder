`ifndef SBBR_SENSOR_DRIVER_SV
`define SBBR_SENSOR_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_sensor_seq_item.sv"

class sbbr_sensor_driver extends uvm_driver #(sbbr_sensor_seq_item);
  `uvm_component_utils(sbbr_sensor_driver)

  virtual sbbr_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sbbr_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize defaults
    vif.ext_voltage     <= 32'd1000;
    vif.ext_current     <= 32'd500;
    vif.ext_temperature <= 32'd45;
    vif.ext_pll_lock    <= 1'b1;
    vif.ext_pll_error   <= 1'b0;

    forever begin
      seq_item_port.get_next_item(req);
      @vif.sensor_cb;
      vif.sensor_cb.ext_voltage     <= req.ext_voltage;
      vif.sensor_cb.ext_current     <= req.ext_current;
      vif.sensor_cb.ext_temperature <= req.ext_temperature;
      vif.sensor_cb.ext_pll_lock    <= req.ext_pll_lock;
      vif.sensor_cb.ext_pll_error   <= req.ext_pll_error;
      seq_item_port.item_done();
    end
  endtask

endclass : sbbr_sensor_driver

`endif
