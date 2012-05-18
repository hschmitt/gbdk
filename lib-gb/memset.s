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
1$:
	LD	A,B
	LD	(HL+),A
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,1$
	RET

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
