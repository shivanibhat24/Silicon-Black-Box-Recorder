`ifndef SBBR_APB_MONITOR_SV
`define SBBR_APB_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "sbbr_apb_seq_item.sv"

class sbbr_apb_monitor extends uvm_monitor;
  `uvm_component_utils(sbbr_apb_monitor)

  virtual sbbr_if vif;
  uvm_analysis_port #(sbbr_apb_seq_item) ap;

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
    sbbr_apb_seq_item item;
    
    forever begin
      @vif.mon_cb;
      if (vif.mon_cb.psel && vif.mon_cb.penable && vif.mon_cb.pready) begin
        item = sbbr_apb_seq_item::type_id::create("item");
        item.paddr   = vif.mon_cb.paddr;
        item.pwrite  = vif.mon_cb.pwrite;
        item.pslverr = vif.mon_cb.pslverr;
        if (item.pwrite)
          item.pwdata = vif.mon_cb.pwdata;
        else
          item.prdata = vif.mon_cb.prdata;
          
        ap.write(item);
      end
    end
  endtask

endclass : sbbr_apb_monitor

`endif
