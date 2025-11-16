# Computer Architecture and FPGA Systems Portfolio

This repository presents a clean, portfolio-ready collection of hardware systems developed across four core areas of computer construction: microcoded control, pipelined CPU design, UART communication, and VGA signal generation. All modules are written in VHDL, simulation ready, and structured for clarity and review.

## Skills Demonstrated

* VHDL design of synchronous digital systems
* Microcoded CPU control logic and instruction sequencing
* Pipelined CPU behavior, hazards, and datapath structuring
* UART protocol implementation and serial timing control
* VGA timing generation, character rendering, and video RAM integration
* Hardware testbenches and waveform-driven debugging
* Basys3 FPGA workflows and XDC constraint usage
* Modular hardware architecture and clean digital design patterns

## Project Overview

### microcoded-cpu

A microcoded control unit paired with small assembly programs. Includes:

* Microinstruction sequences defining control behavior
* A simple Haskell-based assembler
* Demonstrations of ALU operations, branching, memory access

Highlights understanding of the control path, microinstruction formats, and the relationship between ISA-level instructions and low-level micro-operations.

### pipelined-cpu

Assembly programs targeting a 5-stage pipelined processor. Includes:

* Arithmetic and branching programs
* Pipeline-aware scheduling
* Analysis of data hazards, NOP insertion, and cycle counting

Demonstrates reasoning about pipelined execution, dependencies, and performance characteristics.

### uart-controller

A UART communication core implemented in VHDL. Features:

* Baud rate generator
* Serial transmission logic
* LED status output
* Accompanying testbench and waveform verification

Shows robust sequential logic design, protocol framing, and real hardware timing considerations.

### vga-controller

A VGA-based text rendering system using custom video RAM, character ROM, and PS/2 keyboard decoding. Includes:

* VGA sync and timing generator
* Character ROM lookup
* CPU-driven video memory writes
* Integrated keyboard decoding pipeline

Demonstrates complete subsystem integration, CPU, peripherals, memory, and display output.

## How to Run Simulations

ModelSim can be used to compile and run all modules:

```tcl
vsim -do first_time.do
```

To re-run simulations:

```tcl
vsim -do rerun.do
```
