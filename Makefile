SRC1 = $(wildcard ./src/PE_array/PE.sv)
SRC2 = $(wildcard ./src/PE_array/PE_array.sv)
SRC3 = $(wildcard ./src/PPU/PPU.sv)
SRC4 = $(wildcard ./src/PE_array/SUPER.sv)

ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

VERILATOR_FLAGS += --cc --exe
VERILATOR_FLAGS += -I./include
CXXFLAGS += -g

# Optimize
# VERILATOR_FLAGS += -x-assign fast

# Warn abount lint issues; may not want this on less solid designs
# VERILATOR_FLAGS += -Wall
# VERILATOR_FLAGS += -Wall -Wno-lint

# Automatically build the Verilated model
VERILATOR_FLAGS += --build

# Make waveforms
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --trace-max-array 1024

# assign x when wire/reg not driven
VERILATOR_FLAGS += -x-assign unique

# Run Verilator in debug mode
# VERILATOR_FLAGS += --debug

LOG_FILE ?= logs/terminal_text.log
POST_PROCESS :=

ifneq ($(PE),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_PE=$(PE)"
    LOG_FILE = logs/terminal_text_pe$(PE).log
    VERILATOR_INPUT = $(SRC1) ./testbench/tb_PE.cpp
    TARGET=VPE
    POST_PROCESS = @chmod 666 ./testbench/tb_PE.cpp
else
ifneq ($(ARRAY),)
    VERILATOR_FLAGS += -CFLAGS "-DTBA=$(ARRAY)"
    LOG_FILE = logs/terminal_text_array$(ARRAY).log
    VERILATOR_INPUT = $(SRC2) ./testbench/tb_array.cpp
    TARGET=VPE_array
    POST_PROCESS = @chmod 666 ./testbench/tb_array.cpp
else
ifneq ($(PPU),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_PPU=$(PPU)"
    VERILATOR_INPUT = $(SRC3) ./testbench/tb_PPU.cpp
    TARGET=VPPU
    LOG_FILE = logs/terminal_text_ppu$(PPU).log
    POST_PROCESS = @chmod 666 ./testbench/tb_PPU.cpp
else
ifneq ($(SUPER),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_SUPER=$(SUPER)"
    LOG_FILE = logs/terminal_text_super$(SUPER).log
    VERILATOR_INPUT = $(SRC4) ./testbench/tb_SUPER.cpp
    TARGET = VSUPER
    POST_PROCESS = @chmod 666 ./testbench/tb_SUPER.cpp
endif
endif
endif
endif

######################################################################
default: all

.PHONY: all pe_all array_all ppu_all super_all

pe_all: pe0 pe1 pe2 pe3 pe4 pe5 pe6 pe7
array_all: \
    array0 array1 array2 array3 array4 \
	array5 array7 array8 array9 array10 \
	array11 array12 array13 array14 array15 array16
ppu_all: ppu0 ppu1 ppu2
super_all:super0 super1 super2 super3 super7 super8 super9 super10

all: pe_all array_all ppu_all super_all

VCS_all: \
    vcs0 vcs1 vcs2 vcs3 vcs4 \
	vcs5 vcs7 vcs8 vcs9 vcs10 \
	vcs11 vcs12 vcs13 vcs14 vcs15 vcs16

run:
	@echo
	@echo "-- Verilator Start"

	@echo
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	obj_dir/$(TARGET) +trace > $(LOG_FILE)

	@echo
	@echo "-- DONE --------------------"
	@echo "To see waveforms, open PE_wave.vcd in a waveform viewer"
	@echo

	$(POST_PROCESS)

######################################################################
# Specific Testbench Targets
# Pass TB_select as a parameter to the simulation executable
.PHONY: array% pe% super%

pe%:
	mkdir -p wave
	make run PE=$*

array%:
	mkdir -p wave
	make run ARRAY=$*

ppu%:
	mkdir -p wave
	make run PPU=$*

super%:
	mkdir -p wave
	make run SUPER=$*

######################################################################
# Other targets

format:
	clang-format -i testbench/*.cpp testbench/*.h
	@chmod 666 ./testbench/*.cpp
	@chmod 666 ./testbench/*.h
show-config:
	$(VERILATOR) -V

dist:
	make clean
	python release.py
	cd release && zip -r ../aoc2025-lab3.zip .

gen_test_data_for_array:
	g++ test_data_gen.cpp -DWHOLE_IFMAP
	./a.out > data.log

gen_test_data_for_pe:
	g++ test_data_gen.cpp
	./a.out > data.log

gen_ID_CONV:
	g++ ID_gen.cpp -o gen_ID.out
	./gen_ID.out | tee gen_ID_conv.log

gen_ID_LINEAR:
	g++ ID_gen.cpp -o gen_ID.out -DLINEAR
	./gen_ID.out | tee gen_ID_linear.log

vcs_id_gen:
	mkdir -p logs
	vcs -full64 -sverilog -debug_access+all \
		tb_ID_gen_combinational.v \
		-o simv_id_gen
	./simv_id_gen | tee logs/vcs_id_gen.log
	@echo "VCS simulation finished. Log: logs/vcs_id_gen.log"

id%:
	g++ ID_to_verilog_file_format.cpp -DTBA=$*
	./a.out

vcs%:
	g++ ID_to_verilog_file_format.cpp -DTBA=$*
	./a.out
	g++ GLB_mirror_gen.cpp -DTBA=$*
	./a.out
	mkdir -p logs
	mkdir -p wave
	vcs -R -sverilog +define+TBA$* +define+FSDB +incdir+./include +incdir+./src -debug_access+all -full64 testbench/one_pass_tb.sv | tee ./logs/vcs_simulation_result$*.log
	@echo "Detailed result store in ./logs/"

# clean *.hex
maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs a.out *.txt *.log *.dmp *.vpd wave/*.vcd wave/*.fsdb coverage.dat core *.zip release simv ucli.key simv.daidir csrc
	-rm -rf simv_id_gen.daidir
	-rm -f gen_ID.out simv_id_gen
# clean *.hex
	find . -type f -name "*.hex" -delete 