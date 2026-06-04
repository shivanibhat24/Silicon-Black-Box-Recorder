`ifndef SBBR_IF_SV
`define SBBR_IF_SV

interface sbbr_if (input logic clk, input logic rst_n);

  // -----------------------------------------
  // Sensor Inputs
  // -----------------------------------------
  logic [31:0] ext_voltage;
  logic [31:0] ext_current;
  logic [31:0] ext_temperature;
  logic        ext_pll_lock;
  logic        ext_pll_error;

  // -----------------------------------------
  // APB Interface
  // -----------------------------------------
  logic [31:0] paddr;
  logic        psel;
  logic        penable;
  logic        pwrite;
  logic [31:0] pwdata;
  logic        pready;
  logic [31:0] prdata;
  logic        pslverr;

  // -----------------------------------------
  // Interrupts
  // -----------------------------------------
  logic        fatal_interrupt;

  // -----------------------------------------
  // Clocking Blocks
  // -----------------------------------------
  
  // APB Master Clocking Block (used by APB Driver)
  clocking apb_cb @(posedge clk);
    default input #1step output #1;
    input  pready, prdata, pslverr;
    output paddr, psel, penable, pwrite, pwdata;
  endclocking

  // Sensor Clocking Block (used by Sensor Driver)
  clocking sensor_cb @(posedge clk);
    default input #1step output #1;
    output ext_voltage, ext_current, ext_temperature, ext_pll_lock, ext_pll_error;
  endclocking

  // Monitor Clocking Block (used by Monitors to observe everything)
  clocking mon_cb @(posedge clk);
    default input #1step output #1;
    input ext_voltage, ext_current, ext_temperature, ext_pll_lock, ext_pll_error;
    input paddr, psel, penable, pwrite, pwdata, pready, prdata, pslverr;
    input fatal_interrupt;
  endclocking

  // Modports
  modport apb_master (clocking apb_cb);
  modport sensor_drv (clocking sensor_cb);
  modport monitor    (clocking mon_cb);

endinterface : sbbr_if

`endif
