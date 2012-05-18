#include <stdio.h>

/* Print a number in any radix */

extern char *digits;

UBYTE sprintn(char *s, BYTE number, BYTE radix, BYTE signed_value)
{
  UBYTE i;
  UBYTE pos = 0;

  if(number < 0 && signed_value) {
    putchar('-');
    number = -number;
  }
  if((i = (UBYTE)number / (UBYTE)radix) != 0)
    pos = sprintn(s, i, radix, UNSIGNED);
  s[pos++] = digits[(UBYTE)number % (UBYTE)radix];
  s[pos] = 0;

  return pos;
}
