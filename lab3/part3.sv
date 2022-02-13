// This module uses parameterized instantiation. If values are not set in the testbench the default values specified here are used. 
// The values for EXP and MAN set here are for a IEEE-754 32-bit Floating point representation. 
// TO DO: Edit BITS and BIAS based on the EXP and MAN parameters. 

module part3
	#(parameter EXP = 8,			// Number of bits in the Exponent
	  parameter MAN = 23, 			// Number of bits in the Mantissa
	  parameter BITS = EXP + MAN +1,	// Total number of bits in the floating point number
	  parameter BIAS = (2**(EXP-1)-1)		// Value of the bias, based on the exponent. 
	  )
	(
		input [BITS - 1:0] X,
		input [BITS - 1:0] Y,
		output inf, nan, zero, overflow, underflow,
		output reg[BITS - 1:0] result
);
// Design your 32-bit Floating Point unit here.
logic signX;
logic signY;
logic [EXP-1:0] expX;
logic [EXP-1:0] expY;
logic final_Sign;
logic [MAN-1:0] xman;
logic [MAN-1:0] yman;
assign signX = X[BITS-1];
assign signY = Y[BITS-1];
assign expX = X[BITS-1-1:MAN];
assign expY = Y[BITS-1-1:MAN];
assign xman = X[MAN-1:0];
assign yman = Y[MAN-1:0];
logic [EXP-1:0] ExponentSum ;
assign final_Sign = signX ^ signY;
assign  ExponentSum = expX + expY - BIAS;
logic [MAN:0] Mantissax ;
assign Mantissax={1'b1, xman[MAN-1:0]};
logic [MAN:0] Mantissay ;
assign Mantissay= {1'b1, yman[MAN-1:0]};
logic [(2 * MAN) + 1:0] MantissaProduct ;
assign MantissaProduct = Mantissax * Mantissay;
logic [MAN+1:0] truncatedbits ;
assign truncatedbits = MantissaProduct[(2 * MAN) + 1:MAN];
logic [MAN+1:0] truncatedbits_new;
logic [EXP-1:0] new_Exp;
logic [MAN-1:0] truncatedbits_for_final ;
logic z;
logic infinite;
logic not_a_number;
logic over; 
logic under;
logic [BITS-1:0] final_result_for_speical_cases; 
logic [BITS-1:0] final_answer;
logic [EXP:0] ExponentSum_new;
//logic [EXP-1:0] exponent_filled;
//logic [MAN-1:0] Mantissa_filled;
always_comb begin 
		ExponentSum_new = expX + expY; 
		if ((expX==0'b0 && xman==0'b0) || (expY==0 && yman==0'b0)) begin // zero
			z=1;
			infinite=0;
			not_a_number=0;
			over=0;
			under=0;
			final_result_for_speical_cases = 0;
			final_answer = final_result_for_speical_cases; 
		end
		else if ((expX == BIAS*2+1 && xman != 0)|| (expY == BIAS*2+1 && yman !=0)) begin // NaN
			z=0;
			infinite=0;
			not_a_number=1;
			over=0;
			under=0; 
			//exponent_filled = 1;
			//Mantissa_filled = 0;
			final_result_for_speical_cases = {1'b0, {(EXP){1'b1}}, {(MAN){1'b0}}};
			final_answer = final_result_for_speical_cases;
		end
		else if ((expX == BIAS*2+1 && xman == 0)|| (expY == BIAS*2+1 && yman ==0)) begin // Inf
			z=0;
			infinite=1;
			not_a_number=0;
			over=0;
			under=0; 
			//exponent_filled = 1;
			//Mantissa_filled = 0;
			final_result_for_speical_cases = {1'b0, {(EXP){1'b1}}, {(MAN){1'b0}}};
			final_answer = final_result_for_speical_cases;
		end
		else if ((ExponentSum_new)  > BIAS*3+1 ) begin //overflow
			z=0;
			infinite=0;
			not_a_number=0;
			over=1;
			under=0; 
			//exponent_filled = 1;
			//Mantissa_filled = 0;
			final_result_for_speical_cases = {1'b0, {(EXP){1'b1}}, {(MAN){1'b0}}};
			final_answer = final_result_for_speical_cases;
		end	
		else if ((ExponentSum_new)  < BIAS ) begin // underflow
			z=0;
			infinite=0;
			not_a_number=0;
			over=0;
			under=1; 
			final_result_for_speical_cases = 0;
			final_answer = final_result_for_speical_cases; 
		end 
		else begin
			z=0;
			infinite=0;
			not_a_number=0;
			over=0;
			under=0;
			if (truncatedbits[MAN+1] == 1'b1) begin 
			truncatedbits_new = truncatedbits >> 1;
			new_Exp = ExponentSum +1;
			end 
			else begin 
			truncatedbits_new = truncatedbits;
			new_Exp = ExponentSum;
			end 
			truncatedbits_for_final[MAN-1:0] = truncatedbits_new[MAN-1:0];
			final_answer = {final_Sign, new_Exp, truncatedbits_for_final};
		end 
	end 
	assign result = final_answer;
	assign inf = infinite;
	assign nan = not_a_number;
	assign zero = z;
	assign overflow = over;
	assign underflow = under;

endmodule