#include <string.h>

/* Return length of string */

BYTE strlen(const char *s)
{
  UBYTE i;

  i = 0;
  while(*s++)
    i++;
  return i;
}
