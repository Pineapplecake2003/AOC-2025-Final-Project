vcs:
	mkdir -p logs
	vcs -R -sverilog -debug_access+all -full64 testbench.sv | tee ./logs/vcs_simulation.log
	@echo "VCS simulation finished."

fsdb:
	mkdir -p logs
	vcs -R -sverilog -debug_access+all -full64 +define+FSDB testbench.sv | tee ./logs/vcs_simulation.log
	@echo "VCS simulation finished."

clean:
	rm -rf csrc simv* ucli* vc_hdrs.h DVEfiles logs nWaveLog BSSLib.lib++
	rm -rf *.vpd *.fsdb *.log *.vcd *.vstf *.vstf.gz
	rm -rf *.conf *.rc