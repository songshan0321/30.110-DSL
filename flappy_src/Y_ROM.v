`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:05:03 04/10/2014 
// Design Name: 
// Module Name:    Y_ROM 
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
// This holds default heights (Y coordinates) for pipe obstacles.
// Coordinate is the top edge of the pipe. Bottom edge is calculated in obstacle logic.
//////////////////////////////////////////////////////////////////////////////////
module Y_ROM(I,
	YEdge0T, YEdge0B,
	YEdge1T, YEdge1B,
	YEdge2T, YEdge2B,
	YEdge3T, YEdge3B,
	YEdge4T, YEdge4B
	);
	
	parameter ET0 = 50;
	parameter ET1 = 100;
	parameter ET2 = 150;
	parameter ET3 = 110;
	parameter ET4 = 80;
	
	parameter EB0 = 300 - 50;
	parameter EB1 = 300 - 80;
	parameter EB2 = 300 - 70;
	parameter EB3 = 300 - 30;
	parameter EB4 = 300 - 20;
	
	input [2:0] I;
	
	output [9:0] YEdge0T;
	output [9:0] YEdge0B;
	
	output [9:0] YEdge1T;
	output [9:0] YEdge1B;
	
	output [9:0] YEdge2T;
	output [9:0] YEdge2B;
	
	output [9:0] YEdge3T;
	output [9:0] YEdge3B;
	
	output [9:0] YEdge4T;
	output [9:0] YEdge4B;

	reg [9:0] YEdge0T;
	reg [9:0] YEdge0B;
	
	reg [9:0] YEdge1T;
	reg [9:0] YEdge1B;
	
	reg [9:0] YEdge2T;
	reg [9:0] YEdge2B;
	
	reg [9:0] YEdge3T;
	reg [9:0] YEdge3B;
	
	reg [9:0] YEdge4T;
	reg [9:0] YEdge4B;	
 
   always @(I) //instead of always@(I)
         case (I)
            3'b000: 
				begin 
					YEdge0T <= ET0;
					YEdge0B <= EB0;
					YEdge1T <= ET1;
					YEdge1B <= EB1;
					YEdge2T <= ET2;
					YEdge2B <= EB2;
					YEdge3T <= ET3;
					YEdge3B <= EB3;
					YEdge4T <= ET4;
					YEdge4B <= EB4;
				end
            3'b001:
				begin 
					YEdge0T <= ET1;
					YEdge0B <= EB1;
					YEdge1T <= ET2;
					YEdge1B <= EB2;
					YEdge2T <= ET3;
					YEdge2B <= EB3;
					YEdge3T <= ET4;
					YEdge3B <= EB4;
					YEdge4T <= ET0;
					YEdge4B <= EB0;
				end
            3'b010:
				begin 
					YEdge0T <= ET2;
					YEdge0B <= EB2;
					YEdge1T <= ET3;
					YEdge1B <= EB3;
					YEdge2T <= ET4;
					YEdge2B <= EB4;
					YEdge3T <= ET0;
					YEdge3B <= EB0;
					YEdge4T <= ET1;
					YEdge4B <= EB1;
				end
            3'b011:
				begin 
					YEdge0T <= ET3;
					YEdge0B <= EB3;
					YEdge1T <= ET4;
					YEdge1B <= EB4;
					YEdge2T <= ET0;
					YEdge2B <= EB0;
					YEdge3T <= ET1;
					YEdge3B <= EB1;
					YEdge4T <= ET2;
					YEdge4B <= EB2;
				end
			3'b100:
				begin 
					YEdge0T <= ET4;
					YEdge0B <= EB4;
					YEdge1T <= ET0;
					YEdge1B <= EB0;
					YEdge2T <= ET1;
					YEdge2B <= EB1;
					YEdge3T <= ET2;
					YEdge3B <= EB2;
					YEdge4T <= ET3;
					YEdge4B <= EB3;
				end
            default:
				begin 
					YEdge0T <= 10'bXXXXXXXXXX;
					YEdge0B <= 10'bXXXXXXXXXX;
					YEdge1T <= 10'bXXXXXXXXXX;
					YEdge1B <= 10'bXXXXXXXXXX;
					YEdge2T <= 10'bXXXXXXXXXX;
					YEdge2B <= 10'bXXXXXXXXXX;
					YEdge3T <= 10'bXXXXXXXXXX;
					YEdge3B <= 10'bXXXXXXXXXX;
					YEdge4T <= 10'bXXXXXXXXXX;
					YEdge4B <= 10'bXXXXXXXXXX;
				end
         endcase	 

endmodule
