#ifndef _STDIO_H
#define _STDIO_H

#include <types.h>

#define SIGNED   1
#define UNSIGNED 0

void
printn(BYTE number,
       BYTE radix,
       BYTE signed_value);

void
println(WORD number,
	BYTE radix,
	BYTE signed_value);

void
puts(char *str);

void
print(char *str);

BYTE
printf(char *fmt,
       ...);

BYTE
scanf(char *fmt,
      ...);

UBYTE
sprint(char *s,
       char *str);

UBYTE
sprintn(char *s,
	BYTE number,
	BYTE radix,
	BYTE signed_value);

UBYTE
sprintln(char *s,
	 WORD number,
	 BYTE radix,
	 BYTE signed_value);

BYTE
sprintf(char *s,
	char *fmt,
	...);

/* Assembly functions */
void
cls(void);

void
putchar(char c);

char
getchar(void);

char *
gets(char *s);

#endif /* _STDIO_H */
