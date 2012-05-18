#include <stdlib.h>

WORD labs(WORD num)
{
  if(num < 0)
    return -num;
  else
    return num;
}
