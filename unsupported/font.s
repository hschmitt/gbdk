	.include        "global.s"

	.globl  .copy_vram
	.globl	.cr_curs
	.globl	.adv_curs
	.globl	.cury, .curx
	.globl	_font_std
	.globl	_font_batforever
	.globl	_font_tennis

	.CR     = 0x0A          ; Unix
	.MAX_FONTS	= 	4
	.module font.s

	.area	_BSS
.current_font::
	.ds	3

.first_free_tile::
	.ds	1
.font_temp:
	.ds	1
.font_table::
	.ds	3*.MAX_FONTS
	
	.area   _CODE

	;; Copy part (size = DE) of the VRAM from (BC) to (HL)
	; Note:  Might miss the last byte.  I'm not really sure.
.copy_tiles::
	ld	a,d
	or	e
	ret	z
	xor	a
	cp	e		; Special for when e=0 you will get another loop
	jr	nz,1$
	dec	d
1$:
	LDH	A,(.STAT)
	AND	#0x02
	JR	NZ,1$

	LD	A,(BC)
	LD	(HL),A

	inc	l
	jr	nz,2$
	inc	h
	ld	a,h		; Special wrap-around
	cp	#0x98
	jr	nz,2$
	ld	h,#0x88
2$:
	INC	BC
	dec	e
	jr	nz,1$
	dec	d
	ld	a,#0xff
	cp	d
	JR	NZ,1$
	RET

	;; Copy part (size = DE) of the VRAM from (BC) to (HL)
	; Assumes that HL is word aligned
	; Copys one byte from BC into HL and HL+1
.copy_compressed_tiles::
	ld	a,d
	or	e
	ret	z
	xor	a
	cp	e		; Special for when e=0 you will get another loop
	jr	nz,1$
	dec	d
1$:
	LDH	A,(.STAT)
	AND	#0x02
	JR	NZ,1$

	LD	A,(BC)
	LD	(HL+),A
	ld	(hl),a

	inc	l
	jr	nz,2$
	inc	h
	ld	a,h		; Special wrap-around
	cp	#0x98
	jr	nz,2$
	ld	h,#0x88
2$:
	INC	BC
	dec	e
	jr	nz,1$
	dec	d
	ld	a,#0xff
	cp	d
	JR	NZ,1$
	RET

	;; Enter text mode
.load_font::
	DI                      ; Disable interrupts

	;; Turn the screen off
	LDH     A,(.LCDC)
	BIT     7,A
	JR      Z,1$

	;; Must be in VBL before turning the screen off
	CALL    .wait_vbl

	LDH     A,(.LCDC)
	AND     #0b01111111
	LDH     (.LCDC),A
1$:
	push	hl

	ld	hl,#.font_table+1
	ld	b,#.MAX_FONTS
3$:	
	ld	a,(hl)
	inc	hl
	or	(hl)
	cp	#0
	jr	z,2$

	inc	hl
	inc	hl
	dec	b
	jr	nz,3$
	pop	hl
	ld	hl,#0
	jr	4$		; Couldn't load font
2$:
				; HL points to the end of the free font table entry
	pop	de
	ld	(hl),d		; Copy across the font struct pointer
	dec	hl
	ld	(hl),e

	ld	a,(.first_free_tile)
	dec	hl
	ld	(hl),a		

	push	hl
	call	.set_font	; Copy font pointed to by HL to current

	
	ld	a,(.current_font+1)
	ld	l,a
	ld	a,(.current_font+2)
	ld	h,a

	inc	hl		; Points to the 'tiles required' entry
	push	hl
	ld	l,(hl)
	ld	h,#0
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ld	e,l		; DE now has the length of the tile data
	ld	d,h

	pop	hl
	dec	hl
	ld	a,(hl)
	ld	(.font_temp),a
	and	#3		; Only lower 2 bits set encoding table size

	ld	bc,#0x80
	cp	#0		; 0 for 256 char encoding table, 1 for 128 char
	jr	nz,5$

	ld	bc,#0x100
5$:
	inc	hl
	inc	hl		; Points to the start of the encoding table
	add	hl,bc		; HL points to the start of the tile data

	ld	c,l
	ld	b,h

	push	bc
	push	de
	ld	a,(.current_font+0)	; First tile used for this font
	ld	l,a
	ld	h,#0
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl

	push	hl
	ld	a,#0x90
	add	a,h
	ld	h,a
	
	ld	a,(.font_temp)
	and	#4
	jr	nz,6$
	CALL    .copy_tiles
	jr	7$
6$:
	call	.copy_compressed_tiles
