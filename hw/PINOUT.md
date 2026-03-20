# ESP32-S3 Clockport Pin Mapping

## Clockport signals

The Amiga clockport is a 22-pin connector providing an 8-bit ISA-like bus.
Originally intended for a real-time clock module on the A1200, it exposes active-low /CS, /RD, /WR strobes and 3 address lines (A1-A3) for 8 register slots.

## Pin assignment (ESP32-S3 DevKitC)

| Signal | ESP32 GPIO | Direction | Notes |
|--------|-----------|-----------|-------|
| D0 | 4 | Bidir | Data bus bit 0 |
| D1 | 5 | Bidir | Data bus bit 1 |
| D2 | 6 | Bidir | Data bus bit 2 |
| D3 | 7 | Bidir | Data bus bit 3 |
| D4 | 15 | Bidir | Data bus bit 4 |
| D5 | 16 | Bidir | Data bus bit 5 |
| D6 | 17 | Bidir | Data bus bit 6 |
| D7 | 18 | Bidir | Data bus bit 7 |
| /CS | 8 | Input | Chip select, active low |
| /RD | 9 | Input | Read strobe, active low |
| /WR | 10 | Input | Write strobe, active low |
| A1 | 11 | Input | Register address bit 1 |
| A2 | 12 | Input | Register address bit 2 |
| A3 | 13 | Input | Register address bit 3 |
| /INT | 14 | Output | Interrupt to Amiga, open drain |

## Level shifting

The Amiga clockport is 5V TTL. The ESP32-S3 is 3.3V CMOS.
Use a 74LVC245 (or 74LVC4245) for bidirectional level shifting on D0-D7.
Control signals (/CS, /RD, /WR, A1-A3) are inputs to the ESP32 and can
use a resistor divider or a unidirectional level shifter (74LVC1G125).
/INT is open-drain from the ESP32 with a 4.7k pull-up to 5V on the Amiga side.

## Clockport connector pinout

Pin 1 is at the top-left when the A1200 is oriented with the keyboard facing you.

| Pin | Signal | Pin | Signal |
|-----|--------|-----|--------|
| 1 | /INT2 | 2 | GND |
| 3 | /INT6 | 4 | GND |
| 5 | /IORD | 6 | GND |
| 7 | /IOWR | 8 | GND |
| 9 | /CS | 10 | GND |
| 11 | A2 | 12 | A3 |
| 13 | A4 | 14 | D0 |
| 15 | D1 | 16 | D2 |
| 17 | D3 | 18 | D4 |
| 19 | D5 | 20 | D6 |
| 21 | D7 | 22 | +5V |

Note: A0 is not exposed on the clockport connector. A1 is the lowest address line available. The 8 register offsets ($00-$0E) are decoded from A1-A3, giving even-byte addresses only (word-aligned on the 68000 bus).

## Power

The clockport provides +5V at pin 22. Regulate down to 3.3V for the ESP32
using an AMS1117-3.3 or similar LDO. Current draw of the ESP32-S3 is
typically 100-300 mA depending on WiFi usage.

## BOM

| Part | Qty | Notes |
|------|-----|-------|
| ESP32-S3 DevKitC | 1 | Or any ESP32-S3 module |
| 74LVC245 | 1 | Bidirectional level shifter for data bus |
| 74LVC1G125 | 3 | Unidirectional for /CS, /RD, /WR (or resistor dividers) |
| AMS1117-3.3 | 1 | 5V to 3.3V regulator |
| 4.7k resistor | 1 | Pull-up for /INT |
| 22-pin header | 1 | Clockport connector |
| Bypass caps | 3 | 100nF near ICs |
