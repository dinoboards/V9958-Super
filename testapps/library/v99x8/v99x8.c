#include <ez80.h>
#include <stdbool.h>
#include <stdlib.h>
#include <v99x8.h>

uint8_t registers_mirror[REGISTER_COUNT] = {
    0x0E, // R0 - M5 = 1, M4 = 1, M3 = 1
    0x40, // R1 - ENABLE SCREEN, DISABLE INTERRUPTS, M1 = 0, M2 = 0
    0x1F, // R2 - PATTERN NAME TABLE := 0, A16 = 0
    0x00, // R3 - NO COLOR TABLE
    0x00, // R4 - N/A???
    0xF7, // R5 - SPRITE ATTRIBUTE TABLE -> FA00
    0x1E, // R6 - SPRITE PATTERN => F000
    0x00, // R7 - a background colour?
    0x8A, // R8 - COLOUR BUS INPUT, DRAM 64K, DISABLE SPRITE
    0x00, // R9 LN = 0(192 lines), S1, S0 = 0, IL = 0, EO = 0, NT = 1 (PAL), DC
          // = 0
    0x00, // R10 - color table - n/a
    0x01  // R11 - SPRITE ATTRIBUTE TABLE -> FA00
};

uint8_t register_31_mirror = 0;
uint8_t vdp_current_mode   = 255;

void set_base_registers(void) {
  DI;
  uint8_t *pReg = registers_mirror;

  for (uint8_t i = 0; i < REGISTER_COUNT; i++) {
    vdp_reg_write(i, *pReg); // if we inline the increment, the compiler (with -Oz seems to pre-increment the pointer)
    pReg++;
  }

  EI;
}

void vdp_clear_all_memory(void) {
  DI;
  vdp_reg_write(14, 0);
  vdp_out_cmd(0);
  vdp_out_cmd(0x40);
  for (screen_addr_t i = 0; i < MAX_SCREEN_BYTES; i++)
    vdp_out_dat(0);
  EI;
}

extern void delay(void);

void vdp_erase_bank0(uint8_t color) {
  vdp_cmd_wait_completion();

  DI;
  // Clear bitmap data from 0x0000 to 0x3FFF

  vdp_reg_write(17, 36);                // Set Indirect register Access
  vdp_out_reg_int16(0);                 // DX
  vdp_out_reg_int16(0);                 // DY
  vdp_out_reg_int16(512);               // NX
  vdp_out_reg_int16(212);               // NY
  vdp_out_reg_byte(color * 16 + color); // COLOUR for both pixels (assuming G7 mode)
  vdp_out_reg_byte(0);                  // Direction: VRAM, Right, Down
  vdp_out_reg_byte(CMD_HMMV);
  EI;
}

void vdp_erase_bank1(uint8_t color) {
  vdp_cmd_wait_completion();

  DI;
  // Clear bitmap data from 0x0000 to 0x3FFF

  vdp_reg_write(17, 36);                // Set Indirect register Access
  vdp_out_reg_int16(0);                 // DX
  vdp_out_reg_int16(256);               // DY
  vdp_out_reg_int16(512);               // NX
  vdp_out_reg_int16(212);               // NY
  vdp_out_reg_byte(color * 16 + color); // COLOUR for both pixels (assuming G7 mode)
  vdp_out_reg_byte(0x0);                // Direction: ExpVRAM, Right, Down
  vdp_out_reg_byte(CMD_HMMV);
  EI;
}
