import os
from cocotb_test.simulator import run

PROJ_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

def run_cocotb_test(module, toplevel, sources):
    run(
        verilog_sources=sources,
        toplevel=toplevel,
        module=module,
        simulator="icarus",
        toplevel_lang="verilog",
        compile_args=["-g2012"]
    )

def test_timestamp_generator():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/timestamp/timestamp_generator.sv"
    ]
    run_cocotb_test("test_timestamp_generator", "timestamp_generator", sources)

def test_circular_trace_buffer():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/memory/trace_ram.sv",
        f"{PROJ_ROOT}/rtl/memory/circular_trace_buffer.sv"
    ]
    run_cocotb_test("test_circular_trace_buffer", "circular_trace_buffer", sources)

def test_fault_manager():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/common/fault_types_pkg.sv",
        f"{PROJ_ROOT}/rtl/fault_manager/fault_manager.sv"
    ]
    run_cocotb_test("test_fault_manager", "fault_manager", sources)

def test_snapshot_controller():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/common/fault_types_pkg.sv",
        f"{PROJ_ROOT}/rtl/snapshot/snapshot_controller.sv"
    ]
    run_cocotb_test("test_snapshot_controller", "snapshot_controller", sources)

def test_event_aggregator():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/common/event_types_pkg.sv",
        f"{PROJ_ROOT}/rtl/aggregator/event_aggregator.sv"
    ]
    run_cocotb_test("test_event_aggregator", "event_aggregator", sources)

def test_event_prioritizer():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/prioritizer/event_prioritizer.sv"
    ]
    run_cocotb_test("test_event_prioritizer", "event_prioritizer", sources)

def test_trace_compressor():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/compression/trace_compressor.sv"
    ]
    run_cocotb_test("test_trace_compressor", "trace_compressor", sources)

def test_sbbr_top():
    sources = [
        f"{PROJ_ROOT}/rtl/common/sbbr_package.sv",
        f"{PROJ_ROOT}/rtl/common/event_types_pkg.sv",
        f"{PROJ_ROOT}/rtl/common/fault_types_pkg.sv",
        f"{PROJ_ROOT}/rtl/timestamp/timestamp_generator.sv",
        f"{PROJ_ROOT}/rtl/aggregator/event_aggregator.sv",
        f"{PROJ_ROOT}/rtl/prioritizer/event_prioritizer.sv",
        f"{PROJ_ROOT}/rtl/compression/trace_compressor.sv",
        f"{PROJ_ROOT}/rtl/memory/trace_ram.sv",
        f"{PROJ_ROOT}/rtl/memory/circular_trace_buffer.sv",
        f"{PROJ_ROOT}/rtl/fault_manager/fault_manager.sv",
        f"{PROJ_ROOT}/rtl/snapshot/snapshot_controller.sv",
        f"{PROJ_ROOT}/rtl/apb/apb_slave.sv",
        f"{PROJ_ROOT}/rtl/top/sbbr_top.sv",
        f"{PROJ_ROOT}/models/voltage_sensor_model.sv",
        f"{PROJ_ROOT}/models/current_sensor_model.sv",
        f"{PROJ_ROOT}/models/temperature_sensor_model.sv",
        f"{PROJ_ROOT}/models/pll_model.sv",
        f"{PROJ_ROOT}/models/workload_generator.sv"
    ]
    run_cocotb_test("test_sbbr_top", "sbbr_top", sources)
