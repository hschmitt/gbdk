#include <stdlib.h>

char *ltoa(WORD n, char *s)
{
  UBYTE i, sign;

  if(n < 0) {
    sign = 1;
    n = -n;
  } else
    sign = 0;
  i = 0;
  do {
    s[i++] = n % 10 + '0';
  } while((n = n/10) > 0);
  if(sign)
    s[i++] = '-';
  s[i] = 0;
  reverse(s);
  return s;
}
