	.include "global.s"

;	This is a set of routines for floating point handling for C

;	The format of a floating point number is as follows:
;
;			------------
;			*   sign   *	1 bit
;			*----------*
;			* exponent *	7 bits
;			*----------*
;			* mantissa *	24 bits, normalized
;			------------
;
;		Note that the number is stored with the mantissa in the
;		low order bytes, i.e. the sign is the most significant
;		bit of the most significant byte.

	.area   _BSS

	; Temporary registers
.ldivloopcount:
.scratch:	.ds	1
	; Working float
.res:	
		.ds	4
.mul:
		.ds	4

.mulloops:
.fdiv32loops:
.faddscratch:	.ds	1
.fmulcount:	.ds 	1
.fw:		.ds	4
.q:
.ft:
		.ds	4
fperr:		.ds	1	; floating over/underflow flag

	.area _CODE


;	Set the floating overflow flag and return zero. Floating execptions
;	may be caught in which case the appropriate routine will be called.

fpovrflw:
	ld	a,#1
	ld	(fperr),a
fpzero:
	ld	hl,#0		; Make HLDE = 0
	ld	e,l
	ld	d,h
	ret

;	Negate the mantissa in LDE.
negmant::
	xor	a		; Zero a, reset carry
	sub	e
	ld	e,a
	ld	a,#0
	sbc	d
	ld	d,a
	
	ld	a,#0
	sbc	l		;negate the hi byte
	ld	l,a		;put back
	ret			;and return

; 	Change it to adding HLDE with BCfl1fl0
;	Make HLDE equal ft
fladd_getother:		; Just return fl3fl2fl1fl0 in HLDE
	ld	a,(.fw+3)
	ld	h,a
	ld	a,(.fw+2)
	ld	l,a
	ld	a,(.fw+1)
	ld	d,a
	ld	a,(.fw+0)
	ld	e,a
	ret

;	Swap the two floating pt registers HLDE and ft3ft2ft1ft0
;	Destroys BC
fladd_swap::
	push	af
	push	hl
	push	de
	ld	hl,#.fw
	ld	a,(hl+)
	ld	e,a
	ld	a,(hl+)
	ld	d,a
	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a
	pop	bc
	ld	a,c
	ld	(.fw+0),a
	ld	a,b
	ld	(.fw+1),a
	pop	bc
	ld	a,c
	ld	(.fw+2),a
	ld	a,b
	ld	(.fw+3),a
	pop	af
	ret
	

;	Floating subtraction. The value on the stack is subtracted from the
;	value in HLDE. To simplify matters, we do it thus:
;
;	A-B == A+-B
.fsub32::
flsub:
	push	hl
	lda	hl,7(sp)	; HL points to exponent on stack
	ld	a,(hl)
	xor	#0x80		; Toggle the sign bit
	ld	(hl),a
	pop	hl

	;fall through to fladd


;	Floating addition:
;		Add the value in HLDE to the value on the stack, and
;		return with the argument removed from the stack.

;	Timings for adding 1976.0 and 10.0
;		Initial version				- 4080
;		Removed .exxs, replaced with fadd_swap	- 2500
;		Removed swaps around actual add		- 1860
;		Optimised fpnorm			- 1620
;		Improved setup				- 1184
;		Improved neg mant detect code		- 952
;		Found bug in fpnorm			- 1060
;		 Note that the speed depends on the order
;		 that the operands are in
;		 If HLDE is > stack, then the routine is faster
;		Optimised so that fpnorm and round arnt - 816
;		 used unless the number overflows into
;		 H		 

; 	Analysis of routine
;	fladd:
;		Recover right operand
;		If either operand is zero, return the other
;		Make the smaller number current
;		Comupte the number of bits difference (BD)
;		If BD > 24, return the larger
;		Adjust smaller until both have the same exponent
;		Save the exponent of either (=exponent of result) (E)
;		Fiddle with mag+sign on both
;			Make H=0x0ff if num is negative
;			Else H=0
;		Add
;		Rotate right once, saving LSB
;		Increase exponent to make up for RR'ing number
;		Restore sign and new exponent
;		Negate mantissa if new is negative
;		Round if LSB was one
;		Normalise

.fadd32::
fladd:
	ld	a,l		;check 1st operand for zero
	or	d
	or	e		;only need to check mantissa
	jr	nz,5$		; Mantissa is not zero
	pop	bc		; mantissa is zero - return other operand
	pop	de
	pop	hl
	push	bc
	ret
5$:
	ld	a,e		; Store the current operand
	ld	(.fw+0),a
	ld	a,d
	ld	(.fw+1),a
	ld	a,l
	ld	(.fw+2),a
	ld	a,h
	ld	(.fw+3),a
	
	pop	bc		; return address
	pop	de		; low word of 2nd operand
	pop	hl		; hi word
	push	bc		; put return address back on stack
	ld	a,l		; check for zero 2nd arg
	or	d
	or	e		;if zero, just return the 1st operand
	jr	nz,6$		; Not zero - so continue
	jp	fladd_getother	; Zero - return other operand
6$:
	ld	a,(.fw+3)
	res	7,a		;clear sign
	ld	c,h		;get exponent
	res	7,c		;and clear sign
a::
	sub	c		;find difference
	jr	nc,1$		;if negative,
	call	fladd_swap	; switch operands
	ld	c,a		; Make the difference positive
	xor	a		; (A = 0)
	sub	c

1$:
	cp	#24		; if less than 24 bits difference,
	jr	c,2$		; we can do the add
	jp	fladd_getother	; otherwise just return the larger value
2$:
	or	a		; check for zero difference
	call	nz,fpadjust	; adjust till equal
	ld	a,h		; save exponent of result
	ld	(.faddscratch),a
	bit	7,h		; test sign, do we need to negate?
	ld	h,#0		; zero fill in case +ve
	jr	z,3$		; no
	call	negmant		; yes
	ld	h,#0x0ff	; 1 fill top byte
3$:
	ld	a,(.fw+3)
	bit	7,a		;test sign, do we need to negate?
	ld	a,#0		;zero fill in case +ve
	ld	(.fw+3),a
	jr	z,4$		;no
	call	fladd_swap
	call	negmant		;yes
	ld	h,#0x0ff	;1 fill top byte
