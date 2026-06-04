`ifndef SBBR_APB_CONFIG_SEQ_SV
`define SBBR_APB_CONFIG_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_apb_config_seq extends sbbr_apb_base_seq;
  `uvm_object_utils(sbbr_apb_config_seq)

  rand bit [31:0] config_val;

  function new(string name = "sbbr_apb_config_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing sbbr_apb_config_seq", UVM_LOW)
    // Write to CONTROL register (0x004)
    write_reg(32'h004, config_val);
    `uvm_info(get_type_name(), $sformatf("Configured SBBR with 0x%08x", config_val), UVM_LOW)
  endtask

endclass : sbbr_apb_config_seq

`endif
