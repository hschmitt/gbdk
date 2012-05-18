	;; endin.ms

	;; Simple host <-> net conversion
	.module	endin.s
	.area _CODE
_swap_word::
_ntohs::	
_htons::
	LDA	HL,2(SP)
	LD	D,(HL)
	INC	HL
	LD	E,(HL)
	RET

_swap_byte::
	LDA	HL,2(SP)
	LD	E,(HL)
	SWAP	E
	RET
	
	;; PANIC!!
_ntohl::
	RET

_hotnl::
	RET

