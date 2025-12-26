
# ARC4 Cipher Decryption and Cracking System

A hardware implementation of the ARC4 stream cipher with brute-force decryption capabilities, designed in SystemVerilog for FPGA deployment on the DE1-SoC board.

## Overview

This project implements a complete ARC4 (Alleged RC4) encryption/decryption system in hardware, featuring both single and parallel decryption cores. The design demonstrates advanced digital design concepts including embedded memory management, ready-enable microprotocols, and parallel processing architectures.

## Features

### Core Functionality
- **Complete ARC4 Implementation**: Full hardware implementation of the ARC4 stream cipher algorithm
- **Key-Scheduling Algorithm (KSA)**: Entropy spreading across the cipher state for secure encryption
- **Pseudo-Random Generation Algorithm (PRGA)**: Bytestream generation and XOR operations for encryption/decryption
- **Brute-Force Key Cracking**: Sequential key space search with validation of human-readable ASCII output
- **Parallel Cracking**: Dual-core implementation for 2x performance improvement

### Technical Highlights
- **Memory Architecture**: Utilizes Cyclone V M10K embedded RAM blocks with custom initialization
- **Ready-Enable Protocol**: Efficient handshaking mechanism for variable-latency operations
- **Length-Prefixed Strings**: Pascal-style string encoding for flexible message handling
- **FPGA Integration**: In-System Memory Content Editor support for runtime debugging
- **24-bit Key Space**: Optimized for practical cracking demonstrations (16.7M combinations)

## Architecture

### Module Hierarchy
```
task5 (top-level)
├── ct_mem (ciphertext storage)
├── doublecrack
│   ├── pt (shared plaintext output)
│   ├── crack_core_1 (even keys: 0, 2, 4...)
│   │   ├── pt_local
│   │   └── arc4
│   │       ├── s_mem (cipher state)
│   │       ├── init
│   │       ├── ksa
│   │       └── prga
│   └── crack_core_2 (odd keys: 1, 3, 5...)
│       ├── pt_local
│       └── arc4
│           ├── s_mem
│           ├── init
│           ├── ksa
│           └── prga
```

### Algorithm Stages

1. **Initialization**: State array S initialized to [0..255]
2. **Key Scheduling**: Key entropy distributed across state via swapping operations
3. **Bytestream Generation**: Pseudo-random pad generation from cipher state
4. **Decryption**: XOR operation between ciphertext and generated pad

## Implementation Details

### ARC4 Algorithm

The implementation follows the standard ARC4 cipher specification with a 24-bit key:

**Key-Scheduling Algorithm (KSA)**:
```
j = 0
for i = 0 to 255:
    j = (j + s[i] + key[i mod 3]) mod 256
    swap values of s[i] and s[j]
```

**Pseudo-Random Generation Algorithm (PRGA)**:
```
i = 0, j = 0
message_length = ciphertext[0]
for k = 1 to message_length:
    i = (i+1) mod 256
    j = (j+s[i]) mod 256
    swap values of s[i] and s[j]
    pad[k] = s[(s[i]+s[j]) mod 256]
    plaintext[k] = pad[k] xor ciphertext[k]
```

### Ready-Enable Microprotocol

The design uses a sophisticated handshaking mechanism:
- **`rdy`** signal indicates module readiness to accept requests
- **`en`** signal triggers operation start when `rdy` is asserted
- Prevents combinational loops and ensures proper timing
- Supports pipelined and buffered architectures

### Memory Configuration

- **S Memory**: 256×8-bit state array (M10K blocks)
- **Ciphertext Memory**: 256×8-bit storage with In-System Memory Editor support
- **Plaintext Memory**: 256×8-bit output buffer
- Single-port configuration optimized for FPGA resource utilization

### Key Format

Keys are stored in big-endian format. For example, key `0x035F3C`:
- `key[0]` = `0x03`
- `key[1]` = `0x5F`
- `key[2]` = `0x3C`

### Message Encoding

Messages use length-prefixed (Pascal-style) string encoding:
- First byte contains the message length (0-255 characters)
- Remaining bytes contain ASCII character values
- Example: "hello" → `[0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F]`

