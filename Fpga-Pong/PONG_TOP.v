`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: PONG_TOP
// Description: Top-level module for a 2-player FPGA-based Ping Pong game
// Handles FSM, graphics, VGA sync, timer, and RGB output generation.
//////////////////////////////////////////////////////////////////////////////////

module PONG_TOP(
    input clk,                   // System clock
    input reset,                 // Asynchronous reset
    input [4:0] btn,             // Button input (btn[4] for start, others for control)
    output hsync,                // VGA horizontal sync
    output vsync,                // VGA vertical sync
    output [11:0] rgb            // 12-bit RGB output (4 bits per color)
);

  // FSM states
  parameter newgame = 2'b00,
            play    = 2'b01,
            newball = 2'b10,
            over    = 2'b11;

  // State registers and next state logic
  reg [1:0] state_reg, state_next;

  // VGA and game-related wires
  wire [9:0] w_x, w_y;                 // VGA pixel coordinates
  wire vid_on, ptick;                 // Video ON signal and pixel tick
  wire miss1, miss2;                  // Missed ball indicators for both players
  wire graph_on, timer_tick, timer_up;
  wire [5:0] text_on;                 // Text signals (which overlay text is active)
  wire [11:0] text_rgb, graph_rgb;    // RGB output from text and graphics
  reg [11:0] rgb_reg, rgb_next;       // RGB output register

  // Ball counters (each player has 3 chances, decremented on miss)
  reg [1:0] ball1_reg, ball1_next, ball2_reg, ball2_next;

  // Control signals to timer and graph
  reg graph_still, timer_start;

  //=========================
  // VGA Sync Generator Module
  //=========================
  VGA_SYNC_GENERATOR vga_unit (
    .clk_100MHz(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .x(w_x),
    .y(w_y),
    .video_on(vid_on),
    .p_tick(ptick)
  );

  //=========================
  // Text Rendering Module
  //=========================
  PONG_TEXT text_unit (
    .clk(clk),
    .x(w_x),
    .y(w_y),
    .ball1(ball1_reg),
    .ball2(ball2_reg),
    .text_on(text_on),
    .text_rgb(text_rgb)
  );

  //=========================
  // Game Graphics Module
  //=========================
  PONG_GRAPH graph_unit (
    .clk(clk),
    .reset(reset),
    .btn(btn[3:0]),                // Control inputs for paddles
    .gra_still(graph_still),      // Freeze screen when needed
    .video_on(vid_on),
    .x(w_x),
    .y(w_y),
    .graph_on(graph_on),
    .graph_rgb(graph_rgb),
    .miss1(miss1),
    .miss2(miss2)
  );

  // Generate 1 tick per frame (used for timer updates)
  assign timer_tick = (w_x == 0) && (w_y == 0);

  //=========================
  // Timer Module (2 seconds delay)
  //=========================
  timer timer_unit (
    .clk(clk),
    .reset(reset),
    .timer_tick(timer_tick),
    .timer_start(timer_start),
    .timer_up(timer_up)
  );

  //=========================
  // Sequential Logic
  //=========================
  always @(posedge clk or posedge reset) begin
    if (reset) begin
        state_reg <= newgame;
        ball1_reg <= 0;
        ball2_reg <= 0;
        rgb_reg <= 0;
    end else begin
        state_reg <= state_next;
        ball1_reg <= ball1_next;
        ball2_reg <= ball2_next;
        if (ptick)
            rgb_reg <= rgb_next;
    end
  end

  //=========================
  // FSMD Next State Logic
  //=========================
  always @* begin
    // Defaults
    graph_still = 1'b1;
    timer_start = 1'b0;
    state_next  = state_reg;
    ball1_next  = ball1_reg;
    ball2_next  = ball2_reg;

    case (state_reg)

      //=====================
      // New Game State
      //=====================
      newgame: begin
        ball1_next = 2'b11;  // Player 1 starts with 3 balls
        ball2_next = 2'b11;  // Player 2 starts with 3 balls
        graph_still = 1'b1;
        if (btn[4])  // Start button pressed
            state_next = play;
      end

      //=====================
      // Gameplay State
      //=====================
      play: begin
        graph_still = 1'b0;  // Enable paddle/ball movement

        // Player 1 missed
        if (miss1) begin
          if (ball1_reg == 0) begin
            state_next = over;
            timer_start = 1'b1;
          end else begin
            state_next = newball;
            timer_start = 1'b1;
            ball1_next = ball1_reg - 1;
          end
        end

        // Player 2 missed
        else if (miss2) begin
          if (ball2_reg == 0) begin
            state_next = over;
            timer_start = 1'b1;
          end else begin
            state_next = newball;
            timer_start = 1'b1;
            ball2_next = ball2_reg - 1;
          end
        end
      end

      //=====================
      // New Ball Delay State
      //=====================
      newball:
        if (timer_up)
          state_next = play;

      //=====================
      // Game Over State
      //=====================
      over:
        if (timer_up && reset) begin
          state_next = newgame;
          graph_still = 1'b1;
        end

    endcase
  end

  //=========================
  // RGB Output Logic (Video Muxing)
  //=========================
  always @* begin
    if (~vid_on)
      rgb_next = 12'h000; // Black screen (sync period)
    else if (text_on[5] || text_on[4] || text_on[2])
      rgb_next = text_rgb; // Text overlays
    else if ((state_reg == over) && (text_on[0] || text_on[1]))
      rgb_next = text_rgb; // Game over messages
    else if (graph_on)
      rgb_next = graph_rgb; // Game elements (ball, paddles)
    else if (text_on[3])
      rgb_next = text_rgb; // Player scores
    else if (w_x[3] ^ w_y[3])
      rgb_next = 12'h444; // Checkerboard pattern background
    else
      rgb_next = 12'h000; // Default black
  end

  //=========================
  // Final Output Assignment
  //=========================
  assign rgb = rgb_reg;

endmodule
