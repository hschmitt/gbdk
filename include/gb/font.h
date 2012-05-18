/* font.h
	Multiple font support for the GameBoy
	Michael Hope, 1999
	michaelh@earthling.net
	Distrubuted under the Artistic License - see www.opensource.org
*/
#ifndef __FONT_H
#define __FONT_H

#include <gb.h>

#define	FONT_256ENCODING	0
#define	FONT_128ENCODING	1
#define	FONT_NOENCODING		2

#define	FONT_COMPRESSED		4

/* See gb.h/M_NO_SCROLL and gb.h/M_NO_INTERP */

/* font_t is a handle to a font loaded by font_load() */
typedef UWORD font_t;

/* The default fonts */
extern UBYTE font_spect[], font_italic[], font_ibm[], font_min[];

/* Backwards compatible font */
extern UBYTE fontibm_fixed[];

/* Init the font system */
void	font_init(void);

/* Load the font 'font' */
font_t	font_load( void *font );

/* Set the current font to 'font_handle', which was returned from an earlier
   font_load().  Returns the previously used font handle.
*/
font_t	font_set( font_t font_handle );

/* Print the same character 'show' 'num' times */
void print_repeat(char show, UBYTE num);

/* Use mode() and color() to set the font modes and colours */

/* Internal representation of a font.  What a font_t really is */
typedef struct sfont_handle mfont_handle;
typedef struct sfont_handle *pmfont_handle;

struct sfont_handle {
    UBYTE first_tile;		/* First tile used */
    void *font;			/* Pointer to the base of the font */
};
	
#endif /* __FONT_H */
