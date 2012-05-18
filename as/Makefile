SRC	= .
OBJS	= asdata.o asexpr.o aslex.o aslist.o asmain.o asout.o \
	  assubr.o assym.o z80adr.o z80ext.o z80mch.o z80pst.o
BINS	= as$E

CFLAGS	+= -funsigned-char

all:	$(BINS)

$(BINS):	$(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

%.o:	$(SRC)/%.c
	$(CC) -c $(CFLAGS) -I$(SRC) -o $@ $<

clean:
	rm -f $(OBJS) $(BINS)
