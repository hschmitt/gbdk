#ifndef _GB_H
#define _GB_H

#include <types.h>
#include <hardware.h>
#include <sgb.h>
#include <cgb.h>

/* Joypad bits */

#define	J_START      0x80U
#define	J_SELECT     0x40U
#define	J_B          0x20U
#define	J_A          0x10U
#define	J_DOWN       0x08U
#define	J_UP         0x04U
#define	J_LEFT       0x02U
#define	J_RIGHT      0x01U

/* Modes */

#define	M_DRAWING    0x01U
#define	M_TEXT_OUT   0x02U
#define	M_TEXT_INOUT 0x03U
/* Set this in addition to the others to disable scrolling 
   If scrolling is disabled, the cursor returns to (0,0) */
#define M_NO_SCROLL  0x04U
/* Set this to disable \n interpretation */
#define M_NO_INTERP  0x08U

/* Sprite properties bits */

#define S_PALETTE    0x10U
#define S_FLIPX      0x20U
#define S_FLIPY      0x40U
#define S_PRIORITY   0x80U

/* Interrupt flags */

#define VBL_IFLAG    0x01U
#define LCD_IFLAG    0x02U
#define TIM_IFLAG    0x04U
#define SIO_IFLAG    0x08U
#define JOY_IFLAG    0x10U

/* Limits */

#define SCREENWIDTH  0xA0U
#define SCREENHEIGHT 0x90U
#define MINWNDPOSX   0x07U
#define MINWNDPOSY   0x00U
#define MAXWNDPOSX   0xA6U
#define MAXWNDPOSY   0x8FU

/* ************************************************************ */

/*
 * Interrupt handlers
 */
typedef void (*int_handler)(void);

void
add_VBL(int_handler h);

void
add_LCD(int_handler h);

void
add_TIM(int_handler h);

void
add_SIO(int_handler h);

void
add_JOY(int_handler h);

/* ************************************************************ */

/* Set the current mode - one of M_* defined above */
void
	mode(UBYTE m);

/* Returns the current mode */
UBYTE
	get_mode(void);

/* GB type (GB, PGB, CGB) */
extern UBYTE _cpu;

#define DMG_TYPE 0x01 /* Original GB or Super GB */
#define MGB_TYPE 0xFF /* Pocket GB or Super GB 2 */
#define CGB_TYPE 0x11 /* Color GB */

extern UWORD sys_time;	/* Time in VBL periods (60Hz) */

/* ************************************************************ */

void
send_byte(void);
/* Send byte in _io_out to the serial port */

void
receive_byte(void);
/* Receive byte from the serial port in _io_in */

extern UBYTE _io_status;
extern UBYTE _io_in;
extern UBYTE _io_out;

/* Status codes */
#define IO_IDLE		0x00U		/* IO is completed */
#define IO_SENDING	0x01U		/* Sending data */
#define IO_RECEIVING	0x02U		/* Receiving data */
#define IO_ERROR	0x04U		/* Error */

/* ************************************************************ */

/* Multiple banks */

/* MBC1 */
#define SWITCH_ROM_MBC1(b) \
  *(unsigned char *)0x2000 = (b)

#define SWITCH_RAM_MBC1(b) \
  *(unsigned char *)0x4000 = (b)

#define ENABLE_RAM_MBC1 \
  *(unsigned char *)0x0000 = 0x0A

#define DISABLE_RAM_MBC1 \
  *(unsigned char *)0x0000 = 0x00

/* Note the order used here.  Writing the other way around
 * on a MBC1 always selects bank 0 (d'oh)
 */
/* MBC5 */
#define SWITCH_ROM_MBC5(b) \
  *(unsigned char *)0x3000 = (b)>>8; \
  *(unsigned char *)0x2000 = (b)&0xFF

#define SWITCH_RAM_MBC5(b) \
  *(unsigned char *)0x4000 = (b)

