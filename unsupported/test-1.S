	.area	_CODE
1$:
_main::
	load16	.label,0x1234
	ret

; Comment

load16	MACRO	address,val
	ld	a,#<val
	ld	(address),a
	ld	a,#>val
	ld	(address+1),a
	ENDM
	
writeato	MACRO address
	ld	(address),a
	ENDM

writenumto	MACRO addr,val
	ld	a,#val
	writeato	addr
	ENDM

	.area	_BSS
.label:
	.ds	2

