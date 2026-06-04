`ifndef SBBR_SENSOR_BASE_SEQ_SV
`define SBBR_SENSOR_BASE_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_sensor_base_seq extends uvm_sequence#(sbbr_sensor_seq_item);
  `uvm_object_utils(sbbr_sensor_base_seq)

  function new(string name = "sbbr_sensor_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing sbbr_sensor_base_seq", UVM_HIGH)
  endtask

  // Helper task for driving normal sensor values
  virtual task drive_normal_sensors();
    sbbr_sensor_seq_item req;
    req = sbbr_sensor_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
      ext_voltage == 32'd1000;
      ext_current == 32'd500;
      ext_temperature == 32'd25;
      ext_pll_lock == 1'b1;
      ext_pll_error == 1'b0;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed for normal sensor values")
    end
    finish_item(req);
  endtask

endclass : sbbr_sensor_base_seq

`endif
