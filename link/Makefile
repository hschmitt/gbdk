SRC	= .
OBJS	= lkarea.o lkdata.o lkeval.o lkhead.o lkihx.o lklex.o \
	  lklibr.o lklist.o lkmain.o lkrloc.o lks19.o lksym.o \
	  lkgb.o lkgg.o
BINS	= link$E

CFLAGS	+= -funsigned-char

all:	$(BINS)

$(BINS):	$(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

%.o:	$(SRC)/%.c
	$(CC) -c $(CFLAGS) -I$(SRC) -I$(SRC)/../as -o $@ $<

clean:
	rm -f $(OBJS) $(BINS)
