	;; time.s

	;; Simple, not completly conformant implementation of time routines

	;; Defined in crt0.s

	.module clock.s
	
	.area	_CODE
	.globl	.sys_time
_clock::
.clock::
	LD	HL,#.sys_time
	DI
	LD	A,(HL+)
	EI
	LD	D,(HL)		; Use that the instruction after EI cant be interrupted.
	LD	E,A
	RET
