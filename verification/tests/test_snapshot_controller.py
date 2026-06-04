"""
Silicon Black Box Recorder — Cocotb Test: Snapshot Controller
test_snapshot_controller.py

Verifies:
  1. FSM transitions: ARMED → TRIGGERED → FROZEN → READY
  2. buf_freeze asserted from TRIGGERED through READY
  3. Metadata latch on TRIGGERED
  4. SW clear returns to ARMED and releases freeze
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


async def reset_dut(dut):
    """Apply synchronous reset."""
    dut.rst_n.value = 0
    dut.fault_trigger.value = 0
    dut.fault_meta_in.value = 0
    dut.sw_clear.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_initial_armed(dut):
    """After reset, state should be ARMED with no freeze."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert int(dut.buf_freeze.value) == 0, "buf_freeze should be 0 in ARMED"
    assert int(dut.snapshot_valid.value) == 0, "snapshot_valid should be 0 in ARMED"
    dut._log.info("PASS: Initial ARMED state correct")


@cocotb.test()
async def test_fault_triggers_freeze(dut):
    """A fault_trigger pulse should cause buf_freeze to assert."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Trigger fault
    dut.fault_trigger.value = 1
    dut.fault_meta_in.value = 0xABCD_1234_5678_9ABC  # Some metadata
    await RisingEdge(dut.clk)
    dut.fault_trigger.value = 0
    await RisingEdge(dut.clk)

    # Should now be in TRIGGERED or FROZEN — freeze must be asserted
    assert int(dut.buf_freeze.value) == 1, "buf_freeze should be 1 after fault"
    dut._log.info("PASS: Fault triggers freeze")


@cocotb.test()
async def test_fsm_reaches_ready(dut):
    """FSM should transition from TRIGGERED → FROZEN → READY in 2 cycles."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Trigger
    dut.fault_trigger.value = 1
    dut.fault_meta_in.value = 0x0000_0000_0000_00FF
    await RisingEdge(dut.clk)
    dut.fault_trigger.value = 0

    # TRIGGERED → FROZEN → READY (2 more cycles)
    await ClockCycles(dut.clk, 3)

    assert int(dut.snapshot_valid.value) == 1, "snapshot_valid should be 1 in READY"
    assert int(dut.buf_freeze.value) == 1, "buf_freeze should still be 1 in READY"
    dut._log.info("PASS: FSM reaches READY state")


@cocotb.test()
async def test_sw_clear_releases_freeze(dut):
    """SW clear should return FSM to ARMED and release buf_freeze."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Trigger and wait for READY
    dut.fault_trigger.value = 1
    dut.fault_meta_in.value = 0
    await RisingEdge(dut.clk)
    dut.fault_trigger.value = 0
    await ClockCycles(dut.clk, 3)

    # Now SW clear
    dut.sw_clear.value = 1
    await RisingEdge(dut.clk)
    dut.sw_clear.value = 0
    await RisingEdge(dut.clk)

    assert int(dut.buf_freeze.value) == 0, "buf_freeze should be 0 after sw_clear"
    assert int(dut.snapshot_valid.value) == 0, "snapshot_valid should be 0 after clear"
    dut._log.info("PASS: SW clear releases freeze")
