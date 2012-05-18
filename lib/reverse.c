#include <stdlib.h>

char *reverse(char *s)
{
  UBYTE i, j;
  char c;

  i = 0;
  j = strlen(s) - 1;
  while(i < j) {
    c = s[i];
    s[i] = s[j];
    s[j] = c;
    i++;
    j--;
  }
  return(s);
}
