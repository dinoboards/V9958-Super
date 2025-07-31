#ifndef __Z80_H
#define __Z80_H

#include <stdint.h>

#define DI __asm__("DI")
#define EI __asm__("EI")

typedef uint16_t near_ptr_t;

/*
 *_port_out() - Output a byte to an I/O port
 * @port: the PORT_IO variable to be assigned
 * @value: the byte to be written to the port
 *
 * equivalent to port = value;
 * (uses a common function to avoid code duplication)
 *
 */
#define port_out(port, value) _port_out(((((uint16_t)port)) << 8) + ((uint16_t)(value)))
extern void _port_out(const uint16_t data);

// __sfr __at(0xA0) AYSEL;

#endif
