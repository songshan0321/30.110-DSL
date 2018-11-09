`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc 2011
// Engineer: Michelle Yu  
// Create Date:    08/26/2011
// Module Name:    dcm_all
// Project Name: 	 PmodPS2_Demo
// Target Devices: Nexys3 
// Tool version: 	 ISE 14.2
// Description: This file contains the design for a dcm that generates a 25MHz and a 
//					 40MHz clock from a 100MHz clock.
//
// Revision: 
// Revision 0.01 - File Created
// Revision 1.00 - Converted from VHDL to Verilog (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////////////

// =======================================================================================
// 										  Define Module
// =======================================================================================
module dcm_all(
		CLK,
		RST,
		CLKSYS,
//		CLK25,
		CLK40
);

// =======================================================================================
// 										Port Declarations
// =======================================================================================

			input   CLK;
			input   RST;
			output  CLKSYS;
//			output  CLK25;
			output  CLK40;

// =======================================================================================
// 							  Parameters, Registers, and Wires
// =======================================================================================   

			// Output registers
			wire CLKSYS;
			wire CLK25;
			wire CLK40;

			// architecture of dcm_all entity
			wire    GND = 1'b0;
			wire    CLKSYSint;
			wire    CLKSYSbuf;
			
			assign CLKSYS = CLKSYSbuf;

// =======================================================================================
// 							  		   Implementation
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
						.CLKDV_DIVIDE(4.0), 						  //  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
																		  //    			  7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
						.CLKFX_DIVIDE(5),   						  //  Can be any interger from 2 to 32
						.CLKFX_MULTIPLY(2), 						  //  Can be any integer from 2 to 32
						.CLKIN_DIVIDE_BY_2("FALSE"), 			  //  TRUE/FALSE to enable CLKIN divide by two feature
						.CLKIN_PERIOD(10000.0),          	  //  Specify period of input clock (ps)
						.CLKOUT_PHASE_SHIFT("NONE"), 			  //  Specify phase shift of NONE, FIXED or VARIABLE
						.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), //  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
																		  //     	an integer from 0 to 15
						.DFS_FREQUENCY_MODE("LOW"),     	  	  //  HIGH or LOW frequency mode for frequency synthesis
						.DLL_FREQUENCY_MODE("LOW"),     	  	  //  HIGH or LOW frequency mode for DLL
						.DUTY_CYCLE_CORRECTION("TRUE"), 		  //  Duty cycle correction, TRUE or FALSE
						.FACTORY_JF(16'hC080),          	  	  //  FACTORY JF Values
						.PHASE_SHIFT(0),        			     //  Amount of fixed phase shift from -255 to 255
						.STARTUP_WAIT("FALSE")					  //  Delay configuration DONE until DCM LOCK, TRUE/FALSE
			)
			DCM_inst(
						.CLK0(CLKSYSint),   						  // 0 degree DCM CLK ouptput
						.CLK180(),   								  // 180 degree DCM CLK output
						.CLK270(),   								  // 270 degree DCM CLK output
						.CLK2X(),   								  // 2X DCM CLK output
						.CLK2X180(),  								  // 2X, 180 degree DCM CLK out
						.CLK90(),  									  // 90 degree DCM CLK output
						.CLKDV(), //(CLK25),   							  // Divided DCM CLK out (CLKDV_DIVIDE)
						.CLKFX(CLK40),   							  // DCM CLK synthesis out (M/D)
						.CLKFX180(),   							  // 180 degree CLK synthesis out
						.LOCKED(),   								  // DCM LOCK status output
						.PSDONE(),   								  // Dynamic phase adjust done output
						.STATUS(),   								  // 8-bit DCM status bits output
						.CLKFB(CLKSYSbuf),   					  // DCM clock feedback
						.CLKIN(CLK),   							  // Clock input (from IBUFG, BUFG or DCM)
						.PSCLK(GND),   							  // Dynamic phase adjust clock input
						.PSEN(GND),   								  // Dynamic phase adjust enable input
						.PSINCDEC(GND),   						  // Dynamic phase adjust increment/decrement
						.DSSEN(1'b0),
						.RST(RST)									  // DCM asynchronous reset input
			);
   
endmodule
