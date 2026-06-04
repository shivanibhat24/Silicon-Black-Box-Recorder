`ifndef SBBR_SENSOR_FAULT_SEQ_SV
`define SBBR_SENSOR_FAULT_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_sensor_fault_seq extends sbbr_sensor_base_seq;
  `uvm_object_utils(sbbr_sensor_fault_seq)

  rand bit inject_overtemp;
  rand bit inject_pll_error;

  function new(string name = "sbbr_sensor_fault_seq");
    super.new(name);
  endfunction

  virtual task body();
    sbbr_sensor_seq_item req;
    `uvm_info(get_type_name(), "Executing sbbr_sensor_fault_seq", UVM_LOW)
    
    req = sbbr_sensor_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
      if (inject_overtemp) ext_temperature == 32'd150;
      else ext_temperature == 32'd25;

      if (inject_pll_error) ext_pll_error == 1'b1;
      else ext_pll_error == 1'b0;

      ext_pll_lock == 1'b1;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed for fault sequence")
    end
    finish_item(req);
  endtask

endclass : sbbr_sensor_fault_seq

`endif
