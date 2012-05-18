#include <gb.h>
#include <stdio.h>
#include <string.h>

UWORD counter;

void inc()
{
  counter++;
}

void print_counter()
{
  printf(" Counter is %lu\n", counter);
}

void main()
{
  extern UBYTE end_inc, start_inc;
  /* Declare extern functions */
  void inc_ram();
  void inc_hiram();
  /* Declare pointer-to-function variables */
  void (*inc_ram_var)() = (void (*)())0xD000;
  void (*inc_hiram_var)() = (void (*)())0xFFA0;

  puts("Program Start...");
  counter = 0;
  /* Copy 'inc' to HIRAM at 0xFFA0 */
  hiramcpy(0xA0U, (void *)&start_inc, (UBYTE)(&end_inc-&start_inc));
  /* Copy 'inc' to RAM at 0xD000 */
  memcpy((void *)0xD000, (void *)&start_inc, (UWORD)(&end_inc-&start_inc));

  print_counter();

  /* Call function in ROM */
  puts("Call ROM");
  inc();
  print_counter();

  /* Call function in RAM using link-time address */
  puts("Call RAM direct");
  inc_ram();
  print_counter();

  /* Call function in RAM using pointer-to-function variable */
  puts("Call RAM indirect");
  inc_ram_var();
  print_counter();

  /* Call function in HIRAM using link-time address */
  puts("Call HIRAM direct");
  inc_hiram();
  print_counter();

  /* Call function in HIRAM using pointer-to-function variable */
  puts("Call HIRAM indirect");
  inc_hiram_var();
  print_counter();

  puts("The End...");
}
