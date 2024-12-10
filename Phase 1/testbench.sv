module t_RED();
logic signed [15:0] rs, rt;
logic [15:0] Sum;

RED redDUT (.rs(rs), .rt(rt), .Sum(Sum));

initial begin
	rs = 16'h1111;
	rt = 16'h1111;
	#5
	if(Sum != 16'h2222) begin	
		$display("Sum is %h, when it should be %h", Sum, 16'h2222);
		$stop();
	end
	#5;
end
endmodule

module saturate_tb();
logic signed [15:0] A,B;
logic [15:0] Sum; //sum output
logic Ovfl; //To indicate overflow
logic pad;
logic isub;

addsub_16bit DUT (.Sum(Sum), .Error(Ovfl), .A(A), .B(B), .sub(isub), .pad(pad));

initial begin
	pad = '1;
	isub = '0;
	A = 16'h8009;
	B = 16'h9009;
	#5
	if(Sum != 16'h8008) begin
		$display("Sum is %h, when it should be %h", Sum, 16'h8008);
		$stop();
	end
	if(!Ovfl) begin
		$display("Should be negative overflow");
		$stop();
	end
	#5
	A = 16'h0FD8;
	B = 16'h0019;
	#5
	if(Sum != 16'h0FE8) begin
		$display("Sum is %h, when it should be %h", Sum, 16'h0FEF);
		$stop();
	end
	if(!Ovfl) begin
		$display("Should be positive overflow");
		$stop();
	end
	#5
	pad = !pad;
	A = 16'h8800;
	B = 16'h8901;
	#5
	if(Sum != 16'h8000) begin
		$display("Sum is %h, when it should be %h", Sum, 16'h8000);
		$stop();
	end
	if(!Ovfl) begin
		$display("Should be negative overflow");
		$stop();
	end
	#5
	A = 16'h7FFF;
	B = 16'h0001;
	#5
	if(Sum != 16'h7FFF) begin
		$display("Sum is %h, when it should be %h", Sum, 16'h7FFF);
		$stop();
	end
	if(!Ovfl) begin
		$display("Should be positive overflow");
		$stop();
	end
	repeat (8) begin
	pad = '0;
	isub = '1;
	A = $random();
	B = $random();
	#5;
	
	end
	repeat (8) begin
	pad = '0;
	isub = '0;
	A = $random();
	B = $random();
	#5;
	
	end
	#10
		$display("Yahoooo!! Test passed");
		$stop();
		
end
endmodule

//Test bench fo 4 bit adder
`timescale 1ns/100ps
module t_carry_look_ahead;
	logic signed [3:0] a;
	logic signed  [3:0] b;
	//These ints are used to calculate overflow later. This is so the same
	//logic that is used to calculate the DUT overflow is not the same as
	//the testbench
	int a_in;
	int b_in;
	reg sub;
	reg iover;
	wire signed [3:0] sum;
	
	carry_look_ahead iDUT (.Sum(sum),.Ovfl(iover),.A(a),.B(b),.sub(sub));

	initial begin
		 a = '0;
		 b = '0;
		 sub = 0;
		# 5
		if (iDUT.Sum !== '0) begin
			$display("Wrong output");
			$stop();
		end
		$display("Right Start");
		repeat (128) begin
			a = $random();
			b = $random();
			sub = $random();
			a_in = a;
			b_in = b;
			#5
			if (!sub) begin
				//check for overflow flag
				if (a_in + b_in > 7 || a_in + b_in < -8) begin
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
				if (iDUT.Sum !== a + b) begin
					$display("Error");
					$stop();
				end
			end else begin
				if (a_in - b_in < -8 || a_in - b_in  > 7) begin
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
				if (iDUT.Sum !== a - b) begin
					$display("Error");
					$stop();
				end
			end
		end
		$display("Wahooooo!!! Test Passed");
		#10 $stop();
	end

endmodule
module t_ALU;
	logic signed [3:0] a;
	logic signed  [3:0] b;
	logic [1:0] iOp;
	int a_in;
	int b_in;
	reg iover;
	wire signed [3:0] out;
	
	ALU iDUT (.ALU_Out(out), .Error(iover), .ALU_In1(a), .ALU_In2(b), .Opcode(iOp));

	//The default case statement should never go high; this always
	//statements outside of the initial statement keeps tabs on that
	always @ (posedge iDUT.flag) begin
		$display("ERROR! opcode mux reached default statement %d", iDUT.flag );
		$stop();
	end

	initial begin
		 a = '0;
		 b = '0;
		 iOp = '0;
		$display("Hello!");
		#5
		if (out !== '0) begin
			$display("Wrong output");
			$stop();
		end

		$display("Right Start");
		repeat (256) begin
			a = $random();
			b = $random();
			iOp = $random();
			a_in = a;
			b_in = b;
			#5

			assert(iDUT.flag !== 1) 
			else begin
				$display("ERROR! opcode mux reached default statement %d", iDUT.flag );
				$stop();
			end
			//The upper bit of opcode determines add or sub
			if (iOp[1] == 0) begin 
				if (!iOp[0]) begin
					if (a_in + b_in > 7) begin
						assert(iover === 1'b1) $display("overflow check");
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
					if (out !== a + b) begin
						$display("Error");
						$stop();
					end
				end 
				else begin
					if (a_in - b_in < -8) begin
						assert(iover === 1'b1) $display("overflow check");
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
					if (out !== a - b) begin
						$display("Error");
						$stop();
					end
				end
			end 
			//lower opcode bit checks the NAND and XOR
			else begin
				//There cannot be an overflow error in logical
				//operations
				assert(iover === 1'b0)
				else begin
					$display("Error");
					$stop();
				end
				if (iOp[0] === 0) begin
					assert( out === ~(a & b))
					else begin
						$display("Error");
						$stop();
					end
				end
				else begin
					assert( out === a ^ b)
					else begin
						$display("Error");
						$stop();
					end
				end
			end
		end
		$display("Yahooooo!!! Test Passed");
		#10 $stop();
	end

endmodule