7$:

	pop	hl
	pop	de
	pop	bc
	ld	a,#0x80
	add	a,h
	ld	h,a
	call	.copy_tiles

				; Increase the 'first free tile' counter
	ld	a,(.current_font+1)
	ld	l,a
	ld	a,(.current_font+2)
	ld	h,a

	inc	hl
	ld	a,(.first_free_tile)
	add	a,(hl)
	ld	(.first_free_tile),a

	pop	hl		; Return font setup in HL
4$:
	;; Turn the screen on
	LDH     A,(.LCDC)
	OR      #0b10000001     ; LCD           = On
				; BG            = On
	AND     #0b11100111     ; BG Chr        = 0x8800
				; BG Bank       = 0x9800
	LDH     (.LCDC),A

	EI                      ; Enable interrupts

	RET

.set_font::
	ld	a,(hl+)
	ld	(.current_font),a
	ld	a,(hl+)
	ld	(.current_font+1),a
	ld	a,(hl+)
	ld	(.current_font+2),a
	ret
	
	;; Print a character with interpretation
.mput_char::
	CP      #.CR
	JR      NZ,1$
	CALL    .cr_curs
	RET
1$:
	CALL    .mset_char
	CALL    .adv_curs
	RET

	;; Print the character in A
.mset_char:
	PUSH    BC
	PUSH    DE
	PUSH    HL
				; Compute which tile maps to this character
	ld	e,a
	ld	a,(.current_font+1)
	ld	l,a
	ld	a,(.current_font+2)
	ld	h,a
	inc	hl
	inc	hl
				; Now at the base of the encoding table
				; E is set above
	ld	d,#0
	add	hl,de
	ld	e,(hl)		; That's the tile!
	ld	a,(.current_font+0)
	add	a,e
	ld	e,a

	LD      A,(.cury)       ; Y coordinate
	LD      L,A
	LD      H,#0x00
	ADD     HL,HL
	ADD     HL,HL
	ADD     HL,HL
	ADD     HL,HL
	ADD     HL,HL
	LD      A,(.curx)       ; X coordinate
	LD      C,A
	LD      B,#0x00
	ADD     HL,BC
	LD      BC,#0x9800
	ADD     HL,BC
1$:
	LDH     A,(.STAT)
	AND     #0x02
	JR      NZ,1$
	LD      (HL),E
	POP     HL
	POP     DE
	POP     BC
	RET

_mput_char::
	LDA     HL,2(SP)        ; Skip return address
	LD      A,(HL)          ; A = c
	CALL    .mput_char
	RET

_mset_char::
	LDA     HL,2(SP)        ; Skip return address
	LD      A,(HL)          ; A = c
	CALL    .mset_char
	RET

_load_font::
	push	bc
	LDA     HL,4(SP)        ; Skip return address and bc
	LD      A,(HL)          ; A = c
	inc	hl
	ld	h,(hl)
	ld	l,a
	CALL    .load_font
	push	hl
	pop	de		; Return in DE
	pop	bc
	RET

_mprint_string::
	LDA     HL,2(SP)        ; Skip return address
	LD      A,(HL)          ; A = c
	inc	hl
	ld	h,(hl)
	ld	l,a
	CALL    .mprint_string
	RET

_set_font::
	LDA     HL,2(SP)        ; Skip return address
	LD      A,(HL)          ; A = c
	inc	hl
	ld	h,(hl)
	ld	l,a
	CALL    .set_font
	ld	de,#0		; Always good...
	RET

	.if	0
_main:
	call	_init_font

	ld	hl,#_font_tennis
	call	.load_font
	push	hl
	
	ld	hl,#_font_batforever
	call	.load_font
	push	hl

	ld	hl,#_font_std
	call	.load_font

	push	hl
	
	ld	hl,#test_string
	call	.mprint_string

	pop	de
	pop	hl
	push	de
	call	.set_font

	ld	hl,#test_string
	call	.mprint_string

	pop	hl
	call	.set_font
	ld	hl,#test_string
	call	.mprint_string

	pop	hl
	call	.set_font
	ld	hl,#test_string
	call	.mprint_string
	
	ld	b,#0
66$:
	ld	a,b
	push	bc
	call	.mput_char
	pop	bc
	inc	b
	ld	a,b
	cp	#128
	jr	nz,66$

	ret
	.endif

_init_font::
	ld	hl,#.font_table
	ld	b,#3*.MAX_FONTS
	xor	a
	ld	(.first_free_tile),a
1$:
	ld	(hl+),a
	dec	b
	jr	nz,1$
	ret
	
.mprint_string:
	ld	a,(hl)
	cp	#0
	ret	z
	push	hl
	call	.mput_char
	pop	hl
	inc	hl
	jr	.mprint_string

	.area	_DATA
test_string:
	.asciz	"09AaBbXxYy Hi There!"
