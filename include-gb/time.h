/*
  time.h

  Simple, not completly conformant implementation of time routines
*/

#ifndef __TIME_H
#define __TIME_H

#include <types.h>

/* The data types */
typedef UWORD	clock_t;
typedef UWORD	time_t;

/* Run of the VBL interrupt so rate is 60/sec */
#define CLK_TCK		60
#define CLOCKS_PER_SEC	60

/* Returns time since turn on */
clock_t clock(void);

/* Returns time since turn on in seconds */
/* If t != NULL, is also stored in *t */
time_t time(time_t *t);

#endif /* __TIME_H */
