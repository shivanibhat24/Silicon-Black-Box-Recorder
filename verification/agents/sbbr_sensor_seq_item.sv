`ifndef SBBR_SENSOR_SEQ_ITEM_SV
`define SBBR_SENSOR_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_sensor_seq_item extends uvm_sequence_item;
  
  rand bit [31:0] ext_voltage;
  rand bit [31:0] ext_current;
  rand bit [31:0] ext_temperature;
  rand bit        ext_pll_lock;
  rand bit        ext_pll_error;

  `uvm_object_utils_begin(sbbr_sensor_seq_item)
    `uvm_field_int(ext_voltage,     UVM_ALL_ON)
    `uvm_field_int(ext_current,     UVM_ALL_ON)
    `uvm_field_int(ext_temperature, UVM_ALL_ON)
    `uvm_field_int(ext_pll_lock,    UVM_ALL_ON)
    `uvm_field_int(ext_pll_error,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "sbbr_sensor_seq_item");
    super.new(name);
  endfunction

endclass : sbbr_sensor_seq_item

`endif
