# FPGA-Memories
Writing to/from FPGA memory
# FPGA ARC4 Decryption + 24-bit Key Search (DE1-SoC)

This project implements an **ARC4 (RC4) stream-cipher pipeline in hardware**, targeting the Intel/Altera **DE1-SoC (Cyclone V)**. The design uses **on-chip RAM blocks** to store cipher state and messages, supports **hardware decryption**, and includes a **brute-force key search** mode (with an optional **parallel** version for higher throughput). :contentReference[oaicite:0]{index=0}

> ARC4 generates a pseudo-random byte stream (“pad”) from a key and XORs it with the message; encryption and decryption are symmetric. :contentReference[oaicite:1]{index=1}

---

## Highlights
- **Full ARC4 datapath in hardware**
  - State initialization `S[i] = i`
  - Key Scheduling Algorithm (KSA): iterative mixing via swaps
  - Pseudo-Random Generation Algorithm (PRGA) + XOR to produce plaintext :contentReference[oaicite:2]{index=2}
- **24-bit key space (3-byte key)** with **big-endian key interpretation** :contentReference[oaicite:3]{index=3}
- **Length-prefixed message format** (Pascal-style): first byte is length, remaining bytes are ASCII payload :contentReference[oaicite:4]{index=4}
- **Ready/Enable (rdy/en) handshake** for clean variable-latency module integration :contentReference[oaicite:5]{index=5}
- **Embedded 1-port RAMs (256 × 8)** mapped to **M10K** blocks, compatible with **In-System Memory Content Editor (ISMCE)** for live inspection :contentReference[oaicite:6]{index=6}
- Optional **parallel cracking** using two cracking cores (even/odd key stepping) to speed up brute force :contentReference[oaicite:7]{index=7}

---

## Architecture (high level)

### Memory-centric design
- `S` memory: ARC4 internal permutation state (256 bytes)
- `CT` memory: ciphertext input (length-prefixed)
- `PT` memory: plaintext output (length-prefixed)

Messages are stored from address `0` with the first byte representing message length. :contentReference[oaicite:8]{index=8}

### Module handshake (rdy/en)
All major blocks use a **ready/enable microprotocol**:
- Callee asserts `rdy` when it can accept a request
- Caller asserts `en` only when `rdy=1`
- `en` is a one-cycle request; `rdy` must drop if the callee can’t accept back-to-back requests :contentReference[oaicite:9]{index=9}

---

## Tooling
- **SystemVerilog RTL**
- **Quartus Prime** for synthesis/fit on DE1-SoC
- **ModelSim** for RTL + post-synthesis simulation (where applicable)

---

## Demo / Portfolio Notes
- Add screenshots of:
  - Memory contents (S/CT/PT) viewed via ISMCE
  - A decrypted plaintext result in PT memory
  - Key discovered in cracking mode
- (Optional) Add a short video showing the board running and outputs updating.

---

## Collaboration
This was developed collaboratively (pair implementation). For a portfolio-friendly public version, sensitive/course-restricted material should be removed if required (e.g., private test vectors, provided scaffolding, etc.).

---

## References
- ARC4 algorithm structure (init/KSA/PRGA) and design notes. :contentReference[oaicite:10]{index=10}
- Ready/Enable handshake protocol. :contentReference[oaicite:11]{index=11}
- Length-prefixed string encoding. :contentReference[oaicite:12]{index=12}
- Embedded RAM configuration (256×8, M10K, ISMCE). :contentReference[oaicite:13]{index=13}
