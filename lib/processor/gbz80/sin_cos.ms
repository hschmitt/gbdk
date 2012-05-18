	INCLUDE "macros.ms"
	.include "math.s"
	.module sin_cos.ms

	.area	_BSS
tmp:
	.ds	1
	.area _CODE

; Compute cosine of HLDE
.cos::
	pushf	.pi2
	call	.fadd32
.sin::
	pushf	.onedivtwopi
	call	.fmul32
	call	.dec
	ld	a,h		; Mul by 4
	ld	c,h		; Save the sign bit
	and	#0x7f
	inc	a
	inc	a
	bit	7,h
	jr	z,1$
	or	#0x80
1$:
	ld	h,a
sin_norm:
	cp	#0x42
	jr	z,sin_inc
	or	a
	rr	l
	rr	d
	inc	a
	jr	sin_norm
sin_inc:
	; Upper 2 bits of l are the quadrant
	ld	b,l
	rl	d
	rl	l
	rl	d
	rl	l	; l is now the offset into the quadrant

	bit	6,b
	jr	z,sin_sense	; Correct sense

	ld	a,l
	cpl
	inc	a
	ld	l,a
sin_sense:
	ld	h,#0
	add	hl,hl
	add	hl,hl
	ld	de,#sin_table
	add	hl,de

	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a
	ld	a,b
	and	#0x80
	or	h
	bit	7,c
	jr	z,sin_notneg
	xor	#0x80
sin_notneg:	
	ld	h,a
	ret