4$:
	ld	c,l
	ld	b,h
	ld	hl,#.fw
	ld	a,(hl+)
	add	e
	ld	e,a
	ld	a,(hl+)
	adc	d
	ld	d,a
	ld	a,(hl+)
	adc	c
	ld	c,a
	ld	a,(hl)
	adc	b
	ld	h,a
	ld	l,c

	sra	h		; now shift down 1 bit to compensate
	rr	l		; Rotate in the carry bit
	rr	d		; propogate the shift
	rr	e

	push    af              ;save carry flag
	ld	a,(.faddscratch)
        res     7,a             ;clear sign from exponent
        inc     a               ;increment to compensate for shift above
        ld      c,a             ;save it
        ld      a,h
        and     #0x80           ;mask off low bits
        or      c               ;or in exponent
        ld      h,a             ;now have it!
	bit	7,h
	call	nz,negmant
        pop     af              ;restore carry flag
        call    c,round         ;round up if necessary
        		        ;normalize and return!!

;	fpnorm	- passed a floating point number in HLDE (sign and exponent
;		in H) - returns with it normalized.
;
;	Points to note:
;		Normalization consists of shifting the mantissa until there
;		is a 1 bit in the MSB of the mantissa.
;
fpnorm::
	bit	7,l		; If it's already normalised, then do nothing
	ret	nz

	ld	a,l		;check for zero mantissa
	or	d
	or	e
	jp	z,fpzero	;make it a clean zero

	ld	b,h		; Store the exponent in B
	ld	c,b		;copy into c
	res	7,c		;reset the sign bit

	; We know that bit 7 is zero due to test above
5$:
	dec	c		;decrement exponent
	bit 	7,c
	jp	nz,fpovrflw	; Exp is <0 - underflow

	or	a		; Clear carry
	rl	e		; Rotate LDE left
	rl	d
	rl	l

	bit	7,l		; Is HLDE normalised?
	jr	z,5$		; no - loop

3$:
	bit	7,b		;test sign
	jr	z,4$		;skip if clear
	set	7,c		;set the new sign bit
4$:
	ld	h,c		;put exponent and sign back where it belongs
	ret			;finished

;	Round the number in HLDE up by one, because of a shift of bits out
;	earlier

round:
	inc	e
	ret	nz
	inc	d
	ret	nz
	inc	l
	ret	nz
;	
;	ld	a,#1		; Add 1 to LDE
;	add	e
;	ld	e,a
;	ld	a,#0
;	adc	d
;	ld	d,a
;
;	ld	a,#0
;	adc	l	
;	ld	l,a

;	jr	nc,2$		; Carry is clear - dont need to increase
				; exponent
	; Shift the carry in
	; ALT: LDE will equal 800000 - speedup?
	rr	l		; Carry is set - rr mantissa and increase
	rr	d		; exponent
	rr	e
	ld	a,h		; get exponent/sign
	and	#0x07f		; get exponent only
	inc	a		; add one
	ld	c,a
	ld	a,h
	and	#0x080
	or	c		;now exponent and sign again
	ld	h,a
2$:
	ret

;	Adjust the floating number in HLDE by increasing the exponent by the
;	contents of A. The mantissa must be shifted right to compensate.

fpadjust:
	and	#0x01F		;mask of hi bits - irrelevant
1$:
	srl	l		; Rotate mantissa right
	rr	d
	rr	e
	inc	h		; increment exponent - it will not overflow
	dec	a
	jr 	nz,1$		; loop if more
	ret

;	Get the right operand into HLDE', leave the left operand
;	where it is in HLDE, but make both of them +ve. The original
;	exponents/signs are left in C and B, left and right operands
;	respectively.

fsetup::
	push	hl
	lda	hl,6(sp)
	ld	a,(hl+)
	ld	(.fw+0),a	; lower word of right operand
	ld	a,(hl+)
	ld	(.fw+1),a
	ld	a,(hl+)		; high word of right operand
	ld	(.fw+2),a
	ld	a,(hl)
	ld	(.fw+3),a
	
	pop	hl
	ld	a,h		; Store HL
	ld	(.scratch),a
	ld	a,l

	pop	hl
	pop	bc
	lda	sp,4(sp)	; Unjunk stack
	push	bc
	push	hl

	ld	l,a		; Recover HL
	ld	a,(.scratch)
	ld	h,a
	ld	c,a		; Store the exponent
	res	7,h		; Make the working copy positive
	ld	a,(.fw+3)
	ld	b,a
	res	7,a
	ld	(.fw+3),a
	ret

;	Floating multiplication. The number in HLDE is multiplied by the
;	number on the stack under the return address. The stack is cleaned
;	up and the result returned in HLDE.
;
;	Timings: multiply 1976.0 by 10.0
;		Initial					- ~60000
;		Much hacking afterwards			- 6268
;		Added mulx0 = 8 shift hack		- 5228
;		Trimmed some old instruction		- 5148
;		Improved fsetup				- 4436

.fmul32::
flmul:
	call	fsetup		;get operands, make them +ve.

	push	bc		;save exponents etc.

	ld	a,d		; Set DEDE' equal to HLDE
	ld	(.ft+1),a
	ld	a,e
	ld	(.ft+0),a
	ld	e,l		; D is zeroed later

	xor	a		; Zero product
	ld	(.fw+3),a	
	ld	h,a
	ld	l,a
	ld	b,a
	ld	c,a
	ld	d,a		

	ld	a,(.fw+0)	; get low 8 bits of multiplier
	call	mult26		; do 8 bits of multiply

	ld	a,(.fw+1)
	call	mult8		;next 8 bits

	ld	a,(.fw+2)	;next 8 bits
	call	mult8		;do next chunk

	ld	d,b
	ld	e,c
	ld	a,h		;get hi byte
	ld	h,#0
	ld	c,h		;zero lower byte
	jr	1$		;skip forward 	1f
2$:	; 2
	srl	a
	rr	l
	rr	d
	rr	e
	rr	c		;save carry bit in c
	inc	h
