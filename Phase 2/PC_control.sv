module PC_control(input [2:0]C, input [15:0] I, input [2:0] F, input [1:0] branch, input [15:0] PC_in,input stall, input clk, input rst_n, output [15:0] Branch_PC_out, output [15:0] PC_plus_2, output flush, output reg branch_taken);
	//Overflow is [2], Negative[1], Zero[0]	
	reg [15:0] calculated_pc, IFID_normal_pc, normal_pc, inter_PC_out;
	reg [15:0] inter_op2, inter_op1;
	//wire [15:0] PC_plus_2;
	//When branch [0] == 1, we are doing the B instruction. When branch [0] == 0, we are doing the BR (Branch Register) instruction 
	// branch = x0: I<<1, branch = x1: rs
	assign inter_op2 = ~branch[0]? I : (I << 4'h1);
	// branch = x0: normal_pc, branch = x1: 0 to jump to rs
	assign inter_op1 = ~branch[0]? '0 : IFID_normal_pc;
	assign PC_plus_2 = normal_pc;
	
	//reset low
	dff IFID_flop [15:0] (.q(IFID_normal_pc), .d(normal_pc), .wen(~stall), .clk(clk), .rst(~rst_n));
	
	addsub_16bit normal (.Sum(normal_pc),.Error(), .A(PC_in),. B(16'h0002),.sub('0),.pad('0));
	
	addsub_16bit immediate (.Sum(calculated_pc),.Error(), .A(inter_op1),. B(inter_op2),.sub('0),.pad('0));
	
	// If branch instruction, take the pc decided, else go to next pc address
	// branch = 1x: branch instruction, branch = 0x: not a branch instruction
	assign Branch_PC_out = (branch[1]) ? inter_PC_out : IFID_normal_pc;
	assign flush = branch_taken; 


	//Watch out for the reset
	reg error;
	always @ (C,I,F,branch) begin
	error = 1'b0;
	//Overflow is [2], Negative[1], Zero[0]
		case(C) 
			3'b000: begin //Not Equal 
				inter_PC_out = ~F[0] ? calculated_pc : IFID_normal_pc; 	
				branch_taken = ~F[0] && branch[1] ? 1'b1 : 1'b0;
				end
			3'b001: begin //Equal
				inter_PC_out = F[0] ? calculated_pc : IFID_normal_pc; 	
				branch_taken = F[0] && branch[1] ? 1'b1 : 1'b0;
				end
			3'b010: begin //Greater Than
				inter_PC_out = (~F[0] & ~F[1]) ? calculated_pc : IFID_normal_pc;	 	
				branch_taken = (~F[0] & ~F[1]) && branch[1] ? 1'b1 : 1'b0;
				end
			3'b011: begin //Less Than
				inter_PC_out = F[1] ? calculated_pc : IFID_normal_pc; 	
				branch_taken = F[1] && branch[1] ? 1'b1 : 1'b0;
				end
			3'b100: begin //Greater Than or Equal
				inter_PC_out = (F[0] | (~F[0] & ~F[1])) ? calculated_pc : IFID_normal_pc;	 	
				branch_taken = (F[0] | (~F[0] & ~F[1])) && branch[1]? 1'b1 : 1'b0; 
				end
			3'b101: begin //Less Than or Equal
				inter_PC_out = (F[0] | F[1]) ? calculated_pc : IFID_normal_pc;	 	
				branch_taken = (F[0] | F[1]) && branch[1] ? 1'b1 : 1'b0; 
				end		
			3'b110: begin //Overflow
				inter_PC_out = (F[2]) ? calculated_pc : IFID_normal_pc;	 	
				branch_taken = (F[2]) && branch[1]? 1'b1 : 1'b0; 
				end
			3'b111: begin //Unconditional
				inter_PC_out = calculated_pc; 	
				branch_taken = branch[1];
				end
			default:
				error = 1'b1;
		endcase
	end
endmodule

module t_PC_control ();
	logic [2:0] iC;
	logic signed [8:0] iI;
	logic [2:0] iF;
	logic [15:0] iPC_in, iPC_out;
	PC_control iDUT (.C(iC), .I(iI), .F(iF), .PC_in(iPC_in), .PC_out(iPC_out));

	initial begin
		iC = '0;
		iF = '0;
		iI ='0;
		iPC_in = '0;
		#5;
	end
endmodule
