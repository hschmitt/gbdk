/*
  malloc.c

  Simple implementation of a malloc library for the GB

  Notes:
  * Designed for the Nintendo GB - 8 bitter with little RAM, so efficency and allocation
  speed are important.  recursion or malloc/free pairs are rare.
  * Garbage collection is lazy
  * Singly linked list of 'hunks' - regions of memory
  * Each hunk is preceeded by a header - header describes a singly linked list
  * If the header is corrupted, this system dies - but so does the program so youve got other problems
  * All allocations are on byte boundries
  * See types.h for the definitions of UBYTE, BYTE...
  * Theres a bug in GBDK 2.0b9 - cant handle pointer addition, requiring (UWORD) casting
*/
#include "malloc.h"
#include "processor.h"
#include "platform.h"
#include <types.h>
#include <stdio.h>


/* First hunk in the linked list
   Equals zero if malloc() is not setup */
pmmalloc_hunk malloc_first;

/*
  malloc_init

  Initialise the malloc system.  
  Only initalises if the magic number on the first hunk is invalid.
  Note that this number is invalidated in crt0.s 
  
  Returns: BYTE, -1 on failure, 0 on success
*/
BYTE malloc_init(void)
{
	if (malloc_first==NULL) {
		/* Init by setting up the first hunk */

		MALLOC_DEBUG("malloc_init", "Setting up");
		/* malloc_heap_start is set by the linker to point to the start of free memory */
		malloc_first = (pmmalloc_hunk)(MALLOC_HEAP_START);

		/* Set the size to all of free memory (mem ends at 0xE000), less 200h for the stack */
		malloc_first->size = (MALLOC_HEAP_END - sizeof(mmalloc_hunk) - MALLOC_HEAP_START) | MALLOC_FREE;
		return 0;
	}
	return -1;
}

/*
  malloc_gc

  Do a grabage collect on the malloc list.  Join any adjacent, free hunks into one
  free hunk.  Called by malloc() when there is no one free block of memory big
  enough.
  Note that malloc_gc is only called when needed to save processor time
  Note:  assumes that hunks ae consecutive
*/
void malloc_gc(void)
{
    /* Note: Hunks are consecutive */
    /* thisHunk is the one that were lookin at */
    /* nextHunk is used when joining hunks */
    pmmalloc_hunk thisHunk, nextHunk;

    /* changed is set if at least two hunks are joined */
    /* Note that logically all will be joined on the first pass, but you get that */
    UBYTE changed;
    
    MALLOC_DEBUG("malloc_gc","Running");
    do {
	thisHunk = malloc_first;
	changed = 0;
	/* Walk the whole of the linked list */
	while (thisHunk->size != 0) {
	    /* Is this hunk free ? */
	    if ((WORD)thisHunk->size < 0) {
		/* Yes - if the next is as well, join them */
		nextHunk = (pmmalloc_hunk)((UBYTE *)thisHunk + (thisHunk->size & MALLOC_MASK) + sizeof(mmalloc_hunk));
		/* This catches the case where there are many consecutive free hunks */
		while ((WORD)nextHunk->size < 0) {
		    /* Must be consecutive */
		    /* Dont worry about wrap around on the top bit here - fix it later */
		    changed = 1;
		    thisHunk->size += nextHunk->size + sizeof(mmalloc_hunk);
		    nextHunk = (pmmalloc_hunk)((UBYTE *)nextHunk + (nextHunk->size & MALLOC_MASK) + sizeof(mmalloc_hunk));
		}
		thisHunk->size |= MALLOC_FREE;
	    }
	    thisHunk= (pmmalloc_hunk)((UBYTE *)thisHunk + (thisHunk->size & MALLOC_MASK) + sizeof(mmalloc_hunk));
	}
	/* If thisHunk is not NULL, then the magic number was corrupt */
    } while (changed);
}

#ifndef PROVIDES_MALLOC	
/*
  malloc

  Attempt to allocate a hunk of at least 'size' bytes from free memory
  Return:  pointer to the base of free memory on success, NULL if no memory
  was available
*/
void *malloc( UWORD size )
{
    /* thisHunk: list walker
    */
    pmmalloc_hunk thisHunk, newHunk;

    UBYTE firstTry;

    /* Init the system if required */
    if (malloc_first == NULL)
	malloc_init();
    
    firstTry = 1;	/* Allows gc if no big enough hunk is found */
    thisHunk = malloc_first;

    //    malloc_dump();
    do {
	
	/* Walk the list */
	while (thisHunk->size != 0) {
	    MALLOC_DEBUG("malloc", "Entering hunk" );
	    if ((WORD)thisHunk->size <0) {
		MALLOC_DEBUG("malloc", "Found free hunk" );
		
		/* Free, is it big enough? (dont forget the size of the header) */
		if ((thisHunk->size&MALLOC_MASK) >= size+sizeof(mmalloc_hunk)) {
		    
		    MALLOC_DEBUG("malloc","Found a big enough hunk.");
		    
		    /* Yes, big enough */
		    /* Create a new header at the end of this block */
		    /* Note: the header can be of zero length - should add code to combine */
		    newHunk = (pmmalloc_hunk)((UBYTE *)thisHunk + size + sizeof(mmalloc_hunk));
		    newHunk->size = thisHunk->size - size - sizeof(mmalloc_hunk);
		    /* Shrink this hunk, and mark it as used */

		    /* size is the free space, less that allocated, less the new header */
		    thisHunk->size = size&MALLOC_MASK;
		    
		    /* Return a pointer to the new region */
		    return (void *)((UBYTE *)thisHunk + sizeof(mmalloc_hunk));
		}
	    }
	    thisHunk=(pmmalloc_hunk)((UBYTE *)thisHunk + (thisHunk->size & MALLOC_MASK) + sizeof(mmalloc_hunk));
	}
	malloc_gc();
	thisHunk = malloc_first;
	/* Try again after a garbage collect */
    } while (firstTry--);

    /* Couldnt do it */
    return NULL;
}
#endif /* PROVIDES_MALLOC */

void malloc_dump(void) 
{
    /* Walk the malloc list */
    pmmalloc_hunk walk;

    walk = malloc_first;
    
    while (walk->size != 0) {
	if ((WORD)walk->size < 0) {
	    printf("Free");
	}
	else {
	    printf("Used");
	}
	printf(" hunk at %lx, length %ld\n", (UWORD)walk, (UWORD)walk->size&MALLOC_MASK);
	walk=(pmmalloc_hunk)((UWORD)walk + (walk->size&MALLOC_MASK) + (UWORD)sizeof(mmalloc_hunk));
    }
    if ((UWORD)walk != (UWORD)MALLOC_HEAP_END) {
	printf("malloc_dump: somethings stuffed (%lx).\n", (UWORD)walk);
    }
    printf("Done at %lx.\n", (UWORD)walk);
}
