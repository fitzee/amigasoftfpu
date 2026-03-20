/*
 * Clockport bus interface for ESP32.
 *
 * Pin mapping (accent, accent accent accent accent accent accent accent):
 *   D0-D7:  GPIO 4,5,6,7,15,16,17,18  (accent, accent 8-bit data bus)
 *   /CS:    GPIO 8                      (clockport chip select, active low)
 *   /RD:    GPIO 9                      (read strobe, active low)
 *   /WR:    GPIO 10                     (write strobe, active low)
 *   A1-A3:  GPIO 11,12,13              (register address, accent 3 bits)
 *   /INT:   GPIO 14                     (interrupt to Amiga, active low, open drain)
 *
 * Register file: 8 x 16-bit registers, accent accent accent by A1-A3.
 * accent accent accent accent accent accent accent accent accent accent accent accent.
 *
 * For desktop testing, this file provides a stub implementation
 * using a simple array. Replace with ESP-IDF GPIO code for hardware.
 */

#include <stdint.h>

/* Register file: 8 registers, indexed by offset/2 */
static volatile uint16_t regs[8];
static volatile int cmd_pending = 0;

void bus_init(void) {
    for (int i = 0; i < 8; i++) regs[i] = 0;
    cmd_pending = 0;

    /* On real ESP32, configure GPIO pins here:
     *   gpio_config() for data bus, control signals
     *   gpio_install_isr_service() for /CS + /WR edge detection
     */
}

int bus_has_cmd(void) {
    return cmd_pending;
}

int bus_read_reg(int offset) {
    int idx = offset / 2;
    if (idx < 0 || idx >= 8) return 0;
    return (int)regs[idx];
}

void bus_write_reg(int offset, int val) {
    int idx = offset / 2;
    if (idx < 0 || idx >= 8) return;
    regs[idx] = (uint16_t)(val & 0xFFFF);
}

/* --- Test harness helpers (not used on real hardware) --- */

void bus_inject_cmd(int cmd, uint32_t argA, uint32_t argB) {
    regs[0] = (uint16_t)cmd;           /* CMD */
    regs[1] = (uint16_t)(argA >> 16);  /* ARGA_HI */
    regs[2] = (uint16_t)(argA);        /* ARGA_LO */
    regs[3] = (uint16_t)(argB >> 16);  /* ARGB_HI */
    regs[4] = (uint16_t)(argB);        /* ARGB_LO */
    cmd_pending = 1;
}

uint32_t bus_get_result(void) {
    return ((uint32_t)regs[5] << 16) | (uint32_t)regs[6];
}

int bus_get_status(void) {
    return (int)regs[7];
}

void bus_clear_cmd(void) {
    cmd_pending = 0;
}
