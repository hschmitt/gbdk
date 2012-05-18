#include <stdio.h>

/* Print a number in any radix */

extern char *digits;

void printn(BYTE number, BYTE radix, BYTE signed_value)
{
  UBYTE i;

  if(number < 0 && signed_value) {
    putchar('-');
    number = -number;
  }
  if((i = (UBYTE)number / (UBYTE)radix) != 0)
    printn(i, radix, UNSIGNED);
  putchar(digits[(UBYTE)number % (UBYTE)radix]);
}
