#include <stdio.h>

void print(char *str)
{
  while(*str)
    putchar(*str++);
}
