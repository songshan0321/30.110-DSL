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
	 
    output [2:0] vgaRed,
    output [2:0] vgaGreen,
    output [2:1] vgaBlue,
    output hsync,
    output vsync,
	 
    inout [7:0] ja,
    inout [7:0] jb,
    inout [7:0] jc,
    input [7:0] jd,
    inout [19:0] exp_io_n,
    inout [19:0] exp_io_p
    );

    // all unused outputs must be assigned
    assign vgaRed = 3'b111;
    assign vgaGreen = 3'b111;
    assign vgaBlue = 2'b11;
    assign hsync = 1'b1;
    assign vsync = 1'b1;
	 
  ////////////////////////////////////////////////////////////////////////////
  //
  // Reset Generation
  //
  // A shift register primitive is used to generate an active-high reset
  // signal that remains high for 16 clock cycles after configuration finishes
  // and the FPGA's internal clocks begin toggling.
  //
  ////////////////////////////////////////////////////////////////////////////
  wire reset;
  SRL16 reset_sr(.D(1'b0), .CLK(clk_100mhz), .Q(reset),
	         .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
  defparam reset_sr.INIT = 16'hFFFF;



  // next three lines turns the 7 seg display completely off
  // assign seg = 7'b111_1111; 	//output 0->6 = seg A->G ACTIVE LOW
  // assign dp = 1'b1; 				//decimal point ACTIVE LOW
  // assign dig = 4'hF;  			//selectives digits 0-3, ACTIVE LOW

//  assign dig = 4'b1110;          // use only digit 0
  //
  
//  assign led = switch;  // provide feedback
  


//////////////////////////////////////////////////////////////////
// dcm_all is a general purpose digital clock manager. It is used
// to create clocks at desired frequncies and phases.
//
   wire clk_40mhz;
	wire clk_100mhz_buf;  // 100mhz buffered clock, not used
	
	
   dcm_all my_clocks(
				.CLK(clk_100mhz),
				.RST(reset),
				.CLKSYS(clk_100mhz_buf),
//				.CLK25(CLK25),
				.CLK40(clk_40mhz)
	);

//////////////////////////////////////////////////////////////////
  
	reg [25:0] counter;
	reg flash;
	
	always@(posedge clk_40mhz) begin
	  counter <= (counter == (40_000_000-1)) ? 0 : counter + 1;
	  flash <= (counter == (40_000_000-1)) ? !flash : flash;
	end
	
	assign seg[7] = flash;
	

// start of lab 3

//	        (input reset, clock, noisy,
//	         output reg clean);


// Sensor/Actuator	Labkit device
//
   debounce db_driver_door(1'b0,clk_40mhz, btn_left, driver_door);
   debounce db_pass_door(1'b0, clk_40mhz, btn_right, pass_door);
   debounce db_enter(1'b0, clk_40mhz, btn_enter, reprogram);
   debounce db_down(1'b0, clk_40mhz, btn_down, brake);
   debounce db_hidden(1'b0, clk_40mhz, btn_up, hidden);
	   
   wire [7:0]switch_sync;
   genvar i;
   generate   for(i=0; i<8; i=i+1) 
     begin: gen_modules  // generate 8 synchronize modules
       synchronize s(clk_40mhz,switch[i], switch_sync[i]);
     end
   endgenerate

   //assign led = switch_sync;  // provide feedback
	
	wire my_reset = switch_sync[0]||reset;
	wire ignition = switch_sync[7];
	

	
   wire [1:0] time_param_selector = switch_sync[5:4];
   wire [3:0] time_value =	switch_sync[3:0];
   wire load_start_timer;
   wire [3:0] count;
   wire [2:0] state;
	wire [3:0] time_remaining = (state==3'b000 || state==3'b100 || state==3'b101) ? 
							4'b0 : (4'hf-count);
	display_4hex  my_display(
	  .clk(clk_40mhz),
     .data({time_remaining,1'b0, state, 4'b0,switch_sync[3:0]}),
	  .seg(seg[6:0]),
     .strobe(dig)
    );
	 


fsm_gph fsm_rev1(.clock(clk_40mhz), .reprogram(reprogram), .time_param_sel(time_param_selector), 
    .time_value(time_value), .ignition(ignition), .driver_door(driver_door), .pass_door(pass_door),
    .state(state), .load_start_timer(load_start_timer), .count(count), .status_led(status_led), 
	 .debug_on(switch_sync[6]), .my_reset(my_reset));


fuel_pump security(.brake(brake), .hidden(hidden), .clock(clk_40mhz),
    .ignition(ignition), .power(led[6]));


   assign led[0] = pass_door;
   assign led[1] = driver_door;
   assign led[2] = reprogram;
   assign led[3] = my_reset;
   assign led[4] = hidden;
   assign led[5] = brake;
   assign led[7] = status_led; 	
//	assign led[6] = 1'b0;  
	
	wire out_880;
	

////////////////////////////////////////////////////////////////////
// sound effect section
// generate tones... instantiated two tones for have both available.
// could have just changed the constant with one module.


tones tone_880(clk_40mhz, 1'b0, 1'b0, 16'd22738, out_880);
tones tone_440(clk_40mhz, 1'b0, 1'b0, 16'd45456, out_440);
//
four_khz   pulse_4khz(.clock(clk_40mhz), .reset(1'b0), 
    .debug_on(1'b0), .pulse_out(out_4khz_pulse));
	
reg [15:0] tick = 0;
reg [15:0] sweep;	// variable divider for sweep frequency
	
	//generate freq sweep
	always @(posedge clk_40mhz)  
		begin
			if (out_4khz_pulse) begin
				tick <= tick + 1;
			   sweep <= (sweep <= 16'd10000) ? 16'd40000 : (sweep - 1);
				end
		end

tones tone_sweep(clk_40mhz, 1'b0, 1'b0, sweep, out_sweep);
//////////////////////////////////////////////////////////////////////



assign ja[1] = out_440; // 440 
assign ja[2] = out_880; // 880
assign ja[3] = (tick[11] ? out_440 : out_880); // alternating tones
assign ja[4] = out_sweep; // sweep
assign ja[5] = ((tick[15]||tick[14]) ? out_sweep : ja[3]); // alternating tones <=> sweep

assign ja[0] = (state == 3) ? ja[5] : 0;  // the siren
	
endmodule
