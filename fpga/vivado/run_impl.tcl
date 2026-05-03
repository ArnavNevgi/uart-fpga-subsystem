###############################################################################
# Run Implementation for UART FPGA Subsystem
###############################################################################

set PROJECT_NAME "uart_fpga_subsystem"

set SCRIPT_DIR   [file normalize [file dirname [info script]]]
set REPO_ROOT    [file normalize [file join $SCRIPT_DIR "../.."]]
set REPORT_DIR   [file join $REPO_ROOT "fpga" "reports"]
set PROJECT_DIR  [file join "C:/vivado_uart_build" $PROJECT_NAME]
set PROJECT_XPR  [file join $PROJECT_DIR "${PROJECT_NAME}.xpr"]

puts "============================================================"
puts "Running Vivado implementation"
puts "Project file : $PROJECT_XPR"
puts "Report dir   : $REPORT_DIR"
puts "============================================================"

if {[catch {current_project} current_proj]} {
  if {![file exists $PROJECT_XPR]} {
    error "No open project and project file not found: $PROJECT_XPR. Run source create_project.tcl first."
  }

  open_project $PROJECT_XPR
}

file mkdir $REPORT_DIR

if {[llength [get_runs -quiet impl_1]] == 0} {
  error "Vivado run impl_1 does not exist. Recreate the project with create_project.tcl."
}

reset_run impl_1
launch_runs impl_1 -to_step route_design -jobs 4

if {[catch {wait_on_run impl_1} wait_msg]} {
  set impl_status [get_property STATUS [get_runs impl_1]]
  error "wait_on_run impl_1 failed. Run status: $impl_status. Tcl error: $wait_msg"
}

set impl_status   [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]

puts "Implementation status   : $impl_status"
puts "Implementation progress : $impl_progress"

if {![string match "*Complete*" $impl_status]} {
  error "Implementation did not complete successfully. Run status: $impl_status"
}

open_run impl_1

report_utilization -file [file join $REPORT_DIR "phase8_impl_utilization.rpt"]
report_timing_summary -file [file join $REPORT_DIR "phase8_impl_timing_summary.rpt"]
report_route_status -file [file join $REPORT_DIR "phase8_route_status.rpt"]
report_drc -file [file join $REPORT_DIR "phase8_drc.rpt"]

puts "============================================================"
puts "IMPLEMENTATION COMPLETE"
puts "Generated reports:"
puts "[file join $REPORT_DIR phase8_impl_utilization.rpt]"
puts "[file join $REPORT_DIR phase8_impl_timing_summary.rpt]"
puts "[file join $REPORT_DIR phase8_route_status.rpt]"
puts "[file join $REPORT_DIR phase8_drc.rpt]"
puts "============================================================"

# Bitstream generation is intentionally not launched here yet.
# Full board pin constraints are required for a clean board-ready bitstream.
