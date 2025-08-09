
	section CODE

	include	"common.inc"

	PUBLIC	_vdp_cpu_to_vram

; void vdp_cpu_to_vram(const uint8_t* const source, uint32_t vdp_address, uint16_t length)

	; iy + 2 -> source (2, 3)
	; iy + 4 -> vdp_address (4, 5, 6, 7)
	; iy + 8 -> length (8, 9)

_vdp_cpu_to_vram:
	ld	iy, 0
	add	iy, sp

	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	; SET STATUS REGISTER to #02
	ld	bc, VDP_IO_ADDR
	ld	a, 2
	out	(BC), a
	ld	a, 0x80|15
	out	(BC), a

waitb4:
	in	a, (bc)
	bit	2, a
	jr	z, waitb4

	; Write to VDP_ADDR:
	;  0000 0 <A16..A14> 	of vdp_address
	;  1000 1110 		select register 14
	;  <A7..A0> 		of vdp_address
	;  01 <A13..A8> 	of vdp_address to enable write mode

	ld	a, (iy+6) 		; vdp_address bits 16..23

	and	%00001111		; extract bit 16..19 (super supports up to 20bit address)
	rlca				; move 'B16' to B1
	rlca				; move 'B16' to B2
	ld	b, a			; save

	ld	a, (iy+5) 		; vdp_address bits 8..15
	and	%11000000		; extract bits 15 and 14
	rlca				; move 'B15' to B0, 'B14' to B7
	rlca				; move 'B15' to B1, 'B14' to B0
	or	b			; merge with B16 to B19

	ld	bc, VDP_IO_ADDR
	out	(BC), a			; value for reg 14 (B19..B14)
	ld	a, $80+14		; VDP register 14
	out	(BC), a

	ld	a, (iy+4)		; vdp_address bits 0..7
	out	(BC), a			; submit bits 0 to 7

	ld	a, (iy+5)		; vdp_address bits 8..15
	and	%00111111		; extract bits 8..13
	or	%01000000		; enable write mode
	out	(BC), a			; submit bits 8 to 13

	ld	de, (iy+8)		; length
	ld	hl, (iy+2)		; source
	ld      bc, VDP_IO_DATA

	exx
	ld	bc, VDP_IO_ADDR
	exx
loop:
	exx
wait:
	in	a, (bc)
	bit	2, a
	jr	z, wait

	exx

	ld	a, (hl)
	inc	hl
	out	(BC), a
	dec	de
	ld	a, e		; warning only 16bit counter
	or	d
	jr	nz, loop

	ld	bc, VDP_IO_ADDR
	xor	a
	out	(BC), a
	ld	a, 0x80|15
	out	(BC), a

	RESTORE_IO_SPEED
	RESTORE_EI

	ret

