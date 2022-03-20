
module cpu # (
	parameter IW = 32, // instr width
	parameter REGS = 32 // number of registers
)(
	input clk,
	input reset,
	
	// read only port
	output [IW-1:0] 	o_pc_addr,
	output 				o_pc_rd,
	input  [IW-1:0] 	i_pc_rddata,
	output [3:0] 		o_pc_byte_en,
	
	// read/write port
	output [IW-1:0] 	o_ldst_addr,
	output 				o_ldst_rd,
	output 				o_ldst_wr,
	input  [IW-1:0] 	i_ldst_rddata,
	output [IW-1:0] 	o_ldst_wrdata,
	output [3:0] 		o_ldst_byte_en,
	
	output [IW-1:0] 	o_tb_regs [0:REGS-1]
);



// create regs
reg [IW-1:0] PC;
reg			 IR_fetch_bool;
reg [IW-1:0] IR;
//reg [	  3:0] PC_byte_en;
reg [IW-1:0] mem_addr;
reg 			 mem_read_bool;
reg 			 mem_writ_bool;
//reg [IW-1:0] mem_read_data;
reg [IW-1:0] mem_writ_data;
reg [   3:0] mem_byte_en;
reg [IW-1:0] Reg [0:REGS-1];

// connect regs to ports
assign o_pc_addr = PC;
assign o_pc_rd = IR_fetch_bool;
//assign IR = i_pc_rddata;
assign o_pc_byte_en = 4'b1111;
assign o_ldst_addr = mem_addr;
assign o_ldst_rd = mem_read_bool;
assign o_ldst_wr = mem_writ_bool;
//assign mem_read_data = i_ldst_rddata;
assign o_ldst_wrdata = mem_writ_data;
assign o_ldst_byte_en = mem_byte_en;
assign o_tb_regs = Reg;



wire  [ 6:0] 	opcode;
wire	[ 2:0]	funct3;
wire	[ 6:0]	funct7;
wire	[ 4:0]	rs1;
wire	[ 4:0]	rs2;
wire	[ 4:0]	rd;
wire	[31:0]	imm;
wire 	[ 5:0]	op;
localparam R__ = 5'b01100;
localparam I_1 = 5'b00100;
localparam I_2 = 5'b00000;
localparam S__ = 5'b01000;
localparam U_1 = 5'b01101;
localparam U_2 = 5'b00101;
localparam B__ = 5'b11000;
localparam J__ = 5'b11011;
localparam I_3 = 5'b11001;
IR_decoder d0(IR, opcode, funct3, funct7, rs1, rs2, rd, imm, op);



// Stage change
enum {S0, S1, S2, S3, S4, S5} Stage_curr;

