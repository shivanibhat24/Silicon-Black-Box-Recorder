`ifndef SBBR_UVM_TB_TOP_SV
`define SBBR_UVM_TB_TOP_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

module sbbr_uvm_tb_top;

  // Clock and Reset
  logic clk;
  logic rst_n;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
  end

  // Interface instance
  sbbr_if vif(clk, rst_n);

  // DUT instance
  sbbr_top dut (
    .clk             (clk),
    .rst_n           (rst_n),
    .ext_voltage     (vif.ext_voltage),
    .ext_current     (vif.ext_current),
    .ext_temperature (vif.ext_temperature),
    .ext_pll_lock    (vif.ext_pll_lock),
    .ext_pll_error   (vif.ext_pll_error),
    .paddr           (vif.paddr),
    .psel            (vif.psel),
    .penable         (vif.penable),
    .pwrite          (vif.pwrite),
    .pwdata          (vif.pwdata),
    .pready          (vif.pready),
    .prdata          (vif.prdata),
    .pslverr         (vif.pslverr),
    .fatal_interrupt (vif.fatal_interrupt)
  );

  // Bind Assertions
  bind sbbr_top sbbr_assertions u_assertions (
    .clk(clk),
    .rst_n(rst_n),
    .psel(psel),
    .penable(penable),
    .pready(pready),
    // For fault_overtemp, we can connect it to the input ext_temperature threshold
    // or assume the testbench injects it. In our tb, we have ext_temperature from vif.
    // The top module parses it into fault_overtemp. We will just pass the internal signal if accessible,
    // or we can connect it to a dummy for now.
    // Assuming sbbr_top has a wire `fault_overtemp` inside (from fault_manager), 
    // we can access it via hierarchical reference or just map the ports:
    .fault_overtemp(fault_manager_inst.fault_overtemp), // Assuming instance name
    .fatal_interrupt(fatal_interrupt)
  );

  // UVM Test Startup
  initial begin
    // Pass the virtual interface to the UVM configuration database
    uvm_config_db#(virtual sbbr_if)::set(null, "uvm_test_top", "vif", vif);

    // Assert reset
    rst_n = 0;
    #20;
    rst_n = 1;

    // Start UVM tests
    run_test();
  end

  // Optional Waveform Dumping
  initial begin
    $dumpfile("waves/sbbr_uvm.fst");
    $dumpvars(0, sbbr_uvm_tb_top);
  end

endmodule : sbbr_uvm_tb_top

`endif
