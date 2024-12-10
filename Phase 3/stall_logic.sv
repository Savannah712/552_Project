module stall_logic (output stall, input MemtoReg, input [3:0] write_register, input [3:0] SrcReg1, input [3:0] SrcReg2, input flag_enable, input Branch, input MemWrite, input clk, input rst_n);
	//TODO FIXME if 
	//next clock cycle always set to 1 previous_stall
	dff STALL1 (.q(previous_stall), .d(stall), .wen('1), .clk(clk), .rst(~rst_n));
	assign stall = previous_stall ? 1'b0 : ((((write_register == SrcReg1) | (write_register == SrcReg2)) && MemtoReg && ~MemWrite) ? 1'b1 : ((flag_enable && Branch) ? 1'b1 : 1'b0));
endmodule
