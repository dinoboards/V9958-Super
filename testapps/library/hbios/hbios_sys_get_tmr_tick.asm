
	SECTION CODE

	; include "common.inc"

	PUBLIC	_hbios_sys_get_tmr_tick

; extern uint32_t hbios_sys_get_tmr_tick(void);

_hbios_sys_get_tmr_tick:
	push	ix

	ld	bc, 0xF8D0

	CALL	$FFF0

	pop	ix
	ret
