	.globl	_main
	.globl	.init
	.globl	.STACK
	
		;; ****************************************
	;; Beginning of module
	.title	"rrgb Runtime"
	.module	Runtime
	.area	_HEADER (ABS)

	;; Standard header for the GB
	.org	0x00
	RET			; Empty function (default for interrupts)

	.org	0x10
	.byte	0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01
	.byte	0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80

	.org 0x100
.code_start:
	LD	D,A		; Store CPU type in D
	XOR	A
	;; Initialize the stack
	LD	SP,#.STACK

	;; Store CPU type
	LD	A,D
	LD	(__cpu),A

	XOR	A		; Erase the malloc list
	LD	(_malloc_heap_start+0),A
	LD	(_malloc_heap_start+1),A
	LD	(.sys_time+0),A	; Zero the system clock
	LD	(.sys_time+1),A	

	;; Call the main function
	CALL	_main

	RST	0x00		; Exit EMU

	;; ****************************************

	;; Ordering of segments for the linker
	.area	_CODE
	.area	_DATA
	.area	_LIT
	.area	_BSS
	.area	_HEAP		; HEAP is for malloc

	.area	_BSS

__cpu::
	.ds	0x01		; GB type (GB, PGB, CGB)
.mode::
	.ds	0x01		; Current mode
.sys_time::
_sys_time::
	.ds	0x02		; System time in VBL units

	;; Runtime library
	.area	_CODE
	
.set_mode::
	RET
	
_mode::
	LDA	HL,2(SP)	; Skip return address
	LD	L,(HL)
	LD	H,#0x00
	CALL	.set_mode
	RET

_get_mode::
	LD	HL,#.mode
	LD	E,(HL)
	RET
	
_enable_interrupts::
	EI
	RET

_disable_interrupts::
	DI
	RET

.reset::
_reset::
	LD	A,(__cpu)
	JP	.code_start

	; Hack(s)
.add_TIM::
.add_SIO::
.add_JOY::
.add_LCD::
.add_VBL::
.display_off::
.wait_vbl_done::
__io_in::
__io_out::
__io_status::
	ret

	.area	_HEAP
_malloc_heap_start::
