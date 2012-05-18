#include <ctype.h>

BYTE isupper(char c)
{
  if(c >= 'A' && c <= 'Z')
    return 1;
  else
    return 0;
}
