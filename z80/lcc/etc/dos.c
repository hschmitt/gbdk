/* DOS */

#ifndef LCCDIR
#define LCCDIR "\\SDK\\"
#endif

#include <string.h>

char *suffixes[] = { ".c;.C", ".i;.I", ".s;.S;.asm;.ASM", ".o;.O;.obj;.OBJ", ".exe", 0 };
char inputs[256] = "";
char *cpp[] = { LCCDIR "bin\\cpp",
	"-DINT_8_BITS", "-D__STDC__=1", "-DZ80",
#ifdef GAMEBOY
	"-DGB", "-DGAMEBOY",
#endif
	"$1", "$2", "$3", 0 };
char *include[] = { "-I" LCCDIR "include", 0 };
/* The 2nd argument of com must contain "win32" for DOS compilation... */
char *com[] = { LCCDIR "bin\\rcc", "-g_win32",
#ifdef GAMEBOY
	"-target=gbz80/int8",
#else
	"-target=z80/int8",
#endif
	"-optimize", "$1", "$2", "$3", 0 };
char *as[] = { LCCDIR "bin\\as", "-o", "$1", "$3", "$2", 0 };
char *ld[] = { LCCDIR "bin\\link", "-n", "--",
#ifdef GAMEBOY
	"-z",
#else
	"-i",
#endif
	"$1", "-k" LCCDIR "lib\\", 
#ifdef GAMEBOY
	"-lgb.lib",
#else
	"-lz80.lib",
#endif
	"$3", LCCDIR "lib\\crt0.o", "$2", 0 };

extern char *concat(char *, char *);

int option(char *arg) {
	if(strncmp(arg, "-lccdir=", 8) == 0) {
		cpp[0] = concat(&arg[8], "\\bin\\cpp");
		include[0] = concat("-I", concat(&arg[8], "\\include"));
		com[0] = concat(&arg[8], "\\bin\\rcc");
		as[0] = concat(&arg[8], "\\bin\\as");
		ld[0] = concat(&arg[8], "\\bin\\link");
		ld[5] = concat("-k", concat(&arg[8], "\\lib\\"));
		ld[8] = concat(&arg[8], "\\lib\\crt0.o");
	} else if(strcmp(arg, "-int8") == 0) {
		cpp[1] = "-DINT_8_BITS";
#ifdef GAMEBOY
		com[2] = "-target=gbz80/int8";
#else
		com[2] = "-target=z80/int8";
#endif
	} else if(strcmp(arg, "-int16") == 0) {
		cpp[1] = "-DINT_16_BITS";
#ifdef GAMEBOY
		com[2] = "-target=gbz80/int16";
#else
		com[2] = "-target=z80/int16";
#endif
	} else
		return 0;
	return 1;
}