always @(posedge clk) begin
	IR_fetch_bool <= 1'b0;
	mem_read_bool <= 1'b0;
	mem_writ_bool <= 1'b0;
	
	// reset
	if  (reset) begin
		Stage_curr <= S0;
		PC <= 32'b0;
		IR <= 32'b0;
		for (int i = 0; i < 32; i = i + 1) Reg[i] <= 32'b0;
	end
	
	// run
	else begin
		case (Stage_curr)
		
			// fetch instr
			S0: begin
				Stage_curr <= S1;
				IR_fetch_bool <= 1'b1;
			end
			
			// wait for instr fetch
			S1: begin
				Stage_curr <= S2;
			end
			
			// store instr in IR
			S2: begin
				Stage_curr <= S3;
				IR <= i_pc_rddata;
			end
			
			// execute instruction
			S3: begin
				Stage_curr <= S0;
				PC <= PC +4;
				// R&I&U
				if (opcode[6:2]==R__ || opcode[6:2]==I_1 || opcode[6:2]==U_1 || opcode[6:2]==U_2) begin
					case(op)
						6'd00: begin Reg[rd] <= Reg[rs1] + Reg[rs2]; end
						6'd01: begin Reg[rd] <= Reg[rs1] - Reg[rs2]; end
						6'd02: begin Reg[rd] <= Reg[rs1] ^ Reg[rs2]; end
						6'd03: begin Reg[rd] <= Reg[rs1] | Reg[rs2]; end
						6'd04: begin Reg[rd] <= Reg[rs1] & Reg[rs2]; end
						6'd05: begin Reg[rd] <= Reg[rs1] <<  Reg[rs2][4:0]; end
						6'd06: begin Reg[rd] <= Reg[rs1] >>  Reg[rs2][4:0]; end
						6'd07: begin Reg[rd] <= Reg[rs1] >>> Reg[rs2][4:0]; end
						6'd08: begin Reg[rd] <= $signed(Reg[rs1]) < $signed(Reg[rs2]) ? 1 : 0; end
						6'd09: begin Reg[rd] <= Reg[rs1] < Reg[rs2] ? 1 : 0; end
						
						6'd10: begin Reg[rd] <= Reg[rs1] + imm; end
						6'd11: begin Reg[rd] <= Reg[rs1] ^ imm; end
						6'd12: begin Reg[rd] <= Reg[rs1] | imm; end
						6'd13: begin Reg[rd] <= Reg[rs1] & imm; end
						6'd14: begin Reg[rd] <= Reg[rs1] <<  imm[4:0]; end
						6'd15: begin Reg[rd] <= Reg[rs1] >>  imm[4:0]; end
						6'd16: begin Reg[rd] <= Reg[rs1] >>> imm[4:0]; end
						6'd17: begin Reg[rd] <= $signed(Reg[rs1]) < $signed(imm) ? 1 : 0; end
						6'd18: begin Reg[rd] <= Reg[rs1] < imm ? 1 : 0; end
						
						6'd27: begin Reg[rd] <= imm; end
						6'd28: begin Reg[rd] <= PC + imm; end
						default: ;
					endcase// op's
				end// R&I&U
				
				// B&J
				else if (opcode[6:2]==B__ || opcode[6:2]==J__ || opcode[6:2]==I_3) begin
					case(op)
						6'd29: begin PC <= (Reg[rs1] == Reg[rs2]) ? (PC + imm) : (PC + 4); end
						6'd30: begin PC <= (Reg[rs1] != Reg[rs2]) ? (PC + imm) : (PC + 4); end
						6'd31: begin PC <= ($signed(Reg[rs1]) <  $signed(Reg[rs2])) ? (PC + imm) : (PC + 4); end
						6'd32: begin PC <= ($signed(Reg[rs1]) >= $signed(Reg[rs2])) ? (PC + imm) : (PC + 4); end
						6'd33: begin PC <= (Reg[rs1] <  Reg[rs2]) ? (PC + imm) : (PC + 4); end
						6'd34: begin PC <= (Reg[rs1] >= Reg[rs2]) ? (PC + imm) : (PC + 4); end
						
						6'd35: begin Reg[rd] <= PC + 4; PC <= PC + imm; end
						6'd36: begin Reg[rd] <= PC + 4; PC <= Reg[rs1] + imm; end
						default: ;
					endcase// op's
				end// B&J
				
				// Load&Store
				else if (opcode[6:2]==I_2 || opcode[6:2]==S__) begin
					Stage_curr <= S4;
					mem_addr <= Reg[rs1] + imm;
					case(op)
						6'd19: begin mem_byte_en <= 4'b1111; mem_read_bool <= 1'b1; end
						6'd20: begin mem_byte_en <= 4'b1111; mem_read_bool <= 1'b1; end
						6'd21: begin mem_byte_en <= 4'b1111; mem_read_bool <= 1'b1; end
						6'd22: begin mem_byte_en <= 4'b1111; mem_read_bool <= 1'b1; end
						6'd23: begin mem_byte_en <= 4'b1111; mem_read_bool <= 1'b1; end
						
						6'd24: begin mem_byte_en <= 4'b0001; mem_writ_bool <= 1'b1; mem_writ_data <= Reg[rs2]; end
						6'd25: begin mem_byte_en <= 4'b0011; mem_writ_bool <= 1'b1; mem_writ_data <= Reg[rs2]; end
						6'd26: begin mem_byte_en <= 4'b1111; mem_writ_bool <= 1'b1; mem_writ_data <= Reg[rs2]; end
						default: ;
					endcase// op's
				end// Load&Store
			end// S3
			
			// wait for memory fetch/store
			S4: begin
				Stage_curr <= S5;
			end
			
			// store data in regs
			S5: begin
				Stage_curr <= S0;
				if (opcode[6:2]==I_2) begin
					case(op)
						6'd19: begin Reg[rd][ 7: 0] = i_ldst_rddata[7:0]; 
										 Reg[rd][31: 8] = i_ldst_rddata[7] ? (~24'b0) : 24'b0; end
						6'd20: begin Reg[rd] = {16'b0, i_ldst_rddata[15:0]}; 
										 Reg[rd][31:16] = i_ldst_rddata[15] ? (~16'b0) : 16'b0; end
						6'd21: begin Reg[rd] = i_ldst_rddata; end
						6'd22: begin Reg[rd] = {24'b0, i_ldst_rddata[ 7:0]}; end
						6'd23: begin Reg[rd] = {16'b0, i_ldst_rddata[15:0]}; end
						default: ;
					endcase// op's
				end// Load
			end// S4
		endcase//Stages
		
		Reg[0] <= 32'b0; // correct Reg[0]
	end
