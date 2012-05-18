CC	= ../../bin/lcc -Wa-l -Wl-m

BINS	= gb-dtmf.gb

all:	$(BINS)

%.o:	%.c
	$(CC) -c -o $@ $<

%.o:	%.s
	$(CC) -c -o $@ $<

%.gb:	%.o
	$(CC) -o $@ $<

clean:
	rm -f *.o *.lst *.map *.gb
