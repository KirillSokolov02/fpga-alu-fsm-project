# FPGA ALU + FSM — 4-bit ALU with Factorial/Fibonacci Controller

4-bit Arithmetic Logic Unit implemented in Verilog with a 13-state FSM that computes factorial and Fibonacci sequences. Built with Quartus Prime 19.1.

## Overview

This project implements a complete datapath+control system on an Intel MAX 10 FPGA. The ALU performs arithmetic and logical operations on 4-bit operands, controlled by a finite state machine that sequences through factorial and Fibonacci number calculations.

## Project Structure

| File | Description |
|------|-------------|
| `ALU.v` | 4-bit ALU with add, sub, and, or, xor, not operations |
| `Verilog1.v` | Testbench with stimulus generation |

## Hardware

- **Device:** Intel MAX 10
- **Tool:** Quartus Prime 19.1
- **Language:** Verilog-2001

## Architecture

The design consists of two main components:

**ALU (4-bit):** Supports addition, subtraction, AND, OR, XOR, and NOT operations selected by a 3-bit control signal.

**FSM (13-state):** Controls the ALU sequencing to compute factorial values, Fibonacci numbers, and intermediate calculations. The state machine manages data flow through the ALU using registered outputs.

## Building

1. Open `test.qpf` in Quartus Prime
2. Run Analysis & Synthesis
3. Run TimeSim simulation with `Verilog1.v` testbench
4. Program the target board
