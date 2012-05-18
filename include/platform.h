/*
  platform.h

  Platform specific varibles
*/

#ifndef __PLATFORM_H
#define __PLATFORM_H

#ifdef GAMEBOY
/* MALLOC_HEAP_END and MALLOC_HEAP_START define the size of the heap */
#define	MALLOC_HEAP_END		(0xDFFF - 0x200)
#define MALLOC_HEAP_START	((UWORD)&malloc_heap_start)
#endif

#endif /* __PLATFORM_H */
