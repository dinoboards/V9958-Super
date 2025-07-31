
	SECTION CODE

	include	"common.inc"

	PUBLIC	_vdp_cmd_logical_move_vdp_to_vram

; extern void vdp_cmd_logical_move_vdp_to_vram(
;     uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t colour, uint8_t direction, uint8_t operation);

	; x => iy + 2 ; 3
	; y => iy + 4 ; 6
	; width => iy + 6 ; 9
	; height => iy + 8 ; 12
	; colour => iy + 10 ; 15
	; direction => iy + 11 ; 18
	; operation => iy + 12 ; 21

_vdp_cmd_logical_move_vdp_to_vram:
	ld	iy, 0
	add	iy, sp

	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	ld	bc, VDP_IO_ADDR
	ld	a, 36					; submit 36, with auto increment
	out	(bc), a
	ld	a, 0x80|17				; to register 17
	out	(bc), a

	ld	bc, VDP_IO_REGS

	ld	a, (iy+2)				; load x
	out	(bc), a					; low byte into #R36
	ld	a, (iy+3)				; load x
	out	(bc), a					; high byte into #R37

	ld	a, (iy+4)				; load y
	out	(bc), a					; low byte into #R38
	ld	a, (iy+5)				; load y
	out	(bc), a					; high byte into #R39

	ld	a, (iy+6)				; load width
	out	(bc), a					; low byte into #R40
	ld	a, (iy+7)				; load width
	out	(bc), a					; high byte into #R41

	ld	a, (iy+8)				; load height
	out	(bc), a					; low byte into #R42
	ld	a, (iy+9)				; load height
	out	(bc), a					; high byte into #R43

	ld	a, (iy+10)				; load colour
	out	(bc), a					; into #R44

	ld	a, (iy+11)				; load direction
	out	(bc), a					; into #R45

	ld	a, (iy+12)				; load operation
	or	CMD_LMMV
	out	(bc), a					; into #R46


	ld	bc, VDP_IO_ADDR
	XOR	A
	OUT	(bc), A
	LD	A, 0x80 | 15
	OUT	(bc), A

	RESTORE_IO_SPEED
	RESTORE_EI

	ret
