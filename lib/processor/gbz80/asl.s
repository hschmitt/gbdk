	.include	"global.s"

	.area	_CODE

.asl8::
.lsl8::
	LD	B,#0x00
	; Fall through

	;; 16-bit arithmetic and logical shift left
	;; 
	;; Entry conditions
	;;   BC = value to shift
	;;   A = number of bits to shift
	;; 
	;; Exit conditions
	;;   BC = result
	;;
	;; Register used: AF,BC,DE,HL
.asl16::
.lsl16::
	OR	A		; Test if shift value is 0
	RET	Z		; If yes, return
1$:
	SLA	C		; Shift left
	RL	B
	DEC	A
	JR	NZ,1$		; Finished?
	RET

