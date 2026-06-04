"""
Silicon Black Box Recorder — Cocotb Test: SBBR Top Integration
test_sbbr_top.py

End-to-end integration test verifying:
  1. System boots and timestamp increments
  2. APB register read/write
  3. Fault injection → snapshot → freeze → APB readback
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


async def reset_dut(dut):
    """Apply synchronous reset."""
    dut.rst_n.value = 0
    dut.src_valid.value = 0
    dut.fault_voltage_droop.value = 0
    dut.fault_overcurrent.value = 0
    dut.fault_overtemp.value = 0
    dut.fault_pll_unlock.value = 0
    dut.fault_clk_fail.value = 0
    dut.fault_watchdog.value = 0
    dut.fault_sensor_fault.value = 0
    dut.fault_user.value = 0
    dut.paddr.value = 0
    dut.psel.value = 0
    dut.penable.value = 0
    dut.pwrite.value = 0
    dut.pwdata.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def apb_write(dut, addr, data):
    """Perform a single APB write transaction."""
    dut.paddr.value = addr
    dut.pwdata.value = data
    dut.pwrite.value = 1
    dut.psel.value = 1
    await RisingEdge(dut.clk)
    dut.penable.value = 1
    await RisingEdge(dut.clk)
    dut.psel.value = 0
    dut.penable.value = 0
    dut.pwrite.value = 0
    await RisingEdge(dut.clk)


async def apb_read(dut, addr):
    """Perform a single APB read transaction, return prdata."""
    dut.paddr.value = addr
    dut.pwrite.value = 0
    dut.psel.value = 1
    await RisingEdge(dut.clk)
    dut.penable.value = 1
    await RisingEdge(dut.clk)
    val = int(dut.prdata.value)
    dut.psel.value = 0
    dut.penable.value = 0
    await RisingEdge(dut.clk)
    return val


@cocotb.test()
async def test_boot_timestamp(dut):
    """After reset, timestamp should be incrementing (no freeze)."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Read timestamp via APB (REG_TS_LOW = 0x018)
    await ClockCycles(dut.clk, 20)
    ts_low = await apb_read(dut, 0x018)
    dut._log.info(f"Timestamp low = {ts_low}")
    assert ts_low > 0, "Timestamp should be incrementing"
    dut._log.info("PASS: Timestamp is running after boot")


@cocotb.test()
async def test_apb_control_readback(dut):
    """Write to CONTROL register and read it back."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    test_val = 0x00FF_0305  # rate_window=0xFF, rate_limit=3, zero_sup|dedup|delta=on, sev=CRITICAL
    await apb_write(dut, 0x004, test_val)
    readback = await apb_read(dut, 0x004)
    dut._log.info(f"CONTROL: wrote 0x{test_val:08x}, read 0x{readback:08x}")
    assert readback == test_val, f"Readback mismatch: 0x{readback:08x}"
    dut._log.info("PASS: CONTROL register readback matches")


@cocotb.test()
async def test_fault_to_snapshot(dut):
    """Inject a fault, verify snapshot_valid via STATUS register."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # STATUS before fault
    status = await apb_read(dut, 0x000)
    assert (status >> 1) & 1 == 0, "snapshot_valid should be 0 before fault"

    # Inject overtemperature fault (debounce is fixed at 4 cycles in APB)
    dut.fault_overtemp.value = 1
    await ClockCycles(dut.clk, 20)  # Wait for debounce + FSM

    # STATUS after fault
    status = await apb_read(dut, 0x000)
    snap_valid = (status >> 1) & 1
    dut._log.info(f"STATUS = 0x{status:08x}, snapshot_valid = {snap_valid}")
    assert snap_valid == 1, "snapshot_valid should be 1 after fault"

    # Read FAULT_STATUS
    fault_status = await apb_read(dut, 0x008)
    dut._log.info(f"FAULT_STATUS = 0x{fault_status:08x}")
    assert fault_status & 0x04, "Overtemp bit (bit 2) should be set"

    dut._log.info("PASS: Fault → snapshot pipeline works end-to-end")


@cocotb.test()
async def test_snapshot_clear(dut):
    """After sw_clear via SNAPSHOT_INFO write, snapshot_valid should deassert."""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)

    # Trigger fault
    dut.fault_voltage_droop.value = 1
    await ClockCycles(dut.clk, 20)

    # Verify snapshot is active
    status = await apb_read(dut, 0x000)
    assert (status >> 1) & 1 == 1, "snapshot_valid should be 1"

    # Clear snapshot by writing to SNAPSHOT_INFO (0x014)
    await apb_write(dut, 0x014, 0x1)

    # Release fault and wait
    dut.fault_voltage_droop.value = 0
    await ClockCycles(dut.clk, 5)

    status = await apb_read(dut, 0x000)
    snap_valid = (status >> 1) & 1
    dut._log.info(f"STATUS after clear = 0x{status:08x}, snapshot_valid = {snap_valid}")
    assert snap_valid == 0, "snapshot_valid should be 0 after sw_clear"
    dut._log.info("PASS: Snapshot clear works")
