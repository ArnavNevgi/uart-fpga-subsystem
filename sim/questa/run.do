echo "============================================================"
echo "Running Phase 6 Assertions and Functional Coverage Simulation"
echo "============================================================"

file mkdir ../logs
file mkdir ../../docs/waveforms

transcript file ../logs/run.log

vsim -coverage -voptargs="+acc" -wlf ../../docs/waveforms/phase6_assertions_coverage.wlf work.tb_uart_loopback

do wave.do

run -all

coverage report -details -file ../logs/phase6_coverage_report.txt

transcript file ""

echo "============================================================"
echo "SIMULATION DONE"
echo "Coverage report: ../logs/phase6_coverage_report.txt"
echo "============================================================"
