`ifndef SBBR_APB_SEQ_ITEM_SV
`define SBBR_APB_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_apb_seq_item extends uvm_sequence_item;
  
  rand bit [31:0] paddr;
  rand bit [31:0] pwdata;
  rand bit        pwrite;
       bit [31:0] prdata;
       bit        pslverr;

  `uvm_object_utils_begin(sbbr_apb_seq_item)
    `uvm_field_int(paddr,   UVM_ALL_ON)
    `uvm_field_int(pwdata,  UVM_ALL_ON)
    `uvm_field_int(pwrite,  UVM_ALL_ON)
    `uvm_field_int(prdata,  UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "sbbr_apb_seq_item");
    super.new(name);
  endfunction

endclass : sbbr_apb_seq_item

`endif
