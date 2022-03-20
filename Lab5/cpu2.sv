module ALU_ctrl (
	input 	[ 6:0] 	opcode,
	input		[ 2:0]	funct3,
	input		[ 6:0]	funct7,
	output 	[ 3:0] 	ctrl_sig
);
endmodule



//////////////////// IR Decoder ////////////////////

module IR_decoder(
	input		[31:0] 	instr,
	output logic [ 6:0] 	opcode,
	output logic [ 2:0]	funct3,
	output logic [ 6:0]	funct7,
	output logic [ 4:0]	rs1,
	output logic [ 4:0]	rs2,
	output logic [ 4:0]	rd,
	output logic [31:0]	imm,
	output logic [ 5:0]	op
);

localparam R__ = 5'b01100;
localparam I_imm = 5'b00100;
localparam I_loadoperations = 5'b00000;
localparam S_store = 5'b01000;
localparam U_load_upper = 5'b01101;
localparam U_adduper_imm_to_pc = 5'b00101;
localparam B_branchops = 5'b11000;
localparam J_JAL = 5'b11011;
localparam J_JAL_REG = 5'b11001;
	  
always_comb begin

	opcode = instr[6:0];
	
	//case(opcode[6:2])
	if (opcode[6:2] == R__)
		begin
			funct3 = instr[14:12];
			funct7 = instr[31:25];
			rs1	 = instr[19:15];
			rs2	 = instr[24:20];
			rd	 	 = instr[11: 7];
			op = 6'd00;
			// no immediate value 
			imm	 = 32'b0;
			
			if 	(funct3==3'h0) begin 
				if (funct7==7'h00) begin 
					op = 6'd00;
				end 
			end 
			if 	(funct3==3'h0 ) begin 
				if(funct7==7'h20) begin 
					op = 6'd01;
				end
			end 
			if 	(funct3==3'h4) begin 
				if (funct7==7'h00) begin 
					op = 6'd02;
				end
			end 
			if 	(funct3==3'h6) begin  
				if (funct7==7'h00) begin 
					op = 6'd03;
				end 
			end 
			if 	(funct3==3'h7) begin 
				if (funct7==7'h00) begin  
					op = 6'd04;
				end 
			end 
			if 	(funct3==3'h1) begin
				if(funct7==7'h00) begin 
					op = 6'd05;
				end 
			end 
			if 	(funct3==3'h5) begin 
				if (funct7==7'h00) begin 
					op = 6'd06;
				end 
			end 
			if 	(funct3==3'h5 ) begin 
				if (funct7==7'h20) begin  
				op = 6'd07;
				end 
			end 
			if 	(funct3==3'h2) begin 
				if (funct7==7'h00) begin  
					op = 6'd08;
				end 
			end 
			if 	(funct3==3'h3) begin  
				if (funct7==7'h00) begin 
					op = 6'd09;
				end 
			end 
			
		end
		
		if (opcode[6:2] == I_imm)
		begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm = {{21{instr[31]}},instr[30:20]};
			//op = 6'd00;
			//imm	 = {20'b0, instr[31:20]};
			
//imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			//if 		(funct3==3'h0) op = 6'd10;
			//else if 	(funct3==3'h4) op = 6'd11;
			//else if 	(funct3==3'h6) op = 6'd12;
			//else if 	(funct3==3'h7) op = 6'd13;
			//else if 	(funct3==3'h1 && imm[11:5]==7'h00) op = 6'd14;
			else if 	(funct3==3'h5 && imm[11:5]==7'h00) op = 6'd15;
			else if 	(funct3==3'h5 && imm[11:5]==7'h20) op = 6'd16;
			else if 	(funct3==3'h2) op = 6'd17;
			else if 	(funct3==3'h3) op = 6'd18;
			//else 							op = 6'd00;
		end
		
		if (opcode[6:2] == I_loadoperations)
		begin 
		//I_loadoperations: begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm = {{21{instr[31]}},instr[30:20]};
			//imm	 = {20'b0, instr[31:20]};
			//imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			op = 6'd00;
			if 		(funct3==3'h0) begin 
				op = 6'd19;
			end 
			if 	(funct3==3'h1) begin
				op = 6'd20;
			end 
			if 	(funct3==3'h2) begin 
				op = 6'd21;
			end 
			if 	(funct3==3'h4) begin 
				op = 6'd22;
			end 
			if 	(funct3==3'h5) begin 
				op = 6'd23;
			end 
			//else 							op = 6'd00;
		end
		
		if (opcode[6:2] == S_store)
		begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = instr[24:20];
			rd	 	 = 5'b0;;
			imm	 = {{21{instr[31]}}, instr[30:25], instr[11:7]};
			op = 6'd00;
			//imm	 = {20'b0, instr[31:25], instr[11:7]};
			//imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			if 		(funct3==3'h0) begin 
				op = 6'd24;
			end 
			if 	(funct3==3'h1) begin 
				op = 6'd25;
			end 
			if 	(funct3==3'h2) begin 
				op = 6'd26;
		
			end
		end 
		if (opcode[6:2] == U_load_upper)
			begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {instr[31:12], 12'b0};
			
			op = 6'd27;
		end
		
		if (opcode[6:2] == U_adduper_imm_to_pc)
		begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {instr[31:12], 12'b0};
			
			op = 6'd28;
		end
		
		if (opcode[6:2] == B_branchops)
		begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = instr[24:20];
			rd	 	 = instr[11: 7];
			op = 6'd00;
			imm	 = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
			//imm[31:13] = instr[31] ? (~19'b0) : 19'b0;
			
			if 		(funct3==3'h0) op = 6'd29;
			if 	(funct3==3'h1) op = 6'd30;
			if 	(funct3==3'h4) op = 6'd31;
			if 	(funct3==3'h5) op = 6'd32;
			if 	(funct3==3'h6) op = 6'd33;
			if 	(funct3==3'h7) op = 6'd34;
			//else 							
		end

		if (opcode[6:2] == J_JAL)
		begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
			//imm[31:21] = instr[31] ? (~11'b0) : 1'b0;
			
			op		 = 6'd35;
		end
		
		if (opcode[6:2] == J_JAL_REG)
		begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {20'b0, instr[31:20]};
			imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			op = 6'd36;
		end
		
		/*
		default: begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = 5'b0;
			imm	 = 32'b0;
			
			op		 = 6'd0;
		end
	endcase
	*/
end
endmodule