## Project Structure
```
.
├── task1/              # State initialization module
│   ├── init.sv
│   ├── task1.sv
│   └── tb_*.sv        # Testbenches
├── task2/              # Key-scheduling algorithm
│   ├── ksa.sv
│   ├── task2.sv
│   └── tb_*.sv
├── task3/              # Complete decryption
│   ├── prga.sv
│   ├── arc4.sv
│   ├── task3.sv
│   └── tb_*.sv
├── task4/              # Single-core cracking
│   ├── crack.sv
│   ├── task4.sv
│   └── tb_*.sv
└── task5/              # Parallel cracking
    ├── doublecrack.sv
    ├── crack.sv
    ├── task5.sv
    └── tb_*.sv
```

## Hardware Requirements

- **FPGA Board**: DE1-SoC (Cyclone V)
- **Development Tools**: 
  - Quartus Prime (for synthesis and programming)
  - ModelSim (for simulation)
  - Intel FPGA IP Catalog (for memory generation)

## Key Features by Module

### Task 1: State Initialization
- Initializes ARC4 state array to [0..255]
- Ready-enable protocol implementation
- Single-cycle memory writes

### Task 2: Key Scheduling
- Implements KSA with 24-bit key support
- State permutation through swap operations
- Switch-based key input (SW[9:0] for lower bits)

### Task 3: Complete Decryption
- Full PRGA implementation with XOR decryption
- Three memory instances (S, CT, PT)
- Handles variable-length messages (0-255 bytes)

### Task 4: Brute-Force Cracking
- Sequential key search from 0x000000 to 0xFFFFFF
- ASCII validation (0x20-0x7E range check)
- Seven-segment display output for discovered keys
- Displays "------" if no valid key found

### Task 5: Parallel Cracking
- Dual-core architecture for 2x speedup
- Core 1: searches even keys (0, 2, 4, ...)
- Core 2: searches odd keys (1, 3, 5, ...)
- Shared plaintext memory for result aggregation
- First-found-wins termination strategy

## Design Constraints

- All sequential logic uses positive clock edge triggering
- Synchronous active-low reset throughout
- No latches or tristate elements
- Clock and reset paths remain unmodified
- Memory instances follow specific naming conventions for debugging

## Testing

Comprehensive testbenches provided for each module:
- **RTL simulation**: Functional verification with ModelSim
- **Post-synthesis simulation**: Timing-accurate netlist validation
- **FPGA verification**: In-System Memory Content Editor for runtime inspection

### Example Test Cases

**Ciphertext 1** (Key: `0x1E4600`):
```
A7 FD 08 01 84 45 68 85 82 5C 85 97 43 4D E7 07 25 0F 9A EC C2 6A 4E A7 49 E0 EB 71 ...
```

**Ciphertext 2** (Key: `0x000018`):
```
56 C1 D4 8C 33 C5 52 01 04 DE CF 12 22 51 FF 1B 36 81 C7 FD C4 F2 88 5E 16 9A B5 D3 ...
```

Both decrypt to English sentences when the correct key is used.

## Performance

- **Single-core cracking**: ~1.67M key attempts in 2 mins
- **Dual-core cracking**: ~1.67M key attempts/ min
- Clock frequency: Depends on FPGA timing constraints and optimization utilized PLL clock and more cracking cores(8 cores) to increase speed to 1.67M key attempts in 9 seconds 
- Memory access: Single-cycle read/write to embedded RAM

## Applications

This project demonstrates concepts applicable to:
- Hardware security implementations
- Cryptanalysis and cipher breaking
- Parallel processing architectures
- Embedded memory management
- Protocol design for variable-latency operations

## Learning Outcomes

- Advanced SystemVerilog design techniques
- FPGA memory resource utilization (M10K blocks)
- Microprotocol design and implementation
- Hardware optimization for cryptographic operations
- Parallel processing and resource sharing
- FSM design for complex control flows


## License

Educational project - Implementation details based on standard ARC4 specification.
