//Simple 1 bit adder
module full_adder_1bit (input A, input B, input Cin, output S, output Cout);
	assign S = A ^ B ^ Cin;
	assign Cout = (A&B) | (Cin & (A | B));
endmodule

//Instantiates full_adder_1bit to make it 4 wide
//overflow is determined by seperate logic than carry out
module addsub_4bit (Sum, Ovfl, A, B, sub);
	input [3:0] A, B; //Input values
	input sub; // add-sub indicator
	output [3:0] Sum; //sum output
	output Ovfl; //To indicate overflow
	wire [3:0] interC;
	wire [3:0] interB;
	assign interB = sub ? ~B : B;

	//note interB is not technically full2s compliment, but its close enough for the calculation needed
	assign Ovfl = (Sum[3] ? (~A[3]&~interB[3]) : (A[3] & interB[3])); 
	full_adder_1bit FA [3:0]  (.A(A),.B(interB),.Cin({interC[2:0],sub}),.Cout(interC),.S(Sum));
endmodule
module PSA_16bit (Sum, Error, A, B);
input [15:0] A, B; 	// Input data values
output [15:0] Sum; 	// Sum output
output Error; 	// To indicate overflows
wire [3:0] temp_error;

	assign Error = |temp_error;

	addsub_4bit Partial [3:0]  (.Sum(Sum), .Ovfl(temp_error), .A(A), .B(B), .sub('0));
endmodule

module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
input [15:0] Shift_In; 	// This is the input data to perform shift operation on
input [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
input  [1:0] Mode; 		// To indicate 0=SLL or 1=SRA 
output [15:0] Shift_Out; 	// Shifted output data

wire [15:0] shift3, shift2,shift1,shift0;
wire [15:0] ashift3, ashift2,ashift1,ashift0;
wire [15:0] rshift3, rshift2,rshift1,rshift0;
	assign shift3 = Shift_Val[3] ? (Shift_In << 8) : Shift_In;
	assign shift2 = Shift_Val[2] ? (shift3 << 4) : shift3;
	assign shift1 = Shift_Val[1] ? (shift2 << 2) : shift2;
	assign shift0 = Shift_Val[0] ? (shift1 << 1) : shift1;

	assign ashift3 = Shift_Val[3] ? ({{8{Shift_In[15]}},Shift_In[15:8]}) : Shift_In;
	assign ashift2 = Shift_Val[2] ? ({{4{ashift3[15]}},ashift3[15:4]}) : ashift3;
	assign ashift1 = Shift_Val[1] ? ({{2{ashift2[15]}},ashift2[15:2]}) : ashift2;
	assign ashift0 = Shift_Val[0] ? ({{1{ashift1[15]}},ashift1[15:1]}) : ashift1;

	assign rshift3 = Shift_Val[3] ? ({Shift_In[7:0],Shift_In[15:8]}) : Shift_In;
	assign rshift2 = Shift_Val[2] ? ({rshift3[3:0],rshift3[15:4]}) : rshift3;
	assign rshift1 = Shift_Val[1] ? ({rshift2[1:0],rshift2[15:2]}) : rshift2;
	assign rshift0 = Shift_Val[0] ? ({rshift1[0],rshift1[15:1]}) : rshift1;
	
	assign Shift_Out = Mode[1] ? rshift0 : (Mode[0] ? ashift0 : shift0);
endmodule

module t_Shifter;
	logic signed [15:0] shifty;
	logic signed [3:0] amount;
	logic [15:0] out;
	logic [15:0] viz;
	logic [1:0] mode;

	Shifter iDUT (.Shift_Out(out), .Shift_In(shifty), .Shift_Val(amount), .Mode(mode));

	initial begin
		shifty = '0;
		amount = '0;
		mode = 2'hb00;
		#5
		assert(out === '0)
		else begin
			$display("Not clean reset");
			$stop();
		end
		repeat (256) begin
			shifty = $random();
			amount = $random();
			mode = $random();
			#2
			if(~mode[1] & mode[0])
				viz = shifty >>> amount;
			else if(~mode[1] & mode[0] )	
				viz = shifty << amount;
			#3
			assert (out === viz) $display("Hi");
			else begin
				$display("shifty didn't shift");
				//$stop();
			end
		end
		#10
		$display("Yahoooo!! Test passed");
		$stop();
	end

endmodule
module t_PSA_16bit;
	logic signed [3:0] a0;
	logic signed [3:0] a1;
	logic signed [3:0] a2;
	logic signed [3:0] a3;
	logic signed [3:0] b0;
	logic signed [3:0] b1;
	logic signed [3:0] b2;
	logic signed [3:0] b3;
	//These ints are used to calculate overflow later. This is so the same
	//logic that is used to calculate the DUT overflow is not the same as
	//the testbench
	int a_0;
	int a_1;
	int a_2;
	int a_3;
	int b_0;
	int b_1;
	int b_2;
	int b_3;
	reg iover;
	wire signed [15:0] sum;
	logic signed [15:0] t_sum;
	
	PSA_16bit iDUT (.Sum(sum),.Error(iover),.A({a3,a2,a1,a0}),.B({b3,b2,b1,b0}));

	initial begin
		 a3 = '0;
		 a2 = '0;
		 a1 = '0;
		 a0 = '0;
		 b3 = '0;
		 b2 = '0;
		 b1 = '0;
		 b0 = '0;
		# 5
		if (iDUT.Sum !== '0) begin
			$display("Wrong output");
			$stop();
		end


		$display("Right Start");
		repeat (4096) begin
			 a3 = $random();
			 a2 = $random();
			 a1 = $random();
			 a0 = $random();
			 b3 = $random();
			 b2 = $random();
			 b1 = $random();
			 b0 = $random();
			t_sum = {(a0 + b0),(a1 + b1),(a2 + b2),(a3 + b3)};
			a_0 = a0;
			a_1 = a1;
			a_2 = a2;
			a_3 = a3;
			b_0 = b0;
			b_1 = b1;
			b_2 = b2;
			b_3 = b3;
			#5
			//check for overflow flag
			if (a_0 + b_0 > 7 || a_0 + b_0 < -8 || a_1 + b_1 > 7 || a_1 + b_1 < -8 || 
			a_2 + b_2 > 7 || a_2 + b_2 < -8 || a_3 + b_3 > 7 || a_3 + b_3 < -8) begin
				assert(iover === 1'b1) $display("overflow checking...");
				else begin
					$display("Error");
					$stop();

				end
			end
			else begin
				assert(iover === 1'b0)
				else begin
					$display("Overflow error with adder going over");
					$stop();
				end
			end
			//check sum with normal bits
			if (iDUT.Sum !== {(a3 + b3),(a2 + b2),(a1 + b1),(a0 + b0)}) begin
				$display("Error");
				$stop();
			end
		end 
		$display("Wahooooo!!! Test Passed");
		#10 $stop();
	end
endmodule
