###############################################################################
# Create Vivado Project for UART FPGA Subsystem
###############################################################################

set PROJECT_NAME "uart_fpga_subsystem"
set PART_NAME    "xc7a35tcpg236-1"
set TOP_NAME     "uart_top"

set SCRIPT_DIR   [file normalize [file dirname [info script]]]
set REPO_ROOT    [file normalize [file join $SCRIPT_DIR "../.."]]
set RTL_DIR      [file join $REPO_ROOT "rtl"]
set XDC_FILE     [file join $SCRIPT_DIR "constraints.xdc"]

# Keep Vivado generated project/cache files outside OneDrive.
set BUILD_ROOT   "C:/vivado_uart_build"
set PROJECT_DIR  [file join $BUILD_ROOT $PROJECT_NAME]

puts "============================================================"
puts "Creating Vivado project"
puts "Repo root    : $REPO_ROOT"
puts "Build dir    : $PROJECT_DIR"
puts "Part         : $PART_NAME"
puts "Top          : $TOP_NAME"
puts "============================================================"

# Close any open project before deleting/recreating generated files.
if {![catch {current_project} current_proj]} {
  puts "Closing open Vivado project: $current_proj"
  close_project
}

# Remove generated Vivado logs from the script directory.
foreach stale_file [concat \
  [glob -nocomplain -directory $SCRIPT_DIR "*.jou"] \
  [glob -nocomplain -directory $SCRIPT_DIR "*.log"] \
  [glob -nocomplain -directory $SCRIPT_DIR "*.str"]] {
  file delete -force $stale_file
}

# Clean the generated project directory outside OneDrive.
if {[file exists $PROJECT_DIR]} {
  puts "Deleting old generated project directory: $PROJECT_DIR"
  if {[catch {file delete -force $PROJECT_DIR} delete_msg]} {
    error "Failed to delete $PROJECT_DIR. Close Vivado, ensure no files are locked, then delete it manually. Tcl error: $delete_msg"
  }
}

file mkdir $BUILD_ROOT

create_project $PROJECT_NAME $PROJECT_DIR -part $PART_NAME

set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set rtl_files [list \
  [file join $RTL_DIR "uart_pkg.sv"] \
  [file join $RTL_DIR "baud_gen.sv"] \
  [file join $RTL_DIR "uart_tx.sv"] \
  [file join $RTL_DIR "uart_rx.sv"] \
  [file join $RTL_DIR "sync_fifo.sv"] \
  [file join $RTL_DIR "uart_fifo_subsystem.sv"] \
  [file join $RTL_DIR "uart_regs.sv"] \
  [file join $RTL_DIR "uart_top.sv"] \
]

foreach rtl_file $rtl_files {
  if {![file exists $rtl_file]} {
    error "Missing RTL source: $rtl_file"
  }
}

if {![file exists $XDC_FILE]} {
  error "Missing constraints file: $XDC_FILE"
}

add_files -fileset sources_1 $rtl_files
add_files -fileset constrs_1 $XDC_FILE

foreach rtl_file $rtl_files {
  set_property file_type SystemVerilog [get_files $rtl_file]
}

set_property top $TOP_NAME [current_fileset]

update_compile_order -fileset sources_1

puts "============================================================"
puts "Vivado project created successfully"
puts "Project file : [file join $PROJECT_DIR ${PROJECT_NAME}.xpr]"
puts "Reports stay : [file join $REPO_ROOT fpga reports]"
puts "============================================================"
