from cocotb.clock import Clock
from cocotb import start_soon
from cocotb.triggers import RisingEdge, Timer

class ClkReset:
    def __init__(self, dut, period=10, reset_length=100, reset_sense=0, clkname='clk', resetname='resetn'):
        self.clk = getattr(dut, clkname)
        self.reset = getattr(dut, resetname)
        self.period = period
        self.reset_length = reset_length
        self.reset_sense = reset_sense
        
        start_soon(self.start_test(self.period, reset_length=self.reset_length))

    async def wait_clkn(self, length=1):
        for i in range(int(length)):
            await RisingEdge(self.clk)

    async def start_test(self, period=10, units="ns", reset_length=100):
        start_soon(Clock(self.clk, self.period, units=units).start())        
        
        self.reset.setimmediatevalue(self.reset_sense)
        await self.wait_clkn(reset_length)
        self.reset.value = (~self.reset_sense)  & 0x1
        await self.wait_clkn(100)

    async def end_test(self, length=10):
        await self.wait_clkn(length)
