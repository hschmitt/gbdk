#include <string.h>

/*
/*
 * Copy string s2 to s1. s1 must be large enough.
 * Return s1.
 */

char *strcpy(char *s1, const char *s2)
{
  char *os1;

  os1 = s1;
  while(*s1++ = *s2++)
    ;
  return os1;
}
