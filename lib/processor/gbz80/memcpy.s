	.include	"global.s"

	.area	_CODE

	;; Copy memory zone
	;; 
	;; Entry conditions
	;;   BC = source
	;;   DE = length
	;;   HL = destination
	;; 
	;; Register used: AF, BC, DE, HL
.memset::
	xor	a
	or	e
	jr	nz,2$
	or	d
	ret	z		; Nothing to do
	dec	d		; e is zero, so cancel out the extra loop
2$:	
	inc	d
1$:
	ld	a,(bc)
	LD	(HL+),A
	inc	bc
	dec	e
	jr	nz,1$
	dec	d
	jr	nz,1$
	ret

_memcpy::
	PUSH	BC

	LDA	HL,9(SP)	; Skip return address and registers
	LD	D,(HL)		; DE = n
	DEC	HL
	LD	E,(HL)
	DEC	HL
	LD	B,(HL)		; BC = s2
	DEC	HL
	LD	C,(HL)
	DEC	HL
	LD	A,(HL-)		; HL = s1
	LD	L,(HL)
	LD	H,A
	PUSH	HL
	CALL	.memcpy
	POP	DE		; Return s1

	POP	BC
	RET
