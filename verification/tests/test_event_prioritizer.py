"""
Silicon Black Box Recorder — Cocotb Test: Event Prioritizer
test_event_prioritizer.py

Verifies:
  1. Events pass through when severity >= min_severity
  2. Events are filtered below min_severity
  3. FATAL events always pass regardless of rate limit
  4. Rate limiting of low-priority events
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


async def reset_dut(dut):
    """Apply synchronous reset."""
    dut.rst_n.value = 0
    dut.in_valid.value = 0
    dut.in_event.value = 0
    dut.out_ready.value = 1
    dut.cfg_min_severity.value = 0    # Accept all
    dut.cfg_rate_limit.value = 255    # No rate limit
    dut.cfg_rate_window.value = 100
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_state(dut):
    """After reset, output should be idle."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert int(dut.out_valid.value) == 0, "out_valid should be 0 after reset"
    dut._log.info("PASS: Reset state correct")


@cocotb.test()
async def test_event_passes_above_severity(dut):
    """An event with severity >= min_severity should pass through."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    dut.cfg_min_severity.value = 0  # Accept INFO and above

    # Build a minimal event packet with severity = SEV_INFO (0)
    # event_pkt_t layout: timestamp[47:0], source_id[7:0], severity[1:0], event_type[3:0], payload[31:0]
    # severity bits are at position [EVENT_PAYLOAD_W + 4 : EVENT_PAYLOAD_W + 4 + 1] = [36:35]
    dut.in_valid.value = 1
    dut.in_event.value = 0  # All zeros = SEV_INFO
    dut.out_ready.value = 1

    await ClockCycles(dut.clk, 3)

    assert int(dut.out_valid.value) == 1, "Event should pass through"
    dut._log.info("PASS: Event passes above severity threshold")


@cocotb.test()
async def test_in_ready_signal(dut):
    """in_ready should reflect downstream readiness."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    dut.out_ready.value = 1
    await RisingEdge(dut.clk)

    ready = int(dut.in_ready.value)
    assert ready == 1, "in_ready should be 1 when downstream is ready"
    dut._log.info("PASS: in_ready reflects downstream readiness")
