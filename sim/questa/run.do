echo "============================================================"
echo "Running Phase 7 Randomized UART Verification"
echo "============================================================"

file mkdir ../logs
file mkdir ../../docs/waveforms

transcript file ../logs/run.log

vsim -coverage -voptargs="+acc" -wlf ../../docs/waveforms/phase7_randomized_verification.wlf work.tb_uart_random

do wave.do

run -all

coverage report -details -file ../logs/phase7_coverage_report.txt

transcript file ""

echo "============================================================"
echo "SIMULATION DONE"
echo "Coverage report: ../logs/phase7_coverage_report.txt"
echo "============================================================"
