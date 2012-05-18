CC	= ../../bin/lcc -Wa-l -Wl-m

BINS	= colorbar.gb

all:	$(BINS)

%.o:	%.c
	$(CC) -c -o $@ $<

%.o:	%.s
	$(CC) -c -o $@ $<

%.gb:	%.o
	$(CC) -o $@ $<

clean:
	rm -f *.o *.lst *.map *.gb

# Link file, and write 0x80 at position 0x143 in header
colorbar.gb:	colorbar.o
	$(CC) -Wl-yp0x143=0x80 -o colorbar.gb colorbar.o
