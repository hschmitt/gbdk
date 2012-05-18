#include <gb.h>
#include <stdio.h>

UBYTE var_3;  /* In external RAM bank 3 */

void bank_3() /* In ROM bank 3 */
{
  puts("I'm in ROM bank 3");
}
