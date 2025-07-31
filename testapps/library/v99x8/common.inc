
CMD_PSET	equ	$50
CMD_LINE	equ	$70
CMD_LMMV	equ	$80
CMD_LMMM	equ	$90
CMD_LMMC	equ	$B0
CMD_HMMV	equ	$C0
CMD_HMMM	equ	$D0
CMD_HMMC	equ	$F0

VDP_IO_DATA	equ	0xFF98
VDP_IO_ADDR	equ	0xFF99
VDP_IO_PALT	equ	0xFF9A
VDP_IO_REGS	equ	0xFF9B

macro	SET_SLOW_IO_SPEED
endm
macro	RESTORE_IO_SPEED
endm

macro	DI_AND_SAVE
	ld	a, i ; P = IEF2
	di
	push	af
endm

macro	RESTORE_EI
LOCAL skipEI
	pop	af
	jp	po, skipEI
	ei
skipEI:
endm
