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

module experiment4 (
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
		output logic[7:0] VGA_BLUE_O,              // VGA blue

		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I                   // PS2 clock
);

integer i;

`include "VGA_param.h"
parameter SCREEN_BORDER_OFFSET = 32;
parameter DEFAULT_MESSAGE_LINE = 280;
parameter DEFAULT_MESSAGE_START_COL = 360;
parameter KEYBOARD_MESSAGE_LINE = 320;
parameter KEYBOARD_MESSAGE_START_COL = 360;
parameter COUNT_MESSAGE_LINE = 360;
parameter COUNT_MESSAGE_START_COL = 360;
logic resetn, enable;

logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic [5:0] character_address;
logic rom_mux_output;

logic screen_border_on;

assign resetn = ~SWITCH_I[17];

logic [3:0] numkey_presses[9:0];
logic [5:0] char_temp;
logic [3:0] max_presses;
logic [7:0] PS2_code;
logic [7:0]PS2_reg [14:0];
logic PS2_code_ready;

logic nokey_flag;
logic full_reg;

logic [3:0]data_counter;
logic PS2_code_ready_buf;
logic PS2_make_code;
logic [5:0]count_character0;
logic[5:0]count_character1;

// PS/2 controller
PS2_controller ps2_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

// Putting the PS2 code into a register
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		PS2_code_ready_buf <= 1'b0;
		for (i=0; i<15; i=i+1) begin
			PS2_reg[i] <= 8'd0;
		end
		data_counter <= 1'b0;
		for (i=0; i<10; i=i+1) begin
			numkey_presses[i] <= 1'b0;
		end
		nokey_flag <= 1'b0;
		// if no key is found
		max_presses <= 1'b0;
		// holds the max amount of presses
		char_temp <= 1'b0;
		// temp variable to hold char
		full_reg <= 1'b0;
		count_character0 <= 1'b0;
		// holds 0's column of character for BCD display
		count_character1 <= 1'b0;
		// holds 1's column of character for BCD display
	end else begin
		PS2_code_ready_buf <= PS2_code_ready;
		
		if(data_counter == 15) begin
			data_counter <= 1'd0;
			if(max_presses > 9)begin
				count_character1 <= 6'o61;
			end else begin
				count_character1 <= 6'o60;
			end
			case (max_presses)
				4'b00:   count_character0 <= 6'o60; // 0
				4'b0001:   count_character0 <= 6'o61; // 1
				4'b0010:   count_character0 <= 6'o62; // 2
				4'b0011:   count_character0 <= 6'o63; // 3
				4'b0100:   count_character0 <= 6'o64; // 4
				4'b0101:   count_character0 <= 6'o65; // 5
				4'b0110:   count_character0 <= 6'o66; // 6
				4'b0111:   count_character0 <= 6'o67; // 7
				4'b1000:   count_character0 <= 6'o70; // 8
				4'b1001:   count_character0 <= 6'o71; // 9
				4'b1010:   count_character0 <= 6'o60; // 10
				4'b1011:   count_character0 <= 6'o61; // 11
				4'b1100:   count_character0 <= 6'o62; // 12
				4'b1101:   count_character0 <= 6'o63; // 13
				4'b1110:   count_character0 <= 6'o64; // 14
				4'b1111:   count_character0 <= 6'o65; // 15
				default: count_character0 <= 6'o40; // space
			endcase
			if(max_presses == 1'b0) begin
				nokey_flag <= 1'b1;
			end
		end
		
		if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code) begin
			// scan code detected

			if(data_counter < 4'd15)begin
				nokey_flag <= 1'b0;
				if(PS2_code == 8'h45) begin
					PS2_reg[data_counter] <= PS2_code;
					// put key in register
					if(max_presses <= numkey_presses[0] + 1'b1 && 6'o60 >= char_temp)begin
						// check if the current count of the key is greater than the max counter
						max_presses <= numkey_presses[0] + 1'b1;
						char_temp <= 6'o60;
					end
					numkey_presses[0] <= numkey_presses[0] + 1'b1;
					
				end else if(PS2_code == 8'h16) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[1] + 1'b1 && 6'o61 >= char_temp)begin
						max_presses <= numkey_presses[1] + 1'b1;
						char_temp <= 6'o61;
					end
					numkey_presses[1] <= numkey_presses[1] + 1'b1;
					
				end else if(PS2_code == 8'h1E) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[2] + 1'b1 && 6'o62 >= char_temp)begin
						max_presses <= numkey_presses[2] +1'b1;
						char_temp <= 6'o62;
					end
					numkey_presses[2] <= numkey_presses[2] + 1'b1;
					
				end else if(PS2_code == 8'h26) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[3] + 1'b1 && 6'o63 >= char_temp)begin
						max_presses <= numkey_presses[3] + 1'b1;
						char_temp <= 6'o63;
					end
					numkey_presses[3] <= numkey_presses[3] + 1'b1;
					
				end else if(PS2_code == 8'h25) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[4] + 1'b1 && 6'o64 >= char_temp)begin
						max_presses <= numkey_presses[4] + 1'b1;
						char_temp <= 6'o64;
					end
					numkey_presses[4] <= numkey_presses[4] + 1'b1;
					
				end else if(PS2_code == 8'h2E) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[5] + 1'b1 && 6'o65 >= char_temp)begin
						max_presses <= numkey_presses[5] + 1'b1;
						char_temp <= 6'o65;
					end
					numkey_presses[5] <= numkey_presses[5] + 1'b1;
					
				end else if(PS2_code == 8'h36) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[6] + 1'b1 && 6'o66 >= char_temp)begin
						max_presses <= numkey_presses[6] + 1'b1;
						char_temp <= 6'o66;
					end
					numkey_presses[6] <= numkey_presses[6] + 1'b1;
					
				end else if(PS2_code == 8'h3D) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[7] + 1'b1 && 6'o67 >= char_temp)begin
						max_presses <= numkey_presses[7] + 1'b1;
						char_temp <= 6'o67;
					end
					numkey_presses[7] <= numkey_presses[7] + 1'b1;
					
				end else if(PS2_code == 8'h3E) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[8] + 1'b1 && 6'o70 >= char_temp)begin
						max_presses <= numkey_presses[8] + 1'b1;
						char_temp <= 6'o70;
					end
					numkey_presses[8] <= numkey_presses[8] + 1'b1;
					
				end else if(PS2_code == 8'h46) begin
					PS2_reg[data_counter] <= PS2_code;
					if(max_presses <= numkey_presses[9] + 1'b1 && 6'o71 >= char_temp)begin
						max_presses <= numkey_presses[9] + 1'b1;
						char_temp <= 6'o71;
					end
					numkey_presses[9] <= numkey_presses[9] + 1'b1;
					
				end else begin
					PS2_reg[data_counter] <= 8'h29;
				end
				
				data_counter <= data_counter + 1'd1;
				
			end 	
		end
	end
end




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

logic [2:0] delay_X_pos;

always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		delay_X_pos[2:0] <= 3'd0;
	end else begin
		delay_X_pos[2:0] <= pixel_X_pos[2:0];
	end
end

// Character ROM
char_rom char_rom_unit (
	.Clock(CLOCK_50_I),
	.Character_address(character_address),
	.Font_row(pixel_Y_pos[2:0]),
	.Font_col(delay_X_pos[2:0]),
	.Rom_mux_output(rom_mux_output)
);
// this experiment is in the 800x600 @ 72 fps mode
assign enable = 1'b1;
assign VGA_CLOCK_O = ~CLOCK_50_I;

always_comb begin
	screen_border_on = 0;
	if (pixel_X_pos == SCREEN_BORDER_OFFSET || pixel_X_pos == H_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_Y_pos >= SCREEN_BORDER_OFFSET && pixel_Y_pos < V_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
	if (pixel_Y_pos == SCREEN_BORDER_OFFSET || pixel_Y_pos == V_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_X_pos >= SCREEN_BORDER_OFFSET && pixel_X_pos < H_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
end

// Display text
always_comb begin

	character_address = 6'o40; // Show space by default
	
	// 8 x 8 characters
	if (pixel_Y_pos[9:3] == ((DEFAULT_MESSAGE_LINE) >> 3)) begin
		// Reach the section where the text is displayed
		case (pixel_X_pos[9:3])
			(DEFAULT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o14; // L
			(DEFAULT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o01; // A
			(DEFAULT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o02; // B
			(DEFAULT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) +  4: character_address = 6'o63; // 3			
			(DEFAULT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o05; // E
			(DEFAULT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o30; // X
			(DEFAULT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
			(DEFAULT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o22; // R
			(DEFAULT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o03; // C			
			(DEFAULT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o11; // I
			(DEFAULT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o23; // S
			(DEFAULT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o05; // E
			(DEFAULT_MESSAGE_START_COL >> 3) + 14: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) + 15: character_address = 6'o07; // G
			(DEFAULT_MESSAGE_START_COL >> 3) + 16: character_address = 6'o22; // R
			(DEFAULT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o17; // O
			(DEFAULT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o25; // U	
			(DEFAULT_MESSAGE_START_COL >> 3) + 19: character_address = 6'o20; // P
			(DEFAULT_MESSAGE_START_COL >> 3) + 20: character_address = 6'o40; // space
			(DEFAULT_MESSAGE_START_COL >> 3) + 21: character_address = 6'o64; // 4
			(DEFAULT_MESSAGE_START_COL >> 3) + 22: character_address = 6'o61; // 1
			default: character_address = 6'o40; // space
		endcase
	end
	
	if(nokey_flag == 1'b0) begin
		if (pixel_Y_pos[9:3] == ((COUNT_MESSAGE_LINE) >> 3)) begin
			// Reach the section where the text is displayed
			case (pixel_X_pos[9:3])
				(COUNT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o13; // K
				(COUNT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o05; // E
				(COUNT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o31; // Y
				(COUNT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) +  4: character_address = char_temp;		
				(COUNT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o20; // P
				(COUNT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o22; // R
				(COUNT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
				(COUNT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o23; // S
				(COUNT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o23; // S			
				(COUNT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o05; // E
				(COUNT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o04; // D
				(COUNT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) + 15: character_address = count_character1;
				(COUNT_MESSAGE_START_COL >> 3) + 16: character_address = count_character0;
				(COUNT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o24; // T
				(COUNT_MESSAGE_START_COL >> 3) + 19: character_address = 6'o11; // I
				(COUNT_MESSAGE_START_COL >> 3) + 20: character_address = 6'o15; // M	
				(COUNT_MESSAGE_START_COL >> 3) + 21: character_address = 6'o05; // E	
				(COUNT_MESSAGE_START_COL >> 3) + 22: character_address = 6'o23; // S	
				default: character_address = 6'o40; // space
			endcase
		end
	end else begin
		if (pixel_Y_pos[9:3] == ((COUNT_MESSAGE_LINE) >> 3)) begin
			// Reach the section where the text is displayed
			case (pixel_X_pos[9:3])
				(COUNT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o16; // N
				(COUNT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o17; // O
				(COUNT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o16; // N
				(COUNT_MESSAGE_START_COL >> 3) +  4: character_address = 6'o25; // U	
				(COUNT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o15; // M
				(COUNT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o13; // K
				(COUNT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
				(COUNT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o31; // Y
				(COUNT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o23; // S			
				(COUNT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o40; // space
				(COUNT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o20; // P
				(COUNT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o22; // R
				(COUNT_MESSAGE_START_COL >> 3) + 14: character_address = 6'o05; // E
				(COUNT_MESSAGE_START_COL >> 3) + 15: character_address = 6'o23; // S
				(COUNT_MESSAGE_START_COL >> 3) + 16: character_address = 6'o23; // S			
				(COUNT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o05; // E
				(COUNT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o04; // D
				default: character_address = 6'o40; // space
			endcase
		end
	end
	// 8 x 8 characters
	if (pixel_Y_pos[9:3] == ((KEYBOARD_MESSAGE_LINE) >> 3)) begin
		// Reach the section where the text is displayed
		if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3)) begin
			case (PS2_reg[0])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end 	
		if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 1) begin
			case (PS2_reg[1])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 2) begin
			case (PS2_reg[2])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 3) begin
			case (PS2_reg[3])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 4) begin
			case (PS2_reg[4])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 5) begin
			case (PS2_reg[5])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 6) begin
			case (PS2_reg[6])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 7) begin
			case (PS2_reg[7])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 8) begin
			case (PS2_reg[8])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 9) begin
			case (PS2_reg[9])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 10) begin
			case (PS2_reg[10])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 11) begin
			case (PS2_reg[11])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 12) begin
			case (PS2_reg[12])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 13) begin
			case (PS2_reg[13])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
				if (pixel_X_pos[9:3] == (KEYBOARD_MESSAGE_START_COL >> 3) + 14) begin
			case (PS2_reg[14])
				8'h45:   character_address = 6'o60; // 0
				8'h16:   character_address = 6'o61; // 1
				8'h1E:   character_address = 6'o62; // 2
				8'h26:   character_address = 6'o63; // 3
				8'h25:   character_address = 6'o64; // 4
				8'h2E:   character_address = 6'o65; // 5
				8'h36:   character_address = 6'o66; // 6
				8'h3D:   character_address = 6'o67; // 7
				8'h3E:   character_address = 6'o70; // 8
				8'h46:   character_address = 6'o71; // 9
				default: character_address = 6'o40; // space
			endcase
		end
	end
end

// RGB signals
always_comb begin
		VGA_red = 8'h00;
		VGA_green = 8'h00;
		VGA_blue = 8'h00;

		if (screen_border_on) begin
			// blue border
			VGA_blue = 8'hFF;
		end
		
		if (rom_mux_output) begin
			// yellow text
			VGA_red = 8'hFF;
			VGA_green = 8'hFF;
		end
end

endmodule
