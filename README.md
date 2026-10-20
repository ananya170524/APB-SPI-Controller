APB-SPI-Controller

A modular APB-based SPI controller implemented in Verilog HDL, verified using ModelSim and synthesized using Intel Quartus Prime.

Design Modules

- APB Slave Interface — Handles APB register accesses.
- Baud Rate Generator — Generates timing signals for SPI communication.
- Shift Register — Supports serial data transmission and reception.
- Slave Select Control — Manages SPI slave selection.
- Top-Level Controller— Integrates the design modules.

Verification:

Functional verification was performed using ModelSim testbenches to examine APB register accesses and SPI data transfers, including supported SPI modes and MSB-first/LSB-first operation.

Synthesis:

The design was synthesized for a Cyclone V SoC FPGA using Intel Quartus Prime.

- Adaptive Logic Modules (ALMs): 134
- Registers: 117
- Device pins: 31
- DSP blocks: 1

Tools Used:

Verilog HDL · ModelSim · Intel Quartus Prime

Repository Contents:

RTL source files and testbench files for the APB-based SPI controller. Verification waveforms and synthesis results may be added separately.