end


endmodule



//////////////////// ALU Control ////////////////////

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
localparam I_1 = 5'b00100;
localparam I_2 = 5'b00000;
localparam S__ = 5'b01000;
localparam U_1 = 5'b01101;
localparam U_2 = 5'b00101;
localparam B__ = 5'b11000;
localparam J__ = 5'b11011;
localparam I_3 = 5'b11001;
	  
always_comb begin

	opcode = instr[6:0];
	
	case(opcode[6:2])
		R__: begin
			funct3 = instr[14:12];
			funct7 = instr[31:25];
			rs1	 = instr[19:15];
			rs2	 = instr[24:20];
			rd	 	 = instr[11: 7];
			imm	 = 32'b0;
			
			if 		(funct3==3'h0 && funct7==7'h00) op = 6'd00;
			else if 	(funct3==3'h0 && funct7==7'h20) op = 6'd01;
			else if 	(funct3==3'h4 && funct7==7'h00) op = 6'd02;
			else if 	(funct3==3'h6 && funct7==7'h00) op = 6'd03;
			else if 	(funct3==3'h7 && funct7==7'h00) op = 6'd04;
			else if 	(funct3==3'h1 && funct7==7'h00) op = 6'd05;
			else if 	(funct3==3'h5 && funct7==7'h00) op = 6'd06;
			else if 	(funct3==3'h5 && funct7==7'h20) op = 6'd07;
			else if 	(funct3==3'h2 && funct7==7'h00) op = 6'd08;
			else if 	(funct3==3'h3 && funct7==7'h00) op = 6'd09;
			else 												  op = 6'd00;
		end
		
		
		I_1: begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = 5'b0;
			rd	 = instr[11: 7];
			imm = {{21{instr[31]}},instr[30:20]};
			//imm	 = {20'b0, instr[31:20]};
			
			//imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			if 		(funct3==3'h0) op = 6'd10;
			else if 	(funct3==3'h4) op = 6'd11;
			else if 	(funct3==3'h6) op = 6'd12;
			else if 	(funct3==3'h7) op = 6'd13;
			else if 	(funct3==3'h1 && imm[11:5]==7'h00) op = 6'd14;
			else if 	(funct3==3'h5 && imm[11:5]==7'h00) op = 6'd15;
			else if 	(funct3==3'h5 && imm[11:5]==7'h20) op = 6'd16;
			else if 	(funct3==3'h2) op = 6'd17;
			else if 	(funct3==3'h3) op = 6'd18;
			else 							op = 6'd00;
		end
		
		
		I_2: begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {20'b0, instr[31:20]};
			imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			if 		(funct3==3'h0) op = 6'd19;
			else if 	(funct3==3'h1) op = 6'd20;
			else if 	(funct3==3'h2) op = 6'd21;
			else if 	(funct3==3'h4) op = 6'd22;
			else if 	(funct3==3'h5) op = 6'd23;
			else 							op = 6'd00;
		end
		
		
		S__: begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = instr[24:20];
			rd	 	 = 5'b0;;
			imm	 = {20'b0, instr[31:25], instr[11:7]};
			imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			if 		(funct3==3'h0) op = 6'd24;
			else if 	(funct3==3'h1) op = 6'd25;
			else if 	(funct3==3'h2) op = 6'd26;
			else 							op = 6'd00;
		end


		U_1: begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {instr[31:12], 12'b0};
			
			op = 6'd27;
		end
		
		
		U_2: begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {instr[31:12], 12'b0};
			
			op = 6'd28;
		end
		
		
		B__: begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = instr[24:20];
			rd	 	 = instr[11: 7];
			imm	 = {19'b0, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
			imm[31:13] = instr[31] ? (~19'b0) : 19'b0;
			
			if 		(funct3==3'h0) op = 6'd29;
			else if 	(funct3==3'h1) op = 6'd30;
			else if 	(funct3==3'h4) op = 6'd31;
			else if 	(funct3==3'h5) op = 6'd32;
			else if 	(funct3==3'h6) op = 6'd33;
			else if 	(funct3==3'h7) op = 6'd34;
			else 							op = 6'd00;
		end

		
		J__: begin
			funct3 = 3'b0;
			funct7 = 7'b0;
			rs1	 = 5'b0;
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {11'b0, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
			imm[31:21] = instr[31] ? (~11'b0) : 1'b0;
			
			op		 = 6'd35;
		end
		
		
		I_3: begin
			funct3 = instr[14:12];
			funct7 = 7'b0;
			rs1	 = instr[19:15];
			rs2	 = 5'b0;
			rd	 	 = instr[11: 7];
			imm	 = {20'b0, instr[31:20]};
			imm[31:12] = instr[31] ? (~20'b0) : 20'b0;
			
			op = 6'd36;
		end
		
		
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
end
endmodule



//////////////////// ALU ////////////////////

module ALU (
	input		[31:0] InA,
	input		[31:0] InB,
	input		[ 3:0] ctrl_sig,
	output logic [31:0] Out
);

enum logic[3:0]{
		ADD=4'd0,
		SUB=4'd1,
		XOR=4'd2,
		OR	=4'd3,
		AND=4'd4,
		SLL=4'd5,
		SRL=4'd6,
		SRA=4'd7,
		SLT=4'd8,
	  SLTU=4'd9} ctrl_sig_enum;

always_comb begin
	case(ctrl_sig)
		ADD: Out = InA + InB;
		SUB: Out = InA - InB;
		XOR: Out = InA ^ InB;
		 OR: Out = InA | InB;
		AND: Out = InA & InB;
		SLL: Out = InA << InB;
		SRL: Out = InA >> InB;
		SRA: Out = InA >>> InB;
		SLT: Out = $signed(InA) < $signed(InB) ? 1 : 0;
		/*
		begin
			if (InA[63] != InB[63])
					Out  = InB[63];
			else
					Out  = InA < InB ? 1 : 0;
		end
		*/
	  SLTU: Out = InA < InB ? 1 : 0;
		default: Out = 0;
	endcase
end


endmodule



//////////////////// ALU ////////////////////
/*
module ALU (
	input		[31:0] InA,
	input		[31:0] InB,
	input		[ 3:0] ctrl_sig,
	output logic [31:0] Out
);

enum logic[3:0]{
		ADD=4'd0,
		SUB=4'd1,
		XOR=4'd2,
		OR	=4'd3,
		AND=4'd4,
		SLL=4'd5,
		SRL=4'd6,
		SRA=4'd7,
		SLT=4'd8,
	  SLTU=4'd9} ctrl_sig_enum;

always_comb begin
	case(ctrl_sig)
		ADD: Out = InA + InB;
		SUB: Out = InA - InB;
		XOR: Out = InA ^ InB;
		 OR: Out = InA | InB;
		AND: Out = InA & InB;
		SLL: Out = InA << InB;
		SRL: Out = InA >> InB;
		SRA: Out = InA >>> InB;
		SLT: Out = $signed(InA) < $signed(InB) ? 1 : 0;
		/*
		begin
			if (InA[63] != InB[63])
					Out  = InB[63];
			else
					Out  = InA < InB ? 1 : 0;
		end
		
	  SLTU: Out = InA < InB ? 1 : 0;
		default: Out = 0;
	endcase
end


endmodule
*/
