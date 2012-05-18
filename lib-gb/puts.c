#include <stdio.h>

void puts(char *str)
{
  while(*str)
    putchar(*str++);
  putchar('\n');
}
