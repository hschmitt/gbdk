/*
  free.c
  
  Implementation of free()
*/
#include "malloc.h"
#include "platform.h"

#ifndef PROVIDES_FREE
/*
  free

  Attempts to free the memory pointed to by 'ptr'
  Different from the standard free:  returns -1 if already free, or -2 if not part of the malloc list
*/
BYTE free(void *ptr)
{
    /* Do a relativly safe free by only freeing vaild used hunks */
    pmmalloc_hunk thisHunk, lastHunk, nextHunk;
    
    thisHunk = malloc_first;
    lastHunk = NULL;
    
    /* Adjust the pointer to point to the start of the hunk header - makes the comparision easier */
    ptr = (void *)((UBYTE *)ptr - sizeof(mmalloc_hunk));
    
    /* Walk the linked list */
    while (thisHunk->size != 0) {
	/* Is this the hunk? */
	if (thisHunk == ptr) {
	    MALLOC_DEBUG("free", "Found hunk");
	    /* Only free it if it's used */
	    if ((WORD)thisHunk->size > 0) {
		/* Check the next hunk as well - see if we can combine */
		nextHunk = (pmmalloc_hunk)((UBYTE *)thisHunk + thisHunk->size + sizeof(mmalloc_hunk));
		if (nextHunk->size & MALLOC_FREE) {
		    thisHunk->size += sizeof(mmalloc_hunk) + nextHunk->size;
		}
		if (lastHunk) {
		    if (lastHunk->size & MALLOC_FREE) {
			lastHunk->size += sizeof(mmalloc_hunk) + thisHunk->size;
			lastHunk->size |= 0x8000;
		    }
		    else {
			thisHunk->size = thisHunk->size | MALLOC_FREE;
		    }
		}
		else {
		    thisHunk->size = thisHunk->size | MALLOC_FREE;
		}
		return 0;
	    }
	    MALLOC_DEBUG("free", "Attempt to free a free hunk");
	    return -1;
	}
	/* walking... */
	lastHunk = thisHunk;
	thisHunk=(pmmalloc_hunk)((UBYTE *)thisHunk + (thisHunk->size & MALLOC_MASK) + sizeof(mmalloc_hunk));
    };
    
    MALLOC_DEBUG("free", "No hunk found");
    return -2;
}
#endif /* PROVIDES_FREE */
