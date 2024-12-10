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

//Test bench fo 4 bit adder
`timescale 1ns/100ps
module t_addsub_4bit;
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
	
	addsub_4bit iDUT (.Sum(sum),.Ovfl(iover),.A(a),.B(b),.sub(sub));

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
module ALU (ALU_Out, Error, ALU_In1, ALU_In2, Opcode);
input [3:0] ALU_In1, ALU_In2;
input [1:0] Opcode; 
output reg [3:0] ALU_Out;
output reg Error; // Just to show overflow
wire [3:0] sum;
wire ovfl;
reg flag;

	addsub_4bit Adder (.Sum(sum),.Ovfl(ovfl),.A(ALU_In1),.B(ALU_In2),.sub(Opcode[0]));
	always @ (Opcode, ALU_In1, ALU_In2) begin
		case (Opcode)
		2'b10 :
		begin	ALU_Out = ~(ALU_In1 & ALU_In2);
			Error = 0'b0;
			flag = 0'b0;
		end
		2'b11 :
		begin	ALU_Out = ALU_In1 ^ ALU_In2;
			Error = 0'b0;
			flag = 0'b0;
		end
		2'b00:
		begin	ALU_Out = sum;
			Error = ovfl;
			flag = 0'b0;
		end
		2'b01:
		begin	ALU_Out = sum;
			Error = ovfl;
			flag = 0'b0;
		end
		//This case should never be reached. If it is, testbench
		//should throw and error
		default:
			flag = 1'b1;
		endcase
	end

endmodule

