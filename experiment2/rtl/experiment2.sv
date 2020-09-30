/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module experiment2 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O              // VGA blue
);

`include "VGA_param.h"

logic resetn, enable;

// For VGA
logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic object_on;
logic object_on1;
logic object_on2;
logic object_on3;
logic object_on4;
logic object_on5;
logic object_on6;

assign resetn = ~SWITCH_I[17];

VGA_controller VGA_unit(
	.clock(CLOCK_50_I),
	.resetn(resetn),
	.enable(enable),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	// VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O)
);

// we emulate the 25 MHz clock by using a 50 MHz AND
// updating the registers every other clock cycle
assign VGA_CLOCK_O = enable;
always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		enable <= 1'b0;
	end else begin
		enable <= ~enable;
	end
end

// if the column counter is between columns 300 and 339
// and line counter is between rows 220 and 259 (inclusive)
// assert the "object_on" signal
always_comb begin

	object_on = 1'b0;
	object_on1 = 1'b0;
	object_on2 = 1'b0;
	object_on3 = 1'b0;
	object_on4 = 1'b0;
	object_on5 = 1'b0;
	object_on6 = 1'b0;
	
	if (pixel_X_pos >= 10'd300 && pixel_X_pos < 10'd340 && pixel_Y_pos >= 10'd220 && pixel_Y_pos < 10'd260) 
		object_on = 1'b1;
	else if (pixel_X_pos >= 10'd300 && pixel_X_pos < 10'd340 && pixel_Y_pos >= 10'd320 && pixel_Y_pos < 10'd360) 
		object_on1 = 1'b1;
	else if (pixel_X_pos >= 10'd10 && pixel_X_pos < 10'd50 && pixel_Y_pos >= 10'd220 && pixel_Y_pos < 10'd260) 
		object_on2 = 1'b1;
	else if (pixel_X_pos >= 10'd100 && pixel_X_pos < 10'd140 && pixel_Y_pos >= 10'd220 && pixel_Y_pos < 10'd260) 
		object_on3 = 1'b1;
	else if (pixel_X_pos >= 10'd300 && pixel_X_pos < 10'd340 && pixel_Y_pos >= 10'd400 && pixel_Y_pos < 10'd440) 
		object_on4 = 1'b1;
	else if (pixel_X_pos >= 10'd660 && pixel_X_pos < 10'd640 && pixel_Y_pos >= 10'd220 && pixel_Y_pos < 10'd260) 
		object_on5 = 1'b1;
	else if (pixel_X_pos >= 10'd300 && pixel_X_pos < 10'd380 && pixel_Y_pos >= 10'd110 && pixel_Y_pos < 10'd120) 
		object_on6 = 1'b1;
		
end

// the background is black and a white square is 
// displayed only if the "object_on" signal is asserted
always_comb begin
	VGA_red = 8'h00;
	VGA_green = 8'h00;
	VGA_blue = 8'h00;
	if (object_on == 1'b1) begin
		VGA_red = 8'hFF; 
		VGA_green = 8'hFF;
		VGA_blue = 8'hFF;
	end else if(object_on1 == 1'b1) begin
		VGA_red = 8'hFF; 
		VGA_green = 8'h00;
		VGA_blue = 8'h00;
	end else if(object_on2 == 1'b1) begin
		VGA_red = 8'h00; 
		VGA_green = 8'hFF;
		VGA_blue = 8'h00;
	end else if(object_on3 == 1'b1) begin
		VGA_red = 8'h0; 
		VGA_green = 8'h0;
		VGA_blue = 8'hFF;
	end else if(object_on4 == 1'b1) begin
		VGA_red = 8'hFF; 
		VGA_green = 8'h00;
		VGA_blue = 8'hFF;
	end else if(object_on5 == 1'b1) begin
		VGA_red = 8'hFF; 
		VGA_green = 8'hFF;
		VGA_blue = 8'h00;
	end else if(object_on6 == 1'b1) begin
		VGA_red = 8'h00; 
		VGA_green = 8'hFF;
		VGA_blue = 8'hFF;
	end
end

endmodule
