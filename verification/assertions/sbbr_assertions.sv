`ifndef SBBR_ASSERTIONS_SV
`define SBBR_ASSERTIONS_SV

module sbbr_assertions (
  input logic clk,
  input logic rst_n,
  
  // APB interface signals
  input logic psel,
  input logic penable,
  input logic pready,

  // Fault signals and interrupt
  input logic fault_overtemp,
  input logic fatal_interrupt
);

  // Assertion: APB Handshake
  // When psel is asserted, penable must be asserted in the next cycle.
  property p_apb_setup_phase;
    @(posedge clk) disable iff (!rst_n)
      (psel && !penable) |=> penable;
  endproperty

  assert_apb_setup_phase: assert property(p_apb_setup_phase)
    else $error("APB Setup phase violation: penable not asserted after psel");

  // Assertion: APB Access Phase
  // penable must stay high until pready is high.
  property p_apb_access_phase;
    @(posedge clk) disable iff (!rst_n)
      (psel && penable && !pready) |=> (psel && penable);
  endproperty

  assert_apb_access_phase: assert property(p_apb_access_phase)
    else $error("APB Access phase violation: psel or penable dropped before pready");

  // Assertion: Fatal Interrupt on Overtemp
  // If an overtemp fault occurs, a fatal interrupt should eventually fire
  // Note: the exact cycle delay depends on the debounce logic in the RTL, using a bounded window.
  property p_fatal_interrupt_overtemp;
    @(posedge clk) disable iff (!rst_n)
      $rose(fault_overtemp) |-> ##[1:20] $rose(fatal_interrupt);
  endproperty

  assert_fatal_interrupt_overtemp: assert property(p_fatal_interrupt_overtemp)
    else $error("Fatal interrupt did not trigger within 20 cycles of overtemp fault");

endmodule : sbbr_assertions

`endif
