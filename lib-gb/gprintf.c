#include <stdarg.h>
#include <drawing.h>

BYTE gprintf(char *fmt, ...)
{
  va_list ap;
  BYTE nb = 0;

  va_start(ap, fmt);
  for(; *fmt; fmt++)
    if(*fmt == '%') {
      switch(*++fmt) {
      case 'c':
	/* char */
	wrtchr(va_arg(ap, char));
	break;
      case 'd':
	/* decimal int */
	gprintn(va_arg(ap, BYTE), 10, SIGNED);
	break;
      case 'u':
	/* unsigned int */
	gprintn(va_arg(ap, BYTE), 10, UNSIGNED);
	break;
      case 'o':
	/* octal int */
	gprintn(va_arg(ap, BYTE), 8, UNSIGNED);
	break;
      case 'x':
	/* hexadecimal int */
	gprintn(va_arg(ap, BYTE), 16, UNSIGNED);
	break;
      case 's':
	/* string */
	gprint(va_arg(ap, char *));
	break;
      case 'l':
	/* long */
	switch(*++fmt) {
	case 'd':
	  /* decimal long */
	  println(va_arg(ap, WORD), 10, SIGNED);
	  break;
	case 'u':
	  /* unsigned long */
	  println(va_arg(ap, WORD), 10, UNSIGNED);
	  break;
	case 'o':
	  /* octal long */
	  println(va_arg(ap, WORD), 8, UNSIGNED);
	  break;
	case 'x':
	  /* hexadecimal long */
	  println(va_arg(ap, WORD), 16, UNSIGNED);
	  break;
	}
	break;
      case '%':
	/* % */
	wrtchr(*fmt);
	break;
      default:
	return -1;
      }
      nb++;
    } else
      wrtchr(*fmt);
  va_end(ap);

  return nb;
}
