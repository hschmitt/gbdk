addf	MACRO	to,add
	pushf	to
	fetchf	add
	call	.fadd32
	storef	to
	ENDM

subf	MACRO	to,sub
	pushf	sub
	fetchf	to
	call	.fsub32
	storef	to
	ENDM

; Add 16 bit constant const to BC
add16	MACRO	const
	ld	a,c
	add	#<const
	ld	c,a
	ld	a,b
	adc	#>const
	ld	b,a
	ENDM
	
; Fetch BC from addr
load16	MACRO	addr
	ld	a,(addr+0)
	ld	c,a
	ld	a,(addr+1)
	ld	b,a
	ENDM

; Store BC in addr
store16	MACRO	addr
	ld	a,b
	ld	(addr+1),a
	ld	a,c
	ld	(addr+0),a
	ENDM

; Fetch fp number from addr, preserving BC
fetchf	MACRO	addr
	ld	hl,#addr
	ld	a,(hl+)		; 8
	ld	e,a		; 4 = 12
	ld	a,(hl+)
	ld	d,a
	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a
	ENDM

; Store FP number HLDE in addr without destroying HLDE
storef	MACRO	addr
	ld	a,h		; 4
	ld	(addr+3),a	; 16
	ld	a,l
	ld	(addr+2),a
	ld	a,d
	ld	(addr+1),a
	ld	a,e
	ld	(addr+0),a
	ENDM

; Fetch fp number from offset+bc without destroying BC
fetchfi	MACRO	offset
	ld	hl,#offset
	add	hl,bc
	ld	a,(hl+)
	ld	e,a
	ld	a,(hl+)
	ld	d,a
	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a
	ENDM

; Store fp number into (BC), destroying BC but preserving HLDE
storefi	MACRO
	ld	a,e
	ld	(bc),a		; 8 cycles
	inc	bc		; 8 cycles
	ld	a,d		; 4 cycles
	ld	(bc),a
	inc	bc
	ld	a,l
	ld	(bc),a
	inc	bc
	ld	a,h
	ld	(bc),a		; Total = 20*4 = 80
	ENDM

; Push fp number at addr, destroying BC
pushf	MACRO	addr
	ld	a,(addr+3)
	ld	b,a
	ld	a,(addr+2)
	ld	c,a
	push	bc
	ld	a,(addr+1)
	ld	b,a
	ld	a,(addr+0)
	ld	c,a
	push	bc
	ENDM
	
