SIM?=icarus
TOPLEVEL_LANG=verilog
WORK_BASE?=..
#XILINX_BASE=${HOME}/projects/XilinxUnisimLibrary
#XILINX_BASE=/cadtools/ubuntu_x86/xilinx/Vivado/2021.2/data
PROJ_HOME?=$(shell readlink -f ..)
RTLFLOW_PATH?=../rtlflo

TOPLEVEL = dut
MODULE = test_${TOPLEVEL}

# USE_CDS=true
# XILINX_PART?=xc7k325tffg900-2
# XILINX_REV?=2021.2
# ifneq (,$(wildcard ./makefile_synth.mak))
#     include ./makefile_synth.mak
# endif

SIM_SOURCES += \
	${PROJ_HOME}/cocotb/testbench.v 

RTL_SOURCES += \
	${PROJ_HOME}/picorv32.v

COCOTB_SOURCES = \
    ${PROJ_HOME}/cocotb/dut.sv 
    
# ifeq ($(SIM), verilator)
# COCOTB_SOURCES += \
#     ../testbench.cc
# endif

VERILOG_DESIGN += ${XILINX_SIM_SOURCES} ${RTL_SOURCES} ${SIM_SOURCES} ${IMPORT_SOURCES}

VERILOG_SOURCES = \
    ${VERILOG_DESIGN} \
    ${COCOTB_SOURCES}

DEFINES = \
    COMPRESSED_ISA \

# GENERICS = \
# 	VERBOSE=1

include ${RTLFLOW_PATH}/cocotb_helper.mak
