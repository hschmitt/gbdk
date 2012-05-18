#include <stdio.h>

/* Print a long number in any radix */

extern char *digits;

void println(WORD number, BYTE radix, BYTE signed_value)
{
  UWORD l;

  if(number < 0 && signed_value) {
    putchar('-');
    number = -number;
  }
  if((l = (UWORD)number / (UWORD)radix) != 0)
    println(l, radix, UNSIGNED);
  putchar(digits[(UWORD)number % (UWORD)radix]);
}
