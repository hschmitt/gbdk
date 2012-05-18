#include <stdlib.h>

UBYTE abs(BYTE num)
{
  if(num < 0)
    return -num;
  else
    return num;
}
