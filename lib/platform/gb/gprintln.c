#include <drawing.h>

/* Print a long number in any radix */

extern char *digits;

void gprintln(WORD number, BYTE radix, BYTE signed_value)
{
  UWORD l;

  if(number < 0 && signed_value) {
    wrtchr('-');
    number = -number;
  }
  if((l = (UWORD)number / (UWORD)radix) != 0)
    gprintln(l, radix, UNSIGNED);
  wrtchr(digits[(UWORD)number % (UWORD)radix]);
}