1$:	; 1
	or	a		;hi byte zero yet?
	jr	nz,2$		;no, keep shifting down		2b
	ld	a,c		;copy shifted-out bits
	ld	(.scratch),a
	pop	bc		;get exponents
	bit	7,l		;check for zero mantissa
	jp	z,fpzero	;return a clean zero if so
	ld	a,c
	res	7,a		;mask off sign
	sub	#0x41		;remove bias, allow one bit shift
	add	a,h		;add in shift count
	sub	#6		;compensate for shift up earlier
	ld	h,b		;the other
	res	7,h		;mask off signs
	add	a,h		;add them together
	ld	h,a		;put exponent in
	ld	a,c		;now check signs
	xor	b

	bit	7,a
	ret	z		;return if +ve

	set	7,h		;set sign flag
	ld	a,(.scratch)
	rla			;shift top bit out
	ret	nc		;return if no carry
	jp	round		;round it

; 	Register useage
;		HL  1
;		HL' 1
;		DE  11
;		DE' 11


mult26::
	push	af
	ld	a,#6
	ld	(.fmulcount),a
3$:	; 3
	pop	af
	srl	a		;shift LSB of multiplier into carry
	jr	nc,1$		; 1f
	push	af
	
	ld	a,(.ft+0)
	add	c
	ld	c,a
	ld	a,(.ft+1)
	adc	b
	ld	b,a

	jr	nc,2$
	inc	hl
2$:
	add	hl,de
	pop	af
1$:	; 1
	push	af
	or	a
	push	hl
	ld	hl,#.ft
	rl	(hl)
	inc	hl
	rl	(hl)
	pop	hl
	rl	e
	rl	d

	ld	a,(.fmulcount)
	dec	a
	ld	(.fmulcount),a

	jr 	nz,3$

	ld	a,#2
	ld	(.fmulcount),a
	pop	af
	jr	mul8_4		; 4f

; Register useage count
;		HL  11
;		HL' 11
;		DE  1
;		DE' 1

mult8::
				; Encapsulate it
	cp	#0		; Simple hack to speed up mul if A = 0
	jr	nz,mul8_normal
				; If A = 0, then it's just rr HLBC 8 times
	ld	c,b
	ld	b,l
	ld	h,a		; (A=0)		
	ret

mul8_normal:
	push	af
	ld	a,#8
	ld	(.fmulcount),a
mul8_3:
	pop	af
	srl	h
	rr	l
	rr	b
	rr	c	
mul8_4: ; 4
	srl	a		;shift LSB into carry
	jr	nc,1$		; 1f
	push	af
	ld	a,(.ft+0)
	add	c
	ld	c,a
	ld	a,(.ft+1)
	adc	b
	ld	b,a

	jr	nc,2$
	inc	hl
2$:
	add	hl,de
	pop	af
1$:
	push	af
	ld	a,(.fmulcount)
	dec	a
	ld	(.fmulcount),a
	jr	nz,mul8_3		;more?	3b
	
				; De-encapsulate
	pop	af
	ret			;no, return as is


;	Floating division. The number in HLDE is divided by the
;	number on the stack under the return address. The stack is cleaned
;	up and the result returned in HLDE.
;
;	Timings Divide 1976.0 by 10.0 giving 197.600006-ish
;		Initial					- 111272
;		Removed .exx's around 3$		- 72512
;		Removed all .exx's up to 5$		- 20192
;		Swapped BCBC' for q4..q0		- 19708
;		Swapped HL' for BC			- 14428
;		Removed .exafaf's			- 14120
;		Found a redundant scf			- 14060
;		Found that D was free - removed q1	- 13060
;		Better shift of q			- 9856
;	Profile counts
;		Useage of	HL  11(.5)1
;				HL' 11(.5)1
;				DE  1
;				DE' 1
;		Useage of	q3  11
;				q1  11

.fdiv32::
fldiv:
	call	fsetup		; get operands, make them +ve.
				; NOTE returns with them in HLDE, HLDE' =12 34
				; and orig exponents in BC = 5
				; fsetup takes 1044 cycles
				; Time from here
	push	bc		; save exponents etc.	TOS=5
				; Swap DE and HL'
	ld	b,d		; HL=1,DE=2,HL'=3,DE'=4
				; Then HL=1,HL'=2,DE=3,DE'=4
	ld	c,e		; Ignore D as it's zeroed later
	ld	a,(.fw+2)
	ld	e,a

	xor	a		; Zero a
	ld	(.q+0),a	; ...and the quotient
	ld	d,a		; D is free
	ld	(.q+2),a
	ld	(.q+3),a

	ld	h,a		; Zero top byte of divisor
				; Dividend is taken care of later
	
				; Ends with HL=1,HL'=2,DE=3,DE'=4
	ld	a,#24+6		;number of bits in dividend and then some
	ld	(.fdiv32loops),a

3$:
	ld	a,h
	cp	d
	jr	c,5$
	jr	nz,8$
	ld	a,l
	cp	e
	jr	c,5$
8$:
	push	bc
	push	hl		;save dividend - hl is now free

	ld	hl,#.fw
				; Subtract DEfw1fw0 from HLBC
	ld	a,c		; Subtract fw1fw0 from BC
	sub	(hl)
	ld	c,a
	inc	hl
	ld	a,b
	sbc	(hl)
	ld	b,a
		
	pop	hl		; Recover HL
	push	hl

	ld	a,l		; Subtract high words
	sbc	e		; (Subtract DE from HL)
	ld	l,a
	ld	a,h
	sbc	#0
	ld	h,a
	jr	nc,4$
	pop	hl		; DEfw1fw0 is greater than HLBC
	pop	bc		; restore dividend
	jr	5$

4$:
	lda	sp,4(sp)	;unjunk stack
5$:
	ccf			; complement carry bit
	push	hl
	ld	hl,#.q
	rl	(hl)
	inc	hl
	rl	d
	inc	hl
	rl	(hl)
	inc	hl
	rl	(hl)
	pop	hl
	
	or	a		; clear carry flag
	rl	c		; Shift HLBC left 
	rl	b
	rl	l	
	rl	h
	
	ld	a,(.fdiv32loops)
	dec	a		;decrement loop count
	ld	(.fdiv32loops),a
	jr	nz,3$

	ld	hl,#.q
	ld	a,(hl+)
	ld	e,a
	inc	hl		; D is taken care of above
	ld	l,(hl)
	ld	a,(.q+3)

	ld	h,#0
	ld	c,h		;zero lower byte
	jr	1$		;skip forward
2$:
	srl	a
	rr	l
	rr	d
	rr	e
	rr	c		;save carry bit in c
	inc	h
