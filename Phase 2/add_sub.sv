//Simple 1 bit adder
module full_adder_1bit (input A, input B, input Cin, output S, output Cout);
	assign S = A ^ B ^ Cin;
	assign Cout = (A&B) | (Cin & (A | B));
endmodule

module addsub_16bit (Sum, Error, A, B, sub, pad);
input [15:0] A, B; 	// Input data values
input sub;			// To indicate sub or add
input pad;			// To indicate pad or not pad
output [15:0] Sum; 	// Sum output
output Error; 		// To indicate overflows

// 
wire [15:0] interSum;
wire [3:0] temp_error;
wire [3:0] carry;
wire [15:0] interB;
assign interB = sub ? ~B : B;
assign Error = (pad)? (temp_error[0] | temp_error[1] | temp_error[2] | temp_error[3]) 
		: (interSum[15] ? (~A[15]&~interB[15]) : (A[15] & interB[15]));
assign Sum = (pad) ? interSum : ((Error) ? ((~A[15])? 16'h7FFF : 16'h8000) : interSum);

// Add/Sub
carry_look_ahead Partial [3:0] (.Sum(interSum), .Ovfl(temp_error), . Cout(carry),.A(A), .B(interB), .pad(pad), .Cin({carry[2:0],sub}));
endmodule
