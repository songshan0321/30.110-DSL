`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:13:31 04/23/2013 
// Design Name: 
// Module Name:    fuel_pump 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fuel_pump(
    input brake,
    input hidden,
    input clock,
    input ignition,
    output power
    );

  reg [1:0] state;
  parameter ON = 1;
  parameter OFF = 0;
  parameter WAIT = 2;
  // write your code here
  initial state = OFF;
  
  always  @(posedge clock) begin
    case (state)
	   OFF:
		  begin
		    if (ignition) 
			   state <= WAIT;
		  end
		WAIT:
		  begin
		    if (ignition)
			   begin
			     if (hidden && brake) 
				    state <= ON;
			   end
			 else state <= OFF; 
		  end
		ON:
		  begin
		    if (~ignition) 
			   state <= OFF;
		  end
    endcase
  end
  
  assign power = (state == ON);
  


endmodule
