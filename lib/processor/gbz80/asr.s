	.include	"global.s"

	.area	_CODE
.asr8::
	LD	B,#0x00
	; Fall through
	
	;; 16-bit arithmetic shift right
	;; 
	;; Entry conditions
	;;   BC = value to shift
	;;   A = number of bits to shift
	;; 
	;; Exit conditions
	;;   BC = result
	;;
	;; Register used: AF,BC,DE,HL
.asr16::
	OR	A		; Test if shift value is 0
	RET	Z		; If yes, return
1$:
	SRA	B		; Shift right
	RR	C
	DEC	A
	JR	NZ,1$		; Finished?
	RET

