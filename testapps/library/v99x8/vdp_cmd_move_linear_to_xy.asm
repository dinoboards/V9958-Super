
	SECTION	CODE
	include	"common.inc"

	PUBLIC	_vdp_cmd_move_linear_to_xy
;extern void vdp_cmd_move_linear_to_xy(screen_addr_t src_addr, uint16_t x, uint16_t y, uint16_t width, uint16_t height, uint8_t direction, uint8_t operation);

	; src => iy + 2 ; was 3
	; x => iy + 6  ; was 6
	; y => iy + 8 ; was 9
	; width => iy + 10 ; was 12
	; height => iy + 12 ; was 15
	; dir => iy + 14 ; was 18
	; op => iy + 15 ; was 21

_vdp_cmd_move_linear_to_xy:
	ld	iy, 0
	add	iy, sp

	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	ld	bc, VDP_IO_ADDR
	ld	a, 32					; submit 32, with auto increment
	out	(bc), a
	ld	a, 0x80|17				; to register 17
	out	(bc), a

	ld	bc, VDP_IO_REGS

	ld	hl, (iy+2)				; load x
	out	(bc), l					; low byte into #R32
	out	(bc), h					; mid byte into #R33
	ld	a, (iy+4)
	out	(bc), a					; high byte #R34

	xor	a
	out	(bc), a					; N/A #R35

	ld	hl, (iy+6)				; load to_x
	out	(bc), l					; low byte into #R36
	out	(bc), h					; high byte into #R37

	ld	hl, (iy+8)				; load to_y
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

	ld	a, (iy+15)				; load operation
	or	CMD_BMXL
	out	(bc), a					; into #R46

	RESTORE_IO_SPEED
	RESTORE_EI

	ret
