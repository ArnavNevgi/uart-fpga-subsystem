echo "============================================================"
echo "Running Phase 1 UART TX Simulation"
echo "============================================================"

transcript file ../logs/run.log

vsim -voptargs="+acc" work.tb_uart_tx

do wave.do

run -all

transcript file

echo "============================================================"
echo "SIMULATION DONE"
echo "============================================================"