
	SECTION CODE
	PUBLIC	__port_out

; void _port_out(const uint16_t data)
__port_out:
	ld	iy, 0
	add	iy, sp
	ld	a, (IY+2)
	ld	c, (IY+3)
	ld	b, $FF
	out	(BC), a
	ret

