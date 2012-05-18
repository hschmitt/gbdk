	INCLUDE "macros.ms"
	.include "math.s"
	.module ftou.ms

	.area	_CODE
;	Float to unsigned
.ftou::
	bit	7,h
	jr	z,ftou_pos
	ld	a,#0
	ret
ftou_pos:
	ld	a,h
	cp	#64
	jr	nc,ftou_gteqone
	ld	a,#0
	ret
ftou_gteqone:
	or	a
	rr	l
	rr	d
	rr	e
	inc	h
	ld	a,h

	cp	#64+24
	jr	c,ftou_gteqone
	ld	a,e
	ret

.ftoi::
	ld	b,h
	ld	a,h
	and	#0x7f
	ld	h,a
	cp	#0x41
	jr	nc,ftoi_gteqone
	ld	a,#0
	ret
ftoi_gteqone:
	cp	#0x48		; 128 = 48800000
	jr	c,ftoi_norm
	ld	a,#0x7f		; +max
	bit	7,b
	ret	z
	ld	a,#0x80		; -max
	ret
ftoi_norm:
	cp	#64+8
	jr	z,ftoi_done
	or	a
	rr	l
	rr	d
	rr	e
	inc	h
	ld	a,h
	jr	ftoi_norm
ftoi_done:
	ld	a,l
	bit	7,b
	ret	z
	cpl
	inc	a
	ret
