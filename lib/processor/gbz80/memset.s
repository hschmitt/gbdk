	.include	"global.s"

	.area	_CODE

	;; Set memory zone
	;; 
	;; Entry conditions
	;;   A,B = value
	;;   DE = length
	;;   HL = destination
	;; 
	;; Register used: AF, B, DE, HL
.memset::
	xor	a
	or	e
	jr	nz,2$
	or	d
	ret	z		; Nothing to do
	dec	d		; e is zero, so cancel out the extra loop
2$:	
	inc	d
	ld	a,b
1$:
	LD	(HL+),A
	dec	e
	jr	nz,1$
	dec	d
	jr	nz,1$
	ret
	
_memset::
	PUSH	BC

	LDA	HL,8(SP)	; Skip return address and registers
	LD	D,(HL)		; DE = n
	DEC	HL
	LD	E,(HL)
	DEC	HL
	LD	B,(HL)		; B = c
	DEC	HL
	LD	A,(HL-)		; HL = s1
	LD	L,(HL)
	LD	H,A
	PUSH	HL
	CALL	.memset
	POP	DE		; Return s1

	POP	BC
	RET
