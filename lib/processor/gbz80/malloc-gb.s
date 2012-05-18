	;;
	;; malloc-gb.s
	;; Assambly implementation of malloc()

	.globl _malloc_first
	.globl _malloc_init
	
	.area	_CODE
	;;  Parameter is on the stack
_malloc::
	lda	hl,2(sp)	; Get the parameter
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		; Size in BC

	inc	bc
	inc	bc		; It needs to be a bit bigger to fit the header

	ld	hl,#_malloc_first
	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	;; See if we need to call malloc_init()
	ld	a,l
	or	h
	jr	nz,_malloc_loop
	call	_malloc_init
	jr	_malloc
_malloc_loop::	
	;; Test if size == 0 (end of list)
	ld	a,(hl+)
	ld	e,a
	or	(hl)
	jr	nz,_malloc_check

	ld	de,#0		; End of list, no free chunks - return NULL
	ret
_malloc_check::	
	;; Get the size into DE as no matter what were going to use it
	ld	d,(hl)
	
	bit	7,d		; Is it free?
	jr	z,_malloc_next	; No

	res	7,d
	ld	a,d		; Is it big enough?
	sub	b

	jr	c,_malloc_next	; Nope
	jr	nz,_malloc_found ; Yes

	;; Special check when size.h = requested.h
	ld	a,e
	sub	c
	jr	c,_malloc_next
_malloc_found::	
	;; Got a big enough block - allocate it
	;; HL is base+1
	push	hl		; Store the return value

	dec	bc		; Remove the header offset from before.
	dec	bc
	ld	(hl),b		; Set the new size
	dec	hl
	ld	(hl),c

	inc	bc		; Add in the space for the header
	inc	bc
	;; Create a new hunk
	add	hl,bc

	ld	a,e
	sub	c
	ld	(hl+),a
	ld	a,d
	sbc	b
	or	#0x80
	ld	(hl),a

	pop	de
	inc	de		; Return the pointer
	ret
_malloc_next::				; Advance through the list
	;; HL is at size.h
	res	7,d
	add	hl,de
	inc	hl
	jr	_malloc_loop

	;; Find the malloc region given on the stack
_malloc_find::
	push	bc
	
	lda	hl,4(sp)	; Get the parameter
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		; Location

	dec	de
	dec	de		; Points to the hunk header

	ld	hl,#_malloc_first
	ld	a,(hl+)
	ld	h,(hl)
	ld	l,a

	;; See if we need to call malloc_init()
	ld	a,l
	or	h
	jr	nz,_malloc_find_loop

	pop	bc
	ld	de,#0		; Cant find it if the system isnt inited
	ret	
_malloc_find_loop::
	;; Is this the one were looking for?
	ld	a,l
	cp	e
	jr	nz,_malloc_find_next
	ld	a,h
	cp	d
	jr	nz,_malloc_find_next

	pop	bc
	ret			; Found it!
	
_malloc_find_next::
	;; Advance on
	ld	a,(hl+)
	ld	c,a
	ld	b,(hl)
	or	b
	jr	nz,_malloc_find_advance

	;; Didnt find
	pop	bc
	ld	de,#0
	ret
_malloc_find_advance:
	res	7,b
	add	hl,bc
	inc	hl
	jr	_malloc_find_loop
