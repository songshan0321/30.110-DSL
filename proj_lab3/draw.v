`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:57:00 11/02/2018 
// Design Name: 
// Module Name:    draw 
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
module draw_box
 #(parameter WIDTH=200, // default width: 200 pixels
 HEIGHT=16, // default height: 64 pixels
 COLOR=8'b111_000_00) // default color: red

 (input pixel_clk,
 input [10:0] hcount, x,
 input [9:0] vcount, y,
 output reg [7:0] pixel);
 always @(hcount or vcount) begin
 if ((hcount >= x && hcount < (x+WIDTH)) &&
(vcount >= y && vcount < (y+HEIGHT)))
pixel = COLOR;
 else pixel = 0;
 end
endmodule