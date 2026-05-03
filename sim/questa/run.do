echo "============================================================"
echo "Running Phase 5 Internal Loopback Simulation"
echo "============================================================"

file mkdir ../logs
file mkdir ../../docs/waveforms

transcript file ../logs/run.log

vsim -voptargs="+acc" -wlf ../../docs/waveforms/phase5_internal_loopback.wlf work.tb_uart_loopback

do wave.do

run -all

transcript file ""

echo "============================================================"
echo "SIMULATION DONE"
echo "============================================================"