1$:
	or	a		;hi byte zero yet?
	jr	nz,2$		;no, keep shifting down

	push	af
	ld	a,c		;copy shifted-out bits
	ld	(.scratch),a
	pop	af

	pop	bc		;restore exponents
	push	bc		;save signs
	ld	a,c
	res	7,a
	res	7,b
	sub	b
	add	#0x041-6		;compensate
	add	a,h
	ld	h,a
	pop	bc
	ld	a,c
	xor	b		; get sign
	bit	7,a		; Jump if a is positive
	jr	z,6$

	set	7,h
6$:
	ld	a,(.scratch)
	rla
	call	c,round		; round if necessary
	jp	fpnorm		; normalize it and return

; .add32 - add HLDE and stack
;  Add HLDE to the 4 byte long on the stack, returning the result in HLDE
;  Note that the stack grows downwards fro the top, so SP+0 is the return address,
;   SP+2 is the least significant byte and SP+5 is the most significant
;	So push hl; push de
.add32::
	LD	B,H		; BC = temporary registers
	LD	C,L
	LDA	HL,2(SP)	; HL = LSB of operand
	LD	A,E
	ADD	(HL)
	LD	E,A
	INC	HL
	LD	A,D
	ADC	(HL)
	LD	D,A
	INC	HL
	LD	A,C
	ADC	(HL)
	LD	C,A
	INC	HL
	LD	A,B
	ADC	(HL)
	LD	H,A
	LD	L,C
	POP	BC		; Return address
	LDA	SP,4(SP)	; Remove the operand from the stack
	PUSH	BC		; Put return address back on stack
	RET

; .sub32 - subtract stack from HLDE
;  Subtract the 4 byte long on the stack at SP+2 from HLDE
.sub32::
	LD	B,H
	LD	C,L
	LDA	HL,2(SP)	; HL points to the operand
	LD	A,E
	SUB	(HL)
	LD	E,A
	INC	HL
	LD	A,D
	SBC	(HL)
	LD	D,A
	INC	HL
	LD	A,C
	SBC	(HL)
	LD	C,A
	INC	HL
	LD	A,B
	SBC	(HL)
	LD	H,A
	LD	L,C
	POP	BC		; Return address
	LDA	SP,4(SP)	; Remove the operand from the stack
	PUSH	BC		; Put return address back on stack
	RET

; .neg32 - negate HLDE
;  Note that HLDE is a in two's complement form
;  The order of the complementing the registers is unimportant
.neg32::
	LD	A,E
	CPL			; Take 2's complement of A
	LD	E,A
	LD	A,D
	CPL
	LD	D,A
	LD	A,L
	CPL
	LD	L,A
	LD	A,H
	CPL
	LD	H,A
	RET

; .cpl32 - complement HLDE
;  Confused - dosnt this do the same as .neg32?
.cpl32::
	XOR	A		; Zero A, clear flags
	SUB	E
	LD	E,A
	LD	A,#0x00
	SBC	D
	LD	D,A
	LD	A,#0x00
	SBC	L
	LD	L,A
	LD	A,#0x00
	SBC	H
	LD	H,A
	RET

; .xor32 - logical XOR of HLDE with the stack
.xor32::
	LD	B,H		; Temporarialy store HL in BC
	LD	C,L
	LDA	HL,2(SP)	; HL points to the operand
	LD	A,E
	XOR	(HL)
	LD	E,A
	INC	HL
	LD	A,D
	XOR	(HL)
	LD	D,A
	INC	HL
	LD	A,C
	XOR	(HL)
	LD	C,A
	INC	HL
	LD	A,B
	XOR	(HL)
	LD	H,A
	LD	L,C
	POP	BC		; Return address
	LDA	SP,4(SP)	; Remove the operand
	PUSH	BC		; Put return address back on stack
	RET

; .or32 - logical OR of HLDE with the stack
.or32::
	LD	B,H
	LD	C,L
	LDA	HL,2(SP)
	LD	A,E
	OR	(HL)
	LD	E,A
	INC	HL
	LD	A,D
	OR	(HL)
	LD	D,A
	INC	HL
	LD	A,C
	OR	(HL)
	LD	C,A
	INC	HL
	LD	A,B
	OR	(HL)
	LD	H,A
	LD	L,C
	POP	BC		; Return address
	LDA	SP,4(SP)
	PUSH	BC		; Put return address back on stack
	RET

; .and32 - logical AND of HLDE with the stack
.and32::
	LD	B,H
	LD	C,L
	LDA	HL,2(SP)
	LD	A,E
	AND	(HL)
	LD	E,A
	INC	HL
	LD	A,D
	AND	(HL)
	LD	D,A
	INC	HL
	LD	A,C
	AND	(HL)
	LD	C,A
	INC	HL
	LD	A,B
	AND	(HL)
	LD	H,A
	LD	L,C
	POP	BC		; Return address
	LDA	SP,4(SP)
	PUSH	BC		; Put return address back on stack
	RET

; .asl32 - arithmitic shift left of HLDE 'A' times
.asl32::
1$:
	SLA	E
	RL	D
	RL	L
	RL	H
	DEC	A
	JR	NZ,1$
	RET

; .asr32 - arithmitic shift right of HLDE 'A' times
.asr32::
1$:
	SRA	H
	RR	L
	RR	D
	RR	E
	DEC	A
	JR	NZ,1$
	RET

; .lsl32 - logical shift left of HLDE 'A' times
.lsl32::
1$:
;	SLL	E
	RL	D
	RL	L
	RL	H
	DEC	A
	JR	NZ,1$
	RET

; .lsr32 - logical shift right of HLDE 'A' times
.lsr32::
1$:
	SRL	H
	RR	L
	RR	D
	RR	E
	DEC	A
	JR	NZ,1$
	RET

; .cmp32 - check if HLDE is negative, positive or zero
;  Can be used with a subtraction to compare numbers
;   If ( A-B > 0 ) A > B
;   If ( A-B = 0 ) B = A
;   If ( A-B < 0 ) A < B
;  Returns Z = 1 if HLDE = 0, C = 1 if HLDE < 0

	;; Long comparison Sets C if HLDE is negative, and Z if HLDE is zero.
.cmp32::
	BIT	7,H		; Test sign
	JR	Z,1$
	LD	A,E		; Set Z flag
	OR	D		; xxx confused
	OR	L
	OR	H
	SCF			; Negative:	set carry flag
	RET
