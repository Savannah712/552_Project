module PC_control(input [2:0]C, input [15:0] I, input [2:0] F, input [1:0] branch, input [15:0] PC_in, output [15:0] PC_out);
	//Overflow is [2], Negative[1], Zero[0]	
	reg [15:0] calculated_pc,normal_pc, inter_PC_out;
	reg [15:0] inter_op2, inter_op1;
	//When branch [0] == 1, we are doing the B instruction. When branch [0] == 0, we are doing the BR (Branch Register) instruction 
	// branch = x0: I<<1, branch = x1: rs
	assign inter_op2 = (~branch[0])? I : (I << 4'h1);
	// branch = x0: normal_pc, branch = x1: 0 to jump to rs
	assign inter_op1 = (~branch[0])? '0 : normal_pc;
	
	addsub_16bit normal (.Sum(normal_pc),.Error(), .A(PC_in),. B(16'h0002),.sub('0),.pad('0));
	addsub_16bit immediate (.Sum(calculated_pc),.Error(), .A(inter_op1),. B(inter_op2),.sub('0),.pad('0));
	
	// If branch instruction, take the pc decided, else go to next pc address
	// branch = 1x: branch instruction, branch = 0x: not a branch instruction
	assign PC_out = (branch[1])? inter_PC_out : normal_pc;

	//Watch out for the reset
	reg error;
	always @ (C,I,F) begin
	error = 1'b0;
	//Overflow is [2], Negative[1], Zero[0]
		case(C) 
			3'b000: //Not Equal
				inter_PC_out = ~F[0] ? calculated_pc : normal_pc; 	
			3'b001: //Equal
				inter_PC_out = F[0] ? calculated_pc : normal_pc;
			3'b010: //Greater Than
				inter_PC_out = (~F[0] & ~F[1]) ? calculated_pc : normal_pc;	
			3'b011: //Less Than
				inter_PC_out = F[1] ? calculated_pc : normal_pc;
			3'b100: //Greater Than or Equal
				inter_PC_out = (F[0] | (~F[0] & ~F[1])) ? calculated_pc : normal_pc;	
			3'b101: //Less Than or Equal
				inter_PC_out = (F[0] | F[1]) ? calculated_pc : normal_pc;			
			3'b110: //Overflow
				inter_PC_out = (F[2]) ? calculated_pc : normal_pc;	
			3'b111: //Unconditional
				inter_PC_out = calculated_pc;
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
