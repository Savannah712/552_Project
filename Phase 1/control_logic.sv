			//this determines if the alu gets imm or reg
module control_logic(input [3:0]Instr, output reg RegDst, output reg [1:0] Branch, output reg MemtoReg, output reg MemWrite, output reg ALUSrc, output reg RegWrite, output reg Halt, output reg PCS, output reg LoadByte);
		reg error;
		
	always @Instr begin
		PCS = '0;
		error = '0;
		RegDst = '0;
		Branch = '0;
		MemtoReg = '0;
		MemWrite = '0;
		ALUSrc = '0;
		RegWrite = '0;
		Halt = '0;
		LoadByte = '0;

	case(Instr)
		//Arithmetic/Logic Instructions

		(4'b0000): begin //Add
			RegDst = '1;
			RegWrite = '1;
			end

		(4'b0001): begin //Sub
			RegDst = '1;
			RegWrite = '1;
			end

		(4'b0010): begin //XOR
			RegDst = '1;
			RegWrite = '1;
			end

		(4'b0011): begin //RED
			RegDst = '1;
			RegWrite = '1;
			end

		(4'b0100): begin //SLL
			RegDst = '1;
			ALUSrc = '1;
			RegWrite = '1;
			end

		(4'b0101): begin //SRA
			RegDst = '1;
			ALUSrc = '1;
			RegWrite = '1;
			end

		(4'b0110): begin //ROR
			RegDst = '1;
			ALUSrc = '1;
			RegWrite = '1;
			end

		(4'b0111): begin //PADDSB
			RegDst = '1;
			RegWrite = '1;
			end

		//Memory Instructions

		(4'b1000): begin //LW
			MemtoReg = '1;
			ALUSrc = '1;
			RegWrite = '1;
			end

		(4'b1001): begin //SW
			ALUSrc = '1;
			MemWrite = '1;
			end

		(4'b1010): begin //LLB
			ALUSrc = '1;
			RegWrite = '1;
			LoadByte = '1;
			end

		(4'b1011): begin //LHB
			ALUSrc = '1;
			RegWrite = '1;
			LoadByte = '1;
			end

		//Control Instructions

		(4'b1100): begin //B	
			Branch[0] = '1;
			Branch[1] = '1;
			end

		(4'b1101): begin //BR	
			Branch[0] = '0;
			Branch[1] = '1;
			end

		(4'b1110): begin //PCS	
			PCS = '1;
			ALUSrc = '1;
			RegWrite = '1;
			end

		(4'b1111): begin //HLT	
			Halt = '1;
			end

		default:
			error = 1'b1;
		endcase
	end
	
endmodule 
