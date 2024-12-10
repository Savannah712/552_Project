module ReadDecoder_4_16(input [3:0] RegId, output [15:0] Wordline);
		// Seperate idea
	wire [15:0] shift3, shift2,shift1,shift0,shiftv;
	assign shiftv = 16'h0001;
	assign shift3 = RegId[3] ? (shiftv << 8) : shiftv;
	assign shift2 = RegId[2] ? (shift3 << 4) : shift3;
	assign shift1 = RegId[1] ? (shift2 << 2) : shift2;
	assign shift0 = RegId[0] ? (shift1 << 1) : shift1;
	assign Wordline = shift0;
endmodule

module WriteDecoder_4_16(input [3:0] RegId, input WriteReg, output [15:0] Wordline);
	wire [15:0] shift3, shift2, shift1, shift0, shiftv;
	assign shiftv = 16'h0001;
	assign shift3 = RegId[3] ? (shiftv << 8) : shiftv;
	assign shift2 = RegId[2] ? (shift3 << 4) : shift3;
	assign shift1 = RegId[1] ? (shift2 << 2) : shift2;
	assign shift0 = RegId[0] ? (shift1 << 1) : shift1;
	assign Wordline = WriteReg ? shift0 : 16'b0000;
endmodule

module BitCell( input clk,  input rst, input D, input WriteEnable, input ReadEnable1, input ReadEnable2, inout Bitline1, inout Bitline2);
	wire temp_q,combined_out;
	dff one_flop(.q(temp_q), .d(D), .wen(WriteEnable), .clk(clk), .rst(rst));
	assign Bitline1 = ~ReadEnable1 ? temp_q : 1'bz;
	assign Bitline2 = ~ReadEnable2 ? temp_q : 1'bz;	
endmodule

module Register( input clk,  input rst, input [15:0] D, input WriteReg, input ReadEnable1, input ReadEnable2, inout [15:0] Bitline1, inout [15:0] Bitline2);
	BitCell line [15:0] (.clk(clk),  .rst(rst), .D(D), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .Bitline1(Bitline1), .Bitline2(Bitline2));
endmodule

module RegisterFile(input clk, input rst, input [3:0] SrcReg1, input [3:0] SrcReg2, input [3:0] DstReg, input WriteReg, input [15:0] DstData, inout [15:0] SrcData1, inout [15:0] SrcData2);
	wire [15:0] read_1en, read_2en, write_en;
	ReadDecoder_4_16 read_src1 (.RegId(SrcReg1),.Wordline(read_1en));
	ReadDecoder_4_16 read_src2 (.RegId(SrcReg2),.Wordline(read_2en));
	WriteDecoder_4_16 write_d  (.RegId(DstReg),.WriteReg(WriteReg),.Wordline(write_en));
	//READ ENABLES ARE ACTIVE LOW
	Register regs [15:0] (.clk(clk),  .rst(rst), .D(DstData), .WriteReg(write_en), .ReadEnable1(~read_1en), .ReadEnable2(~read_2en), .Bitline1(SrcData1), .Bitline2(SrcData2));
endmodule


module t_RegisterFile();
logic clk,rst,WriteReg;
logic [3:0] SrcReg1,SrcReg2,DstReg;
wire [15:0] SrcData1, SrcData2;
logic [15:0] DstData;
	RegisterFile iDUT (.clk(clk),.rst(rst),.SrcReg1(SrcReg1),.SrcReg2(SrcReg2),.DstReg(DstReg),.WriteReg(WriteReg),.DstData(DstData),.SrcData1(SrcData1),.SrcData2(SrcData2));
	always
		#5 clk <= ~clk;
	initial begin
		clk = 0;
		rst = 1;
		DstData = 16'h3099;
		SrcReg1 = '1;
		SrcReg2 = '1;
		#15
		rst = 0;
		WriteReg = 1;
		assert(SrcData1 === '0 & SrcData2 === '0)
		else begin
			$display("Bad Reset");
			$stop();
		end
		#5
		DstReg = 4'h7;
		DstData = 16'h3099;
		SrcReg1 = 4'h7;
		#10;
		DstReg = 4'h0;
		SrcReg1 = 4'h1; // Random Reg
		DstData = 16'h808A;
		SrcReg2 = 4'h0;
		#15;
		WriteReg = 0;
		#5;
		SrcReg1 = 4'h7; // Random Reg
		DstData = 16'hA173;
		#15;
		rst = 1;
		#15
		$display("Wahooooo!!! Test Passed");
		$stop();

	end
endmodule
