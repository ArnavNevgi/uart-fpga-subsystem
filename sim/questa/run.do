echo "============================================================"
echo "Running Phase 3 FIFO Simulation"
echo "============================================================"

transcript file ../logs/run.log

vsim -voptargs="+acc" -wlf ../../docs/waveforms/phase3_sync_fifo_basic.wlf work.tb_sync_fifo

do wave.do

run -all

transcript file

echo "============================================================"
echo "SIMULATION DONE"
echo "============================================================"