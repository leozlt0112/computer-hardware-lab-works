module wallace_mult (
  input [7:0] x,
  input [7:0] y,
  output [15:0] out,
  output [15:0] pp [4]
);

// These signals are created to help you map the wires you need with the diagram provided in the lab document.

wire [15:0] s_lev01; //the first "save" output of level0's CSA array
wire [15:0] c_lev01; //the first "carry" output of level0's CSA array
wire [15:0] s_lev02; //the second "save" output of level0's CSA array
wire [15:0] c_lev02;
wire [15:0] s_lev11;
wire [15:0] c_lev11;
wire [15:0] s_lev12; //the second "save" output of level1's CSA array
wire [15:0] c_lev12;
wire [15:0] s_lev21;
wire [15:0] c_lev21;
wire [15:0] s_lev31;
wire [15:0] c_lev31;
logic [15:0] i_s [8];

assign i_s[0] = {(8'b0), (x & {(8){y[0]}})};

assign i_s[1] = {7'b0, (x & {(8){y[1]}}), 1'b0};

assign i_s[2] = {6'b0, (x & {(8){y[2]}}), 2'b0};

assign i_s[3] = {5'b0, (x & {(8){y[3]}}), 3'b0};

assign i_s[4] = {4'b0, (x & {(8){y[4]}}), 4'b0};

assign i_s[5] = {3'b0, (x & {(8){y[5]}}), 5'b0};

assign i_s[6] = {2'b0, (x & {(8){y[6]}}), 6'b0};

assign i_s[7] = {1'b0, (x & {(8){y[7]}}), 7'b0};

/*
logic [7:0] i0, i1, i2, i3, i4, i5, i6, i7;
	
	assign i0 = (y[0] == 1'b1) ? x : 7'b0;
	assign i1 = (y[1] == 1'b1) ? x : 7'b0;
	assign i2 = (y[2] == 1'b1) ? x : 7'b0;
	assign i3 = (y[3] == 1'b1) ? x : 7'b0;
	assign i4 = (y[4] == 1'b1) ? x : 7'b0;
	assign i5 = (y[5] == 1'b1) ? x : 7'b0;	
	assign i6 = (y[6] == 1'b1) ? x : 7'b0;
	assign i7 = (y[7] == 1'b1) ? x : 7'b0;

	logic [15:0] ii0, ii1, ii2, ii3, ii4, ii5, ii6, ii7;

	assign ii0 = {8'b0, i0};
	assign ii1 = {7'b0, i1, 1'b0};
	assign ii2 = {6'b0, i2, 2'b0};
	assign ii3 = {5'b0, i3, 3'b0};
	assign ii4 = {4'b0, i4, 4'b0};
	assign ii5 = {3'b0, i5, 5'b0};
	assign ii6 = {2'b0, i6, 6'b0};
	assign ii7 = {1'b0, i7, 7'b0};
*/		
//genvar i, j, x_index;
//generate 
	//for (i=0; i<8; i++) begin
		//for (j=0; j<16; j++) begin 
			//if ((j-i) <= 7 && j>=i) begin 
				//assign i_s[i][j]=(y[i]&x[]);
		
			//end 
			//else begin 
				//assign i_s[i][j]=0;
			//end 
		//end 
	//end 
//endgenerate
// TODO: complete the hardware design for instantiating the CSA blocks per level.

csa level_zero_left(
.op1(i_s[0]),
.op2(i_s[1]),
.op3(i_s[2]),
.S(s_lev01),
.C(c_lev01)
);
csa level_zero_right(
.op1(i_s[3]),
.op2(i_s[4]),
.op3(i_s[5]),
.S(s_lev02),
.C(c_lev02)
);
//level 0
//assign c_lev01 = {c_lev01 << 1};

//assign c_lev02 = {c_lev02 << 1};
csa level_one_left(
.op1(s_lev01),
.op2(c_lev01 << 1),
.op3(s_lev02),
.S(s_lev11),
.C(c_lev11)
);
csa level_one_right(
.op1(c_lev02 << 1),
.op2(i_s[6]),
.op3(i_s[7]),
.S(s_lev12),
.C(c_lev12)
);
//level 1
//assign c_lev11 = {c_lev11 << 1};
csa level_2(
.op1(c_lev11 << 1),
.op2(s_lev11),
.op3(s_lev12),
.S(s_lev21),
.C(c_lev21)
);
//level 2, the save and carry output of level 2 will be pp[2] and pp[3]
// assigning pps 
  assign pp[0] = s_lev21;
  assign pp[1] = c_lev21;

csa level_3(
.op1(s_lev21),
.op2(c_lev21<< 1),
.op3(c_lev12<< 1),
.S(s_lev31),
.C(c_lev31)
);
//level 3, the save and carry output of level 3 will be pp[2] and pp[3]
 // assigning pps 
  assign pp[2] = s_lev31;
  assign pp[3] = c_lev31;

	logic coutt;
rca final_put(
.op1(s_lev31),
.op2(c_lev31 << 1),
.cin(1'b0),
.sum(out),
.cout(coutt)
);
// Ripple carry adder to calculate the final output.

endmodule





// These modules are provided for you to use in your designs.
// They also serve as examples of parameterized module instantiation.
module rca #(width=16) (
    input  [width-1:0] op1,
    input  [width-1:0] op2,
    input  cin,
    output [width-1:0] sum,
    output cout
);

wire [width:0] temp;
assign temp[0] = cin;
assign cout = temp[width];

genvar i;
for( i=0; i<width; i=i+1) begin
    full_adder u_full_adder(
        .a      (   op1[i]     ),
        .b      (   op2[i]     ),
        .cin    (   temp[i]    ),
        .cout   (   temp[i+1]  ),
        .s      (   sum[i]     )
    );
end

endmodule


module full_adder(
    input a,
    input b,
    input cin,
    output cout,
    output s
);

assign s = a ^ b ^ cin;
assign cout = a & b | (cin & (a ^ b));

endmodule

module csa #(width=16) (
	input [width-1:0] op1,
	input [width-1:0] op2,
	input [width-1:0] op3,
	output [width-1:0] S,
	output [width-1:0] C
);

genvar i;
generate
	for(i=0; i<width; i++) begin
		full_adder u_full_adder(
			.a      (   op1[i]    ),
			.b      (   op2[i]    ),
			.cin    (   op3[i]    ),
			.cout   (   C[i]	  ),
			.s      (   S[i]      )
		);
	end
endgenerate

endmodule

