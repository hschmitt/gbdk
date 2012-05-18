#ifndef _CONSOLE_H
#define _CONSOLE_H

#include <types.h>

void
gotoxy(UBYTE x,
	   UBYTE y);

UBYTE
posx(void);

UBYTE
posy(void);

void
setchar(char c);

#endif /* _CONSOLE_H */
