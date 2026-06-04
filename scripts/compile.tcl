# =============================================================================
# Silicon Black Box Recorder — Compilation Script
# compile.tcl
#
# Iverilog compilation for Cocotb simulation
# Usage: tclsh scripts/compile.tcl  (or sourced by Makefile)
# =============================================================================

set rtl_root  "rtl"
set model_root "models"

# Package files (must be compiled first)
set pkg_files [list \
  "$rtl_root/common/sbbr_package.sv" \
  "$rtl_root/common/event_types_pkg.sv" \
  "$rtl_root/common/fault_types_pkg.sv" \
]

# RTL design files
set rtl_files [list \
  "$rtl_root/timestamp/timestamp_generator.sv" \
  "$rtl_root/aggregator/event_aggregator.sv" \
  "$rtl_root/prioritizer/event_prioritizer.sv" \
  "$rtl_root/compression/trace_compressor.sv" \
  "$rtl_root/memory/trace_ram.sv" \
  "$rtl_root/memory/circular_trace_buffer.sv" \
  "$rtl_root/fault_manager/fault_manager.sv" \
  "$rtl_root/snapshot/snapshot_controller.sv" \
  "$rtl_root/apb/apb_slave.sv" \
  "$rtl_root/top/sbbr_top.sv" \
]

# Model files
set model_files [list \
  "$model_root/voltage_sensor_model.sv" \
  "$model_root/current_sensor_model.sv" \
  "$model_root/temperature_sensor_model.sv" \
  "$model_root/pll_model.sv" \
  "$model_root/workload_generator.sv" \
]

puts "=== SBBR Compile Script ==="
puts "Packages:  [llength $pkg_files]"
puts "RTL files: [llength $rtl_files]"
puts "Models:    [llength $model_files]"

set all_files [concat $pkg_files $rtl_files $model_files]

foreach f $all_files {
  if {![file exists $f]} {
    puts "ERROR: File not found: $f"
  } else {
    puts "  OK: $f"
  }
}

puts "=== Done ==="
