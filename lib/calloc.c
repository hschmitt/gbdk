/*
  calloc.c
*/
#include "malloc.h"
#include "platform.h"
#include <string.h>
#include <stdlib.h>

#ifndef PROVIDES_CALLOC
void *calloc( UWORD nmem, UWORD size )
{
	void *malloced;

	malloced = malloc( nmem*size );
	if (malloced!=NULL) {
		memset( malloced, 0, nmem*size );
		return malloced;
	}
	return	NULL;
}
#endif
