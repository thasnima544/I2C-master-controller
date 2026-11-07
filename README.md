# I2C Master Controller — Verilog RTL

## Project Overview

This project implements a **7-bit addressed I2C Master Controller** using Verilog HDL and a Finite State Machine (FSM) architecture.

The controller performs a single-byte I2C write transaction by generating the START condition, transmitting the slave address and data byte, detecting ACK/NACK responses, and generating the STOP condition.

The design was verified through simulation using Icarus Verilog, with waveform analysis using GTKWave.

## Features

- 7-bit slave addressing
- Single-byte write transaction
- START and STOP condition generation
- MSB-first serial data transmission
- Open-drain SDA interface
- SCL clock generation using a configurable divider
- ACK/NACK detection
- FSM-based RTL architecture
- Busy and transaction completion indicators
- Simulation testbench with a simulated slave
- VCD waveform generation for debugging

## System Architecture


           +-------------------------+
           |      I2C Master         |
           |                         |
 start --->|     Control FSM         |
           |                         |
 address ->|   Address Shift Reg     |
 data ---->|     Data Shift Reg      |
           |                         |
           |   SCL Clock Divider     |
           |                         |
           |  START / STOP Control   |
           +------------+------------+
                        |
              +---------+---------+
              |                   |
             SCL                 SDA
              |                   |
              +-------+-----------+
                      |
                I2C Slave


## I2C Write Transaction

The controller performs the following sequence:

1. Generates the START condition.
2. Transmits the 7-bit slave address.
3. Transmits the write bit (`0`).
4. Releases SDA for the slave ACK response.
5. Transmits the 8-bit data byte.
6. Releases SDA for the data ACK response.
7. Generates the STOP condition.
8. Sets the `done` signal to indicate transaction completion.

## RTL Design

|      Signal       |          Description         |
|-------------------|------------------------------|
| `clk`             | System clock                 |
| `rst`             | Active-high reset            |
| `start`           | Initiates transaction        |
| `slave_addr[6:0]` | 7-bit slave address          |
| `data_in[7:0]`    | Data byte to transmit        |
| `scl`             | I2C serial clock             |
| `sda`             | Open-drain serial data       |
| `busy`            | Indicates active transaction |
| `done`            | Transaction completion pulse |
| `ack_error`       | Indicates NACK detection     |

## FSM States

|   State   |           Function               |
|-----------|----------------------------------|
| IDLE      | Waits for transaction request    |
| START     | Generates START condition        |
| BIT_LOW   | Sets data while SCL is low       |
| BIT_HIGH  | Transmits data during SCL high   |
| ACK_LOW   | Releases SDA for slave ACK       |
| ACK_HIGH  | Samples ACK/NACK response        |
| STOP_LOW  | Prepares STOP condition          |
| STOP_HIGH | Raises SCL while SDA remains low |
| STOP_END  | Releases SDA to generate STOP    |

## Project Structure


i2c_master_controller/
├── rtl/
│   └── i2c_master.v
├── tb/
│   └── i2c_master_tb.v
├── sim/
│   ├── i2c_sim.exe
│   └── i2c_waveform.vcd
├── docs/
└── README.md


## Simulation and Verification

### Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- Windows CMD

### Compile

```bash
iverilog -g2012 -o sim/i2c_sim.exe rtl/i2c_master.v tb/i2c_master_tb.v
```

### Run Simulation

```bash
vvp sim/i2c_sim.exe
```

### View Waveform

```bash
gtkwave sim/i2c_waveform.vcd
```

## Verification Results

Test transaction:

|          Parameter       |  Value   |
|--------------------------|----------|
| Slave Address            | `0x50`   |
| Write Bit                | `0`      |
| Transmitted Address Byte | `0xA0`   |
| Data Byte                | `0x3C`   |
| Address ACK              | Detected |
| Data ACK                 | Detected |

### Simulation Output


RESET TEST PASSED
I2C TRANSACTION STARTED
SLAVE RECEIVED ADDRESS: a0
SLAVE ACK DETECTED
SLAVE RECEIVED DATA: 3c
SLAVE ACK DETECTED
ADDRESS TEST PASSED
DATA TEST PASSED
ACK TEST PASSED
BUSY TEST PASSED
I2C TESTBENCH COMPLETED

**Result:** The address and data byte were successfully captured by the simulated slave, and the ACK and busy checks passed.

## Learning Outcomes

- Understanding I2C serial communication
- FSM-based RTL design
- Open-drain bus implementation
- Serial shift-register operation
- ACK/NACK handling
- RTL simulation and testbench development
- Digital waveform debugging

## Future Enhancements

- I2C read transaction support
- Repeated START condition
- Clock stretching support
- Configurable clock frequency
- Multi-byte data transfer
- FPGA hardware implementation

## Author

Thasnima Nargies M

Electronics and Communication Engineering  
VLSI & Chip Design

## Project Category

Digital Design | RTL Design | Verilog HDL | Serial Communication | VLSI
