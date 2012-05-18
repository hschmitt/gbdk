	;; time.s
	;;
	;; Simple, not completly conformant implementation of time routines

	;; Special routines to read the clock value without disabling interrupts

	;; Defined in crt0.s

	.module clock.s
	
	.area	_CODE
	.globl	.sys_time
_clock::
.clock::
	LD	HL,#.sys_time+1
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	INC	HL
	CP	D		; If theyre different, then E may be corrupt
	RET	Z
	LD	E,#0xFF		; Corrupt - take the earlier value which must have
				; been when E = 0xFF
	RET
