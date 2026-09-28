# FPGA ALU with Arithmetic FSM

A Verilog-based Arithmetic Logic Unit (ALU) paired with a finite state machine (FSM) that can compute **factorials** or **Fibonacci numbers** using repeated ALU operations — all synthesized for Intel MAX 10 FPGA using Quartus Prime.

## Overview

This project implements a modular arithmetic system on an **Intel MAX 10 FPGA** using **Verilog**. At its core is a 4-bit ALU capable of **addition**, **subtraction**, and **multiplication**, wrapped inside a 13-state FSM that orchestrates these operations to compute **factorial** or **Fibonacci** sequences based on user input.

The design demonstrates several key digital design concepts:
- **Parameterized arithmetic** — Three operations share a single ALU module
- **Multi-step computation** — Complex math (factorial/Fibonacci) broken into ALU cycles
- **State machine control** — 13-state FSM orchestrates data flow between ALU inputs/outputs
- **Modular design** — ALU is instantiated as a sub-module, promoting reuse

The FSM can compute two sequences based on a `fac` control signal:
- **Factorial** (`fac = 1`): Computes `n!` iteratively using repeated multiplication
- **Fibonacci** (`fac = 0`): Computes the nth Fibonacci number using repeated addition

Both use a 4-bit input `in1` (values 0–15) and produce results on a 8-bit `result` output with overflow detection.

## Features

### ALU Module (`ALU.v` — lines 1–37)

A 4-bit arithmetic unit with three operations controlled by a 2-bit `OpCode`:

| OpCode | Operation | Description |
|--------|-----------|-------------|
| `00` | Add | `result = in1 + in2` (8-bit result, overflow if > 255) |
| `01` | Subtract | `result = in1 - in2` (8-bit result, overflow detection) |
| `10` | Multiply | `result = in1 * in2` (8-bit result, overflow if > 255) |

- **Overflow flag** — Asserted when the 8-bit result exceeds 255 (`0xFF`)
- **4-bit operands** — Both inputs are 4-bit (0–15 range)
- **8-bit result** — Sufficient for 15×15 = 225 without truncation

### FSM Controller (`ALU.v` — lines 40–192)

A 13-state finite state machine that computes factorials or Fibonacci numbers iteratively:

#### States (13 total):

| State | Value | Purpose |
|-------|-------|---------|
| `Idle` | 0 | Wait for input, transition to `Choose` |
| `Choose` | 1 | Branch to factorial or Fibonacci path based on `fac` |
| `StoreNFact` | 4 | Initialize factorial: store n, check if n ≤ 0 |
| `StoreNFibi` | 9 | Initialize Fibonacci: store n, handle edge cases (n < 2) |
| `Nminus` | 5 | Decrement counter (`index = index - 1`) for factorial loop |
| `Fact` | 2 | Multiply: `result = resultOld * index` (accumulate factorial) |
| `UpdateFact` | 7 | Store intermediate factorial result, check completion |
| `Fibi` | 3 | Add: `result = resultOld + index` (accumulate Fibonacci) |
| `UpdateFibi` | 8 | Store intermediate sum, prepare next iteration |
| `WaitUpdateFibi` | 12 | Swap accumulated values for Fibonacci |
| `Wait` | 11 | Wait condition — checks if Fibonacci index has reached target `n` |
| `AddFibiIndex` | 10 | Increment Fibonacci index by 1 |
| `Return` | 6 | Finalize: output result, return to `Idle` |

#### Computation Flow:

**Factorial (`fac = 1`):**
```
Idle → Choose → StoreNFact → (n ≤ 0?) → Return / Nminus → Wait → Fact → UpdateFact → Nminus → ...
```
- Computes `n! = n × (n-1) × (n-2) × ... × 1`
- Uses subtraction to count down, multiplication to accumulate

**Fibonacci (`fac = 0`):**
```
Idle → Choose → StoreNFibi → (n < 2?) → Return / Fibi → UpdateFibi → WaitUpdateFibi → AddFibiIndex → Wait → Fibi → ...
```
- Computes `Fib(n)` using iterative addition
- Uses addition to accumulate, subtraction to count down to target

### Testbench (`Verilog1.v`)

A comprehensive testbench that verifies both the ALU and FSM:

- **FSM test** (commented out) — Simulates the FSM with 30 clock cycles
- **ALU test** (active) — Exhaustive verification:
  - Tests all combinations of 4-bit inputs (0–15 × 0–15) for **addition**, **subtraction**, and **multiplication**
  - Displays pass/fail for each combination
  - Uses `$display` and `$dumpfile` for simulation logging

## Project Structure

```
test/
├── ALU.v                 # ALU + FSM (main design)
├── Verilog1.v            # Testbench for ALU and FSM verification
├── ALU.v.bak             # Backup of ALU (previous version)
├── Verilog1.v.bak        # Backup of testbench (previous version)
├── test.qpf              # Quartus Prime project file
├── test.qsf              # Quartus settings (pin/device config)
├── test.qws              # Quartus workspace
├── test_description.txt  # Project description (empty)
└── .gitignore            # Excludes Quartus build artifacts
```

## Building

### Prerequisites

- **Intel Quartus Prime Lite Edition 19.1** (or later)
- **Verilog-2001** language standard
- Intel MAX 10 FPGA development board (DE10-Lite recommended)

### Compilation Steps

1. Open Quartus Prime → **File → Open Project**
2. Open `test.qpf` from this directory
3. Select **Project → Start Compilation** (F7)
4. Review the compilation report for resource utilization

### Device Configuration

| Parameter | Value |
|-----------|-------|
| Family | MAX 10 |
| Top-level Entity | ALU (for ALU alone) or fsm (for FSM) |
| Quartus Version | 19.1.0 Lite Edition |

> **Note:** The FSM module contains multiple internal signals and state registers. When targeting a complete design, the FSM must be instantiated in a top-level wrapper that maps its I/O to FPGA pins (clk, reset, fac, in1, result, Overflow).

## Design Details

### Data Path

```
                    ┌──────────────────────────────────────┐
                    │              FSM                     │
                    │  13-state controller                  │
                    └──────┬──────────────┬───────────────┘
                           │              │
                    in1Temp│              │ resultTemp
                           ▼              ▲
                    ┌──────────────────────────────┐
                    │              ALU              │
                    │  +  -  *  (OpCode control)    │
                    └──────┬──────────────┬───────────────┘
                           │              │
                    in2Temp│              │ OverflowTemp
                           ▼              ▲
                    ┌──────────────────────────────┐
                    │   Internal Registers         │
                    │   resultOld, index, state     │
                    └──────────────────────────────┘
```

### FSM Design Methodology

- **Two-always-block FSM** — Separates sequential (clocked) logic from combinational (output) logic
- **Registered output** — `result` is a `reg`, updated in the combinational block but output from sequential path
- **Default state** — `default: state <= Idle` catches any illegal state transitions
- **Multiple registers** — `resultOld` stores accumulated results, `index` counts iterations

### Overflow Handling

The ALU uses 8-bit arithmetic for a 4-bit × 4-bit operation:
- Addition: max result = 15 + 15 = 30 (within 8-bit range)
- Subtraction: result can go negative, but signed interpretation required
- Multiplication: max result = 15 × 15 = 225 (within 8-bit range, overflow flag never triggers)

The overflow check `> 9'b011111111` (255) is conservative — for 4-bit inputs, only multiplication could theoretically overflow, and only with values ≥ 17 (impossible with 4-bit).

## References

- IEEE 1364 Verilog-2001 Standard
- Intel MAX 10 Device Datasheet
- Quartus Prime Getting Started Tutorial
