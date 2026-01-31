## FPGA Market Data Feed Handler

This repository contains an FPGA-based streaming market data feed
handler designed for high-throughput and predictable-latency operation.

The focus of the project is protocol-aware parsing of packetized
Ethernet/UDP-style market data streams, with careful control over
combinational depth and pipeline structure.

---

## Status

This project is under active development. The current focus is on
establishing a clean streaming pipeline and validating parsing logic
under realistic traffic patterns.

The full RTL implementation, testbenches, and supporting artifacts
will be uploaded once a major functional milestone of the project
is completed.

---

## Project Goals

- Parse streaming market data with deterministic latency
- Maintain line-rate throughput without stalling the pipeline
- Use protocol-aware assumptions to simplify hardware parsing
- Verify functionality using cycle-accurate simulation

---

## Design Approach

The feed handler is implemented as a streaming pipeline operating on
packetized input data.

Key design considerations include:
- Fixed-latency data paths where possible
- Separation of combinational parsing and registered stages
- Minimal buffering to avoid latency variability
- Backpressure handling using ready/valid-style interfaces

Protocol assumptions are made explicitly to reduce complexity and
enable predictable timing behavior.

---

## Verification

Functionality is verified using SystemVerilog testbenches that replay
representative packet traces.

Waveform-level debugging is performed using GTKWave to validate:
- Correct packet boundary detection
- Field extraction correctness
- Pipeline timing and alignment

---


