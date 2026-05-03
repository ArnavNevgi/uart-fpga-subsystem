echo "============================================================"
echo "Compiling UART FPGA Subsystem"
echo "============================================================"

transcript file ../logs/compile.log

if {[file exists work]} {
    echo "Deleting old work library..."
    vdel -lib work -all
}

echo "Creating work library..."
vlib work
vmap work work

echo "Compiling RTL files..."
vlog -sv -work work -f ../../filelists/rtl.f

echo "Compiling TB files..."
vlog -sv -work work -f ../../filelists/tb.f

echo "Compilation completed."
echo "Check ../logs/compile.log for full transcript."

transcript file ""

echo "============================================================"
echo "COMPILE DONE"
echo "============================================================"