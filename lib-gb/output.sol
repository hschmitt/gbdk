	.include	"global.s"

	.globl	.copy_vram
	.globl	.vbl
	.globl	.lcd
	.globl	.int_0x40
	.globl	.int_0x48
	.globl	.remove_int

	.MAXCURSPOSX	= 0x13	; In tiles
	.MAXCURSPOSY	= 0x11

	.SPACE	= 0x20
	.BS	= 0x08
	.CR	= 0x0A		; Unix
;	.CR	= 0x0D		; Dos

	.area	_HEADER (ABS)

	.org	.MODE_TABLE+4*.T_MODE
	JP	.tmode

	.module Terminal

	.area	_BSS

.curx::				; Cursor position
	.ds	0x01
.cury::
	.ds	0x01

	.area	_CODE

	;; Enter text mode
.tmode::
	DI			; Disable interrupts

	;; Turn the screen off
	LDH	A,(.LCDC)
	BIT	7,A
	JR	Z,1$

	;; Turn the screen off
	CALL	.display_off

	;; Remove any interrupts setup by the drawing routine
	LD	BC,#.vbl
	LD	HL,#.int_0x40
	CALL	.remove_int
	LD	BC,#.lcd
	LD	HL,#.int_0x48
	CALL	.remove_int
1$:

	CALL	.tmode_out

	;; Turn the screen on
	LDH	A,(.LCDC)
	OR	#0b10000001	; LCD		= On
				; BG		= On
	AND	#0b11100111	; BG Chr	= 0x8800
				; BG Bank	= 0x9800
	LDH	(.LCDC),A

	EI			; Enable interrupts

	RET

	;; Text mode (out only)
.tmode_out::

	XOR	A
	LD	(.curx),A
	LD	(.cury),A

	LD	BC,#.tp1	; Move characters (font_a)
	LD	HL,#0x8000
	LD	DE,#.endtp1-.tp1
	CALL	.copy_vram

	LD	BC,#.tp2	; Move characters (font_b)
	LD	HL,#0x8800
	LD	DE,#.endtp2-.tp2
	CALL	.copy_vram

	LD	BC,#.tp1	; Move characters (font_a)
	LD	HL,#0x9000
	LD	DE,#.endtp1-.tp1
	CALL	.copy_vram

	;; Clear screen
	CALL	.cls

	LD	A,#.T_MODE
	LD	(.mode),A

	RET

	;; Print a character without interpretation
.out_char::
	CALL	.set_char
	CALL	.adv_curs
	RET

	;; Print a character with interpretation
.put_char::
	CP	#.CR
	JR	NZ,1$
	CALL	.cr_curs
	RET
1$:
	CALL	.set_char
	CALL	.adv_curs
	RET

	;; Delete a character
.del_char::
	CALL	.rew_curs
	LD	A,#.SPACE
	CALL	.set_char
	RET

	;; Print the character in A
.set_char:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	E,A

	LD	A,(.cury)	; Y coordinate
	LD	L,A
	LD	H,#0x00
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	A,(.curx)	; X coordinate
	LD	C,A
	LD	B,#0x00
	ADD	HL,BC
	LD	BC,#0x9800
	ADD	HL,BC
1$:
	LDH	A,(.STAT)
	AND	#0x02
	JR	NZ,1$
	LD	(HL),E
	POP	HL
	POP	DE
	POP	BC
	RET

	;; Move the cursor left
.l_curs:
	LD	A,(.curx)	; X coordinate
	CP	#0
	RET	Z
	DEC	A
	LD	(.curx),A
	RET

	;; Move the cursor right
.r_curs:
	LD	A,(.curx)	; X coordinate
	CP	#.MAXCURSPOSX
	RET	Z
	INC	A
	LD	(.curx),A
	RET

	;; Move the cursor up
.u_curs:
	LD	A,(.cury)	; Y coordinate
	CP	#0
	RET	Z
	DEC	A
	LD	(.cury),A
	RET

	;; Move the cursor down
.d_curs:
	LD	A,(.cury)	; Y coordinate
	CP	#.MAXCURSPOSY
	RET	Z
	INC	A
	LD	(.cury),A
	RET

	;; Advance the cursor
.adv_curs::
	PUSH	HL
	LD	HL,#.curx	; X coordinate
	LD	A,#.MAXCURSPOSX
	CP	(HL)
	JR	Z,1$
	INC	(HL)
	JR	99$
