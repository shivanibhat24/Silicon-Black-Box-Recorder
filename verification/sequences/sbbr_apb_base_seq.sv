`ifndef SBBR_APB_BASE_SEQ_SV
`define SBBR_APB_BASE_SEQ_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_apb_base_seq extends uvm_sequence#(sbbr_apb_seq_item);
  `uvm_object_utils(sbbr_apb_base_seq)

  function new(string name = "sbbr_apb_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing sbbr_apb_base_seq", UVM_HIGH)
  endtask

  // Helper task for APB write
  virtual task write_reg(bit [31:0] addr, bit [31:0] data);
    sbbr_apb_seq_item req;
    req = sbbr_apb_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
      paddr  == addr;
      pwdata == data;
      pwrite == 1'b1;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed for APB write")
    end
    finish_item(req);
  endtask

  // Helper task for APB read
  virtual task read_reg(bit [31:0] addr, output bit [31:0] data);
    sbbr_apb_seq_item req;
    req = sbbr_apb_seq_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
      paddr  == addr;
      pwrite == 1'b0;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed for APB read")
    end
    finish_item(req);
    data = req.prdata;
  endtask

endclass : sbbr_apb_base_seq

`endif
