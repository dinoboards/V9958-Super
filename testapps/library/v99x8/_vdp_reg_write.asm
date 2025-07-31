
	SECTION CODE

	include "common.inc"

	PUBLIC	__vdp_reg_write

; void __vdp_reg_write(uint16_t rd)
__vdp_reg_write:
	ld	iy, 0
	add	iy, sp

	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	ld	l, (IY+2)
	ld	h, (IY+3)
	ld	bc, VDP_IO_ADDR
	out	(BC), l
	ld	a, 0x80
	or	h

	out	(BC), a

	RESTORE_IO_SPEED
	RESTORE_EI
	ret

