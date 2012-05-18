#include "c.h"
#ifndef SDK
extern Interface alphaIR;
extern Interface mipsebIR, mipselIR;
extern Interface sparcIR, solarisIR;
extern Interface x86IR, x86linuxIR;
#endif /* SDK */
#ifdef SDK
#ifdef GAMEBOY
extern Interface z80gbIR8;
extern Interface z80gbIR16;
#else /* GAMEBOY */
extern Interface z80IR8;
extern Interface z80IR16;
#endif /* GAMEBOY */
#endif /* SDK */
extern Interface symbolicIR, symbolic64IR;
extern Interface nullIR;
extern Interface bytecodeIR;
Binding bindings[] = {
#ifndef SDK
        "alpha/osf",     &alphaIR,
        "mips/irix",     &mipsebIR,
        "mips/ultrix",   &mipselIR,
        "sparc/sun",     &sparcIR,
        "sparc/solaris", &solarisIR,
        "x86/win32",     &x86IR,
        "x86/linux",     &x86linuxIR,
        "symbolic/osf",  &symbolic64IR,
        "symbolic/irix", &symbolicIR,
#endif /* SDK */
#ifdef SDK
#ifdef GAMEBOY
        "gbz80/int8",       &z80gbIR8,
        "gbz80/int16",      &z80gbIR16,
#else /* GAMEBOY */
        "z80/int8",         &z80IR8,
        "z80/int16",        &z80IR16,
#endif /* GAMEBOY */
#endif /* SDK */
        "symbolic",      &symbolicIR,
        "null",          &nullIR,
        "bytecode",      &bytecodeIR,
        NULL,            NULL
};
