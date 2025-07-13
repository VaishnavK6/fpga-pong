`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2025 23:17:45
// Design Name: Timer Module
// Module Name: timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   Countdown timer that starts at 255 and decrements by 1 on every timer_tick.
//   The countdown begins on `timer_start`, and output `timer_up` goes high
//   when the count reaches 0.
//
// Dependencies: None
//////////////////////////////////////////////////////////////////////////////////

module timer(
    input clk,                // Clock signal
    input reset,              // Active-high synchronous reset
    input timer_start,        // Start signal to initialize timer
    input timer_tick,         // Tick signal to decrement the timer
    output timer_up           // Output goes high when timer reaches zero
);

    // Signal declarations
    reg [7:0] timer_reg, timer_next;  // 8-bit timer register and next state

    // Sequential logic: Update timer on clock edge or reset
    always @(posedge clk or posedge reset)
        if (reset)
            timer_reg <= 8'b11111111;    // Initialize timer to 255 on reset
        else
            timer_reg <= timer_next;     // Update with next state

    // Combinational logic: Determine next state of the timer
    always @*
        if (timer_start)
            timer_next = 8'b11111111;    // Restart timer to 255 when start is asserted
        else if (timer_tick && (timer_reg != 0))
            timer_next = timer_reg - 1'b1; // Decrement timer on each tick if not 0
        else
            timer_next = timer_reg;      // Hold value otherwise

    // Output: Assert timer_up when timer reaches 0
    assign timer_up = (timer_reg == 0);

endmodule
