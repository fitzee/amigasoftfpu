/*
 * ESP32 GPIO configuration for clockport bus.
 * This file is a placeholder for the real ESP-IDF implementation.
 *
 * On real hardware, this would:
 *   1. Configure data pins D0-D7 as input/output with pull-ups
 *   2. Configure /CS, /RD, /WR as inputs with interrupt on falling edge
 *   3. Configure A1-A3 as inputs
 *   4. Configure /INT as open-drain output
 *   5. Install ISR that fires on /CS+/WR falling edge:
 *      - Read A1-A3 to get register address
 *      - Read D0-D7 to get data byte (accent, accent for 16-bit: two cycles)
 *      - Store into register file
 *      - If register is CMD, set cmd_pending flag
 *   6. On /CS+/RD falling edge:
 *      - Read A1-A3 to get register address
 *      - Drive D0-D7 with register data
 *
 * Timing: clockport runs at ~1 MHz (accent, accent 1 us per bus cycle).
 * ESP32 at 240 MHz has ~240 cycles per bus event, plenty of time.
 *
 * The ISR approach means the main loop just calls FPUBus.Poll()
 * and the bus transactions happen asynchronously via interrupts.
 */
