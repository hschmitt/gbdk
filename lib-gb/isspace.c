#include <ctype.h>

BYTE isspace(char c)
{
  if(c == ' ' || c == '\t' || c == '\n')
    return 1;
  else
    return 0;
}
