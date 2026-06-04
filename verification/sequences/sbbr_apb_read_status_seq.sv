`ifndef SBBR_APB_READ_STATUS_SEQ_SV
`define SBBR_APB_READ_STATUS_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_apb_read_status_seq extends sbbr_apb_base_seq;
  `uvm_object_utils(sbbr_apb_read_status_seq)

  bit [31:0] status_val;
  bit [31:0] fault_status_val;

  function new(string name = "sbbr_apb_read_status_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing sbbr_apb_read_status_seq", UVM_LOW)
    
    // Read STATUS register (0x000)
    read_reg(32'h000, status_val);
    `uvm_info(get_type_name(), $sformatf("Read STATUS: 0x%08x", status_val), UVM_LOW)

    // Read FAULT_STATUS register (0x008)
    read_reg(32'h008, fault_status_val);
    `uvm_info(get_type_name(), $sformatf("Read FAULT_STATUS: 0x%08x", fault_status_val), UVM_LOW)
  endtask

endclass : sbbr_apb_read_status_seq

`endif
