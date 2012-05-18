#include <stdio.h>

UBYTE sprint(char *s, char *str)
{
  UBYTE n = 0;

  while(*str) {
    *(s++) = *(str++);
    n++;
  }
  *s = 0;

  return n;
}
