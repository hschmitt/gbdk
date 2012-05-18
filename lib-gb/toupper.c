#include <ctype.h>

BYTE toupper(char c)
{
  return ((c >= 'a' && c <= 'z') ? c - 32: c);
}
