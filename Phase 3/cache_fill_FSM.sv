module cache_fill_FSM(clk, rst_n, miss_detected, miss_address, fsm_busy, write_data_array, write_tag_array,memory_address);
	input clk, rst_n;
	
	input miss_detected; // active high when tag match logic detects a miss
	input [15:0] miss_address; // address that missed the cache
	output fsm_busy; // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
	output write_data_array; // write enable to cache data array to signal when filling with memory_data
	output write_tag_array; // write enable to cache tag array to signal when all words are filled in to data array
	
	//input [15:0] memory_data; // data returned by memory (after  delay)
	//input memory_data_valid; // active high indicates valid data returning on memory bus


	wire [4:0] timer, timer_adder, timer_inter;
	wire state_stored, memory_increment;
	wire[4:0] adder_carry;
	wire [15:0] memory_addr_out,incremented_memory, memory_start;
	
	assign memory_address = incremented_memory;
	assign fsm_busy = state_stored;
	assign memory_increment = &timer_inter[1:0];
	assign write_tag_array = &timer_inter;
	assign write_data_array = &timer_inter[1:0];
	
	assign timer = state_stored ? timer_inter : '0;
	assign memory_start = (timer_adder == 16'h0001) ? miss_address : incremented_memory;

	//Flip Flops
	dff state_ff (.q(state_stored), .d(~state_stored), .wen((~fsm_busy & miss_detected)| write_tag_array), .clk(clk), .rst(rst_n));
	
	dff timer_ff [4:0] (.q(timer_inter), .d(timer_adder), .wen({5{fsm_busy}}), .clk(clk), .rst(~state_stored));
	
	dff memory_addr_ff [15:0] (.q(memory_addr_out), .d(memory_start), .wen(memory_increment | (~fsm_busy & miss_detected)), .clk(clk), .rst(rst_n));
  
	//Adders
	full_adder_1bit timer_inc [4:0]  (.A(timer),.B(5'b00001),.Cin({adder_carry[3:0],1'b0}),.Cout(adder_carry),.S(timer_adder));

	addsub_16bit adder (.Sum(incremented_memory), .Error(), .A(memory_addr_out), .B(16'h0002), .sub('0), .pad('0));

endmodule

module tb_cache_fill_FSM();
logic clk, rst_n, miss_detected;
logic [15:0] miss_address;
	cache_fill_FSM iDUT(.clk(clk), .rst_n(rst_n), .miss_detected(miss_detected), .miss_address(miss_address), .fsm_busy(), .write_data_array(), .write_tag_array(), .memory_address());

	initial begin 
		clk = 1;
		rst_n = 0;
		miss_detected = 0;
		miss_address = 16'ha120;
		repeat (1) @ (posedge clk) begin 
		rst_n = '1;
		miss_detected = '1;
		end
		repeat (36) @ (posedge clk)

		miss_detected = '0;
		repeat (1) @ (posedge clk) begin
		miss_detected = '1;
		end
		repeat (36) @ (posedge clk)
		$stop();
	end
	always #5 begin
		clk = ~clk;
	end
	
endmodule