#define ENABLE_RAM_MBC5 \
  *(unsigned char *)0x0000 = 0x0A

#define DISABLE_RAM_MBC5 \
  *(unsigned char *)0x0000 = 0x00

/* ************************************************************ */

void
delay(UWORD d);

/* ************************************************************ */

UBYTE
joypad(void);

UBYTE
waitpad(UBYTE mask);

void
waitpadup(void);

/* ************************************************************ */

void
enable_interrupts(void);

void
disable_interrupts(void);

void
set_interrupts(UBYTE flags);

void
reset(void);

void
wait_vbl_done(void);

void
display_off(void);

/* ************************************************************ */

void
hiramcpy(UBYTE dst,
	 const void *src,
	 UBYTE n);

/* ************************************************************ */

#define DISPLAY_ON \
  LCDC_REG|=0x80U

#define DISPLAY_OFF \
  display_off();

#define SHOW_BKG \
  LCDC_REG|=0x01U

#define HIDE_BKG \
  LCDC_REG&=0xFEU

#define SHOW_WIN \
  LCDC_REG|=0x20U

#define HIDE_WIN \
  LCDC_REG&=0xDFU

#define SHOW_SPRITES \
  LCDC_REG|=0x02U

#define HIDE_SPRITES \
  LCDC_REG&=0xFDU

#define SPRITES_8x16 \
  LCDC_REG|=0x04U

#define SPRITES_8x8 \
  LCDC_REG&=0xFBU

/* ************************************************************ */

void
set_bkg_data(UBYTE first_tile,
	     UBYTE nb_tiles,
	     unsigned char *data);

void
set_bkg_tiles(UBYTE x,
	      UBYTE y,
	      UBYTE w,
	      UBYTE h,
	      unsigned char *tiles);

void
get_bkg_tiles(UBYTE x,
	      UBYTE y,
	      UBYTE w,
	      UBYTE h,
	      unsigned char *tiles);

void
move_bkg(UBYTE x,
	 UBYTE y);

void
scroll_bkg(BYTE x,
	   BYTE y);

/* ************************************************************ */

void
set_win_data(UBYTE first_tile,
	     UBYTE nb_tiles,
	     unsigned char *data);

void
set_win_tiles(UBYTE x,
	      UBYTE y,
	      UBYTE w,
	      UBYTE h,
	      unsigned char *tiles);

void
get_win_tiles(UBYTE x,
	      UBYTE y,
	      UBYTE w,
	      UBYTE h,
	      unsigned char *tiles);

void
move_win(UBYTE x,
	 UBYTE y);

void
scroll_win(BYTE x,
	   BYTE y);

/* ************************************************************ */

void
set_sprite_data(UBYTE first_tile,
		UBYTE nb_tiles,
		unsigned char *data);

void
get_sprite_data(UBYTE first_tile,
		UBYTE nb_tiles,
		unsigned char *data);

void
set_sprite_tile(UBYTE nb,
		UBYTE tile);

UBYTE
get_sprite_tile(UBYTE nb);

void
set_sprite_prop(UBYTE nb,
		UBYTE prop);

UBYTE
get_sprite_prop(UBYTE nb);

void
move_sprite(UBYTE nb,
	    UBYTE x,
	    UBYTE y);

void
scroll_sprite(BYTE nb,
	      BYTE x,
	      BYTE y);

/* ************************************************************ */

void
set_data(unsigned char *vram_addr,
	 unsigned char *data,
	 UWORD len);

void
get_data(unsigned char *data,
	 unsigned char *vram_addr,
	 UWORD len);

void
set_tiles(UBYTE x,
	  UBYTE y,
	  UBYTE w,
	  UBYTE h,
	  unsigned char *vram_addr,
	  unsigned char *tiles);

void
get_tiles(UBYTE x,
	  UBYTE y,
	  UBYTE w,
	  UBYTE h,
	  unsigned char *tiles,
	  unsigned char *vram_addr);

#endif /* _GB_H */
