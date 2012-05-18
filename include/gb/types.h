#ifndef _TYPES_H
#define _TYPES_H

#ifndef INT_8_BITS
#ifndef INT_16_BITS
#error "INT_8_BITS or INT_16_BITS must be defined"
#define INT_8_BITS
#endif /* INT_16_BITS */
#endif /* INT_8_BITS */

#ifdef INT_16_BITS
typedef char               INT8;
typedef unsigned char      UINT8;
typedef int                INT16;
typedef unsigned int       UINT16;
typedef long               INT32;
typedef unsigned long      UINT32;
#else /* INT_16_BITS */
typedef int                INT8;
typedef unsigned int       UINT8;
typedef long               INT16;
typedef unsigned long      UINT16;
typedef long long          INT32;
typedef unsigned long long UINT32;
#endif /* INT_16_BITS */

typedef INT8               BYTE;
typedef UINT8              UBYTE;
typedef INT16              WORD;
typedef UINT16             UWORD;
typedef INT32              LWORD;
typedef UINT32             ULWORD;
typedef INT32		   DWORD;
typedef UINT32		   UDWORD;

typedef void *             POINTER;

#define	NULL     0

#define	FALSE    0
#define	TRUE     (!FALSE)

/* Useful definition for fixed point values */

typedef union _fixed {
  struct {
    UBYTE l;
    UBYTE h;
  } b;
  UWORD w;
} fixed;

#endif /* _TYPES_H */
