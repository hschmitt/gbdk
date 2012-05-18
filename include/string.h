#ifndef _STRING_H
#define _STRING_H

#include <types.h>

void *
memset(void *s1,
       UBYTE c, 
       UWORD n);

void *
memcpy(void *s1,
       const void *s2,
       UWORD n);

char *
strcat(char *s1,
       const char *s2);

BYTE
strcmp(const char *s1,
       const char *s2);

char *
strcpy(char *s1,
       const char *s2);

BYTE
strlen(const char *s);

char *
strncat(char *s1,
	const char *s2,
	UBYTE n);

BYTE
strncmp(const char *s1,
	const char *s2,
	UBYTE n);

char *
strncpy(char *s1,
	const char *s2,
	UBYTE n);

#endif /* _STRING_H */
