	INCLUDE "macros.ms"
	.include "math.s"

	.area	_BSS
tmp:
x:
	.ds	4
og:
	.ds	4
niter:
	.ds	1

	.area	_CODE
.sqrt::
;	og = x;
	storef	x
	storef	og
;	if(og < 1.0)
;		og = 1.0/og;

;	og = frexp(og, &exp);
;	og = ldexp(og, exp/2);	- basically half the exponent

	ld	a,h
	sub	#64
	rr	a
	add	#64
	ld	h,a
	
;	if(x < 1.0)
;		og = 1.0/og;
	
;	for(niter = 0 ; niter < 20 ; niter++) {
	ld	a,#5
	ld	(niter),a
start_for:
;		ng = (x/og + og)/2.0;
	pushf	og
	fetchf	x
	call	.fdiv32
	pushf	og
	call	.fadd32

	; Divide by 2 - decrease mantissa by 1
	dec	h

;		if(ng == og)
;			break;
;		og = ng;
	; See if the result has converged
;	ld	a,(og)		; Guess that e has the highest entropy
;	cp	e
;	jr	nz,exit_for
	ld	a,(og+1)
	cp	d
	jr	nz,exit_for
	ld	a,(og+2)
	cp	l
	jr	nz,exit_for
	ld	a,(og+3)
	cp	h
	jr	nz,exit_for
	ret
	
exit_for:
	storef	og

	ld	a,(niter)
	dec	a
	ld	(niter),a
	jr	nz,start_for
;	}
;	return og;
;}
	ret

