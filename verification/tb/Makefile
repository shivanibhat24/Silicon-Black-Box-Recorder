# =============================================================================
# Silicon Black Box Recorder — Cocotb Makefile
#
# Usage:
#   make MODULE=test_timestamp_generator TOPLEVEL=timestamp_generator
#   make MODULE=test_sbbr_top TOPLEVEL=sbbr_top
#
# Requires: iverilog, cocotb, cocotb-bus
# =============================================================================

SHELL := /bin/bash

# Simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Project root (two levels up from verification/tb/)
PROJ_ROOT := $(shell cd ../.. && pwd)

# RTL source files (packages first, then modules)
PKG_SOURCES = \
	$(PROJ_ROOT)/rtl/common/sbbr_package.sv \
	$(PROJ_ROOT)/rtl/common/event_types_pkg.sv \
	$(PROJ_ROOT)/rtl/common/fault_types_pkg.sv

RTL_SOURCES = \
	$(PROJ_ROOT)/rtl/timestamp/timestamp_generator.sv \
	$(PROJ_ROOT)/rtl/aggregator/event_aggregator.sv \
	$(PROJ_ROOT)/rtl/prioritizer/event_prioritizer.sv \
	$(PROJ_ROOT)/rtl/compression/trace_compressor.sv \
	$(PROJ_ROOT)/rtl/memory/trace_ram.sv \
	$(PROJ_ROOT)/rtl/memory/circular_trace_buffer.sv \
	$(PROJ_ROOT)/rtl/fault_manager/fault_manager.sv \
	$(PROJ_ROOT)/rtl/snapshot/snapshot_controller.sv \
	$(PROJ_ROOT)/rtl/apb/apb_slave.sv \
	$(PROJ_ROOT)/rtl/top/sbbr_top.sv

MODEL_SOURCES = \
	$(PROJ_ROOT)/models/voltage_sensor_model.sv \
	$(PROJ_ROOT)/models/current_sensor_model.sv \
	$(PROJ_ROOT)/models/temperature_sensor_model.sv \
	$(PROJ_ROOT)/models/pll_model.sv \
	$(PROJ_ROOT)/models/workload_generator.sv

VERILOG_SOURCES = $(PKG_SOURCES) $(RTL_SOURCES) $(MODEL_SOURCES)

# Cocotb test module (Python file name without .py)
MODULE ?= test_timestamp_generator

# Top-level module name in the RTL
TOPLEVEL ?= timestamp_generator

# Where the test Python files live
export PYTHONPATH := $(PROJ_ROOT)/verification/tests

# Icarus Verilog compile flags
COMPILE_ARGS += -g2012
COMPILE_ARGS += -DSBBR_ASSERT_ON

# Dump waveforms
SIM_ARGS += -fst

# Cocotb Makefile include
include $(shell cocotb-config --makefiles)/Makefile.sim

# Convenience targets
.PHONY: test_timestamp test_aggregator test_prioritizer test_compressor
.PHONY: test_buffer test_fault_mgr test_snapshot test_top test_all

test_timestamp:
	$(MAKE) MODULE=test_timestamp_generator TOPLEVEL=timestamp_generator

test_aggregator:
	$(MAKE) MODULE=test_event_aggregator TOPLEVEL=event_aggregator

test_prioritizer:
	$(MAKE) MODULE=test_event_prioritizer TOPLEVEL=event_prioritizer

test_compressor:
	$(MAKE) MODULE=test_trace_compressor TOPLEVEL=trace_compressor

test_buffer:
	$(MAKE) MODULE=test_circular_trace_buffer TOPLEVEL=circular_trace_buffer

test_fault_mgr:
	$(MAKE) MODULE=test_fault_manager TOPLEVEL=fault_manager

test_snapshot:
	$(MAKE) MODULE=test_snapshot_controller TOPLEVEL=snapshot_controller

test_top:
	$(MAKE) MODULE=test_sbbr_top TOPLEVEL=sbbr_top

test_all: test_timestamp test_aggregator test_prioritizer test_compressor test_buffer test_fault_mgr test_snapshot test_top
	@echo "=== ALL TESTS COMPLETE ==="
