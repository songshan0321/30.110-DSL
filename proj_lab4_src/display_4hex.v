`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:   g.p.hom
// Engineer: 
// 
// Create Date:    18:18:59 04/21/2013 
// Module Name:    display_4hex 

// Description:  Display 4 hex numbers on 7 segment display
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module display_4hex(
    input clk,                 // system clock
    input [15:0] data,         // 4 hex numbers, msb first
    output reg [6:0] seg,      // seven segment display output
    output reg [3:0] strobe    // digit strobe
    );

    localparam bits = 13;
     
    reg [bits:0] counter = 0;  // clear on power up
     
    wire [6:0] segments[15:0]; // 16 7 bit memorys
    assign segments[0]  = 7'b100_0000;
    assign segments[1]  = 7'b111_1001;
    assign segments[2]  = 7'b010_0100;
    assign segments[3]  = 7'b011_0000;
    assign segments[4]  = 7'b001_1001;
    assign segments[5]  = 7'b001_0010;
    assign segments[6]  = 7'b000_0010;
    assign segments[7]  = 7'b111_1000;
    assign segments[8]  = 7'b000_0000;
    assign segments[9]  = 7'b001_1000;
    assign segments[10] = 7'b000_1000;
    assign segments[11] = 7'b000_0011;
    assign segments[12] = 7'b010_0111;
    assign segments[13] = 7'b010_0001;
    assign segments[14] = 7'b000_0110;
    assign segments[15] = 7'b000_1110;
     
    always @(posedge clk) begin
      counter <= counter + 1;
      case (counter[bits:bits-1])
          2'b00: begin
                  seg <= segments[data[15:12]];
                  strobe <= 4'b0111;
                 end

          2'b01: begin
                  seg <= segments[data[11:8]];
                  strobe <= 4'b1011;
                 end

          2'b10: begin
                   seg <= segments[data[7:4]];
                   strobe <= 4'b1101;
                  end
          2'b11: begin
                  seg <= segments[data[3:0]];
                  strobe <= 4'b1110;
                 end
       endcase
      end

endmodule
