VERILATOR = verilator
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
COMPRESSED_ISA = C
OSS_RELEASE?=2024-06-08
OSS_DIR?=./oss-cad-suite/${OSS_RELEASE}
# SHELL := /usr/bin/bash

${OSS_DIR}:
	mkdir -p ${OSS_DIR}
	wget -c -P downloads https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2024-06-08/oss-cad-suite-linux-x64-20240608.tgz
	tar -zxvf downloads/oss-cad-suite-linux-x64-20240608.tgz -C ${OSS_DIR}
	mv ${OSS_DIR}/oss-cad-suite/* ${OSS_DIR}/.
	rmdir ${OSS_DIR}/oss-cad-suite

setup: ${OSS_DIR}
# 	source ${OSS_DIR}/environment
	iverilog -v

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
	rm -rf *.vvp testbench_verilator* synth.* *.vcd

.PHONY: test test_axi test_synth clean
