VERILATOR = verilator
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
COMPRESSED_ISA = C
OSS_RELEASE?=2024-06-29
YY=$(subst -,,$(OSS_RELEASE))
OSS_DIR?=./oss-cad-suite/${OSS_RELEASE}
# SHELL := /usr/bin/bash

xx:
	echo ${OSS_RELEASE}
	echo ${YY}
    
${OSS_DIR}: xx
	mkdir -p ${OSS_DIR}
	wget -c -P downloads https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_RELEASE}/oss-cad-suite-linux-x64-${YY}.tgz
	tar -zxvf downloads/oss-cad-suite-linux-x64-${YY}.tgz -C ${OSS_DIR}
	mv ${OSS_DIR}/oss-cad-suite/* ${OSS_DIR}/.
	rmdir ${OSS_DIR}/oss-cad-suite
	rm -rf ./oss-cad-suite/release
	cd ./oss-cad-suite ; ln -s ${OSS_RELEASE} release

setup: ${OSS_DIR}
	@echo "source ./oss-cad-suite/release/environment"
#     iverilog -v

# 	curl -s https://api.github.com/reposYosysHQ/oss-cad-suite-build/releases/latest | grep browser_download_url | cut -d '"' -f 4

test: testbench.vvp firmware/firmware.hex
	$(VVP) -N $<

test_axi: testbench.vvp firmware/firmware.hex
	$(VVP) -N $< +axi_test +vcd

test_synth: testbench_synth.vvp firmware/firmware.hex
	$(VVP) -N $<

test_verilator: testbench_verilator firmware/firmware.hex
	./testbench_verilator

testbench.vvp: testbench.v picorv32.v
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

testbench_synth.vvp: testbench.v synth.v
	$(IVERILOG) -o $@ -DSYNTH_TEST $^
	chmod -x $@

testbench_verilator: testbench.v picorv32.v testbench.cc
	$(VERILATOR) --cc --exe -Wno-lint -trace --top-module picorv32_wrapper testbench.v picorv32.v testbench.cc \
			$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) --Mdir testbench_verilator_dir
	$(MAKE) -C testbench_verilator_dir -f Vpicorv32_wrapper.mk
	cp testbench_verilator_dir/Vpicorv32_wrapper testbench_verilator

synth.v: picorv32.v scripts/yosys/synth_sim.ys
	yosys -qv3 -l synth.log scripts/yosys/synth_sim.ys

test_synth_yosys: testbench.v  synth_yosys.v
	$(IVERILOG) -o testbench_synth_yosys.vvp -DSYNTH_TEST $^
	chmod -x testbench_synth_yosys.vvp
	vvp -N testbench_synth_yosys.vvp

test_synth_verilator: testbench.v  synth_yosys.v
	$(VERILATOR) --cc --exe -Wno-lint -trace -DSYNTH_TEST --top-module picorv32_wrapper $^ \
			--Mdir testbench_verilator_yosys_dir 
	$(MAKE) -C testbench_verilator_yosys_dir -f Vpicorv32_wrapper.mk
# 	cp testbench_verilator_yosys_dir/Vpicorv32_wrapper testbench_verilator_yosys
#     ./testbench_verilator_yosys
 

test_ius: testbench.v picorv32.v
	mkdir -p sim_build
	irun -timescale 1ns/1ps \
		-disable_sem2009 -sv  -licqueue -64 -nclibdirpath sim_build -plinowarn -top testbench  \
		-define COMPRESSED_ISA \
		-define COCOTB_CADENCE=1 \
		-access +rwc -createdebugdb  $^

test_cadence: testbench.v picorv32.v
	mkdir -p sim_build
	xrun -timescale 1ns/1ps \
		-disable_sem2009 -sv  -licqueue -64 -xmlibdirpath sim_build -plinowarn -top testbench  -define COMPRESSED_ISA -define COCOTB_CADENCE=1 \
		-access +rwc -createdebugdb $^

test_vcs: testbench.v picorv32.v
	rm -rf simv.daidir/.vcs.timestamp
	vcs +nowarnTFIPC +nowarnSV-SVPIA +nowarnSDFCOM_SWC -sverilog -full64 -v2005 -debug_access+all +vpd_dump \
	-v $^
	./simv +vpd_dump 

firmware/firmware.hex: 
# firmware/firmware.hex: firmware/firmware.bin firmware/makehex.py
# 	$(PYTHON) firmware/makehex.py $< 32768 > $@
# 
# firmware/firmware.bin: firmware/firmware.elf
# 	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
# 	chmod -x $@
# 
lint:
	verible-verilog-lint  \
		--rules -always-comb,-no-trailing-spaces,-line-length,-unpacked-dimensions-range-ordering,-parameter-name-style,-enum-name-style,-generate-label,-macro-name-style \
		blockmem_2p.sv
        
clean:
	rm -rf *.vvp testbench_verilator* synth.* *.vcd vivado* sim_build* simv.daidir/ ucli.key csrc/ ucli.key simv DVEfiles/

.PHONY: test test_axi test_synth clean
