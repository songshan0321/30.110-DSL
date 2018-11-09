`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: GPH
// 
// Create Date:    13:54:20 09/23/2007 
// Module Name:    timer1 
//
//   Being a 6-1 guy with old hardware experience, the timer counts up to 4'hF
//   then expires; use the built in RCO in "LS163"
//                 
// load_start_timer:  pulse to load_start timer value
//            clear:  pulse to clear timer
//            value:  timer value
//         counting:  1 if timing
//          expired:  1 if done
//    expired_pulse:  expired pulse
//         debug_on:  used to shorten 40,000,000 divider to 3; use with logic
//	                   analyzer or chipscope
//
//////////////////////////////////////////////////////////////////////////////////
module timer1
    (input clock, load_start_timer, clear,
    input [3:0] value,
	 input debug_on,
    output counting, expired, expired_pulse, one_hz,
	 output reg [3:0] count);

	 reg [25:0] sec_count;
	 reg old_expired;

	 parameter DEBUG = 3;
	 parameter NORMAL = 39_999_999;
	 wire increment, one_hz; 
	 
	 always @ (posedge clock)
		begin
      // one second divider
		if (load_start_timer || clear) sec_count <= 0;
			else sec_count <= (sec_count == (debug_on ? DEBUG : NORMAL)) ?
					0 : sec_count + 1; 
      // end of second divider
 
      count <= clear ? 0 : load_start_timer ? (4'hF-value) : increment ? count+1 : count;
	   old_expired <= expired;
		
		end
		
		assign one_hz = (sec_count == (debug_on ? DEBUG : NORMAL));		
		assign increment = one_hz && ~(count==15);
		assign expired = ((count==15) && ~load_start_timer);
		assign expired_pulse = expired && ~old_expired;
		assign counting = (!(count==0))&& ~expired;

endmodule

//
// Tone Generator
//
// DIVIDER = freq / 2X of desired frequency = period
// tone_out is a square wave
//
module tones  //(clock, reset, debug_on, DIVIDER, tone_out);
   (input clock, reset,
	 input debug_on, 		// when = 1, set divider to 3;
    input [15:0] divider,
	 output reg tone_out);

	reg [25:0] counter;
	
	parameter DEBUG = 3;
	
	always @(posedge clock)
	   begin
		if (reset)  counter <= 0;
			else counter <= (counter >= (debug_on ? DEBUG : divider)) ? 0 : counter + 1;
      tone_out <= (counter == 2) ? ~tone_out : tone_out;		
	   end

endmodule

//
// outputs a 2khz pulse
//
module four_khz #(parameter DIVIDER=9258) 
//   (clock, reset, debug_on, DIVIDER, pulse_out);

   (input clock, reset,
	input debug_on, 		// when = 1, set divider to 3;

	output reg pulse_out);

//	reg pulse_out;
	reg [20:0] counter;

	parameter DEBUG = 3;
	
	always @(posedge clock)
	   begin
		if (reset)  counter <= 0;
			else counter <= (counter == (debug_on ? DEBUG : DIVIDER)) ? 0 : counter + 1;
      pulse_out <= (counter == 2) ? 1 : 0; 		
	   end
endmodule
	
	