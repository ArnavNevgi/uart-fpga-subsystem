echo "============================================================"
echo "Running Phase 2 UART RX Simulation"
echo "============================================================"

transcript file ../logs/run.log

vsim -voptargs="+acc" -wlf ../../docs/waveforms/phase2_uart_rx_valid_frame.wlf work.tb_uart_rx

do wave.do

run -all

transcript file

echo "============================================================"
echo "SIMULATION DONE"
echo "============================================================"