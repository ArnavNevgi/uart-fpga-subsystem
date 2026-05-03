echo "============================================================"
echo "Running Phase 3B UART FIFO Subsystem Simulation"
echo "============================================================"

transcript file ../logs/run.log

vsim -voptargs="+acc" -wlf ../../docs/waveforms/phase3b_uart_fifo_subsystem.wlf work.tb_uart_fifo_subsystem

do wave.do

run -all

transcript file

echo "============================================================"
echo "SIMULATION DONE"
echo "============================================================"