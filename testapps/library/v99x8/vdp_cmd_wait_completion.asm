
	section CODE

	include	"common.inc"

	PUBLIC _vdp_cmd_wait_completion

_vdp_cmd_wait_completion:
	; Set read register to 2

	DI_AND_SAVE
	SET_SLOW_IO_SPEED

	ld	bc, VDP_IO_ADDR

	ld	a, 2
	out	(bc), a					; DELAY and LD provide the ~2us required delay
	ld	a, 0x80|15				; measured on CPU running @25Mhz
	out	(bc), a

 	exx
	ld	b, $10
	ld  	de, 0
	ld	hl, 0
	exx

_vdp_cmd_wait_completion_wait:
	in	a, (BC)
	rrca
	jr	nc, exit 				; _vdp_cmd_wait_completion_ready

	exx
	dec	hl
	xor	a
	sbc	hl, de
	exx
	jr	nz, _vdp_cmd_wait_completion_wait
	exx
	dec	b
	exx
	jr	nz, _vdp_cmd_wait_completion_wait

exit:
	XOR	A
	OUT	(bc), A
	LD	A, 0x80 | 15
	OUT	(bc), A

	RESTORE_IO_SPEED
	RESTORE_EI
	ret
