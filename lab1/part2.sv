//Top module for game
module top 
(
    // Clock pins
    input                     clk,
    input                     reset,
    input                     enter,
    input               [7:0] guess,
    output                    dp_over,
    output                    dp_under,
    output                    dp_equal,
	output              [3:0] dp_tries,
	output              [7:0] actual
);

	logic over;
	logic under;
	logic equal;
	logic guessbool;
	// Datapath
	logic dp_inc_actual;
	logic dp_dec_guess;
	datapath the_datapath
	(
		.clk(clk),
		.reset(reset),
		.i_guess(guess),
		.i_inc_actual(dp_inc_actual),
		.i_dec_actual(dp_dec_guess),
		.o_over(over),
		.o_under(under),
		.o_equal(equal),
		.o_noguess(guessbool),
        .actual(actual),
		.tries(dp_tries)
	);
	
	// State Machine
	logic ctrl_update_leds;
	control the_control
	(
		.clk(clk),
		.reset(reset),
		.i_enter(enter),
		.o_inc_actual(dp_inc_actual),
		.o_dec_actual(dp_dec_guess),
		.i_over(over),
		.i_under(under),
		.i_equal(equal),
		.i_no_more_guess(guessbool),
		.o_update_leds(ctrl_update_leds)
	);
	
	// LED controllers
	led_ctrl ledc_under(clk, reset, under, ctrl_update_leds, dp_under);
	led_ctrl ledc_over(clk, reset, over, ctrl_update_leds, dp_over);
	led_ctrl ledc_equal(clk, reset, equal, ctrl_update_leds, dp_equal);
	
endmodule

/*******************************************************/
/********************Control module********************/
/*****************************************************/
module control
(
	input clk,
	input reset,
	
	// Button input
	input i_enter,
	
	// Datapath
	output logic o_inc_actual,
	output logic o_dec_actual,
	input i_over,
	input i_under,
	input i_equal,
	input i_no_more_guess,
	// LED Control
	output logic o_update_leds
);

// Declare two objects, 'state' and 'nextstate'
// that are of enum type.
enum int unsigned
{
	S_GEN_RAND,
	S_CHECK,
	S_WAIT_NOENTER,
	S_WAIT_ENTER,
	//S_PAUSE,
	S_END
} state, nextstate;

// Clocked always block for making state registers
always_ff @ (posedge clk or posedge reset) begin
	if (reset) state <= S_GEN_RAND;
	else state <= nextstate;
end

// always_comb replaces always @* and gives compile-time errors instead of warnings
// if you accidentally infer a latch
always_comb begin
	nextstate = state;
	o_inc_actual = 1'b0;
	o_update_leds = 1'b0;
	o_dec_actual =1'b0;
	case (state)
		S_GEN_RAND: begin 
					o_inc_actual = 1'b1;
					nextstate=S_WAIT_ENTER;
		end
		S_WAIT_ENTER: begin 
					if(!i_enter) nextstate=S_WAIT_ENTER;
					else if (i_enter) nextstate = S_CHECK;
					o_inc_actual = 1'b1;
		end  
		S_CHECK: begin 
				if(i_equal) nextstate=S_END;		
				else if(i_over) nextstate=S_WAIT_NOENTER;
				else if(i_under) nextstate=S_WAIT_NOENTER;
				
				o_update_leds = 1'b1;
				o_dec_actual = 1'b1;
				
		end 
		S_WAIT_NOENTER: begin 
					if(i_no_more_guess) nextstate=S_END;
					else begin 
						if(!i_enter) nextstate=S_WAIT_NOENTER;
						else if (i_enter) nextstate = S_CHECK;
					end
					
		end
		S_END: begin 
				//o_dec_actual =1'b0;
				nextstate=S_END;
				//o_update_leds = 1'b0;
		end 
	endcase
end
endmodule

/*******************************************************/
/********************Datapath module*******************/
/*****************************************************/
module datapath
(
	input clk,
	input reset,
	
	// Number entry
	input [7:0] i_guess,
	
	// Increment actual
	input i_inc_actual,
	input i_dec_actual,
	// Comparison result
	output o_over,
	output o_under,
	output o_equal,
	output o_noguess,
	output logic [7:0] actual,
	output logic [3:0] tries
);

// Update the 'actual' register based on control signals
always_ff @ (posedge clk or posedge reset) begin 
	if (reset) begin 
			actual <= '0;
				tries <=4'd7;
    end				
	else begin
		if (i_inc_actual) begin 
			actual <= actual + 8'd1;
		end 
		if (i_dec_actual) begin 
			tries <= tries - 4'd1;
		end
		//if (o_noguess) begin
			//tries <= 0;
	//end
	end 
end 

assign o_over = i_guess > actual;
assign o_equal= i_guess == actual;
assign o_under = i_guess <actual;
assign o_noguess = tries ==0; 
endmodule

/*******************************************************/
/********************LED control module****************/
/*****************************************************/
module led_ctrl
(
	input clk,
	input reset,
	
	input i_val,
	input i_enable,
	output logic o_out
);

always_ff @ (posedge clk or posedge reset) begin
	if (reset) o_out <= '0;
	else if (i_enable) o_out <= i_val;
end

endmodule

