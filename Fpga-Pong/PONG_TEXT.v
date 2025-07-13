`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
//
// Engineer:
//
// Create Date: 01.02.2025 23:16:05
// Module Name: PONG_TEXT
// Description:
//   Renders on-screen text for Pong: player lives, title/logo, rules,
//   and game-over message. Uses ASCII ROM for character bitmaps.
// Dependencies: ascii_values ROM module.
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module PONG_TEXT(
    input clk,              // Pixel clock
    input [1:0] ball1,      // Remaining lives for player1
    input [1:0] ball2,      // Remaining lives for player2
    input [9:0] x, y,       // Current pixel coordinates
    output [5:0] text_on,   // Flags: which text region is active
    output reg [11:0] text_rgb  // Output color for text pixel
);

    // ROM addressing: high bits for char index, low bits for row
    wire [10:0] rom_addr;
    reg [6:0] char_addr, char_addr_p1, char_addr_p2;
    reg [6:0] char_addr_l, char_addr_r;
    reg [6:0] char_addr1_o, char_addr2_o;
    reg [3:0] row_addr;
    // Row and bit positions within character cell
    wire [3:0] row_addr_p1, row_addr_p2, row_addr_l, row_addr_r;
    wire [3:0] row_addr1_o, row_addr2_o;
    reg [2:0] bit_addr;
    wire [2:0] bit_addr_p1, bit_addr_p2, bit_addr_l, bit_addr_r;
    wire [2:0] bit_addr1_o, bit_addr2_o;
    // ASCII ROM output bit and character code
    wire [7:0] ascii_word;
    wire ascii_bit;

    // Region-enabling signals
    wire player1_on, player2_on, logo_on, rule_on, over1_on, over2_on;
    wire [7:0] rule_rom_addr;

    // Instantiate ASCII ROM lookup
    ascii_values ascii_unit(
        .clk(clk),
        .addr(rom_addr),
        .data(ascii_word)
    );

    // --------------------------------------------------
    // Player 1 lives ("PLAYER1: d"), positioned at top-left
    // vertically between y=32..63, horizontally x/16 <= 8
    assign player1_on = (y >= 32) && (y < 64) && (x[9:4] <= 8);
    assign row_addr_p1 = y[4:1];    // 4-pixel rows inside char cell
    assign bit_addr_p1 = x[3:1];    // 2-pixel bits inside char cell

    always @* begin
        case(x[7:4])  // which character cell horizontally
            4'h0: char_addr_p1 = 7'h50; // 'P'
            4'h1: char_addr_p1 = 7'h4C; // 'L'
            4'h2: char_addr_p1 = 7'h41; // 'A'
            4'h3: char_addr_p1 = 7'h59; // 'Y'
            4'h4: char_addr_p1 = 7'h45; // 'E'
            4'h5: char_addr_p1 = 7'h52; // 'R'
            4'h6: char_addr_p1 = 7'h31; // '1'
            4'h7: char_addr_p1 = 7'h3A; // ':'
            4'h8: char_addr_p1 = {5'b01100, ball2}; // digit for lives
            default: char_addr_p1 = 7'd0;
        endcase
    end

    // --------------------------------------------------
    // Player 2 lives ("PLAYER2: d"), top-right region
    assign player2_on = (y >= 32) && (y < 64) && (x[9:4] >= 31) && (x[9:4] <= 39);
    assign row_addr_p2 = y[4:1];
    assign bit_addr_p2 = x[3:1];

    always @* begin
        case(x[9:4] - 31)
            4'h0: char_addr_p2 = 7'h50; // 'P'
            4'h1: char_addr_p2 = 7'h4C; // 'L'
            4'h2: char_addr_p2 = 7'h41; // 'A'
            4'h3: char_addr_p2 = 7'h59; // 'Y'
            4'h4: char_addr_p2 = 7'h45; // 'E'
            4'h5: char_addr_p2 = 7'h52; // 'R'
            4'h6: char_addr_p2 = 7'h32; // '2'
            4'h7: char_addr_p2 = 7'h3A; // ':'
            4'h8: char_addr_p2 = {5'b01100, ball1}; // digit for lives
            default: char_addr_p2 = 7'd0;
        endcase
    end

    // --------------------------------------------------
    // Game logo "PONG" in center-top, 64x128 region
    assign logo_on = (y[9:7] == 2) && (3 <= x[9:6]) && (x[9:6] <= 6);
    assign row_addr_l = y[6:3];
    assign bit_addr_l = x[5:3];

    always @* begin
        case(x[8:6])
            3'b011: char_addr_l = 7'h50; // 'P'
            3'b100: char_addr_l = 7'h4F; // 'O'
            3'b101: char_addr_l = 7'h4E; // 'N'
            default: char_addr_l = 7'h47; // 'G'
        endcase
    end

    // --------------------------------------------------
    // Instruction rules text, 4×16 characters in mid-screen
    assign rule_on = (x[9:7] == 2) && (y[9:6] == 2);  // region active
    assign row_addr_r = y[3:0];
    assign bit_addr_r = x[2:0];
    assign rule_rom_addr = {y[5:4], x[6:3]};

    always @* begin
        case(rule_rom_addr)
            6'h00: char_addr_r = 7'h52; // 'R'
            6'h01: char_addr_r = 7'h55; // 'U'
            6'h02: char_addr_r = 7'h4C; // 'L'
            6'h03: char_addr_r = 7'h45; // 'E'
            6'h04: char_addr_r = 7'h3A; // ':'
            6'h10: char_addr_r = 7'h55; // 'U'
            6'h11: char_addr_r = 7'h53; // 'S'
            6'h12: char_addr_r = 7'h45; // 'E'
            6'h14: char_addr_r = 7'h54; // 'T'
            6'h15: char_addr_r = 7'h57; // 'W'
            6'h16: char_addr_r = 7'h4F; // 'O'
            6'h18: char_addr_r = 7'h42; // 'B'
            6'h19: char_addr_r = 7'h55; // 'U'
            6'h1A: char_addr_r = 7'h54; // 'T'
            6'h1B: char_addr_r = 7'h54; // 'T'
            6'h1C: char_addr_r = 7'h4F; // 'O'
            6'h1D: char_addr_r = 7'h4E; // 'N'
            6'h1E: char_addr_r = 7'h53; // 'S'
            6'h20: char_addr_r = 7'h54; // 'T'
            6'h21: char_addr_r = 7'h4F; // 'O'
            6'h23: char_addr_r = 7'h4D; // 'M'
            6'h24: char_addr_r = 7'h4F; // 'O'
            6'h25: char_addr_r = 7'h56; // 'V'
            6'h26: char_addr_r = 7'h45; // 'E'
            6'h28: char_addr_r = 7'h50; // 'P'
            6'h29: char_addr_r = 7'h41; // 'A'
            6'h2A: char_addr_r = 7'h44; // 'D'
            6'h2B: char_addr_r = 7'h44; // 'D'
            6'h2C: char_addr_r = 7'h4C; // 'L'
            6'h2D: char_addr_r = 7'h45; // 'E'
            6'h30: char_addr_r = 7'h55; // 'U'
            6'h31: char_addr_r = 7'h50; // 'P'
            6'h33: char_addr_r = 7'h41; // 'A'
            6'h34: char_addr_r = 7'h4E; // 'N'
            6'h35: char_addr_r = 7'h44; // 'D'
            6'h37: char_addr_r = 7'h44; // 'D'
            6'h38: char_addr_r = 7'h4F; // 'O'
            6'h39: char_addr_r = 7'h57; // 'W'
            6'h3A: char_addr_r = 7'h4E; // 'N'
            6'h3B: char_addr_r = 7'h2E; // '.'
            default: char_addr_r = 7'd0;  // Blank
        endcase
    end

    // --------------------------------------------------
    // Game-over message "PLAYER1 WON" or "PLAYER2 WON"
    // Scaled 32×64, shown only when lives reach zero
    assign over1_on = (y[9:6] == 3) && (x[9:5] >= 5) && (x[9:5] <= 15);
    assign row_addr1_o = y[5:2];
    assign bit_addr1_o = x[4:2];
    always @* begin
        case(x[8:5])
            4'h5: char_addr1_o = 7'h50; // 'P'
            4'h6: char_addr1_o = 7'h4C; // 'L'
            4'h7: char_addr1_o = 7'h41; // 'A'
            4'h8: char_addr1_o = 7'h59; // 'Y'
            4'h9: char_addr1_o = 7'h45; // 'E'
            4'hA: char_addr1_o = 7'h52; // 'R'
            4'hB: char_addr1_o = 7'h31; // '1'
            4'hD: char_addr1_o = 7'h57; // 'W'
            4'hE: char_addr1_o = 7'h4F; // 'O'
            default: char_addr1_o = 7'h4E; // 'N'
        endcase
    end

    assign over2_on = over1_on;  // same region for both players
    assign row_addr2_o = row_addr1_o;
    assign bit_addr2_o = bit_addr1_o;
    always @* begin
        case(x[8:5])
            4'h5: char_addr2_o = 7'h50; // 'P'
            4'h6: char_addr2_o = 7'h4C;
            4'h7: char_addr2_o = 7'h41;
            4'h8: char_addr2_o = 7'h59;
            4'h9: char_addr2_o = 7'h45;
            4'hA: char_addr2_o = 7'h52;
            4'hB: char_addr2_o = 7'h32; // '2'
            4'hD: char_addr2_o = 7'h57;
            4'hE: char_addr2_o = 7'h4F;
            default: char_addr2_o = 7'h4E; // 'N'
        endcase
    end

    // ---------------------------------------------
    // Multiplex between regions, fetch ASCII bits, set RGB
    always @* begin
        // Background pattern
        text_rgb = (x[3] ^ y[3]) ? 12'h444 : 12'h000;

        if (player1_on) begin
            char_addr = char_addr_p1;
            row_addr = row_addr_p1;
            bit_addr = bit_addr_p1;
            if (ascii_bit) text_rgb = 12'hF00;

        end else if (player2_on) begin
            char_addr = char_addr_p2;
            row_addr = row_addr_p2;
            bit_addr = bit_addr_p2;
            if (ascii_bit) text_rgb = 12'hF00;

        end else if (rule_on) begin
            char_addr = char_addr_r;
            row_addr = row_addr_r;
            bit_addr = bit_addr_r;
            if (ascii_bit) text_rgb = 12'hF00;

        end else if (logo_on) begin
            char_addr = char_addr_l;
            row_addr = row_addr_l;
            bit_addr = bit_addr_l;
            if (ascii_bit) text_rgb = 12'hFF0;

        end else if (over1_on && ball1 == 0) begin
            char_addr = char_addr1_o;
            row_addr = row_addr1_o;
            bit_addr = bit_addr1_o;
            if (ascii_bit) text_rgb = 12'hF00;

        end else if (over2_on && ball2 == 0) begin
            char_addr = char_addr2_o;
            row_addr = row_addr2_o;
            bit_addr = bit_addr2_o;
            if (ascii_bit) text_rgb = 12'hF00;
        end
    end

    // Region indicators output
    assign text_on = {
        player1_on,
        player2_on,
        logo_on,
        rule_on,
        over1_on && (ball2 == 0),
        over2_on && (ball1 == 0)
    };

    // Build ROM address: character index + row
    assign rom_addr = {char_addr, row_addr};
    // Select bit from ASCII byte (MSB-first)
    assign ascii_bit = ascii_word[~bit_addr];

endmodule
