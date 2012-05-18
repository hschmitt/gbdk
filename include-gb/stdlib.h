#ifndef _STDLIB_H
#define _STDLIB_H

#include <types.h>

BYTE
atoi(char *s);

WORD
atol(char *s);

char *
reverse(char *s);

char *
itoa(BYTE n,
     char *s);

char *
ltoa(WORD n,
     char *s);

UBYTE
abs(BYTE num);

WORD
labs(WORD num);

BYTE
malloc_init(void);

void *
malloc(UWORD size);

void *
realloc(void *ptr,
	UWORD size);

BYTE
free(void *ptr);

void *
calloc(UWORD nmemb,
       UWORD size);

#endif /* _STDLIB_H */
