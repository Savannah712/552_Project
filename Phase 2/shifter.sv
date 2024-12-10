module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
input [15:0] Shift_In; 	// This is the input data to perform shift operation on
input [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
input  [1:0] Mode; 		// To indicate 00=SLL or 01=SRA or 1x = ROR 
output [15:0] Shift_Out; 	// Shifted output data

wire [15:0] shift3, shift2,shift1,shift0;
wire [15:0] ashift3, ashift2,ashift1,ashift0;
wire [15:0] rshift3, rshift2,rshift1,rshift0;

	assign shift3 = Shift_Val[3] ? (Shift_Val[2] ? Shift_In << 12 : Shift_In <<8) : (Shift_Val[2] ? Shift_In << 4 : Shift_In << 0);
	assign shift0 = Shift_Val[1] ? (Shift_Val[0] ? shift3 << 3 : shift3 <<2) : (Shift_Val[0] ? shift3 << 1 : shift3 << 0);
	

	assign ashift3 = Shift_Val[3] ? (Shift_Val[2] ? {{12{Shift_In[15]}},Shift_In[15:12]} : {{8{Shift_In[15]}},Shift_In[15:8]}) 
									: (Shift_Val[2] ? {{4{Shift_In[15]}},Shift_In[15:4]} : Shift_In);
				
	assign ashift0 = Shift_Val[1] ? (Shift_Val[0] ? {{3{ashift3[15]}},ashift3[15:3]} : {{2{ashift3[15]}},ashift3[15:2]}) 
									: (Shift_Val[0] ? {{1{ashift3[15]}},ashift3[15:1]} : ashift3);
									
	assign rshift3 = Shift_Val[3] ? (Shift_Val[2] ? {Shift_In[11:0],Shift_In[15:12]} : {Shift_In[7:0],Shift_In[15:8]}) 
									: (Shift_Val[2] ? {Shift_In[3:0],Shift_In[15:4]} : Shift_In);
									
	assign rshift0 = Shift_Val[1] ? (Shift_Val[0] ? {rshift3[2:0],rshift3[15:3]} : {rshift3[1:0],rshift3[15:2]}) 
									: (Shift_Val[0] ? {rshift3[0],rshift3[15:1]} : rshift3);
									
	
	assign Shift_Out = Mode[1] ? rshift0 : (Mode[0] ? ashift0 : shift0);
endmodule
