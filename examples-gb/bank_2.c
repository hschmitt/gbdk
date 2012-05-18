#include <gb.h>
#include <stdio.h>

UBYTE var_2;  /* In external RAM bank 2 */

void bank_2() /* In ROM bank 2 */
{
  puts("I'm in ROM bank 2");
}
