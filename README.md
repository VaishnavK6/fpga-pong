# FPGA-Based Pong Game
This project is a 2-player Pong game implemented entirely on an FPGA using Verilog HDL. The game is displayed in real time using VGA output, with hardware-level control of graphics, text rendering, and game logic. It features a clean FSM architecture, interactive paddle control, ball physics, collision detection, scoring system, and game-over handling.

🎯 Features
Two-player Pong gameplay (one paddle on each side)

VGA display at 640x480 resolution (25 MHz pixel clock)

Paddles controlled via physical buttons

Ball movement with collision detection (walls and paddles)

Game state FSM (NEW GAME → PLAY → NEW BALL → GAME OVER)

Game-over screen when a player loses all lives

On-screen text rendering for:

"PLAYER1: X" and "PLAYER2: Y"

Game instructions

Logo display ("PONG")

Winner announcement

🔧 Technical Details
Language: Verilog

Target Clock: 100 MHz input, internally handles VGA at 25 MHz (ptick)

Modules:

PONG_TOP.v: Top-level integration module

PONG_GRAPH.v: Graphics module for paddles, ball, bricks

PONG_TEXT.v: Text overlay module with ASCII rendering

VGA_SYNC_GENERATOR.v: Generates VGA sync signals

timer.v: 8-bit countdown timer for FSM delay

ascii_values.v: ROM for ASCII font

Development Platform: Xilinx Vivado
