
	SECTION CODE

	include	"common.inc"

	PUBLIC	_vdp_out_reg_int16

; void vdp_out_reg_int16(uint16_t b)
_vdp_out_reg_int16:
	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	ld	iy, 0
	add	iy, sp
	ld	l, (IY+2)
	ld	h, (IY+3)
	ld	bc, (VDP_IO_REGS)
	out	(bc), l
	xor	a
	out	(bc), h

	RESTORE_IO_SPEED
	RESTORE_EI

	ret
