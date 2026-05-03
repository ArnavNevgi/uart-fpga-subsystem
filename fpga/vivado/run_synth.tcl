###############################################################################
# Run Synthesis for UART FPGA Subsystem
###############################################################################

set PROJECT_NAME "uart_fpga_subsystem"
set TOP_NAME     "uart_top"

set SCRIPT_DIR   [file normalize [file dirname [info script]]]
set REPO_ROOT    [file normalize [file join $SCRIPT_DIR "../.."]]
set REPORT_DIR   [file join $REPO_ROOT "fpga" "reports"]
set PROJECT_DIR  [file join "C:/vivado_uart_build" $PROJECT_NAME]
set PROJECT_XPR  [file join $PROJECT_DIR "${PROJECT_NAME}.xpr"]

puts "============================================================"
puts "Running Vivado synthesis"
puts "Project file : $PROJECT_XPR"
puts "Report dir   : $REPORT_DIR"
puts "============================================================"

if {[catch {current_project} current_proj]} {
  if {![file exists $PROJECT_XPR]} {
    error "No open project and project file not found: $PROJECT_XPR. Run source create_project.tcl first."
  }

  open_project $PROJECT_XPR
}

set_property top $TOP_NAME [current_fileset]
update_compile_order -fileset sources_1

file mkdir $REPORT_DIR

if {[llength [get_runs -quiet synth_1]] == 0} {
  error "Vivado run synth_1 does not exist. Recreate the project with create_project.tcl."
}

puts "Resetting synthesis run..."
reset_run synth_1

puts "Launching synthesis run..."
launch_runs synth_1 -jobs 4

if {[catch {wait_on_run synth_1} wait_msg]} {
  set synth_status [get_property STATUS [get_runs synth_1]]
  error "wait_on_run synth_1 failed. Run status: $synth_status. Tcl error: $wait_msg"
}

set synth_status   [get_property STATUS [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]

puts "Synthesis status   : $synth_status"
puts "Synthesis progress : $synth_progress"

if {![string match "*Complete*" $synth_status]} {
  error "Synthesis did not complete successfully. Run status: $synth_status"
}

open_run synth_1

report_utilization -file [file join $REPORT_DIR "phase8_synth_utilization.rpt"]
report_timing_summary -file [file join $REPORT_DIR "phase8_synth_timing_summary.rpt"]
report_clocks -file [file join $REPORT_DIR "phase8_synth_clocks.rpt"]

puts "============================================================"
puts "SYNTHESIS COMPLETE"
puts "Generated reports:"
puts "[file join $REPORT_DIR phase8_synth_utilization.rpt]"
puts "[file join $REPORT_DIR phase8_synth_timing_summary.rpt]"
puts "[file join $REPORT_DIR phase8_synth_clocks.rpt]"
puts "============================================================"
