#include <gb.h>
#include <stdio.h>

UBYTE var_1;  /* In external RAM bank 1 */

void bank_1() /* In ROM bank 1 */
{
  puts("I'm in ROM bank 1");
}
