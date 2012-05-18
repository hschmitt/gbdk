/*
 * Support for Color GameBoy.
 */

#ifndef _CGB_H
#define _CGB_H

/*
 * Macro to create a palette entry out of the color components.
 */
#define RGB(r, g, b) \
  ((((UWORD)(b) & 0x1f) << 10) | (((UWORD)(g) & 0x1f) << 5) | (((UWORD)(r) & 0x1f) << 0))

/*
 * Common colors based on the EGA default palette.
 */
#define RGB_RED        RGB(31,  0,  0)
#define RGB_DARKRED    RGB(15,  0,  0)
#define RGB_GREEN      RGB( 0, 31,  0)
#define RGB_DARKGREEN  RGB( 0, 15,  0)
#define RGB_BLUE       RGB( 0,  0, 31)
#define RGB_DARKBLUE   RGB( 0,  0, 15)
#define RGB_YELLOW     RGB(31, 31,  0)
#define RGB_DARKYELLOW RGB(21, 21,  0)
#define RGB_CYAN       RGB( 0, 31, 31)
#define RGB_AQUA       RGB(28,  5, 22)
#define RGB_PINK       RGB(11,  0, 31)
#define RGB_PURPLE     RGB(21,  0, 21)
#define RGB_BLACK      RGB( 0,  0,  0)
#define RGB_DARKGRAY   RGB(10, 10, 10)
#define RGB_LIGHTGRAY  RGB(21, 21, 21)
#define RGB_WHITE      RGB(31, 31, 31)

#define RGB_LIGHTFLESH RGB(30, 20, 15)
#define RGB_BROWN      RGB(10, 10,  0)
#define RGB_ORANGE     RGB(30, 20,  0)
#define RGB_TEAL       RGB(15, 15,  0)


/*
 * Set bkg palette(s).
 */
void
set_bkg_palette(UBYTE first_palette,
                UBYTE nb_palettes,
                UWORD *rgb_data);

/*
 * Set sprite palette(s).
 */
void
set_sprite_palette(UBYTE first_palette,
                   UBYTE nb_palettes,
                   UWORD *rgb_data);

/*
 * Set a bkg palette entry.
 */
void
set_bkg_palette_entry(UBYTE palette,
                      UBYTE entry,
                      UWORD rgb_data);

/*
 * Set a sprite palette entry.
 */
void
set_sprite_palette_entry(UBYTE palette,
                         UBYTE entry,
                         UWORD rgb_data);

/*
 * Set CPU speed to slow operation.
 * (Make sure interrupts are disabled before call!)
 */
void cpu_slow(void);

/*
 * Set CPU speed to fast operation.
 * (Make sure interrupts are disabled before call!)
 */
void cpu_fast(void);


/*
 * Set defaults compatible with normal GameBoy.
 */
void cgb_compatibility(void);

#endif /* _CGB_H */
