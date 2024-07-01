from cocotb import test
from cocotb.triggers import RisingEdge
# from cocotb import start_soon
# from cocotb.clock import Clock

from interfaces.clkreset import ClkReset

class testbench:
    def __init__(self, dut):
        
        period = 5
        self.cr = ClkReset(dut, period)        
        self.trap = dut.trap
        self.trace_valid = dut.trace_valid
        self.trace_data = dut.trace_data
    
    async def wait_trap(self):
        await RisingEdge(self.trap)

@test()
async def test_dut_basic(dut):
    tb = testbench(dut.i_testbench)
    
    await tb.wait_trap()

