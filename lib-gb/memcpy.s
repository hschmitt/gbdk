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
.memcpy::
	JR	2$
1$:
	LD	A,(BC)
	LD	(HL+),A
	INC	BC
	DEC	DE
2$:
	LD	A,D
	OR	E
	JR	NZ,1$
	RET

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
