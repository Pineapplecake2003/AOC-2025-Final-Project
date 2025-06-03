SRC1 = $(wildcard ./src/PE_array/PE.sv)
SRC2 = $(wildcard ./src/PE_array/PE_array.sv)
SRC3 = $(wildcard ./src/PPU/PPU.sv)
SRC_TOP = ./src/Controller/top.sv

ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

VERILATOR_FLAGS += --cc --exe
VERILATOR_FLAGS += -I./include -I./Controller
CXXFLAGS += -g

VERILATOR_FLAGS += --build
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --trace-max-array 1024
VERILATOR_FLAGS += --debug

LOG_FILE ?= logs/terminal_text.log
POST_PROCESS :=

# ---------- PE TEST ----------
ifneq ($(PE),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_PE=$(PE)"
    LOG_FILE = logs/terminal_text_pe$(PE).log
    VERILATOR_INPUT = $(SRC1) ./testbench/tb_PE.cpp
    TARGET=VPE
    POST_PROCESS = @chmod 666 ./testbench/tb_PE.cpp

# ---------- PE_ARRAY TEST ----------
else ifneq ($(ARRAY),)
    VERILATOR_FLAGS += -CFLAGS "-DTBA=$(ARRAY)"
    LOG_FILE = logs/terminal_text_array$(ARRAY).log
    VERILATOR_INPUT = $(SRC2) ./testbench/tb_array.cpp
    TARGET=VPE_array
    POST_PROCESS = @chmod 666 ./testbench/tb_array.cpp

# ---------- PPU TEST ----------
else ifneq ($(PPU),)
    VERILATOR_FLAGS += -CFLAGS "-DTB_PPU=$(PPU)"
    LOG_FILE = logs/terminal_text_ppu$(PPU).log
    VERILATOR_INPUT = $(SRC3) ./testbench/tb_PPU.cpp
    TARGET=VPPU
    POST_PROCESS = @chmod 666 ./testbench/tb_PPU.cpp

# ---------- TOP TEST ----------
else ifneq ($(TOP),)
    VERILATOR_FLAGS += -CFLAGS "-DTOP_TEST=$(TOP)"
    VERILATOR_INPUT = $(SRC_TOP) ./testbench/tb.cpp
    TARGET=Vtop
    LOG_FILE = logs/terminal_text_top$(TOP).log
    POST_PROCESS = @chmod 666 ./testbench/tb.cpp
endif

######################################################################
default: all

.PHONY: all pe_all array_all ppu_all top_all

pe_all: pe0 pe1 pe2
array_all: array0 array1 array2 array3 array4 array5
ppu_all: ppu0 ppu1 ppu2
top_all: top

all: pe_all array_all ppu_all top_all

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
.PHONY: pe% array% ppu% top%

pe%:
	make run PE=$*

array%:
	make run ARRAY=$*

ppu%:
	make run PPU=$*

top%:
	make run TOP=$*

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

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs *.log *.dmp *.vpd wave/*.vcd wave/*.fsdb coverage.dat core *.zip release
