module part2
	(
		input [31:0] X,
		input [31:0] Y,
		output inf, nan, zero, overflow, underflow,
		output reg[31:0] result
);
logic signX;
	logic signY;
	logic [7:0] expX;
	logic [7:0] expY;
	
	logic final_Sign;
	logic [22:0] xman;
	logic [22:0] yman;
	
	assign signX = X[31];
	assign signY = Y[31];
	
	assign expX = X[30:23];
	assign expY = Y[30:23];

	assign xman = X[22:0];
	assign yman = Y[22:0];
	
	logic [7:0] ExponentSum ;
	assign final_Sign = signX ^ signY;
	assign  ExponentSum = expX + expY - 8'd127;
	
	logic [23:0] Mantissax ;
	assign Mantissax={1'b1, xman[22:0]};
	logic [23:0] Mantissay ;
	assign Mantissay= {1'b1, yman[22:0]};
	logic [47:0] MantissaProduct ;
	assign MantissaProduct = Mantissax * Mantissay;
	
	logic [24:0] truncatedbits ;
	assign truncatedbits = MantissaProduct[47:23];
	logic [24:0] truncatedbits_new;
	logic [7:0] new_Exp;
	logic [22:0] truncatedbits_for_final ;
	logic z;
	logic infinite;
	logic not_a_number;
	logic over; 
	logic under;
	//assign z=0;
	//assign infinite=0;
	//assign not_a_number=0;
	//assign over=0;
	//assign under=0; 
	logic [31:0] final_result_for_speical_cases; 
	logic [31:0] final_answer;
	logic [8:0] ExponentSum_new; 
	always_comb begin 
		ExponentSum_new = expX + expY; 
		if ((expX==0'b0 && xman==0'b0) || (expY==0 && yman==0'b0)) begin // zero
			z=1;
			infinite=0;
			not_a_number=0;
			over=0;
			under=0;
			final_result_for_speical_cases = {1'b0, 8'b0, 23'b0};;
			final_answer = final_result_for_speical_cases; 
		end
		else if ((expX == 8'd255 && xman != 0)|| (expY == 8'd255 && yman !=0)) begin // NaN
			z=0;
			infinite=0;
			not_a_number=1;
			over=0;
			under=0; 
			final_result_for_speical_cases = {1'b0, 8'b11111111, 23'b0};
			final_answer = final_result_for_speical_cases;
		end
		else if ((expX == 8'd255 && xman == 0)|| (expY == 8'd255 && yman ==0)) begin // Inf
			z=0;
			infinite=1;
			not_a_number=0;
			over=0;
			under=0; 
			final_result_for_speical_cases = {1'b0, 8'b11111111, 23'b0};
			final_answer = final_result_for_speical_cases;
		end
		else if (ExponentSum_new  < 9'd127 &&  (ExponentSum_new - 9'd127 > 9'd255 ) ) begin // underflow
			z=0;
			infinite=0;
			not_a_number=0;
			over=0;
			under=1; 
			final_result_for_speical_cases = {1'b0, 8'b0, 23'b0};
			final_answer = final_result_for_speical_cases; 
		end 
		else if (ExponentSum_new - 9'd127 > 9'd255 ) begin //overflow
			z=0;
			infinite=0;
			not_a_number=0;
			over=1;
			under=0; 
			final_result_for_speical_cases = {1'b0, 8'b11111111, 23'b0};
			final_answer = final_result_for_speical_cases;
		end	
		else begin
			z=0;
			infinite=0;
			not_a_number=0;
			over=0;
			under=0;
			if (truncatedbits[24] == 1'b1) begin 
			truncatedbits_new = truncatedbits >> 1;
			new_Exp = ExponentSum +1;
			end 
			else begin 
			truncatedbits_new = truncatedbits;
			new_Exp = ExponentSum;
			end 
			truncatedbits_for_final[22:0] = truncatedbits_new[22:0];
			final_answer = {final_Sign, new_Exp, truncatedbits_for_final};
		end 
	end 
	
	
	
	assign result = final_answer;
	assign inf = infinite;
	assign nan = not_a_number;
	assign zero = z;
	assign overflow = over;
	assign underflow = under;
// Design your 32-bit Floating Point unit here. 


endmodule