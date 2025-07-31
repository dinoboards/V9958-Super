
	SECTION CODE

	; include "common.inc"

	PUBLIC	_hbios_sys_get_tmr_freq

; extern uint8_t hbios_sys_get_tmr_freq(void);

_hbios_sys_get_tmr_freq:
	push	ix

	ld	bc, 0xF8D0

	call	$FFF0

	ld	l, c
	pop	ix
	ret
