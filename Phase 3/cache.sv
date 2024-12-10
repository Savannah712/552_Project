module cache(input clk, input rst, input write, input data_access, input data_rdy, input [15:0] MemAddress, input [15:0] DataIn, output [15:0] CacheOut, output miss);
// Wires
wire [5:0] set, tag;
wire [3:0] block;
wire [127:0] BlockEnable1;
wire [6:0] set_shifted_1;
wire [15:0] DataOut1, DataOut2;
wire [7:0] WordEnable1, MetaDataOut1, MetaDataOut2, MetaDataIn1, MetaDataIn2, ff_MetaDataIn1, ff_MetaDataIn2, ff_MetaDataOut1, ff_MetaDataOut2, MetaDataInF1, MetaDataInF2;
wire hit1,hit2, ff_hit1, ff_hit2;

// Assign tag, set, block
assign tag = DataIn[15:10];
assign set = DataIn[9:4];
assign block = DataIn[3:0];


// Multiply set by 2
assign set_shifted_1 = {set,1'b0};

// BlockEnable1
// Shift 128-bit 1 by (set * 2): 1, 2, 4, 8, ...
BlockShifter BS1 (.Shift_Out(BlockEnable1), .Shift_In(128'h00000000000000000000000000000001), .Shift_Val(set_shifted_1));

//WordEnable1
WordShifter WS1(.Shift_Out(WordEnable1), .Shift_In(8'h01), .Shift_Val(block[3:1]));


// MetaDataOutX[1] = Valid bit
assign hit1 = ((MetaDataOut1[7:2] == tag) & MetaDataOut1[1]) ? 1'b1 : 1'b0;
assign hit2 = ((MetaDataOut2[7:2] == tag) & MetaDataOut2[1]) ? 1'b1 : 1'b0;
assign miss = ~(hit1 | hit2);

//README: The below logic does not include missing
assign CacheOut = miss ? 16'h0000: (hit1 ? DataOut1 : DataOut2);

// Changing the LRU bit
assign MetaDataIn1 = hit1 ? {MetaDataIn1[7:1],1'b0} : (hit2 ? {MetaDataIn1[7:1],1'b1} : ((MetaDataOut1[0] | ~MetaDataOut1[1]) ?  {tag,2'b10} :  {MetaDataIn1[7:1],1'b1}));
assign MetaDataIn2 = hit2 ? {MetaDataIn2[7:1],1'b0} : (hit1 ? {MetaDataIn2[7:1],1'b1} : (MetaDataOut2[0] ?  {tag, 1'b1, 1'b0} :  {MetaDataIn2[7:1],1'b1}));

// Look in MetaDataArray to see if tag is stored
// TAG is MetaDataOut [8:2], valid is [1], LRU is [0]
// README: miss is based on the results of mda1 and mda2 so how are we using miss for Write? --> Make sure to reset first
MetaDataArray mda1(.clk(clk), .rst(rst), .DataIn(MetaDataInF1), .Write(ff_hit1 | ff_hit2 | data_rdy), .BlockEnable(BlockEnable1), .DataOut(MetaDataOut1));
MetaDataArray mda2(.clk(clk), .rst(rst), .DataIn(MetaDataInF2), .Write(ff_hit1 | ff_hit2 | data_rdy), .BlockEnable(BlockEnable1), .DataOut(MetaDataOut2));

assign MetaDataInF1 = data_rdy ? MetaDataIn1 : ff_MetaDataIn1;
assign MetaDataInF2 = data_rdy ? MetaDataIn2 : ff_MetaDataIn2;

dff mdi1 [7:0] (.q(ff_MetaDataIn1), .d(MetaDataIn1), .wen('1), .clk(clk), .rst(rst));
dff mdi2 [7:0] (.q(ff_MetaDataIn2), .d(MetaDataIn2), .wen('1), .clk(clk), .rst(rst));
dff mdo1 [7:0] (.q(ff_MetaDataOut1), .d(MetaDataOut1), .wen('1), .clk(clk), .rst(rst));
dff mdo2 [7:0] (.q(ff_MetaDataOut2), .d(MetaDataOut2), .wen('1), .clk(clk), .rst(rst));
dff ffhit1 [7:0] (.q(ff_hit1), .d(hit1), .wen('1), .clk(clk), .rst(rst));
dff ffhit2 [7:0] (.q(ff_hit2), .d(hit2), .wen('1), .clk(clk), .rst(rst));

//Data Arrays for data
DataArray da1(.clk(clk), .rst(rst), .DataIn(DataIn), .Write((write & hit1) | (data_rdy & (ff_MetaDataOut1[0] | ~ff_MetaDataOut1[1]))), .BlockEnable(BlockEnable1),.WordEnable(WordEnable1) ,.DataOut(DataOut1));
DataArray da2(.clk(clk), .rst(rst), .DataIn(DataIn), .Write((write & hit2) | (data_rdy & ff_MetaDataOut2[0])), .BlockEnable(BlockEnable1),.WordEnable(WordEnable1) ,.DataOut(DataOut2));
endmodule


module BlockShifter (Shift_Out, Shift_In, Shift_Val);
input [127:0] Shift_In; 	// This is the input data to perform shift operation on
input [6:0] Shift_Val; 	// Shift amount (used to shift the input data)
output [127:0] Shift_Out; 	// Shifted output data

wire [127:0] shift6, shift5, shift3;

	assign shift6 = Shift_Val[6] ? Shift_In << 64 : Shift_In;
	assign shift5 = Shift_Val[5] ? (Shift_Val[4] ? shift6 << 48 : shift6 << 32) : (Shift_Val[4] ? shift6 << 16 : shift6);
	assign shift3 = Shift_Val[3] ? (Shift_Val[2] ? shift5 << 12 : shift5 << 8) : (Shift_Val[2] ? shift5 << 4 : shift5);
	assign Shift_Out = Shift_Val[1] ? (Shift_Val[0] ? shift3 << 3 : shift3 << 2) : (Shift_Val[0] ? shift3 << 1 : shift3);
	
endmodule


module WordShifter (Shift_Out, Shift_In, Shift_Val);
input [7:0] Shift_In; 	// This is the input data to perform shift operation on
input [2:0] Shift_Val; 	// Shift amount (used to shift the input data)
output [7:0] Shift_Out; 	// Shifted output data

wire [15:0] shift8;

assign shift8 = Shift_Val[2] ? Shift_In << 4 : Shift_In << 0;
assign Shift_Out = Shift_Val[1] ? (Shift_Val[0] ? shift8 << 3 : shift8 << 2) : (Shift_Val[0] ? shift8 << 1 : shift8 << 0);
	
	
endmodule
