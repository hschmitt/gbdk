#include "malloc.h"
#include <stdlib.h>
#include <types.h>
#include <string.h>

#define DEBUG

#ifndef PROVIDES_MALLOC_FIND
/* panic */
#endif

#ifndef PROVIDES_REALLOC
void *realloc( void *current, UWORD size )
{
	UWORD nextSize;
	pmmalloc_hunk thisHunk, newHunk;
	void *newRegion;

	thisHunk = malloc_first;

	/* Handle the special cases */
	if (size==0) {
		free(current);
		return NULL;
	}
	if (current==NULL) {
		return malloc(size);
	}
		
	thisHunk = malloc_find(current);

#ifdef DEBUG
	printf("realloc: found at %lx\n", thisHunk);
#endif
	if ((thisHunk == NULL)||((WORD)thisHunk->size <0)) {
	    /* Never allocated - cant realloc(), so just malloc() */
	    return malloc(size);
	}

	if (thisHunk->size == size ) {
	    /* Laugh at them and return */
	    return current;
	}

	if (thisHunk->size > size ) {
	    if (thisHunk->size > size + sizeof( mmalloc_hunk )) {
		/* Shrink the hunk */
		newHunk = (pmmalloc_hunk)(size + sizeof( mmalloc_hunk )+ (UWORD)thisHunk);
		newHunk->size = (thisHunk->size - size -sizeof( mmalloc_hunk )) | MALLOC_FREE;
		thisHunk->size = size;
		return current;
	    }
	    else {	
		/* Cant shrink the hunk as there's not enough room to put a new hunk header */
		return current;
	    }
	}

	/* Must be growing this region - see if the next one is free */
	nextSize = ((pmmalloc_hunk)((UBYTE *)thisHunk + sizeof(mmalloc_hunk) + thisHunk->size))->size;
	if ((WORD)newHunk->size < 0) {
	    nextSize = nextSize & MALLOC_MASK;
	    if (nextSize >= (size - thisHunk->size)) {
		/* Next hunk + this is big enough to contain the new hunk */
		newHunk = (pmmalloc_hunk)((UBYTE *)thisHunk + sizeof(mmalloc_hunk) + size);
		newHunk->size = thisHunk->size + nextSize - size - sizeof( mmalloc_hunk );
		return current;
	    }
	}
	/* Oh well.  Allocate a new hunk then free this one */
	newRegion = malloc (size);
	if (newRegion) {
	    memcpy( newRegion, current, thisHunk->size );
	    free( current );
	    return newRegion;
	}
	return NULL;	/* Couldnt do it */
}
#endif /* PROVIDES_REALLOC */
