
//Instantiates full_adder_1bit to make it 4 wide
//overflow is determined by seperate logic than carry out
module carry_look_ahead (Sum, Ovfl, A, B, pad, Cin, Cout);
	input pad; //pad-notpad indicator
	input [3:0] A, B; //Input values
	input Cin;
	output [3:0] Sum; //sum output
	output Ovfl; //To indicate overflow
	output Cout;
	wire interCin;
	wire [3:0] interC;
	wire [3:0] interSum;

	assign interCin = (pad) ? '0 : Cin;
	wire [3:0] P, G;

	// Get propagate for each bit
	assign P[0] = A[0] ^ B[0];
	assign P[1] = A[1] ^ B[1];
	assign P[2] = A[2] ^ B[2];
	assign P[3] = A[3] ^ B[3];

	// Get generate for each bit
	assign G[0] = A[0] & B[0];
	assign G[1] = A[1] & B[1];
	assign G[2] = A[2] & B[2];
	assign G[3] = A[3] & B[3];

	// Calculate carry-outs
	//assign Cout[0] = G[0] ^ (P[0]&Cin);
	//assign Cout[1] = G[1] ^ (P[1]&G[0]) ^(P[1]&P[0]&Cin);
	//assign Cout[2] = G[2] ^ (P[2]&G[1]) ^ (P[2]&P[1]&G[0]) ^(P[2]P[1]&P[0]&Cin);
	assign Cout = G[3] | (P[3]&G[2]) | (P[3]&P[2]&G[1]) | (P[3]&P[2]&P[1]&G[0]) | (P[3]&P[2]&P[1]&P[0]&interCin);

	//note interB is not technically full2s compliment, but its close enough for the calculation needed
	assign Ovfl = (interSum[3] ? (~A[3]&~B[3]) : (A[3] & B[3])); 
	// Saturating arithmetic
	assign Sum = (pad)? ((Ovfl) ? ((~A[3])? 4'b0111 : 4'b1000): interSum) : interSum;

	full_adder_1bit FA [3:0]  (.A(A),.B(B),.Cin({interC[2:0],interCin}),.Cout(interC),.S(interSum));
endmodule
