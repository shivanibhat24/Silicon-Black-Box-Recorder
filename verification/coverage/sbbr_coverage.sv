`ifndef SBBR_COVERAGE_SV
`define SBBR_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class sbbr_coverage extends uvm_subscriber#(sbbr_apb_seq_item);
  `uvm_component_utils(sbbr_coverage)

  uvm_analysis_imp_sensor#(sbbr_sensor_seq_item, sbbr_coverage) sensor_export;

  // Local variables for coverage
  bit [31:0] paddr;
  bit [31:0] pwdata;
  bit        pwrite;

  bit [31:0] ext_temperature;
  bit        ext_pll_error;

  `uvm_analysis_imp_decl(_sensor)

  covergroup cg_apb;
    option.per_instance = 1;
    
    cp_paddr: coverpoint paddr {
      bins status_reg = {32'h000};
      bins control_reg = {32'h004};
      bins fault_status = {32'h008};
      bins snapshot_info = {32'h014};
      bins ts_low = {32'h018};
    }
    
    cp_pwrite: coverpoint pwrite {
      bins read = {0};
      bins write = {1};
    }
    
    cx_addr_write: cross cp_paddr, cp_pwrite;
  endgroup

  covergroup cg_sensor;
    option.per_instance = 1;

    cp_temp: coverpoint ext_temperature {
      bins normal_temp = {[0:100]};
      bins over_temp   = {[101:200]};
    }
    
    cp_pll_error: coverpoint ext_pll_error {
      bins no_error = {0};
      bins error    = {1};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_apb = new();
    cg_sensor = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sensor_export = new("sensor_export", this);
  endfunction

  // Write function for APB analysis port
  virtual function void write(sbbr_apb_seq_item t);
    paddr = t.paddr;
    pwdata = t.pwdata;
    pwrite = t.pwrite;
    cg_apb.sample();
  endfunction

  // Write function for Sensor analysis port
  virtual function void write_sensor(sbbr_sensor_seq_item t);
    ext_temperature = t.ext_temperature;
    ext_pll_error = t.ext_pll_error;
    cg_sensor.sample();
  endfunction

endclass : sbbr_coverage

`endif
