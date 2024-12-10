module RED (rs, rt, Sum); 
input [15: 0] rs, rt; // Input Data Values
output [15:0] Sum; // Final Sum of Values

wire [8:0] totalsumAB;
wire [8:0] totalsumCD;
wire [7:0] sumAB;
wire [7:0] sumCD;
wire [1:0] carryAB;
wire [1:0] carryCD;
wire [2:0] carry2;
wire [11:0] interSum;

//tree layer 1
carry_look_ahead CLA1 [1:0] (.Sum(sumAB), .Ovfl(), .A(rs[15:8]), .B(rs[7:0]), .pad('0), .Cin({carryAB[0], '0}), .Cout(carryAB[1:0]));
carry_look_ahead CLA2 [1:0] (.Sum(sumCD), .Ovfl(), .A(rt[15:8]), .B(rt[7:0]), .pad('0), .Cin({carryCD[0], '0}), .Cout(carryCD[1:0]));
assign totalsumAB = ({carryAB[1], sumAB});
assign totalsumCD = ({carryCD[1], sumCD});

//tree layer 2
carry_look_ahead CLA3 [2:0] (.Sum(interSum), .Ovfl(), .A({{3{totalsumAB[8]}}, totalsumAB}), .B({{3{totalsumCD[8]}}, totalsumCD}), .pad('0), .Cin({carry2[1:0], '0}), .Cout(carry2[2:0]));

assign Sum = {{6{interSum[9]}}, interSum};

endmodule
