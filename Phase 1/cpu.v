module cpu (output hlt, output [15:0] pc, input clk, input rst_n);
	// PC wires
	wire [15:0] current_instruction, next_instruction, stored_instruction, PC_intermediate;  //load_store_immediate 
	
	//Register file wires
	wire [15:0] reg_1_data,reg_2_data,write_reg_data;
	wire [3:0] R_or_load, write_register,first_reg_value;
	
	//ALU wires
	wire [15:0] ALU_result, load_store_immediate, load_byte_immediate, first_ALU_value, second_ALU_value; //not reg_1_data is also a signal into the ALU
	wire [2:0] iflags;

	//Data Memory Wires
	wire [15:0] data_memory_out;
	
	//Top level control_logic
	wire [1:0] Branch;
	wire RegDst, MemtoReg, MemWrite, ALU_Src, RegWrite, Halt, PCS, LoadByte;

	assign pc = stored_instruction;
	assign hlt = Halt;			
	//Instructions follow the sequence: OPCODE, RD (destination), and then (RT and RS) or Immediate value 
	//Watch out for the load lower and upper load

	//Instruction Memory
	memory1c Instr_mem(.data_out(current_instruction), .data_in('0), .addr(stored_instruction), .enable('1), .wr('0), .clk(clk), .rst(~rst_n));	
	//PC controls
	assign PC_intermediate = (Branch[0]) ? {{7{current_instruction[8]}},current_instruction[8:0]} : reg_1_data;
	PC_control pc_cntrl (.C(current_instruction[11:9]), .I(PC_intermediate), .branch(Branch), .F(iflags), .PC_in(stored_instruction), .PC_out(next_instruction));	
	dff stored_pc [15:0] (.q(stored_instruction),.d(next_instruction), .wen(~Halt), .clk(clk), .rst(~rst_n));
	
	//Data Memory
	memory1c Data_mem(.data_out(data_memory_out), .data_in(reg_2_data), .addr(ALU_result), .enable('1), .wr(MemWrite), .clk(clk), .rst(~rst_n));
					
					
	//Register File
	assign R_or_load = MemWrite ? current_instruction[11:8] : current_instruction[3:0];
	assign write_reg_data = MemtoReg ? (data_memory_out) : ALU_result;
	assign write_register = current_instruction[11:8];
	assign first_reg_value = LoadByte ? current_instruction[11:8] : current_instruction[7:4];
	//FIXME for later
	RegisterFile Registers (.clk(clk),.rst(~rst_n),.SrcReg1(first_reg_value),.SrcReg2(R_or_load),.DstReg(write_register),.WriteReg(RegWrite),.DstData(write_reg_data),.SrcData1(reg_1_data),.SrcData2(reg_2_data));

	//Top Level Control signals
	control_logic controls (.Instr(current_instruction[15:12]), .Branch(Branch), .RegDst(RegDst),.MemtoReg(MemtoReg),. MemWrite(MemWrite),.ALUSrc(ALU_Src),.RegWrite(RegWrite),.Halt(Halt),.PCS(PCS), .LoadByte(LoadByte));
	
		
	//ALU
	assign load_store_immediate = {{12{current_instruction[3]}},current_instruction[3:0]};
	assign load_byte_immediate = {8'h00,current_instruction[7:0]};
	assign second_ALU_value = ALU_Src ? (LoadByte ? load_byte_immediate : load_store_immediate) : reg_2_data; 
	assign first_ALU_value = PCS ? stored_instruction : reg_1_data; //This is a hack to see if the instruction is PCS
	ALU i_alu (.ALU_Out(ALU_result), .flags(iflags) ,.opcode(current_instruction[15:12]), .operand1(first_ALU_value),.operand2(second_ALU_value), .clk(clk), .rst(~rst_n));
	
endmodule
