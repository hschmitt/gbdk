#ifndef __STDARG
#define __STDARG

#if !defined(_VA_LIST)
#define _VA_LIST
typedef char *__va_list;
#endif
typedef __va_list va_list;

#define va_start(list, start) \
	((void)((list) = (char *)&start + sizeof(start)))
#define __va_arg(list, mode) \
        *(mode *)(&(list += sizeof(mode))[-(int)(sizeof(mode))])
#define va_end(list) ((void)0)
#define va_arg(list, mode) __va_arg(list, mode)

#endif
