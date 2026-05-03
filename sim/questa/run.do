echo "============================================================"
echo "Running Phase 4 UART Top Register Interface Simulation"
echo "============================================================"

transcript file ../logs/run.log

vsim -voptargs="+acc" -wlf ../../docs/waveforms/phase4_uart_top_register_interface.wlf work.tb_uart_top

do wave.do

run -all

transcript file

echo "============================================================"
echo "SIMULATION DONE"
echo "============================================================"