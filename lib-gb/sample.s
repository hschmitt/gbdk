	;; Playback of raw sound sample
	;; by Lars Malmborg <glue@df.lth.se>
	.include "global.s"

	.title "Sound sample player"
	.module Sample


	.AUD3WAVE = 0xff30

_play_sample::
	PUSH	BC
	LDA	HL,4(SP)
	LD	A,(HL+)
	LD	D,(HL)
	LD	E,A

	LDA	HL,6(SP)
	LD	A,(HL+)
	LD	B,(HL)
	LD	C,A

	LD	H,D
	LD	L,E

	CALL	.play_sample
	POP	BC
	RET

; Playback raw sound sample with length BC from HL at 8192Hz rate.
; BC defines the length of the sample in samples/32 or bytes/16.
; The format of the data is unsigned 4-bit samples,
; 2 samples per byte, upper 4-bits played before lower 4 bits.
;
; Adaption for GBDK by Lars Malmborg.
; Original code by Jeff Frohwein.

.play_sample::
	LD	A,#0x84
	LDH	(.NR52),A	; Enable sound 3

	LD	A,#0x00
	LDH	(.NR30),A
	LDH	(.NR51),A

	LD	A,#0x77
	LDH	(.NR50),A	; Select speakers
	LD	A,#0xff
	LDH	(.NR51),A	; Enable sound 3

	LD	A,#0x80
	LDH	(.NR31),A	; Sound length
	LD	A,#0x20
	LDH	(.NR32),A	; Sound freq high

	LD	A,#0x00
	LDH	(.NR33),A	; Sound freq low

.samp2:
	LD	DE,#.AUD3WAVE	; 12
	PUSH	BC		; 16
	LD	B,#16		; 16

	XOR	A
	LDH	(.NR30),A
.samp3:
	LD	A,(HL+)		; 8
	LD	(DE),A		; 8
	INC	DE		; 8
	DEC	B		; 4
	JR	NZ,.samp3	; 12

	LD	A,#0x80
	LDH	(.NR30),A

	LD	A,#0x87		; (256 Hz)
	LDH	(.NR34),A

	LD	BC,#558		; Delay routine
.samp4:
	DEC	BC		; 8
	LD	A,B		; 4
	OR	C		; 4
	JR	NZ,.samp4	; 12

	LD	A,#0		; More delay
	LD	A,#0
	LD	A,#0

	POP	BC		; 12
	DEC	BC		; 8
	LD	A,B		; 4
	OR	C		; 4
	JR	NZ,.samp2	; 12

	LD	A,#0xBB
	LDH	(.NR51),A	; Disable sound 3
	RET
