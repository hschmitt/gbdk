#include <ctype.h>

BYTE isdigit(char c)
{
  if(c >= '0' && c <= '9')
    return 1;
  else
    return 0;
}
