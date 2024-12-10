module cpu (output hlt, output [15:0] pc, input clk, input rst_n);
	// PC wires
	wire branch_taken;
	wire [15:0] current_instruction, next_instruction, stored_instruction, PC_intermediate, branch_addr, pc_plus2_addr;  //load_store_immediate 
	
	//Register file wires
	wire [15:0] reg_1_data,reg_2_data,write_reg_data;
	wire [3:0] SrcReg2, write_register, SrcReg1;
	
	//ALU wires
	wire [15:0] ALU_result, load_store_immediate, load_byte_immediate, first_ALU_value, second_ALU_value; //not reg_1_data is also a signal into the ALU
	wire [2:0] iflags,iflag_enable;

	//Data Memory Wires
	wire [15:0] data_memory_out;
	
	//Top level control_logic
	wire [1:0] Branch;
	wire MemtoReg, MemWrite, MemRead, ALU_Src, RegWrite, Halt, PCS, LoadByte;

	//IFID Signals
	wire [15:0] IFID_current_instruction, IFID_stored_instruction;
	
	// ID/EX Signals
	wire IDEX_MemtoReg, IDEX_MemWrite, IDEX_MemRead, IDEX_ALU_Src, IDEX_RegWrite, IDEX_LoadByte,IDEX_Halt, IDEX_PCS;
	wire [2:0] IDEX_iflag_enable;
	wire [3:0] IDEX_write_register, IDEX_SrcReg1, IDEX_SrcReg2;
	wire [15:0] IDEX_reg_2_data, IDEX_reg_1_data, IDEX_current_instruction,IDEX_stored_instruction;
	
	// Forwarding to ex signal
	wire [15:0] EX_RegData1, EX_RegData2;

	// EX/MEM Signals
	wire EXMEM_MemtoReg, EXMEM_MemWrite, EXMEM_MemRead, EXMEM_RegWrite,EXMEM_Halt;
	wire [3:0] EXMEM_write_register, EXMEM_SrcReg1, EXMEM_SrcReg2;
	wire [15:0] EXMEM_ALU_result, EXMEM_reg_2_data, EXMEM_reg_1_data, EXMEM_current_instruction;
	
	// Forwarding to mem signal
	wire [15:0] MEM_RegData2;

	// MEM/WB Signals
	wire MEMWB_MemtoReg, MEMWB_RegWrite, MEMWB_MemRead, MEMWB_Halt;
	wire [3:0] MEMWB_write_register, MEMWB_SrcReg1, MEMWB_SrcReg2;
	wire [15:0] MEMWB_ALU_result, MEMWB_data_memory_out, MEMWB_reg_2_data, MEMWB_current_instruction;
	
	//Hazard detection wires
	wire EE_SrcOut1, EE_SrcOut2, ME_SrcOut1, ME_SrcOut2, MM_SrcOut2;

	// Stall wire
	wire stall;
	
	//Flush wire
	wire flush;

	assign pc = stored_instruction;
	assign hlt = MEMWB_Halt;			
	//Instructions follow the sequence: OPCODE, RD (destination), and then (RT and RS) or Immediate value 
	//Watch out for the load lower and upper load

	//Instruction Memory
	assign next_instruction = branch_taken ? branch_addr : pc_plus2_addr;
	memory1c Instr_mem(.data_out(current_instruction), .data_in('0), .addr(stored_instruction), .enable('1), .wr('0), .clk(clk), .rst(~rst_n));	
	//PC controls
	assign PC_intermediate = (Branch[0]) ? {{7{IFID_current_instruction[8]}},IFID_current_instruction[8:0]} : reg_1_data;
	PC_control pc_cntrl (.C(IFID_current_instruction[11:9]), .I(PC_intermediate), .branch(Branch),.stall(stall), .F(iflags), .clk(clk),.rst_n(rst_n), .PC_in(stored_instruction), .Branch_PC_out(branch_addr),.PC_plus_2(pc_plus2_addr) ,.flush(flush) ,.branch_taken(branch_taken));
	
	dff stored_pc [15:0] (.q(stored_instruction),.d(next_instruction), .wen(~Halt), .clk(clk), .rst(~rst_n));
	
	//Data Memory hmmmm memwrite or mem read
	memory1c Data_mem(.data_out(data_memory_out), .data_in(MEM_RegData2), .addr(EXMEM_ALU_result), .enable('1), .wr(EXMEM_MemWrite), .clk(clk), .rst(~rst_n));		
					
	//Register File
	assign SrcReg2 = MemWrite ? IFID_current_instruction[11:8] : IFID_current_instruction[3:0];
	assign write_reg_data = MEMWB_MemRead ? (MEMWB_data_memory_out) : MEMWB_ALU_result;
	assign write_register = IFID_current_instruction[11:8];
	assign SrcReg1 = LoadByte ? IFID_current_instruction[11:8] : IFID_current_instruction[7:4];
	//FIXME for later
	RegisterFile Register (.clk(clk),.rst(~rst_n),.SrcReg1(SrcReg1),.SrcReg2(SrcReg2),.DstReg(MEMWB_write_register),.WriteReg(MEMWB_RegWrite),.DstData(write_reg_data),.SrcData1(reg_1_data),.SrcData2(reg_2_data));
	
	// Stall (flag enable from ALU needed)
	stall_logic SL (.stall(stall), .MemtoReg(IDEX_MemtoReg), .write_register(IDEX_write_register), .SrcReg1(SrcReg1), .SrcReg2(SrcReg2), .flag_enable(|iflag_enable), .Branch(|Branch), .MemWrite(MemWrite), .clk(clk), .rst_n(rst_n));

	// Flipflops for Signals
	// IF/ID
	dff IFID_instruction [15:0] (.q(IFID_current_instruction), .d(current_instruction), .wen(~stall), .clk(clk), .rst((~rst_n)| flush));
	dff IFID_s_instruction [15:0] (.q(IFID_stored_instruction), .d(stored_instruction), .wen(~stall), .clk(clk), .rst((~rst_n)));	

	// ID/EX
	dff MR1 (.q(IDEX_MemtoReg), .d(MemtoReg), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff MW1 (.q(IDEX_MemWrite), .d(MemWrite), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff ML1 (.q(IDEX_MemRead), .d(MemRead), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff AS1 (.q(IDEX_ALU_Src), .d(ALU_Src), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff PS1 (.q(IDEX_PCS), .d(PCS), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff LB1 (.q(IDEX_LoadByte), .d(LoadByte), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff RW1 (.q(IDEX_RegWrite), .d(RegWrite), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff HLT1 (.q(IDEX_Halt), .d(Halt), .wen(~stall), .clk(clk), .rst(~rst_n));
	//dff FE1 [2:0] (.q(IDEX_iflag_enable), .d(iflag_enable), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff Src11 [3:0] (.q(IDEX_SrcReg1), .d(SrcReg1), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff Src21 [3:0] (.q(IDEX_SrcReg2), .d(SrcReg2), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff WR1 [3:0] (.q(IDEX_write_register), .d(write_register), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff RD11 [15:0] (.q(IDEX_reg_2_data), .d(reg_2_data), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff RD21 [15:0] (.q(IDEX_reg_1_data), .d(reg_1_data), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff IDEX_instruction [15:0] (.q(IDEX_current_instruction), .d(IFID_current_instruction), .wen(~stall), .clk(clk), .rst(~rst_n));
	dff IDEX_s_instruction [15:0] (.q(IDEX_stored_instruction), .d(IFID_stored_instruction), .wen(~stall), .clk(clk), .rst(~rst_n));

	// EX-to-EX and MEM-to-EX forwarding (EX-to-EX takes priority)
	
	assign EX_RegData1 = EE_SrcOut1 ? EXMEM_ALU_result : (ME_SrcOut1 ? write_reg_data : IDEX_reg_1_data);
	assign EX_RegData2 = EE_SrcOut2 ? EXMEM_ALU_result : (ME_SrcOut2 ? write_reg_data : IDEX_reg_2_data);	// Possibly need memory-out and not alu_result (MemRead)

	// EX/MEM
	dff MR2 (.q(EXMEM_MemtoReg), .d(IDEX_MemtoReg), .wen('1), .clk(clk), .rst(~rst_n));
	dff MW2 (.q(EXMEM_MemWrite), .d(IDEX_MemWrite), .wen('1), .clk(clk), .rst(~rst_n));
	dff ML2 (.q(EXMEM_MemRead), .d(IDEX_MemRead), .wen('1), .clk(clk), .rst(~rst_n));
	dff RW2 (.q(EXMEM_RegWrite), .d(IDEX_RegWrite), .wen('1), .clk(clk), .rst(~rst_n));
	dff HLT2 (.q(EXMEM_Halt), .d(IDEX_Halt), .wen('1), .clk(clk), .rst(~rst_n));
	dff Src12 [3:0] (.q(EXMEM_SrcReg1), .d(IDEX_SrcReg1), .wen('1), .clk(clk), .rst(~rst_n));
	dff Src22 [3:0] (.q(EXMEM_SrcReg2), .d(IDEX_SrcReg2), .wen('1), .clk(clk), .rst(~rst_n));
	dff WR2 [3:0] (.q(EXMEM_write_register), .d(IDEX_write_register), .wen('1), .clk(clk), .rst(~rst_n));
	dff ALUR [15:0] (.q(EXMEM_ALU_result), .d(ALU_result), .wen('1), .clk(clk), .rst(~rst_n));
	dff RD22 [15:0] (.q(EXMEM_reg_2_data), .d(EX_RegData2), .wen('1), .clk(clk), .rst(~rst_n));
	dff RD12 [15:0] (.q(EXMEM_reg_1_data), .d(EX_RegData1), .wen('1), .clk(clk), .rst(~rst_n));
	dff EXMEM_instruction [15:0] (.q(EXMEM_current_instruction), .d(IDEX_current_instruction), .wen(~stall), .clk(clk), .rst(~rst_n));

	// MEM-to-MEM forwarding
	assign MEM_RegData2 = MM_SrcOut2 ? MEMWB_data_memory_out : EXMEM_reg_2_data;

	// MEM/WB
	dff MR3 (.q(MEMWB_MemtoReg), .d(EXMEM_MemtoReg), .wen('1), .clk(clk), .rst(~rst_n));
	dff RW3 (.q(MEMWB_RegWrite), .d(EXMEM_RegWrite), .wen('1), .clk(clk), .rst(~rst_n));
	dff ML3 (.q(MEMWB_MemRead), .d(EXMEM_MemRead), .wen('1), .clk(clk), .rst(~rst_n));
	dff HLT3 (.q(MEMWB_Halt), .d(EXMEM_Halt), .wen('1), .clk(clk), .rst(~rst_n));
	dff Src13 [3:0] (.q(MEMWB_SrcReg1), .d(EXMEM_SrcReg1), .wen('1), .clk(clk), .rst(~rst_n));
	dff Src23 [3:0] (.q(MEMWB_SrcReg2), .d(EXMEM_SrcReg2), .wen('1), .clk(clk), .rst(~rst_n));
	dff WR3 [3:0] (.q(MEMWB_write_register), .d(EXMEM_write_register), .wen('1), .clk(clk), .rst(~rst_n));
	dff RD23 [15:0] (.q(MEMWB_reg_2_data), .d(MEM_RegData2), .wen('1), .clk(clk), .rst(~rst_n));
	dff ALUR2 [15:0] (.q(MEMWB_ALU_result), .d(EXMEM_ALU_result), .wen('1), .clk(clk), .rst(~rst_n));
	dff MEM [15:0] (.q(MEMWB_data_memory_out), .d(data_memory_out), .wen('1), .clk(clk), .rst(~rst_n));
	dff MEMWB_instruction [15:0] (.q(MEMWB_current_instruction), .d(EXMEM_current_instruction), .wen(~stall), .clk(clk), .rst(~rst_n));
	// Hazard Detection TESTME

	Ex_MemToEx EE_detect (.SrcReg1(IDEX_SrcReg1), .SrcReg2(IDEX_SrcReg2), .write_register(EXMEM_write_register), .RegWrite(EXMEM_RegWrite), .SrcOut1(EE_SrcOut1), .SrcOut2(EE_SrcOut2));
	Ex_MemToEx ME_detect (.SrcReg1(IDEX_SrcReg1), .SrcReg2(IDEX_SrcReg2), .write_register(MEMWB_write_register), .RegWrite(MEMWB_RegWrite), .SrcOut1(ME_SrcOut1), .SrcOut2(ME_SrcOut2));
	MemToMem MM_detect (.SrcReg2(EXMEM_SrcReg2), .write_register(MEMWB_write_register), .MemtoReg(MEMWB_MemtoReg), .MemWrite(EXMEM_MemWrite), .SrcOut2(MM_SrcOut2));

	//Top Level Control signals
	control_logic controls (.Instr(IFID_current_instruction[15:12]), .Branch(Branch), .MemtoReg(MemtoReg),. MemWrite(MemWrite),.ALUSrc(ALU_Src),.RegWrite(RegWrite),.Halt(Halt),.PCS(PCS), .LoadByte(LoadByte), .MemRead(MemRead));
	
		
	//ALU
	assign load_store_immediate = {{12{IDEX_current_instruction[3]}},IDEX_current_instruction[3:0]};
	assign load_byte_immediate = {8'h00,IDEX_current_instruction[7:0]};
	assign second_ALU_value = IDEX_ALU_Src ? (IDEX_LoadByte ? load_byte_immediate : load_store_immediate) : EX_RegData2; 
	//PCS looks a little problematic for ALU Value
	assign first_ALU_value = IDEX_PCS ? IDEX_stored_instruction :  EX_RegData1; //This is a hack to see if the instruction is PCS
	ALU i_alu (.ALU_Out(ALU_result), .flags(iflags), .flag_enable(iflag_enable), .opcode(IDEX_current_instruction[15:12]), .operand1(first_ALU_value),.operand2(second_ALU_value), .clk(clk), .rst(~rst_n));
	
endmodule
