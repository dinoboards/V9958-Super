

	SECTION	CODE

	include	"common.inc"

	PUBLIC	_vdp_cmd_move_vram_to_vram

;extern void vdp_cmd_move_vram_to_vram(uint16_t x, uint16_t y, uint16_t to_x, uint16_t to_y, uint16_t width, uint16_t height, uint8_t direction);

	; x => iy + 2; 3
	; y => iy + 4; 6
	; to_x => iy + 6; 9
	; to_y => iy + 8; 12
	; width => iy + 10; 15
	; height => iy + 12; 18
	; dir => iy + 14; 21

_vdp_cmd_move_vram_to_vram:
	ld	iy, 0
	add	iy, sp

	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	ld	bc, VDP_IO_ADDR
	ld	a, 32					; submit 36, with auto increment
	out	(bc), a
	ld	a, 0x80|17				; to register 17
	out	(bc), a

	ld	bc, VDP_IO_REGS

	ld	hl, (iy+2)				; load x
	out	(bc), l					; low byte into #R32
	out	(bc), h					; high byte into #R33

	ld	hl, (iy+4)				; load y
	out	(bc), l					; low byte into #R34
	out	(bc), h					; high byte into #R35

	ld	hl, (iy+6)				; load to_x
	out	(bc), l					; low byte into #R36
	out	(bc), h					; high byte into #R37

	ld	hl, (iy+7)				; load to_y
	out	(bc), l					; low byte into #R38
	out	(bc), h					; high byte into #R39

	ld	hl, (iy+10)				; load width
	out	(bc), l					; low byte into #R40
	out	(bc), h					; high byte into #R41

	ld	hl, (iy+12)				; load height
	out	(bc), l					; low byte into #R42
	out	(bc), h					; high byte into #R43

	xor	a
	out	(bc), a					; N/A #R44

	ld	a, (iy+14)				; load direction
	out	(bc), a					; low byte into #R45

	ld	a, CMD_HMMM
	out	(bc), a					; into #R46

	ld	bc, VDP_IO_ADDR
	XOR	A
	OUT	(bc), A
	LD	A, 0x80 | 15
	OUT	(bc), A

	RESTORE_IO_SPEED
	RESTORE_EI

	ret
