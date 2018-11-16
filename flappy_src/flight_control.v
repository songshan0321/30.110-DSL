`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:28:43 11/16/2018 
// Design Name: 
// Module Name:    flight_control
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
module flight_control(Clk, reset, Start, Ack, Stop, BtnU, BtnD, Bird_X_L, Bird_X_R, Bird_Y_T, Bird_Y_B,
   q_Initial, q_Flight, q_Stop, PositiveSpeed, NegativeSpeed );

input 	Clk, reset, Start, Ack, Stop;
input 	BtnU, BtnD;

//output signed [9:0]	VertSpeed; // some amount of pixels per clock
output [9:0] Bird_X_L;
output [9:0] Bird_X_R;
output [9:0] Bird_Y_T;
output [9:0] Bird_Y_B;
output [9:0] PositiveSpeed;
output [9:0] NegativeSpeed;
output q_Initial, q_Flight, q_Stop;

reg [2:0] state;
assign {q_Stop, q_Flight, q_Initial} = state;

reg [9:0] PositiveSpeed;
reg[9:0] pos_temp;
reg [9:0] NegativeSpeed;

reg [9:0] Bird_X_L;
reg [9:0] Bird_X_R;
reg [9:0] Bird_Y_T;
reg [9:0] Bird_Y_B;

localparam
			QInitial = 3'b001,
			QFlight	= 3'b010,
			QStop 	= 3'b100,
			UNK		= 3'bXXX;

//parameter JUMP_VELOCITY = 10; // some amount of pixels per clock
//parameter GRAVITY = 1; // change to some number of pixels per clock

reg j;
parameter step = 4;
parameter MIN_BIRD_Y = step;
parameter MAX_BIRD_Y = 767 - 128;

always @ (posedge Clk, posedge reset)
begin	
	if(reset)
	begin
		state <= QInitial;
	end
	else
	
	begin
		case(state)
		
			QInitial:
			begin
				if(Start) // we're startin' folks
					state <= QFlight;
					
				PositiveSpeed <= 10'd0;
				NegativeSpeed <= 10'd0;
				Bird_X_L <= 10'd230; //10'd300;
				Bird_X_R <= 10'd249; //10'd300;
				Bird_Y_T <= 10'd220;//10'd240;
				Bird_Y_B <= 10'd239; //10'd300;
			end	
			
			QFlight:
			begin
				if(Stop)
					state <= QStop;
				
				else 
				begin
					j <= 0;
					// BIRD POSITIONING LOGIC 
					if (BtnU & Bird_Y_T > MIN_BIRD_Y)
						begin
						Bird_Y_T <= Bird_Y_T - step;
						Bird_Y_B <= Bird_Y_B - step;
						end
					else if (BtnD & Bird_Y_B < MAX_BIRD_Y)
						begin
						Bird_Y_T <= Bird_Y_T + step;
						Bird_Y_B <= Bird_Y_B + step;
						end
				end
			end	
			
			QStop:
			begin
				if(Ack)
					state <= QInitial;
			end

			default:
				state <= UNK;
		endcase
	end
end

endmodule
