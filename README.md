# amigasoftfpu

An IEEE 754 floating-point co-processor for the Amiga, built with an ESP32-S3 and written in PIM4 Modula-2 using the mx compiler.

## What this is

An ESP32-S3 sits on the Amiga's clockport and acts as a hardware FPU. The Amiga sends float operations (add, mul, div, sqrt, etc.) over the 8-bit clockport bus. The ESP32 computes the result using its single-precision FPU and returns it. On a stock 68000 with no FPU, this provides roughly 50-100x faster floating-point math than software emulation.

## How it works

The Amiga writes operands and a command byte to clockport registers. The ESP32 firmware polls the bus, dispatches the operation, and posts the result and IEEE 754 status flags (NaN, Inf, zero, sign, overflow, div-by-zero) back to the result registers.

A single-precision float operation takes about 5-7 us round-trip (limited by clockport bus speed, not compute). That gives roughly 140-200 Kop/s sustained throughput, compared to ~2-5 Kop/s for 68000 software float.

## Architecture

```
src/
  FPUProto.def    Protocol constants: opcodes, status bits, register layout
  FPUCore.def     Dispatch engine: takes opcode + operands, returns result
  FPUCore.mod     Implements all float ops using hardware REAL + RealMath
  FPUBus.def      Bus interface: register-level clockport protocol
  FPUBus.mod      Reads bus, dispatches to FPUCore, posts results
  BusBridge.def   C FFI to ESP32 GPIO driver
  Main.mod        Main loop: init + poll

esp/
  bus.c           Clockport bus driver (stub for desktop, GPIO for ESP32)
  gpio_bridge.c   ESP-IDF GPIO configuration (placeholder)

hw/
  PINOUT.md       ESP32-S3 pin mapping, level shifting, BOM

tests/
  Main.mod        Desktop test harness: injects commands, checks results
  Inject.def      C FFI to bus stub injection helpers
```

## Dependencies

- [mx](https://github.com/fitzee/mx) Modula-2 compiler
- [m2float](https://github.com/fitzee/m2float) for FloatBits and RealMath
- ESP-IDF (for hardware target only; desktop testing uses stub bus driver)

## Building

Desktop (test harness):

```
mx test
```

ESP32 (hardware target):

```
mx --emit-c src/Main.mod -I src -o build/main.c
# Then integrate build/main.c into your ESP-IDF project
```

## Targeting the ESP32

mx compiles Modula-2 to C. To run on an ESP32-S3, you emit the C and build it within an ESP-IDF project.

### Setup

```
# Create an ESP-IDF project
idf.py create-project amigasoftfpu_fw
cd amigasoftfpu_fw

# Generate the C source from mx
mx --emit-c ../src/Main.mod -I ../src -o main/m2_main.c

# Copy the C bus driver
cp ../esp/bus.c main/
cp ../esp/gpio_bridge.c main/
```

### Integrate with ESP-IDF

Edit `main/CMakeLists.txt`:

```cmake
idf_component_register(
    SRCS "m2_main.c" "bus.c" "gpio_bridge.c"
    INCLUDE_DIRS "."
)
```

The mx-generated C has its own `main()`. ESP-IDF expects `app_main()`. Add a one-line wrapper in `main/app_entry.c`:

```c
extern int main(int argc, char **argv);
void app_main(void) { main(0, (char**)0); }
```

And add `app_entry.c` to the SRCS list.

### Build and flash

```
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/tty.usbmodem* flash monitor
```

### Pin configuration

See [hw/PINOUT.md](hw/PINOUT.md) for the GPIO assignments and level shifting requirements. The stub `bus.c` included in the repo uses a register array for desktop testing. For real hardware, replace the `bus_init` / ISR functions with ESP-IDF GPIO calls as described in `esp/gpio_bridge.c`.

## Register protocol

| Offset | Name | Dir | Purpose |
|--------|------|-----|---------|
| $00 | CMD | W | Operation code |
| $02 | ARGA_HI | W | Operand A, high 16 bits |
| $04 | ARGA_LO | W | Operand A, low 16 bits |
| $06 | ARGB_HI | W | Operand B, high 16 bits |
| $08 | ARGB_LO | W | Operand B, low 16 bits |
| $0A | RES_HI | R | Result, high 16 bits |
| $0C | RES_LO | R | Result, low 16 bits |
| $0E | STATUS | R | Ready, NaN, Inf, Zero, Neg, Overflow, DivByZero, Invalid |

Operands and results are 32-bit IEEE 754 binary32 values split into two 16-bit clockport writes/reads.

## Opcodes

| Code | Operation | Operands |
|------|-----------|----------|
| 1 | Add | A + B |
| 2 | Sub | A - B |
| 3 | Mul | A * B |
| 4 | Div | A / B |
| 5 | Sqrt | sqrt(A) |
| 6 | Neg | -A |
| 7 | Abs | \|A\| |
| 8 | Cmp | compare A, B |
| 9 | I2F | int32 to float |
| 10 | F2I | float to int32 (truncate) |
| 255 | Ping | returns protocol version |

## Amiga integration

On the Amiga side, a replacement `mathieeesingbas.library` redirects standard math library calls to the clockport device. Any Amiga program that uses the system math libraries gets hardware float acceleration with no code changes.

## License

MIT License. See [LICENSE](LICENSE).

Copyright (c) 2026 Matt Fitzgerald
