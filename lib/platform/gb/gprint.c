#include <drawing.h>

void gprint(char *str)
{
  while(*str)
    wrtchr(*str++);
}
