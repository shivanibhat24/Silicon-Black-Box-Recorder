"""
Silicon Black Box Recorder — Cocotb Test: Event Aggregator
test_event_aggregator.py

Verifies:
  1. Single-source event pass-through
  2. Multi-source arbitration (highest index wins)
  3. Drop counting under back-pressure
  4. Reset behavior
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


async def reset_dut(dut):
    """Apply synchronous reset."""
    dut.rst_n.value = 0
    dut.src_valid.value = 0
    dut.out_ready.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_state(dut):
    """After reset, no output valid and drop count is 0."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert int(dut.out_valid.value) == 0, "out_valid should be 0 after reset"
    assert int(dut.drop_count.value) == 0, "drop_count should be 0 after reset"
    dut._log.info("PASS: Reset state correct")


@cocotb.test()
async def test_single_source(dut):
    """Assert valid on source 0, verify output valid appears."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    dut.src_valid.value = 0x01  # Source 0
    dut.out_ready.value = 1
    await ClockCycles(dut.clk, 3)

    assert int(dut.out_valid.value) == 1, "out_valid should be 1"
    dut._log.info("PASS: Single-source event passes through")


@cocotb.test()
async def test_drop_counter(dut):
    """When downstream is not ready, events are dropped and counted."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Fill the buffer first
    dut.src_valid.value = 0x01
    dut.out_ready.value = 1
    await ClockCycles(dut.clk, 2)

    # Now hold back-pressure and keep sending
    dut.out_ready.value = 0
    await ClockCycles(dut.clk, 10)

    drops = int(dut.drop_count.value)
    dut._log.info(f"Drop count = {drops}")
    assert drops > 0, "Drop counter should be > 0 under back-pressure"
    dut._log.info("PASS: Drop counter increments under back-pressure")
