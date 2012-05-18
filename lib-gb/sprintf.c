#include <stdio.h>
#include <stdarg.h>

BYTE sprintf(char *s, char *fmt, ...)
{
  va_list ap;
  BYTE nb = 0;

  va_start(ap, fmt);
  for(; *fmt; fmt++)
    if(*fmt == '%') {
      switch(*++fmt) {
      case 'c':
	/* char */
	*(s++) = va_arg(ap, char);
	break;
      case 'd':
	/* decimal int */
	s += sprintn(s, va_arg(ap, BYTE), 10, SIGNED);
	break;
      case 'u':
	/* unsigned int */
	s += sprintn(s, va_arg(ap, BYTE), 10, UNSIGNED);
	break;
      case 'o':
	/* octal int */
	s += sprintn(s, va_arg(ap, BYTE), 8, UNSIGNED);
	break;
      case 'x':
	/* hexadecimal int */
	s += sprintn(s, va_arg(ap, BYTE), 16, UNSIGNED);
	break;
      case 's':
	/* string */
	s += sprint(s, va_arg(ap, char *));
	break;
      case 'l':
	/* long */
	switch(*++fmt) {
	case 'd':
	  /* decimal long */
	  s += sprintln(s, va_arg(ap, WORD), 10, SIGNED);
	  break;
	case 'u':
	  /* unsigned long */
	  s += sprintln(s, va_arg(ap, WORD), 10, UNSIGNED);
	  break;
	case 'o':
	  /* octal long */
	  s += sprintln(s, va_arg(ap, WORD), 8, UNSIGNED);
	  break;
	case 'x':
	  /* hexadecimal long */
	  s += sprintln(s, va_arg(ap, WORD), 16, UNSIGNED);
	  break;
	}
	break;
      case '%':
	/* % */
	*(s++) = *fmt;
	break;
      default:
	*s = 0;
	return -1;
      }
      nb++;
    } else
      *(s++) = *fmt;
  va_end(ap);
  *s = 0;

  return nb;
}
