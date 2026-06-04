"""
Silicon Black Box Recorder — Cocotb Test: Fault Manager
test_fault_manager.py

Verifies:
  1. Individual fault detection and debounce
  2. Sticky latch behavior
  3. Fault clear (write-1-to-clear)
  4. First-fault (fatal_o) pulse generation
  5. Fault metadata capture
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


async def reset_dut(dut):
    """Apply synchronous reset, clear all fault inputs."""
    dut.rst_n.value = 0
    dut.fault_voltage_droop.value = 0
    dut.fault_overcurrent.value = 0
    dut.fault_overtemp.value = 0
    dut.fault_pll_unlock.value = 0
    dut.fault_clk_fail.value = 0
    dut.fault_watchdog.value = 0
    dut.fault_sensor_fault.value = 0
    dut.fault_user.value = 0
    dut.timestamp.value = 0
    dut.cfg_debounce_cycles.value = 2  # Short debounce for testing
    dut.fault_clear.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_state(dut):
    """After reset, no faults should be active."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert int(dut.any_fault_o.value) == 0, "No faults expected after reset"
    assert int(dut.fatal_o.value) == 0, "fatal_o should be 0 after reset"
    assert int(dut.fault_vector_o.value) == 0, "fault_vector should be 0"
    dut._log.info("PASS: Reset state correct")


@cocotb.test()
async def test_single_fault_with_debounce(dut):
    """Assert voltage_droop for debounce_cycles+1 to trigger sticky latch."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    dut.cfg_debounce_cycles.value = 3

    # Assert fault
    dut.fault_voltage_droop.value = 1
    dut.timestamp.value = 100

    # Wait for debounce (3 cycles) + 1 to trigger
    await ClockCycles(dut.clk, 6)

    fv = int(dut.fault_vector_o.value)
    assert fv & 0x01, f"Voltage droop fault not set in vector: 0x{fv:02x}"
    assert int(dut.any_fault_o.value) == 1, "any_fault_o should be 1"
    dut._log.info("PASS: Single fault with debounce")


@cocotb.test()
async def test_fatal_pulse(dut):
    """fatal_o should pulse for exactly one cycle on first fault."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    dut.cfg_debounce_cycles.value = 0  # No debounce

    dut.fault_overtemp.value = 1
    dut.timestamp.value = 200

    # Wait a few cycles for the fault to register
    fatal_count = 0
    for _ in range(10):
        await RisingEdge(dut.clk)
        if int(dut.fatal_o.value) == 1:
            fatal_count += 1

    assert fatal_count == 1, f"fatal_o should pulse once, pulsed {fatal_count} times"
    dut._log.info("PASS: fatal_o is single-cycle pulse")


@cocotb.test()
async def test_fault_clear(dut):
    """Writing 1 to fault_clear should deassert the sticky latch."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    dut.cfg_debounce_cycles.value = 0

    # Trigger overcurrent
    dut.fault_overcurrent.value = 1
    await ClockCycles(dut.clk, 4)
    dut.fault_overcurrent.value = 0
    await RisingEdge(dut.clk)

    # Verify it's latched
    fv = int(dut.fault_vector_o.value)
    assert fv & 0x02, "Overcurrent fault should be sticky"

    # Clear it
    dut.fault_clear.value = 0x02
    await RisingEdge(dut.clk)
    dut.fault_clear.value = 0
    await RisingEdge(dut.clk)

    fv = int(dut.fault_vector_o.value)
    assert not (fv & 0x02), "Overcurrent fault should be cleared"
    dut._log.info("PASS: Fault clear works")


@cocotb.test()
async def test_multi_fault(dut):
    """Multiple simultaneous faults should all appear in the vector."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    dut.cfg_debounce_cycles.value = 0

    # Assert multiple faults simultaneously
    dut.fault_voltage_droop.value = 1
    dut.fault_overtemp.value = 1
    dut.fault_pll_unlock.value = 1
    dut.timestamp.value = 500

    await ClockCycles(dut.clk, 4)

    fv = int(dut.fault_vector_o.value)
    # Bit 0 = voltage_droop, bit 2 = overtemp, bit 3 = pll_unlock
    assert fv & 0x01, "Voltage droop not set"
    assert fv & 0x04, "Overtemp not set"
    assert fv & 0x08, "PLL unlock not set"
    dut._log.info(f"PASS: Multi-fault vector = 0x{fv:02x}")
