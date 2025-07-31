	include	"cpm.inc"

	SECTION	CODE
	PUBLIC	_cpm_c_rawio

_cpm_c_rawio:
	push	ix
	ld	c, C_RAWIO
	ld	e, $FF
	call	BDOS
	ld	l, a
	pop	ix
	ret
