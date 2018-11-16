`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:51:37 04/11/2013 C
// Design Name: 
// Module Name:    labkit 
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
module labkit(
    input clk_100mhz,
    input [7:0] switch,
	 
    input btn_up,       // buttons, depress = high
    input btn_enter,
    input btn_left,
    input btn_down,
    input btn_right,
	 
    output [7:0] seg,   //output 0->6 = seg A->G ACTIVE LOW, 
                        //output 7 = decimal point, all active low
								
    output [3:0] dig,   //selects digits 0-3, ACTIVE LOW
    output [7:0] led,   // 1 turns on leds
	 
    output [2:0] vgared,
    output [2:0] vgagreen,
    output [2:1] vgablue,
    output hsync,
    output vsync,
	 
    inout [7:0] ja,
    inout [7:0] jb,
    inout [7:0] jc,
    input [7:0] jd,
    inout [19:0] exp_io_n,
    inout [19:0] exp_io_p
    );

//////////////////////////////////////////////////////////////////
// dcm_all is a general purpose digital clock manager. It is used
// to create clocks at desired frequncies and phases.
//
   wire clk_65mhz;
	wire clk_100mhz_buf;  // 100mhz buffered clock, not used
		
   dcm_all_v2 #(.DCM_DIVIDE(20), .DCM_MULTIPLY(13))
     	my_clocks(
				.CLK(clk_100mhz),
				.CLKSYS(clk_100mhz_buf),
//				.CLK25(CLK25),
				.CLK_out(clk_65mhz)
	);
//
//////////////////////////////////////////////////////////////////

   wire pixel_clk = clk_65mhz;  // clock for 1024 x 768 60hz resolution  

   assign led = switch;  // provide feedback

   wire [10:0] hcount;
   wire [9:0]  vcount;   
	wire blank, hblank;
		
	wire [7:0] pixel; //,paddle_pix,ball;
	
	//assign pixel = paddle_pix | ball;
	
	assign vgared = blank ? pixel[7:5] : 3'b0;
	assign vgagreen = blank ? pixel[4:2] : 3'b0;
	assign vgablue = blank ? pixel[1:0] : 2'b0;
	
	debounce  db_up(.reset(reset), .clock(pixel_clk), .noisy(btn_up), .clean(up));			 
	debounce  db_down(.reset(reset), .clock(pixel_clk), .noisy(btn_down), .clean(down));  
	debounce  db_enter(.reset(1'b0), .clock(pixel_clk), .noisy(btn_enter), .clean(enter)); 
	
   assign reset = enter;
	
   vga_general video_driver(.pixel_clk(pixel_clk),.hcount(hcount), .vcount(vcount),
		.hsync(hsync1),.vsync(vsync1), .blank(blank1), .hblank(hblank1));

   wire [7:0] pong_pixel;
	
	reg [7:0] rgb;
	reg hs, vs, b;
   
	wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount==767);
	
   always @(posedge pixel_clk) begin
//     case (switch[7:6])
     case (switch[1:0])
		2'b00: begin   // checkerboard
		         hs <= phsync;
					vs <= pvsync;
					b <= pblank;
					rgb <= pong_pixel;
				 end
		2'b01:	 begin  // 1 pixel outline of visible area (white)
		         hs <= hsync1;
					vs <= vsync1;
					b <= blank1;
					rgb <= {{8{border}}};
				 end
		2'b10:  begin  // color bars
		         hs <= hsync1;
					vs <= vsync1;
					b <= blank1;
					rgb <= {{3{hcount[8]}}, {3{hcount[7]}}, {2{hcount[6]}}};				
             end
		2'b11: begin   // send the pong pixels through
		         hs <= phsync;
					vs <= pvsync;
					b <= pblank;
					rgb <= pong_pixel;
				 end
		 endcase
	  end
				 
               
		
   assign pixel = rgb; //{{3{hcount[8]}}, {3{hcount[7]}}, {2{hcount[6]}}};	//rgb;
	assign blank = b;
	assign vsync = vs;
	assign hsync = hs;	
	
   pong_game psolution(.pixel_clk(pixel_clk), .reset(reset), .up(up), .down(down), .pspeed(switch[7:4]),
	    .hcount(hcount), .vcount(vcount), .hsync(hsync1), .vsync(vsync1), .blank(blank1),
		 .phsync(phsync), .pvsync(pvsync), .pblank(pblank), .pixel(pong_pixel));
	

//////////////////////////////////////////////////////////////////
// 
// just show counter working as a system check - not necessary.
	reg [30:0] counter;
	
	always@(posedge pixel_clk) begin
	  counter <=  counter + 1;
	end
	
	assign seg[7] = 1'b0; // turn off decimal point

	display_4hex  my_display(
	  .clk(pixel_clk),
     .data(counter[30:15]),
	  .seg(seg[6:0]),
     .strobe(dig)
    );
//
//////////////////////////////////////////////////////////////////
	
endmodule

////////////////////////////////////////////////////////////////////////////////
//
// pong_game: the game itself!
//
////////////////////////////////////////////////////////////////////////////////

module pong_game (
   input pixel_clk,	// 65MHz clock
   input reset,		// 1 to initialize module
   input up,		// 1 when paddle should move up
   input down,  	// 1 when paddle should move down
   input [3:0] pspeed,  // puck speed in pixels/tick 
   input [10:0] hcount,	// horizontal index of current pixel (0..1023)
   input [9:0]  vcount, // vertical index of current pixel (0..767)
   input hsync,		// XVGA horizontal sync signal (active low)
   input vsync,		// XVGA vertical sync signal (active low)
   input blank,		// XVGA blanking (1 means output black pixel)
 	
   output phsync,	// pong game's horizontal sync
   output pvsync,	// pong game's vertical sync
   output pblank,	// pong game's blanking
   output [7:0] pixel	// pong game's pixel  // r=7:5, g=4:2, b=1:0 
   );

////////////////////////////////////////////////////////////////////	
// need to take care of the pipe line delays;
// round puck is delayed by two clock cycles
// paddle_pix, hsync, vsync, pblank are delayed by two clock cycles

  reg [15:0] paddle_pix_delay;
  reg [1:0] hsync_delay, vsync_delay, blank_delay;
  
  always @(posedge pixel_clk) 
  begin
	 paddle_pix_delay <= {paddle_pix_delay[7:0],paddle_pix};
    hsync_delay <= {hsync_delay[0],hsync};
	 vsync_delay <= {vsync_delay[0],vsync};
	 blank_delay <= {blank_delay[0],blank};
  end
 
   assign phsync = hsync_delay[1];
   assign pvsync = vsync_delay[1];
   assign pblank = blank_delay[1]; 
	assign pixel = paddle_pix_delay[15:8] | ball_1 | ball_2;
  
////////////////////////////////////////////////////////////////////	
 
	// draw paddle
   parameter PADDLE_WIDTH = 16;
	parameter PADDLE_HEIGHT = 128;
   parameter PADDLE_X = 28;
   wire [9:0] paddle_y;
	
	draw_box #(.WIDTH(PADDLE_WIDTH), .HEIGHT(PADDLE_HEIGHT), .COLOR(8'b000_111_00)) // green
	   paddle (.pixel_clk(pixel_clk), .hcount(hcount), .vcount(vcount),
		.x(PADDLE_X), .y(paddle_y), .pixel(paddle_pix));


//////////////////////////////////////////////////////////////////
// create a pulse every vertical refresh

	reg vsync_delayed;    
	always @(posedge pixel_clk)
	  vsync_delayed <= vsync;
	assign vsync_pulse = vsync_delayed && ~vsync;
//
//////////////////////////////////////////////////////////////////


			 			
	wire stop;  // used to halt the game
	
   move_paddle paddle_motion(.pixel_clk(pixel_clk), .vsync_pulse(vsync_pulse),
		.up(up), .down(down), .paddle_y(paddle_y), .reset(reset), .stop(stop));

	
	
	wire [4:0] speed_x, speed_y;
	
	assign speed_x = pspeed[3:2]*2;
	assign speed_y = pspeed[1:0]*2;

   parameter BALL_SIZE = 20;
   parameter MAX_BALL_Y = 767 - BALL_SIZE; 
   parameter MIN_BALL_Y = 1;
   parameter MAX_BALL_X = 1023 - BALL_SIZE;
	

	
	reg ball_up, ball_right;
	
	// fixed ball y movement
	wire [9:0]  new_ball_y = ball_y;


//   assign stop = ball_x + 1 > MAX_BALL_X + BALL_SIZE; // halt the game when puck touches left edge

//////////////////////////////////////////////////////////////////	
// use to draw a square puck

//	draw_box #(.WIDTH(BALL_SIZE), .HEIGHT(BALL_SIZE), .COLOR(8'b111_111_11))
//	   create_ball (.pixel_clk(pixel_clk), .hcount(hcount), .vcount(vcount),
//		.x(ball_x), .y(ball_y), .pixel(ball));

//////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////
	// create balls
	wire [7:0] ball_1,ball_2;

	// create ball 1
	wire [9:0] ball_y = (767-BALL_SIZE) / 2; 
	wire [10:0] ball_x;
   round_piped round_puck1(.pixel_clk(pixel_clk), .rx(ball_x),
	   .hcount(hcount), .ry(ball_y), .vcount(vcount), .rpixel(ball_1));
		
	// move ball 1
	move_ball ball_1_motion(.pixel_clk(pixel_clk), .vsync_pulse(vsync_pulse),
		.ball_x(ball_x), .reset(reset), .stop(stop));
		
	// create ball 2
	wire [9:0] ball_y2 = (767-BALL_SIZE) / 4; 
	wire [10:0] ball_x2;
   round_piped round_puck2(.pixel_clk(pixel_clk), .rx(ball_x2),
	   .hcount(hcount), .ry(ball_y2), .vcount(vcount), .rpixel(ball_2));
		
	// move ball 2
	move_ball ball_2_motion(.pixel_clk(pixel_clk), .vsync_pulse(vsync_pulse),
		.ball_x(ball_x2), .reset(reset), .stop(stop));
//////////////////////////////////////////////////////////////////

	wire paddle_range1 = ((ball_y+BALL_SIZE)>= paddle_y) && 
				(ball_y<paddle_y+PADDLE_HEIGHT);
		
endmodule

//////////////////////////////////////////////////////////////////////
//
// draw_box: generate rectangle on screen
//
//////////////////////////////////////////////////////////////////////
module draw_box
	#(parameter WIDTH=200, // default width: 200 pixels
					HEIGHT=16, // default height: 64 pixels
					COLOR=8'b111_000_00) // default color: red
	(input pixel_clk,
		input [10:0] hcount, x,
		input [9:0] vcount, y,
		output reg [7:0] pixel);
		always @(hcount or vcount) 
			begin
				if ((hcount >= x && hcount < (x+WIDTH)) &&
					(vcount >= y && vcount < (y+HEIGHT)))
					pixel = COLOR;
				else pixel = 0;
			end
endmodule
///////////////////////////////////////////////////////////////////

////////////////////move paddle////////////////////////////// INPUT2
module move_paddle(pixel_clk, vsync_pulse, up, down, stop, reset, paddle_y);
	output paddle_y;
	input pixel_clk, vsync_pulse, up, down, stop, reset;
	reg[9:0] paddle_y;
	
	parameter step = 4;
	parameter MIN_PADDLE_Y = step;
	parameter MAX_PADDLE_Y = 767 - 128;
	
	 
	always @(posedge vsync_pulse)
	  begin
		if (reset)
			paddle_y <= (767-128)/2;
		else if (up & ~stop & (paddle_y > MIN_PADDLE_Y)) 
			paddle_y <= paddle_y - step;
		else if (down & ~stop & (paddle_y <= MAX_PADDLE_Y))
			paddle_y <= paddle_y + step;
	  end
		
endmodule
///////////////////////////////////////////////////////////////////////

////////////////////move ball////////////////////////////// 
module move_ball(pixel_clk, vsync_pulse, stop, reset, ball_x);
	output ball_x;
	input pixel_clk, vsync_pulse, stop, reset;
	reg[10:0] ball_x=1023;
	
	parameter step = 4;
	 
	always @(posedge vsync_pulse)
	  begin
		if (reset)
			ball_x <= 1023;
		else if (~stop & (ball_x <=  1023) & (ball_x > 1))
			if (paddle_range1 && ball_x - step < PADDLE_X+PADDLE_WIDTH) // if ball touches paddle
				begin
				ball_x <= 0;
				end
			else
				ball_x <= ball_x - step;
	  end
		
endmodule
///////////////////////////////////////////////////////////////////////

//////////////////////Draw round puck/////////////////////////////////////Input3
module round_piped
  #(parameter ball_size=20, // default width: 20 pixels
					COLOR=8'b111_111_11) // default color: white
	(input pixel_clk,
		input [10:0] hcount, rx,
		input [9:0] vcount, ry,
		output reg [7:0] rpixel);
		
	reg [19:0] sq_figure [0:19];
	wire [4:0] sq_fig_x;
	wire [4:0] sq_fig_y;
	
	assign sq_fig_x = hcount - rx; // our figure's x axis when in square boundary
	assign sq_fig_y = vcount - ry; // our figure's y axis when in square boundary
		
	initial begin //while RESET is high init counters
	  sq_figure[0][19:0] <= 20'b00000000000000000000;
	  sq_figure[1][19:0] <= 20'b00000001111100000000;
	  sq_figure[2][19:0] <= 20'b00000111111111000000;
	  sq_figure[3][19:0] <= 20'b00011111111111110000;
	  sq_figure[4][19:0] <= 20'b00111111111111111000;
	  sq_figure[5][19:0] <= 20'b00111111111111111000;
	  sq_figure[6][19:0] <= 20'b01111111111111111100;
	  sq_figure[7][19:0] <= 20'b01111111111111111100;
	  sq_figure[8][19:0] <= 20'b11111111111111111110;
	  sq_figure[9][19:0] <= 20'b11111111111111111110;
	  sq_figure[10][19:0] <= 20'b11111111111111111110;
	  sq_figure[11][19:0] <= 20'b11111111111111111110;
	  sq_figure[12][19:0] <= 20'b11111111111111111110;
	  sq_figure[13][19:0] <= 20'b01111111111111111100;
	  sq_figure[14][19:0] <= 20'b01111111111111111100;
	  sq_figure[15][19:0] <= 20'b00111111111111111000;
	  sq_figure[16][19:0] <= 20'b00111111111111111000;
	  sq_figure[17][19:0] <= 20'b00011111111111110000;
	  sq_figure[18][19:0] <= 20'b00000111111111000000;
	  sq_figure[19][19:0] <= 20'b00000001111100000000;
	end
	
	always @(hcount or vcount)
		begin
			if ((hcount >= rx && hcount < (rx+ball_size)) && (vcount >= ry && vcount < (ry+ball_size)))
			  begin
				if(sq_figure[sq_fig_y][sq_fig_x] == 1)
					rpixel = COLOR;
				else rpixel = 0;
			  end
			else rpixel = 0;
		end
endmodule
////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Gim P. Hom 3/22/2007
// 
// Create Date:    17:51:37 03/11/2007 
// Design Name: 
// Module Name:    vga_general 
// Project Name: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_general(
    input pixel_clk, 
    output reg [10:0] hcount,
    output reg [9:0] vcount,
    output blank,
    output hblank,	 
    output  hsync, 
    output  vsync
);	 
/*   //reg  hblank=1;
	assign vclock = pixel_clk;
	
   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   reg vblank;
   wire hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount == 1023);    
   assign hsyncon = (hcount == 1047);
   assign hsyncoff = (hcount == 1183);
   assign hreset = (hcount == 1343);

   // vertical: 806 lines total
   // display 768 lines
   wire vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount == 767);    
   assign vsyncon = hreset & (vcount == 776);
   assign vsyncoff = hreset & (vcount == 782);
   assign vreset = hreset & (vcount == 805);

   // sync and blanking
   wire next_hblank,next_vblank;
   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   always @(posedge vclock) begin
      hcount <= hreset ? 0 : hcount + 1;
      hblank <= next_hblank;
      hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low

      vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
      vblank <= next_vblank;
      vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low

      blank <= next_vblank | (next_hblank & ~hreset);
   end*/

	 wire vblank;
	 
 
	 // 1024 x 768 @ 60hz;  alternate resolution = 640x480 75hz
	 parameter hfp = 24;  //24;  // 16;  
	 parameter hsy = 136;  //136; // 96;
	 parameter hbp = 160;  //160; // 48;
	 
	 parameter vfp = 3;  //3;  //  11;
	 parameter vsy = 6;   //6;  //  2;
	 parameter vbp = 29;  //29; //  32;
	 
	 parameter hsize = 1023; //1023; //639;  // there are 640 pixels counting 0
	 parameter vsize = 767; //767; //479;  // similarly there are 480 lines counting line 0
	 
	 wire  h_end = (hcount == (hsize + hfp + hsy + hbp));
	 wire  v_end = (vcount == (vsize + vfp + vsy + vbp));
	 
	 assign hsync = ((hcount < hsize + hfp) || (hcount > hsize + hfp + hsy));
	 assign vsync = ((vcount < vsize + vfp) || (vcount > vsize + vfp + vsy));
	 
	 assign hblank = (hcount <= hsize);
	 assign vblank = (vcount <= vsize);
	 
	 assign blank = hblank && vblank;
	 
	 always @(posedge pixel_clk)
	    begin
		 hcount <= h_end ? 0 : hcount + 1;
		 vcount <= h_end ? (v_end ? 0 : vcount + 1) : vcount;  
		 end
		 
endmodule

// Switch Debounce Module
// use your system clock for the clock input
// to produce a synchronous, debounced output
module debounce #(parameter DELAY=400000)   // .01 sec with a 49Mhz clock
	        (input reset, clock, noisy,
	         output reg clean);

   reg [19:0] count;
   reg new;

   always @(posedge clock)
     if (reset)
       begin
	  count <= 0;
	  new <= noisy;
	  clean <= noisy;
       end
     else if (noisy != new)
       begin
	  new <= noisy;
	  count <= 0;
       end
     else if (count == DELAY)
       clean <= new;
     else
       count <= count+1;
      
endmodule

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


//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc 2011
// Engineer: Michelle Yu  
// Create Date:    08/26/2011
// Module Name:    dcm_all
// Project Name:     PmodPS2_Demo
// Target Devices: Nexys3 
// Tool version:     ISE 14.2
// Description: This file contains the design for a dcm that generates a 25MHz and a 
//                40MHz clock from a 100MHz clock.
//
// Revision: 
// Revision 0.01 - File Created
// Revision 1.00 - Converted from VHDL to Verilog (Josh Sackos)
// Revision 2.00 - removed CLK25, add parameters for divide/multiply
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
//                                 Define Module
// =======================================================================================
module dcm_all_v2  #(parameter DCM_DIVIDE = 4,
                               DCM_MULTIPLY = 2)
     (
      CLK,
//    RST,
      CLKSYS,
//      CLK25,
      CLK_out
);

// =======================================================================================
//                               Port Declarations
// =======================================================================================

         input   CLK;
//         input   RST;
         output  CLKSYS;
//         output  CLK25;
         output  CLK_out;

// =======================================================================================
//                        Parameters, Registers, and Wires
// =======================================================================================   

         // Output registers
         wire CLKSYS;
         wire CLK25;
         wire CLK_out;

         // architecture of dcm_all entity
         wire    GND = 1'b0;
         wire    CLKSYSint;
         wire    CLKSYSbuf;
         
         assign CLKSYS = CLKSYSbuf;

// =======================================================================================
//                                 Implementation
// =======================================================================================   

         // buffer system clock and wire to dcm feedback
         BUFG BUFG_clksys(
                  .O(CLKSYSbuf),
                  .I(CLKSYSint)
         );

         // Instantiation of the DCM device primitive.
         // Feedback is not used.
         // Clock multiplier is 2
         // Clock divider is 5
         // 100MHz * 2/5 = 40MHz   
         // The following generics are only necessary if you wish to change the default behavior.
         DCM #(
                  .CLK_FEEDBACK("1X"),
                  .CLKDV_DIVIDE(4.0),                   //  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
                                                        //             7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
                  .CLKFX_DIVIDE(DCM_DIVIDE),            //  Can be any interger from 2 to 32
                  .CLKFX_MULTIPLY(DCM_MULTIPLY),        //  Can be any integer from 2 to 32
                  .CLKIN_DIVIDE_BY_2("FALSE"),          //  TRUE/FALSE to enable CLKIN divide by two feature
                  .CLKIN_PERIOD(10000.0),               //  Specify period of input clock (ps)
                  .CLKOUT_PHASE_SHIFT("NONE"),          //  Specify phase shift of NONE, FIXED or VARIABLE
                  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), //  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                                        //        an integer from 0 to 15
                  .DFS_FREQUENCY_MODE("LOW"),           //  HIGH or LOW frequency mode for frequency synthesis
                  .DLL_FREQUENCY_MODE("LOW"),           //  HIGH or LOW frequency mode for DLL
                  .DUTY_CYCLE_CORRECTION("TRUE"),       //  Duty cycle correction, TRUE or FALSE
                  .FACTORY_JF(16'hC080),                //  FACTORY JF Values
                  .PHASE_SHIFT(0),                      //  Amount of fixed phase shift from -255 to 255
                  .STARTUP_WAIT("FALSE")                //  Delay configuration DONE until DCM LOCK, TRUE/FALSE
         )
         DCM_inst(
                  .CLK0(CLKSYSint),                     // 0 degree DCM CLK ouptput
                  .CLK180(),                            // 180 degree DCM CLK output
                  .CLK270(),                            // 270 degree DCM CLK output
                  .CLK2X(),                             // 2X DCM CLK output
                  .CLK2X180(),                          // 2X, 180 degree DCM CLK out
                  .CLK90(),                             // 90 degree DCM CLK output
                  .CLKDV(), //(CLK25),                  // Divided DCM CLK out (CLKDV_DIVIDE)
                  .CLKFX(CLK_out),                      // DCM CLK synthesis out (M/D)
                  .CLKFX180(),                          // 180 degree CLK synthesis out
                  .LOCKED(),                            // DCM LOCK status output
                  .PSDONE(),                            // Dynamic phase adjust done output
                  .STATUS(),                            // 8-bit DCM status bits output
                  .CLKFB(CLKSYSbuf),                    // DCM clock feedback
                  .CLKIN(CLK),                          // Clock input (from IBUFG, BUFG or DCM)
                  .PSCLK(GND),                          // Dynamic phase adjust clock input
                  .PSEN(GND),                           // Dynamic phase adjust enable input
                  .PSINCDEC(GND),                       // Dynamic phase adjust increment/decrement
                  .DSSEN(1'b0),
                  .RST (1'b0)  //(RST)                  // DCM asynchronous reset input
         );
   
endmodule
