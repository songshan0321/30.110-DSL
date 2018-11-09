`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date:    20:23:31 04/01/2012
// Design Name: 
// Module Name:    fsm_gph 
//
//		The FSM includes both the FSM and time parameter module. Rather than
//    passing the "interval" and decode the time value, I pass the time value
//    directly.  Passing interval slightly cleaner.
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
		
module fsm_gph
   (input clock, reprogram,
	 input [1:0] time_param_sel,
	 input [3:0] time_value,
	 input ignition, driver_door, pass_door,
	 output reg [3:0] state,
	 output load_start_timer,
	 output [3:0] count,
	 output reg status_led,
	 input debug_on, my_reset
	 );
	 

	 
	   // state assignments
  parameter ARMED = 0;
  parameter DRIVER_OPEN = 1;
  parameter PASS_OPEN = 2;
  parameter SIREN_ON = 3;
  parameter DISARMED = 4;
  parameter ARM_DELAY_WAIT = 5;
  parameter ARM_DELAY_TIMING = 6;
  
  reg [3:0] T_DRIVER_DELAY = 8;
  reg [3:0] T_PASSENGER_DELAY =15;
  reg [3:0] T_ALARM_ON = 10; 
  reg [3:0] T_ARM_DELAY = 6;
  reg [3:0] num_sec; 
  
  reg old_driver_door, old_pass_door, old_both_door;
  reg load_start_timer;
  wire expired_pulse;

  assign driver_door_open = driver_door && ~old_driver_door;
  assign pass_door_open = pass_door && ~old_pass_door;
  assign both_door_closed = old_both_door && ~(driver_door || pass_door);
  
  wire one_hz;
  
  always @ (posedge clock)
  if (my_reset) begin
  			state <= ARMED;
			T_DRIVER_DELAY <= 8;
			T_PASSENGER_DELAY <=15;
			T_ALARM_ON <= 10; 
			T_ARM_DELAY <= 6;
			end
  else
			
  begin
    old_driver_door <= driver_door;
	 old_pass_door <= pass_door;
	 old_both_door <= (driver_door || pass_door);
    case (state)
    ARMED:      	begin  //////////////////////////////////////////////Armed state/////////////////   Input 1
							// Make it blink every 2 seconds
							if (load_start_timer == 0 && ~counting)
								begin
									load_start_timer <= 1;
									num_sec <= 2;
								end
								
							if (load_start_timer == 1)
								load_start_timer <= 0; // start counting down for 2 seconds
								
							if (expired_pulse)
									status_led <= ~status_led;
							
							if (ignition)
								state <= DISARMED;
							else // ~ignition
								if (driver_door_open)
									begin
										state <= DRIVER_OPEN;
										load_start_timer <= 1;
										num_sec <= T_DRIVER_DELAY;
									end
								else if (pass_door_open)
									begin
										state <= PASS_OPEN;
										load_start_timer <= 1;
										num_sec <= T_PASSENGER_DELAY;
									end
						end
						
						
	 PASS_OPEN:  	begin  //////////////////////////////////////////////Passenger door open/////////////////   Input 2
							status_led <= 1;
							load_start_timer <= 0;
							if (ignition)
								state <= DISARMED;
							else // ~ignition
								if (expired_pulse) // T_PASSENGER_DELAY <= 0
									begin
										state <= SIREN_ON;
										load_start_timer <= 1;
										num_sec <= T_ALARM_ON;
									end
						end
						
						
	 DRIVER_OPEN:  begin   //////////////////////////////////////////////driver door open/////////////////   Input 3
							status_led <= 1;
							load_start_timer <= 0;
							if (ignition)
								state <= DISARMED;
							else // ~ignition
								if (expired_pulse) // T_DRIVER_DELAY <= 0
									begin
										state <= SIREN_ON;
										load_start_timer <= 1;
										num_sec <= T_ALARM_ON;
									end
						end
						
	 DISARMED:     begin   //////////////////////////////////////////////disarmed state/////////////////   Input 4
							status_led <= 0;
							if (~ignition && driver_door_open)
								state <= ARM_DELAY_WAIT;
						end
						
						
	 SIREN_ON: 		begin    //////////////////////////////////////////////Sound alarm status/////////////////   Input 5
							status_led <= 1;
							load_start_timer <= 0;
							if (ignition)
								state <= DISARMED;
							else // ~ignition
								if (expired_pulse) // T_ALARM_ON <= 0
									state <= ARMED;
						end
						
						
   ARM_DELAY_WAIT:begin  // wait until a door is opened and both are closed
						status_led <= 0;
						if (ignition) state <= DISARMED;
						   else if (both_door_closed) begin
								state <= ARM_DELAY_TIMING;
								load_start_timer <= 1;
								num_sec <= T_ARM_DELAY;
								end
						end
						
						
	 ARM_DELAY_TIMING:
						begin
						status_led <= 0;
						load_start_timer <= 0;
						if (ignition) 
							state <= DISARMED;
						else if (driver_door || pass_door) 
							state <= ARM_DELAY_WAIT;
						else if (expired_pulse) 
							state <= ARMED;
						end
			
			
    default:		state <= ARMED;
    endcase
	 if (reprogram) begin
			state <= ARMED;
			if (time_param_sel == 0) T_ARM_DELAY <= time_value;
				else if (time_param_sel == 1) T_DRIVER_DELAY <= time_value;
				else if (time_param_sel == 2) T_PASSENGER_DELAY <= time_value;
				else T_ALARM_ON <= time_value;
			end
  end



timer1 timer_fsm(.clock(clock), .load_start_timer(load_start_timer), .clear(1'b0), 
      .value(num_sec), .counting(counting), .expired(expired),
		.expired_pulse(expired_pulse), .one_hz(one_hz), .count(count), 
		.debug_on(debug_on));


endmodule 