1$:
	LD	A,E		; Set Z flag
	OR	D
	OR	L
	OR	H
	SCF			; Positive:	clear carry flag
	CCF
	RET

	;; Long multiplication for Z80.
	;;
	;; Called with 1st arg in HLDE, 2nd arg on stack. Returns with
	;;  result in HLDE, other argument removed from stack.

;	Long multiplication for Z80

;	Called with 1st arg in HLDE, 2nd arg on stack. Returns with
;	result in HLDE, other argument removed from stack

;	global	almul, llmul

;	psect	text
;almul:
;llmul:
;

; Tests:
;	Square 27A3, giving 62311C9
;	Initial: 6796
;	Change final exx for simple moves - 6360
;	Change middle exx to simple moves - 6040
;	Changed to mul DEBC, adding to HLHL' - 5672
;	Cleaned up afterwards	- 5460
;	Tried changing push af to ld (.scratch),a in mul8 - 5540
;	Changed so that mul by 256 (0) is simple swap - 3476
;       Fixed 32 cycle offset in timer - 3444

.mul32::			; hl=1,de=2,sp+4=3,sp+2=4
	; None of this mucking about...
	; HLDE to mul3 mul2 mul1 mul0
	; Begin profiling
	ld a,h
	ld (.mul+3),a		; mulB
	ld a,l
	ld (.mul+2),a		; mulC
	ld a,d
	ld (.mul+1),a		; .Bp
	ld a,e
	ld (.mul+0),a		; - 80 cycles .Cp
	
	pop hl			; HL is ret address
	pop de
	pop bc
	push hl			; Put ret address back
				; - 132 cycles

	xor a			; Zero HLHL'
	ld h,a			; (the result)
	ld l,a
	ld (.res+1),a
	ld (.res+0),a		; - 176 cycles
	
	
	ld a,(.mul+0)		; Do the actual multiply
	call .mul8b		; - 1704 cycles

	ld a,(.mul+1)
	call .mul8b		; - 3232 cycles

	ld a,(.mul+2)
	call .mul8b		; - 3304 cycles

	ld a,(.mul+3)
	call .mul8b		; - 3376 cycles

	ld d,h
	ld e,l
	ld a,(.res+1)
	ld h,a
	ld a,(.res+0)
	ld l,a			; - 3424 cycles

	ret

.mul8b:
	cp a,#0
	jr nz,.realmul8b
	; Simple hack so that if we're multipling by zero then just
	;  the shift is performed
	ld e,d
	ld d,c
	ld c,b
	ld b,#0
	ret

.realmul8b:
	push af
	ld a,#8
	ld (.mulloops),a
1$:
	pop af
	SRL	A		; Shift A left, LSB into carry
	JP	NC,2$		; LSB of A was zero, so continue
	ADD	HL,DE		; Add low words
	; Originally 149 cycles, now 100
	PUSH	AF
	LD	A,(.res+0)	; Add DE' to HL'
	ADC	c
	LD	(.res+0),A
	LD	A,(.res+1)
	ADC	b
	LD	(.res+1),A
				; Hee hee - these two were around the wrong way
	POP	AF
	; To here
2$:
	SLA	E		; Rotate the multiplier left (DE)
	RL	D
	; This section took 90 cycles, now 16
	rl	c
	rl	b

	push af
	ld a,(.mulloops)
	DEC	a		; Loop until all 8 bits are done
	ld (.mulloops),a
	JR	NZ,1$
	pop af	
	RET
; Long division routines for Z80.
;
; Called with dividend in HLDE, divisor on stack under 2 return
;  addresses. Returns with dividend in HL/HL', divisor in DE/DE'
;  on return the HIGH words are selected.
; Interface between C type HLDE/stack operands and that required for divide
; In divide,
;	dividend is HLHL'
;	divisor  is DEBC
;	divisor  is removed from stack
;	
;	Notes:
;	+0	HL
;	+2	ret outer
;	+4	ret inner
;	+6	div.l
;	+8	div.h

.mod32::
	call	.lregset
	call	divide
	ld	a,(.div+0)
	ld	e,a
	ld	a,(.div+1)
	ld	d,a
	ret
	
.div32::
	call	.lregset
	call	divide
	ld	a,(.q+3)	
	ld	h,a
	ld	a,(.q+2)	
	ld	l,a
	ld	a,(.q+1)	
	ld	d,a
	ld	a,(.q+0)	
	ld	e,a
	ret

.lregset:
				; SP = +2
	ld	a,e		; Low word of dividend into HL'
	ld	(.div+0),a
	ld	a,d
	ld	(.div+1),a	; DE is now free
	push	hl		; HL is free
				; SP = 0
	lda	sp,2(sp)	; (+2)
	pop	de		; First return address
				; SP = +4
	pop	hl		; Second return address
				; SP = +6
				; Points to divisor.L
	pop	bc		; Get divisor.L
				; SP = +8
	push	de		; Restore return address
				; SP = +6
	lda	sp,2(sp)	; Points to divisor.H
				; SP = +8
	pop	de
				; SP = +10
	push	hl		; Restore inner return address
				; SP = +8
	lda	sp,-8(sp)	; Recover HL
				; SP = 0
	pop	hl
	lda	sp,4(sp)
	ret

; .lregset:
; 	POP	BC		; Get top return address
; 	CALL	.exx		; Select other bank
; 	POP	BC		; Return address of call to this module
; 	POP	DE		; Get low word of divisor
; 	CALL	.exx		; Select hi bank
; 	EX	DE,HL		; Dividend.low -> HL
; 	EX	(SP),HL		; Divisor.high -> HL
; 	EX	DE,HL		; Dividend.high -> HL
; 	CALL	.exx		; Back to low bank
; 	PUSH	BC		; Put outer r.a. back on stack
; 	POP	HL		; Return address
; 	EX	(SP),HL		; Dividend.low -> HL
; 	CALL	.exx
; 	PUSH	BC		; Top return address
; 	RET

; ;	Much the same as lregset, except that on entry the dividend
; ;	is pointed to by HL.
; ;	The pointer is saved in iy for subsequent updating of memory

