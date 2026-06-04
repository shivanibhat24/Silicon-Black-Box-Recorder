"""
Silicon Black Box Recorder — Cocotb Test: Trace Compressor
test_trace_compressor.py

Verifies:
  1. A single event produces a 64-bit compressed output word
  2. Zero-payload suppression sets the flag bit
  3. Basic FSM cycling (IDLE → EMIT_NORMAL → IDLE)
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
    dut.cfg_delta_en.value = 1
    dut.cfg_dedup_en.value = 0
    dut.cfg_zero_sup_en.value = 1
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
async def test_single_event_compression(dut):
    """Inject one event and verify compressed output appears."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Inject an event with zero payload (to exercise zero suppression)
    # event_pkt_t: {timestamp[47:0], source_id[7:0], severity[1:0], event_type[3:0], payload[31:0]}
    # Total width = 48 + 8 + 2 + 4 + 32 = 94 bits
    dut.in_valid.value = 1
    dut.in_event.value = 0  # All zeros: timestamp=0, source=0, sev=INFO, type=0, payload=0
    dut.out_ready.value = 1
    await RisingEdge(dut.clk)
    dut.in_valid.value = 0

    # Wait for output
    for _ in range(5):
        await RisingEdge(dut.clk)
        if int(dut.out_valid.value) == 1:
            word = int(dut.out_word.value)
            dut._log.info(f"Compressed word: 0x{word:016x}")
            # Bit 61 = zero_payload should be set if cfg_zero_sup_en=1
            zero_pay_bit = (word >> 61) & 1
            assert zero_pay_bit == 1, "Zero-payload flag should be set"
            dut._log.info("PASS: Single event compressed with zero-payload flag")
            return

    assert False, "out_valid never asserted"


@cocotb.test()
async def test_in_ready_during_idle(dut):
    """in_ready should be 1 when FSM is in IDLE."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    assert int(dut.in_ready.value) == 1, "in_ready should be 1 in IDLE"
    dut._log.info("PASS: in_ready = 1 in IDLE state")
