#ifndef __ENDIN_H
#define __ENDIN_H

#ifdef LINUX
	#include <netinet/in.h>
#endif
#ifdef GAMEBOY

#include <types.h>

UWORD ntohs(UWORD convert);
UWORD htons(UWORD convert);

UDWORD ntohl(UDWORD convert);
UDWORD htonl(UDWORD convert);

/* Reverse the order of the bytes in the argument */
UWORD swap_word(UWORD swap);
UBYTE swap_byte(UBYTE swap);
#endif /* GAMEBOY */

#endif /* __ENDIN_H */
