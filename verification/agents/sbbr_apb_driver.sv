`ifndef SBBR_APB_DRIVER_SV
`define SBBR_APB_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_apb_seq_item.sv"

class sbbr_apb_driver extends uvm_driver #(sbbr_apb_seq_item);
  `uvm_component_utils(sbbr_apb_driver)

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
    vif.paddr   <= 0;
    vif.psel    <= 0;
    vif.penable <= 0;
    vif.pwrite  <= 0;
    vif.pwdata  <= 0;

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  task

  task drive_item(sbbr_apb_seq_item item);
    // APB Setup Phase
    @vif.apb_cb;
    vif.apb_cb.paddr  <= item.paddr;
    vif.apb_cb.pwrite <= item.pwrite;
    vif.apb_cb.psel   <= 1'b1;
    if (item.pwrite)
      vif.apb_cb.pwdata <= item.pwdata;
    
    // APB Access Phase
    @vif.apb_cb;
    vif.apb_cb.penable <= 1'b1;

    // Wait for pready
    wait(vif.apb_cb.pready == 1'b1);
    
    // Capture read data
    if (!item.pwrite)
      item.prdata = vif.apb_cb.prdata;
    
    item.pslverr = vif.apb_cb.pslverr;

    // Teardown
    @vif.apb_cb;
    vif.apb_cb.psel    <= 1'b0;
    vif.apb_cb.penable <= 1'b0;
  endtask

endclass : sbbr_apb_driver

`endif