1$:
	LD	(HL),#0x00
	LD	HL,#.cury	; Y coordinate
	LD	A,#.MAXCURSPOSY
	CP	(HL)
	JR	Z,2$
	INC	(HL)
	JR	99$
2$:
	;; See if scrolling is disabled
	LD	A,(.mode)
	AND	#.M_NO_SCROLL
	JR	Z,3$
	;; Nope - reset the cursor to (0,0)
	XOR	A
	LD	(.cury),A
	LD	(.curx),A
	JR	99$
3$:	
	CALL	.scroll
99$:
	POP	HL
	RET

	;; Rewind the cursor
.rew_curs:
	PUSH	HL
	LD	HL,#.curx	; X coordinate
	XOR	A
	CP	(HL)
	JR	Z,1$
	DEC	(HL)
	JR	99$
1$:
	LD	(HL),#.MAXCURSPOSX
	LD	HL,#.cury	; Y coordinate
	XOR	A
	CP	(HL)
	JR	Z,99$
	DEC	(HL)
99$:
	POP	HL
	RET

	;; Advance the cursor to the next line
.cr_curs::
	PUSH	HL
	XOR	A
	LD	(.curx),A
	LD	HL,#.cury	; Y coordinate
	LD	A,#.MAXCURSPOSY
	CP	(HL)
	JR	Z,2$
	INC	(HL)
	JR	99$
2$:
	CALL	.scroll
99$:
	POP	HL
	RET

	;; Scroll the whole screen
.scroll:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	HL,#0x9800
	LD	BC,#0x9800+0x20 ; BC = next line
	LD	E,#0x20-0x01	; E = height - 1
1$:
	LD	D,#0x20		; D = width
2$:
	LDH	A,(.STAT)
	AND	#0x02
	JR	NZ,2$

	LD	A,(BC)
	LD	(HL+),A
	INC	BC
	DEC	D
	JR	NZ,2$
	DEC	E
	JR	NZ,1$

	LD	D,#0x20
3$:
	LDH	A,(.STAT)
	AND	#0x02
	JR	NZ,3$

	LD	A,#.SPACE
	LD	(HL+),A
	DEC	D
	JR	NZ,3$
	POP	HL
	POP	DE
	POP	BC
	RET


	;; Clear the whole screen
.cls:
_cls::
	PUSH	DE
	PUSH	HL
	LD	HL,#0x9800
	LD	E,#0x20		; E = height
1$:
	LD	D,#0x20		; D = width
2$:
	LDH	A,(.STAT)
	AND	#0x02
	JR	NZ,2$

	LD	(HL),#.SPACE
	INC	HL
	DEC	D
	JR	NZ,2$
	DEC	E
	JR	NZ,1$
	POP	HL
	POP	DE
	RET

_putchar::
	LD	A,(.mode)
	AND	#.T_MODE
	JR	NZ,1$
	PUSH	BC
	CALL	.tmode
	POP	BC
1$:
	LDA	HL,2(SP)	; Skip return address
	LD	A,(HL)		; A = c
	CALL	.put_char
	RET

_gotoxy::
	LD	A,(.mode)
	AND	#.T_MODE
	JR	NZ,1$
	PUSH	BC
	CALL	.tmode
	POP	BC
1$:
	LDA	HL,2(SP)	; Skip return address
	LD	A,(HL+)		; A = x
	LD	(.curx),A
	LD	A,(HL+)		; A = y
	LD	(.cury),A
	RET

_posx::
	LD	A,(.mode)
	AND	#.T_MODE
	JR	NZ,1$
	PUSH	BC
	CALL	.tmode
	POP	BC
1$:
	LD	A,(.curx)
	LD	E,A
	RET

_posy::
	LD	A,(.mode)
	AND	#.T_MODE
	JR	NZ,1$
	PUSH	BC
	CALL	.tmode
	POP	BC
1$:
	LD	A,(.cury)
	LD	E,A
	RET

_setchar::
	LD	A,(.mode)
	AND	#.T_MODE
	JR	NZ,1$
	PUSH	BC
	CALL	.tmode
	POP	BC
1$:
	LDA	HL,2(SP)	; Skip return address
	LD	A,(HL)		; A = c
	CALL	.set_char
	RET

	.area	_DATA

.tp1:
	.include	"font_a.h"
.endtp1:

.tp2:
	.include	"font_b.h"
.endtp2:
