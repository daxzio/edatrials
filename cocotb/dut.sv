module dut #(
	  integer AXI_TEST = 0
	, integer VERBOSE = 0
) (
);

    picorv32_wrapper #(
          .AXI_TEST (AXI_TEST)
        , .VERBOSE (VERBOSE)
    ) i_testbench (
    );

`ifdef COCOTB_ICARUS
    initial begin
        $dumpfile("dut.vcd");
        $dumpvars(0, dut);
        /* verilator lint_off STMTDLY */
        #1;
        /* verilator lint_on STMTDLY */
    end
`endif

endmodule

