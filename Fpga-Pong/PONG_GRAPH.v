`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2025 23:16:05
// Design Name: 
// Module Name: PONG_GRAPH
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//      VGA-based PONG game graphics and logic including paddles, ball,
//      and four moving vertical bricks. Handles collision detection,
//      paddle/brick control, ball movement, and game reset.
//
// Dependencies: VGA sync signals, pixel coordinates.
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module PONG_GRAPH(
    input clk,                  // System clock
    input reset,                // Reset signal
    input [3:0] btn,            // Button inputs (2 for each player paddle)
    input gra_still,            // Graphics reset signal
    input video_on,             // Enable video signal
    input [9:0] x, y,           // Current pixel coordinates
    output graph_on,            // Output to indicate active graphic pixel
    output reg miss1, miss2,    // Miss signals for player 1 and player 2
    output reg [11:0] graph_rgb // RGB output for the pixel
);

    // Maximum screen dimensions
    parameter X_MAX = 639;
    parameter Y_MAX = 479;

    // Frame refresh tick: triggers once per screen refresh
    wire refresh_tick;
    assign refresh_tick = (y == 481) & (x == 0);

    // Top and bottom wall coordinates
    parameter T_WALL_T = 1;
    parameter T_WALL_B = 8;
    parameter B_WALL_T = 472;
    parameter B_WALL_B = 479;

    // Brick dimensions and initial position variables
    parameter brick_length = 50;

    // Brick vertical velocity registers
    reg[9:0] brick1_vel_reg, brick2_vel_reg, brick3_vel_reg, brick4_vel_reg;
    reg[9:0] brick1_vel_next, brick2_vel_next, brick3_vel_next, brick4_vel_next;

    // Horizontal boundaries for each brick (fixed)
    parameter brick1_l = 170, brick1_r = 174;
    parameter brick2_l = 250, brick2_r = 254;
    parameter brick3_l = 390, brick3_r = 394;
    parameter brick4_l = 470, brick4_r = 474;

    // Registers to track vertical position of each brick
    reg [9:0] brick1_reg, brick2_reg, brick3_reg, brick4_reg;
    wire [9:0] brick1_t, brick1_b, brick2_t, brick2_b;
    wire [9:0] brick3_t, brick3_b, brick4_t, brick4_b;

    // Compute top and bottom edges of each brick
    assign brick1_t = brick1_reg;
    assign brick1_b = brick1_reg + brick_length - 1;
    assign brick2_t = brick2_reg;
    assign brick2_b = brick2_reg + brick_length - 1;
    assign brick3_t = brick3_reg;
    assign brick3_b = brick3_reg + brick_length - 1;
    assign brick4_t = brick4_reg;
    assign brick4_b = brick4_reg + brick_length - 1;

    // Paddle horizontal boundaries
    parameter x_lpad_l = 4, x_lpad_r = 8;
    parameter x_rpad_l = 631, x_rpad_r = 635;

    // Paddle length and velocity
    parameter PAD_LENGTH = 72;
    parameter PAD_VELOCITY = 3;

    // Paddle vertical position registers
    reg [9:0] y_lpad_reg = 200, y_rpad_reg = 200;
    reg [9:0] y_lpad_next, y_rpad_next;

    // Ball size and position/velocity registers
    parameter BALL_SIZE = 8;
    reg [9:0] x_ball_reg, y_ball_reg;
    reg [9:0] x_delta_reg, y_delta_reg;
    wire [9:0] x_ball_l, x_ball_r, y_ball_t, y_ball_b;
    wire [9:0] x_ball_next, y_ball_next;
    reg [9:0] x_delta_next, y_delta_next;

    // Ball velocity constants
    parameter BALL_VELOCITY_POS = 1;
    parameter BALL_VELOCITY_NEG = -1;

    // ROM to draw a square ball using bitmap
    wire [2:0] rom_addr, rom_col;
    reg [7:0] rom_data;
    wire rom_bit;

    // Reset and update registers every clock cycle
    always @(posedge clk or posedge reset)
        if(reset) begin
            // Initial positions
            y_lpad_reg <= 200;
            y_rpad_reg <= 200;
            x_ball_reg <= 0;
            y_ball_reg <= 0;
            brick1_reg <= 0;
            brick2_reg <= 0;
            brick3_reg <= 0;
            brick4_reg <= 0;
            // Initial velocities
            x_delta_reg <= 10'h001;
            y_delta_reg <= 10'h001;
            brick1_vel_reg <= 10'h001;
            brick2_vel_reg <= 10'h001;
            brick3_vel_reg <= 10'h001;
            brick4_vel_reg <= 10'h001;
        end
        else begin
            // Update all object positions and velocities
            y_lpad_reg <= y_lpad_next;
            y_rpad_reg <= y_rpad_next;
            x_ball_reg <= x_ball_next;
            y_ball_reg <= y_ball_next;
            brick1_reg <= brick1_next;
            brick2_reg <= brick2_next;
            brick3_reg <= brick3_next;
            brick4_reg <= brick4_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
            brick1_vel_reg <= brick1_vel_next;
            brick2_vel_reg <= brick2_vel_next;
            brick3_vel_reg <= brick3_vel_next;
            brick4_vel_reg <= brick4_vel_next;
        end

    // 8x8 square ROM bitmap (all 1s = solid square)
    always @*
        case(rom_addr)
            3'b000: rom_data = 8'b11111111;
            3'b001: rom_data = 8'b11111111;
            3'b010: rom_data = 8'b11111111;
            3'b011: rom_data = 8'b11111111;
            3'b100: rom_data = 8'b11111111;
            3'b101: rom_data = 8'b11111111;
            3'b110: rom_data = 8'b11111111;
            3'b111: rom_data = 8'b11111111;
        endcase

    // Object activation signals
    wire t_wall_on, b_wall_on, pad1_on, pad2_on;
    wire ball_on, sq_ball_on;
    wire brick1_on, brick2_on, brick3_on, brick4_on;

    // Color constants (12-bit RGB)
    wire [11:0] wall_rgb = 12'hFA0;
    wire [11:0] pad_rgb  = 12'hFD0;
    wire [11:0] ball_rgb = 12'hF00;
    wire [11:0] bg_rgb   = 12'h000;

    // Wall on detection based on y
    assign b_wall_on = (B_WALL_T <= y) && (y <= B_WALL_B);
    assign t_wall_on = (T_WALL_T <= y) && (y <= T_WALL_B);

    // Brick visibility condition
    assign brick1_on = (brick1_t <= y) && (y <= brick1_b) && (brick1_l <= x) && (x <= brick1_r);
    assign brick2_on = (brick2_t <= y) && (y <= brick2_b) && (brick2_l <= x) && (x <= brick2_r);
    assign brick3_on = (brick3_t <= y) && (y <= brick3_b) && (brick3_l <= x) && (x <= brick3_r);
    assign brick4_on = (brick4_t <= y) && (y <= brick4_b) && (brick4_l <= x) && (x <= brick4_r);

    // Brick movement logic
    assign brick1_next = (gra_still) ? 65 : (refresh_tick) ? brick1_reg + brick1_vel_reg : brick1_reg;
    assign brick2_next = (gra_still) ? 365 : (refresh_tick) ? brick2_reg + brick2_vel_reg : brick2_reg;
    assign brick3_next = (gra_still) ? 65 : (refresh_tick) ? brick3_reg + brick3_vel_reg : brick3_reg;
    assign brick4_next = (gra_still) ? 365 : (refresh_tick) ? brick4_reg + brick4_vel_reg : brick4_reg;

    // Brick velocity control
    always @* begin
        // Repeating similar logic for each brick
        // Bounce off top and bottom wall
        // Initialization on gra_still signal
        brick1_vel_next = (gra_still) ? BALL_VELOCITY_POS :
                          (brick1_t < T_WALL_B) ? BALL_VELOCITY_POS :
                          (brick1_b > B_WALL_T) ? BALL_VELOCITY_NEG : brick1_vel_reg;

        brick2_vel_next = (gra_still) ? BALL_VELOCITY_POS :
                          (brick2_t < T_WALL_B) ? BALL_VELOCITY_POS :
                          (brick2_b > B_WALL_T) ? BALL_VELOCITY_NEG : brick2_vel_reg;

        brick3_vel_next = (gra_still) ? BALL_VELOCITY_POS :
                          (brick3_t < T_WALL_B) ? BALL_VELOCITY_POS :
                          (brick3_b > B_WALL_T) ? BALL_VELOCITY_NEG : brick3_vel_reg;

        brick4_vel_next = (gra_still) ? BALL_VELOCITY_POS :
                          (brick4_t < T_WALL_B) ? BALL_VELOCITY_POS :
                          (brick4_b > B_WALL_T) ? BALL_VELOCITY_NEG : brick4_vel_reg;
    end

    // Paddle vertical boundaries and active logic
    assign y_lpad_t = y_lpad_reg;
    assign y_lpad_b = y_lpad_reg + PAD_LENGTH - 1;
    assign pad1_on = (y_lpad_t <= y) && (y <= y_lpad_b) &&
                     (x_lpad_l <= x) && (x <= x_lpad_r);

    assign y_rpad_t = y_rpad_reg;
    assign y_rpad_b = y_rpad_reg + PAD_LENGTH - 1;
    assign pad2_on = (y_rpad_t <= y) && (y <= y_rpad_b) &&
                     (x_rpad_l <= x) && (x <= x_rpad_r);

    // Paddle control logic via button inputs
    always @ (*) begin
        if(refresh_tick) begin
            // Player 1: btn[1] = down, btn[0] = up
            case({btn[0], btn[1]})
                2'b01: y_lpad_next = (y_lpad_b < B_WALL_T - 1 - PAD_VELOCITY) ? y_lpad_reg + PAD_VELOCITY : y_lpad_reg;
                2'b10: y_lpad_next = (y_lpad_t > T_WALL_B - 1 - PAD_VELOCITY) ? y_lpad_reg - PAD_VELOCITY : y_lpad_reg;
                default: y_lpad_next = y_lpad_reg;
            endcase
            // Player 2: btn[3] = down, btn[2] = up
            case({btn[2], btn[3]})
                2'b01: y_rpad_next = (y_rpad_b < B_WALL_T - 1 - PAD_VELOCITY) ? y_rpad_reg + PAD_VELOCITY : y_rpad_reg;
                2'b10: y_rpad_next = (y_rpad_t > T_WALL_B - 1 - PAD_VELOCITY) ? y_rpad_reg - PAD_VELOCITY : y_rpad_reg;
                default: y_rpad_next = y_rpad_reg;
            endcase
        end else begin
            y_lpad_next = y_lpad_reg;
            y_rpad_next = y_rpad_reg;
        end
    end

    // Ball boundaries and bitmap control
    assign x_ball_l = x_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_t = y_ball_reg;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;

    assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                        (y_ball_t <= y) && (y <= y_ball_b);
    assign rom_addr = y[2:0] - y_ball_t[2:0];
    assign rom_col = x[2:0] - x_ball_l[2:0];
    assign rom_bit = rom_data[rom_col];
    assign ball_on = sq_ball_on & rom_bit;

    // Ball movement logic
    assign x_ball_next = (gra_still) ? X_MAX / 2 :
                         (refresh_tick) ? x_ball_reg + x_delta_reg : x_ball_reg;
    assign y_ball_next = (gra_still) ? Y_MAX / 2 :
                         (refresh_tick) ? y_ball_reg + y_delta_reg : y_ball_reg;

    // Collision detection and ball bounce logic
    always @* begin
        miss1 = 1'b0;
        miss2 = 1'b0;
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;

        if(gra_still) begin
            x_delta_next = BALL_VELOCITY_POS;
            y_delta_next = BALL_VELOCITY_NEG;
        end
        else if(y_ball_t < T_WALL_B)
            y_delta_next = BALL_VELOCITY_POS;
        else if(y_ball_b > B_WALL_T)
            y_delta_next = BALL_VELOCITY_NEG;

        // Ball hits side or top/bottom of bricks
        else if( (x_ball_r == brick1_l && y_ball_b >= brick1_t && y_ball_t <= brick1_b) ||
                 (x_ball_r == brick2_l && y_ball_b >= brick2_t && y_ball_t <= brick2_b) ||
                 (x_ball_r == brick3_l && y_ball_b >= brick3_t && y_ball_t <= brick3_b) ||
                 (x_ball_r == brick4_l && y_ball_b >= brick4_t && y_ball_t <= brick4_b) )
            x_delta_next = BALL_VELOCITY_NEG;

        else if( (x_ball_l == brick1_r && y_ball_b >= brick1_t && y_ball_t <= brick1_b) ||
                 (x_ball_l == brick2_r && y_ball_b >= brick2_t && y_ball_t <= brick2_b) ||
                 (x_ball_l == brick3_r && y_ball_b >= brick3_t && y_ball_t <= brick3_b) ||
                 (x_ball_l == brick4_r && y_ball_b >= brick4_t && y_ball_t <= brick4_b) )
            x_delta_next = BALL_VELOCITY_POS;

        else if( (y_ball_b == brick1_t && x_ball_r >= brick1_l && x_ball_l <= brick1_r) ||
                 (y_ball_b == brick2_t && x_ball_r >= brick2_l && x_ball_l <= brick2_r) ||
                 (y_ball_b == brick3_t && x_ball_r >= brick3_l && x_ball_l <= brick3_r) ||
                 (y_ball_b == brick4_t && x_ball_r >= brick4_l && x_ball_l <= brick4_r) )
            y_delta_next = BALL_VELOCITY_NEG;

        else if( (y_ball_t == brick1_b && x_ball_r >= brick1_l && x_ball_l <= brick1_r) ||
                 (y_ball_t == brick2_b && x_ball_r >= brick2_l && x_ball_l <= brick2_r) ||
                 (y_ball_t == brick3_b && x_ball_r >= brick3_l && x_ball_l <= brick3_r) ||
                 (y_ball_t == brick4_b && x_ball_r >= brick4_l && x_ball_l <= brick4_r) )
            y_delta_next = BALL_VELOCITY_POS;

        // Paddle collisions
        else if((x_rpad_l <= x_ball_r) && (x_ball_r <= x_rpad_r) &&
                (y_rpad_t <= y_ball_b) && (y_ball_t <= y_rpad_b))
            x_delta_next <= BALL_VELOCITY_NEG;

        else if((x_lpad_l <= x_ball_l) && (x_ball_l <= x_lpad_r) &&
                (y_lpad_t <= y_ball_b) && (y_ball_t <= y_lpad_b))
            x_delta_next <= BALL_VELOCITY_POS;

        // Missed ball conditions
        else if(x_ball_r > X_MAX)
            miss1 = 1'b1;
        else if(x_ball_l == 0)
            miss2 = 1'b1;
    end

    // Combined object detection signal
    assign graph_on = t_wall_on | b_wall_on | pad1_on | pad2_on | ball_on |
                      brick1_on | brick2_on | brick3_on | brick4_on;

    // Output RGB based on object being drawn
    always @*
        if(~video_on)
            graph_rgb = 12'hFFF; // White (no display)
        else if(b_wall_on | t_wall_on | brick1_on | brick2_on | brick3_on | brick4_on)
            graph_rgb = wall_rgb;
        else if(pad1_on | pad2_on)
            graph_rgb = pad_rgb;
        else if(ball_on)
            graph_rgb = ball_rgb;
        else
            graph_rgb = bg_rgb;

endmodule