; iregset:
; 	pop	de		;immediate return address
; 	call	lregset		;returns with hi words selected
; 	push	hl		;save a copy for 'ron
; 	ex	(sp),iy		;get it in iy, saving old iy
; 	ld	h,(iy+3)	;high order byte
; 	ld	l,(iy+2)	;byte 2
; 	exx			;back to low bank
; 	push	hl		;return address
; 	ld	h,(iy+1)	;byte 1
; 	ld	l,(iy+0)	;and LSB
; 	exx			;restore hi words
; 	ret			;now return

; ;	Called with hi words selected, performs division on the absolute
; ;	values of the dividend and divisor. Quotient is positive

; sgndiv:
; 	call	negif		;make dividend positive
; 	exx
; 	ex	de,hl		;put divisor in HL/HL'
; 	exx
; 	ex	de,hl
; 	call	negif		;make divisor positive
; 	ex	de,hl		;restore divisor to DE/DE'
; 	exx
; 	ex	de,hl
; 	exx			;select high words again
; 	jp	divide		;do division

; asaldiv:
; 	call	iregset
; 	call	dosdiv
; store:
; 	ld	(iy+0),e
; 	ld	(iy+1),d
; 	ld	(iy+2),l
; 	ld	(iy+3),h
; 	pop	iy		;restore old iy
; 	ret

; aldiv:
;	call	lregset		;get args

; ;	Called with high words selected, performs signed division by
; ;	the rule that the quotient is negative iff the signs of the dividend
; ;	and divisor differ
; ;	returns quotient in HL/DE

; dosdiv:
; 	ld	a,h
; 	xor	d
; 	ex	af,af'		;sign bit is now sign of quotient
; 	call	sgndiv		;do signed division
; 	ex	af,af'		;get sign flag back
; 	push	bc		;high word
; 	exx
; 	pop	hl
; 	ld	e,c		;low word of quotient
; 	ld	d,b
; 	jp	m,negat		;negate quotient if necessary
; 	ret

; lldiv:	call	lregset

; ;	Called with high words selected, performs unsigned division
; ;	returns with quotient in HL/DE

; doudiv:
; 	call	divide		;unsigned division
; 	push	bc		;high word of quotien
; 	exx
; 	pop	hl
; 	ld	e,c		;low word
; 	ld	d,b
; 	ret

; aslldiv:
; 	call	iregset
; 	call	doudiv
; 	jp	store


; almod:
; 	call	lregset

; ;	Called with high words selected, performs signed modulus - the rule
; ;	is that the sign of the remainder is the sign of the dividend

; dosrem:
; 	ld	a,h		;get sign of dividend
; 	ex	af,af'		;save it
; 	call	sgndiv		;do signed division
; 	push	hl		;high word
; 	exx
; 	pop	de
; 	ex	de,hl		;put high word in hl
; 	ex	af,af'		;get sign bit back
; 	or	a
; 	jp	m,negat		;negate if necessary
; 	ret

; asalmod:
; 	call	iregset
; 	call	dosrem
; 	jp	store

; llmod:
; 	call	lregset

; ;	Called with high words selected, perform unsigned modulus

; dourem:
; 	call	divide
; 	push	hl		;high word of remainder
; 	exx
; 	pop	de
; 	ex	de,hl		;high word in hl
; 	ret

; asllmod:
; 	call	iregset
; 	call	dourem
; 	jp	store

; ;	Negate the long in HL/DE

; negat:	push	hl	;save high word
; 	ld	hl,0
; 	or	a
; 	sbc	hl,de
; 	ex	de,hl
; 	pop	bc		;get high word back
; 	ld	hl,0
; 	sbc	hl,bc
; 	ret		;finito

; negif:	;called with high word in HL, low word in HL'
; 	;returns with positive value

; 	bit	7,h		;check sign
; 	ret	z		;already positive
; 	exx			;select low word
; 	ld	c,l
; 	ld	b,h
; 	ld	hl,0
; 	or	a
; 	sbc	hl,bc
; 	exx
; 	ld	c,l
; 	ld	b,h
; 	ld	hl,0
; 	sbc	hl,bc
; 	ret			;finito

;	Called with dividend in HLHL', divisor in DEBC, high words in
;	selected register set
;	returns with quotient in q3q2q1q0 and DEBC, remainder in HLHL',
;	high words selected


;	Tests on div 62311C9 by 27A3 = 27A3 
;	Initial conversion	- 102096
;	Replaced exx and shift at end	-  90688
;	Shifted loop counter from AF to -  87216
;	 mem, freeing AF
;	Removed need for exx's aroung $1-  81068
;	Changed shift right DEDE' to	-  62708
;	 something simpler
;	Much cleaning and removing of	-  20904
;	 exx's

; From the analysis, S is the most used register.  I'll make S DEBC and
;  Q .q0,.q1,.q2,.q3
;	New time		-  16024
;	Further triming and the quick	-   8548
;	 rotate optimization

