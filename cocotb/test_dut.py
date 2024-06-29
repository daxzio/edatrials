from cocotb import test
from cocotb.triggers import RisingEdge

class testbench:
    def __init__(self, dut):
        self.trap = dut.i_testbench.trap

@test()
async def test_dut_basic(dut):
    tb = testbench(dut)
    
    await RisingEdge(tb.trap)

