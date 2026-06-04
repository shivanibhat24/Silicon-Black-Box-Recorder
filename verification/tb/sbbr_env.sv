`ifndef SBBR_ENV_SV
`define SBBR_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "sbbr_apb_agent.sv"
`include "sbbr_sensor_agent.sv"
`include "sbbr_scoreboard.sv"
`include "sbbr_coverage.sv"

class sbbr_env extends uvm_env;
  `uvm_component_utils(sbbr_env)

  sbbr_apb_agent    apb_agt;
  sbbr_sensor_agent sensor_agt;
  sbbr_scoreboard   scoreboard;
  sbbr_coverage     coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agt    = sbbr_apb_agent::type_id::create("apb_agt", this);
    sensor_agt = sbbr_sensor_agent::type_id::create("sensor_agt", this);
    scoreboard = sbbr_scoreboard::type_id::create("scoreboard", this);
    coverage   = sbbr_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    apb_agt.monitor.ap.connect(scoreboard.apb_fifo.analysis_export);
    sensor_agt.monitor.ap.connect(scoreboard.sensor_fifo.analysis_export);
    
    // Connect Coverage
    apb_agt.monitor.ap.connect(coverage.analysis_export);
    sensor_agt.monitor.ap.connect(coverage.sensor_export);
  endfunction

endclass : sbbr_env

`endif
