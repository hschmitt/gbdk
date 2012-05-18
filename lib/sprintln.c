#include <stdio.h>

/* Print a long number in any radix */

extern char *digits;

UBYTE sprintln(char *s, WORD number, BYTE radix, BYTE signed_value)
{
  UWORD l;
  UBYTE pos = 0;

  if(number < 0 && signed_value) {
    putchar('-');
    number = -number;
  }
  if((l = (UWORD)number / (UWORD)radix) != 0)
    pos = sprintln(s, l, radix, UNSIGNED);
  s[pos++] = digits[(UWORD)number % (UWORD)radix];
  s[pos] = 0;

  return pos;
}