;	Algorithim
;	Given dividend A and divisor S, return quotient Q and
;	remainder R such that
;	A	= ( S * Q ) + R
;	HLHL'	is A
;	DEDE'	is S
;	Returns	Q in BCBC'
;		R in HLHL'
;
;	Simplified
;	Init
;	Set	Q=0
;	Set	loops=1
;	Make S bigger than A by rotating
;	If S > A, continue
;	Rotate S right
;	Increase loops
;	If MSB(S)==1, continue
;	 else loop
;	One step of the divide
;	If S > A, then LSB(Q)=0
;	 else
;		LSB(Q)=1
;		Subtract S from A
;	Rotate Q left
;	Rotate S right
;	Decrease loop counter
;	Loop while loop counter>0
;----------------------------------------------------
;	Every time
;	Parts:
;		divide - 
;		Init Q (BCBC')=0
;		Return if S (DEDE')=0
;		Set loops left to 1
;		1$ -
;		Check to see if S is greater than A
;		If yes,
;			Goto 2 with C set
;		If no,
;			Rotate S (DEDE') right
;			Increase the number of loops left
;			If MSB S !=1, goto 1$ (at 3$)
;		2$ -
;		6$ -
;		Subtract S from A
;		If S is less than A, then goto 5$ (C=0)	
;		Else, restore value of A (C=1), goto 5$
;		5$ -
;		Complement the carry flag
;		Rotate BCBC' left, shifting in C
;		Rotate DEDE' right
;		Decrease loop count
;		Loop to 6$ while loop count > 0
;		

divide:
;	rst	0x08
;	.asciz "divide "
	xor	a		; Set quotient to zero
	ld	(.q+0),a
	ld 	(.q+1),a
	ld	(.q+2),a
	ld 	(.q+3),a
 	ld	a,e		;check for zero divisor
 	or	d
	or	c
	or	b
 	ret	z		;return with quotient == 0
 	ld	a,#1		;loop count
	ld 	(.ldivloopcount),a

	; Simple optmisation
	; If H <> 0 and E == 0, then DEBC is at least 8 bits smaller than
	;  HLHL', so do a simple swap instead of rotate
	xor	a		; Is H<>0 ?
	cp	h
	jp	z,3$		; Cant hack
	ld	a,d
	or	e	
	jp	nz,3$		; Cant hack

	ld	d,e		; DE=0 and H!=0
	ld	e,b		; 'Rotate' DEBC 8 to the right
	ld 	b,c
	ld	c,a		; A is zero
	ld	a,#9		; Increase loop counter by 8
	ld	(.ldivloopcount),a

 	jp	3$		;enter loop in middle
1$:
 	or	a		; clear carry
	ld 	a,(.div+0)	; Subtract DEBC from HLHL'
	sub 	c		; to compare them
	ld 	a,(.div+1)	; C=1 - DEBC > HLHL'
	sbc 	b
	ld 	a,l
	sbc 	e
	ld 	a,h
	sbc 	d

 	jr	c,2$		;finished - divisor is big enough
	ld	a,(.ldivloopcount)
 	inc	a		;increment count
	ld	(.ldivloopcount),a

	or	a		;Shift DEBC left
	rl	c
	rl	b
	rl	e
	rl	d
3$:
 	bit	7,d		;test for max divisor
 	jp	z,1$		;loop if msb not set
2$:	; arrive here with shifted divisor, loop count in a, and low words
 	;selected
	
6$:
 	push	hl		;save dividend
	ld	a,(.div+0)
	push	af
	ld	a,(.div+1)
	push 	af

	or	a		;clear carry
	ld 	a,(.div+0)	; Subtract DEBC from HLHL'
	sbc 	c
	ld	(.div+0),a
	ld 	a,(.div+1)
	sbc 	b
	ld	(.div+1),a

	ld	a,l
	sbc	e
	ld	l,a
	ld	a,h
	sbc	d
	ld	h,a

 	jp	nc,4$		; HLHL' is bigger than DEBC
	pop	af
	ld	(.div+1),a
	pop	af
	ld	(.div+0),a
 	pop	hl		;hi word
	scf			; C junked by POP AF
 	jr	5$
4$:
	lda	sp,6(sp)	;unjunk stack
5$:
 	ccf		;complement carry bit
	ld	a,(.q+0)		; Rotate quotient Q left
	rl	a		; Rotate in C flag
	ld	(.q+0),a
	ld 	a,(.q+1)
	rl 	a
	ld	(.q+1),a
	ld	a,(.q+2)
	rl	a
	ld	(.q+2),a
	ld 	a,(.q+3)
	rl 	a
	ld	(.q+3),a

 	srl	d		; Shift divisor right
 	rr	e
	rr	b
	rr	c
	
	ld	a,(.ldivloopcount)
 	dec	a		;decrement loop count
	ld	(.ldivloopcount),a
 	jr	nz,6$

;	Setup the expected return values
;	ld	a,(.q3)
;	ld	d,a
;	ld	a,(.q2)
;	ld	e,a
;	ld	a,(.q1)
;	ld	b,a
;	ld	a,(.q0)
;	ld	c,a
 	ret			;finished
;	Conversion of integer type things to floating. Uses routines out
;	of float.as.

;	psect	text

;	global	altof, lltof, aitof, litof, abtof, lbtof
;	global	fpnorm

lbtof:
	ld	e,a
	ld	d,#0
litof:
	push	hl
	pop	de
;	ex	de,hl		;put arg in de
	ld	l,#0		;zero top byte
b3tof:
	ld	h,#64+24
	jp	fpnorm

abtof:
	ld	e,a
	rla
	sbc	a,a
	ld	d,a

aitof:
	bit	7,h		;negative?
	jp	z,litof		;no, treat as unsigned
	; Negate HL
	xor	a
	sub	l
	ld	l,a
	ld	a,#0
	sbc	h
	ld	h,a
	call	litof
	set	7,h		;set sign flag
	ret

lltof:
	ld	a,h		;anything in top byte?
	or	a
	jr	z,b3tof		;no, just do 3 bytes
	ld	e,d		;shift down 8 bits
	ld	d,l
	ld	l,h
	ld	h,#64+24+8	;the 8 compensates for the shift
	jp	fpnorm		;and normalize it

altof:
	bit	7,h		; negative?
	jr	z,lltof		; no, treat as unsigned
	xor	a		; Negate HLDE
	sub	e
	ld	e,a
	ld	a,#0
	sbc	d
	ld	d,a
	ld	a,#0
	sbc	l
	ld	l,a
	ld	a,#0
	sbc	h
	ld	h,a

	call	lltof
	set	7,h		;set sign flag
	ret

;	ftol - convert floating to long, by using lower bits can also
;	be used to convert from float to int or char

;	psect	text
;	global	ftol
;	global	alrsh, allsh, negmant

ftol:
	bit	7,h		;test sign
	call	nz,negmant	;negate mantissa if required
	ld	a,h		;get exponent
	res	7,a		;mask sign off
	sub	#64+24		;remove offset
	ld	b,a		;save shift count
	ld	a,h		;get exponent, sign
	rla
	sbc	a,a		;sign extend
	ld	h,a		;put back
	bit	7,b		;test sign
;	jp	z,allsh		;shift it left
	ld	a,#0		; Get the count
	sub	b
;	neg			;make +ve
	dec	a		;and reduce it one
	ld	b,a		;put back in b
;	call	nz,alrsh	;shift right
	; add one for rounding
	ld	a,#1
	add	e
	ld	e,a
	ld	a,#0
	add	d
	ld	d,a
;	jp	nc,alrsh	;and shift down one more
	inc	hl		;add in carry first
;	jp	alrsh
; LWORD _fbcd(float x, WORD *exp, char *buf)
;
; Split x into mantissa and decimal exponent parts.
; Return value is the (long) mantissa part, exponent part is
;  stored in *exp as two's complement. Mantissa is stored into buf
;  as an ascii string.

	.NDIG		= 8	; Number of decimal digits

	.globl	.lldiv,.llmod

.hasfrac:
	LD	C,#0x00		; Zero number
	LD	A,E		; Check low 8 bits
	OR	A
	JR	NZ,1$		; Non zero bit in low 8 bits
	LD	C,#8		; Bump count
	LD	A,D		; Check next 8 bits
	OR	A		; Is there a bit there?
	JR	NZ,1$		; Yup
	LD	C,#16
	LD	A,H		; Now check next 8 bits
1$:
	RRA			; Shift bottom bit out
	JR	C,2$		; Found a bit!
	INC	C		; Increment count
	JR	1$		; And loop

2$:
	LD	A,H		; Get exponent
	RES	7,A		; Clear sign bit - should be zero anyway
	SUB	#64+24		; Normalize - remove bias
	ADD	A,C		; Add in bit position
	RET			; Return with value in a and flags set

	.area	_BSS

.fexp:
	.ds	0x01		; Floating exponent temporary
.fsgn:
	.ds	0x01		; Floating sign temporary

	.area	_DATA

.ftenth:
        ;; 0.1
	.db	0xcc
	.db	0xcc
	.db	0xcc
	.db	0x3d
.ften:
	;; 10.0
	.db	0x0
	.db	0x0
	.db	0xa0
	.db	0x44

	.area	_CODE

__fbcd::
	PUSH	BC

	LDA	HL,9(SP)	; Skip return address and registers
	LD	B,(HL)		; BC = exp
	DEC	HL
	LD	C,(HL)
	LDA	HL,4(SP)
	LD	E,(HL)		; HLDE = x
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL+)
	LD	L,(HL)
	LD	H,A
	XOR	A
	LD	(.fexp),A	; Zero it
	LD	(.fsgn),A
	LD	(BC),A		; And the returned exp value
	LD	A,H		; Check for zero exponent
	AND	#0x7F		; Zero exponent means 0.0
	JP	NZ,1$		; Return if x == 0.0
	LD	L,A		; Zero mantissa just in case
	LD	E,A
	LD	D,A
	LD	H,A		; And sign/exponent
	JP	.sbcd		; Return with mantissa = 0, exponent = 0
1$:
	RES	7,H		; Test mantissa sign
2$:
	CALL	.hasfrac	; Any fractional part?
	BIT	7,A
	JP	NZ,3$		; Negative if there is fractional part
	PUSH	HL		; Put x on stack
	PUSH	DE
	LD	A,(.ftenth+3)
	LD	H,A
	LD	A,(.ftenth+2)
	LD	L,A
	LD	A,(.ftenth+1)
	LD	D,A
	LD	A,(.ftenth)
	LD	E,A
	CALL	.fmul32		; Returns with value in HLDE
	LD	A,(.fexp)
	INC	A		; Increment exponent
	LD	(.fexp),A
	JR	2$		; Now check again
3$:
	PUSH	HL
	PUSH	DE		; Pass x as argument
	LD	A,(.ften+3)
	LD	H,A
	LD	A,(.ften+2)
	LD	L,A
	LD	A,(.ften+1)
	LD	D,A
	LD	A,(.ften)
	LD	E,A
	CALL	.fmul32		; Multiply it
	LD	A,(.fexp)
	DEC	A		; And decrement exponent
	LD	(.fexp),A
	CALL	.hasfrac	; Check for fractional part
	BIT	7,A
	JP	NZ,3$		; Loop if still fractional
	LD	A,H		; Get exponent
	LD	H,#0x00		; Zero top byte
	SUB	#64+24		; Offset exponent
4$:
	OR	A		; Check for zero
	JR	Z,6$		; Return if finished
	BIT	7,A
	JP	Z,5$
	SRL	L		; Shift L down
	RR	D		; Rotate the rest
	RR	E
	INC	A		; Increment count
	JR	4$
5$:
	SLA	E
	RL	D
	RL	L
	RL	H
	DEC	A
	JR	4$
6$:
	LD	A,(.fexp)
	PUSH	HL
	LD	B,(HL)		; BC = exp
	DEC	HL
	LD	C,(HL)
	POP	HL
	LD	(BC),A		; Store exponent
	INC	BC
	RLA
	SBC	A
	LD	(BC),A		; Sign extend it
	LD	A,(.fsgn)
	BIT	0,A		; Test sign
	JP	Z,.sbcd		; Return if no negation needed
	XOR	A		; Negate low word
	SUB	E
	LD	E,A
	LD	A,#0x00
	SBC	D
	LD	D,A
	LD	A,#0x00		; Negate the hi word
	SBC	L
	LD	L,A
	LD	A,#0x00
	SBC	H
	LD	H,A

.sbcd:				; Now store as ascii
	PUSH	HL
	PUSH	DE		; Save return value
	PUSH	HL
	LDA	HL,11(SP)
	LD	B,(HL)		; BC = buf
	DEC	HL
	LD	C,(HL)
	LD	HL,#.NDIG
	ADD	HL,BC		; Point to end of buffer
	LD	(HL),#0x00	; Null terminate
	LD	B,H		; BC = pointer
	LD	C,L
	POP	HL
	LD	A,#.NDIG
1$:
	PUSH	AF		; Save count
	PUSH	BC		; Save pointer
	PUSH	HL		; Save value
	PUSH	DE
	LD	BC,#0x0000
	PUSH	BC		; Pass 10 on stack
	LD	BC,#0x000A
	PUSH	BC
	CALL	.llmod
	LD	A,E		; Get remainder
	ADD	A,#'0		; Asciize
	POP	DE
	POP	HL		; Restore value
	POP	BC		; Restore pointer
	DEC	BC
	LD	(BC),A
	PUSH	BC		; Save pointer
	LD	BC,#0x0000	; Now divide by 10
	PUSH	BC
	LD	BC,#0x000A
	PUSH	BC
	CALL	.lldiv
	POP	BC		; Restore pointer
	POP	AF		; Restore count
	DEC	A
	JR	NZ,1$		; Loop if more to do
	POP	DE		; Restore return value
	POP	HL

	POP	BC
	RET			; All done
