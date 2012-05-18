CC	= ../bin/lcc -Wa-l

# Files to be pre-compiled before distribution

PRECOMPILE = font.s \
	floor.s \
	ftou.s \
	sin_cos.s \
	sintable.s \
	sqrt.s

OBJS	= crt0.o \
	\
	floor.o \
	ftou.o \
	sin_cos.o \
	sintable.o \
	sqrt.o \
	abs.o \
	arand.o \
	asl.o \
	asr.o \
	atoi.o \
	atol.o \
	calloc.o \
	cgb.o \
	cpy_data.o \
	delay.o \
	digits.o \
	div.o \
	drawing.o \
	fp_long.o \
	free.o \
	get_bk_t.o \
	get_data.o \
	get_prop.o \
	get_spr.o \
	get_wi_t.o \
	get_xy_t.o \
	hiramcpy.o \
	init_tt.o \
	input.o \
	isalpha.o \
	isdigit.o \
	islower.o \
	isspace.o \
	isupper.o \
	itoa.o \
	labs.o \
	lreg.o \
	lsr.o \
	ltoa.o \
	malloc.o \
	memcpy.o \
	memset.o \
	mul.o \
	mv_bkg.o \
	mv_spr.o \
	mv_win.o \
	font.o \
	ibmfixed.o \
	f_spect.o \
	f_italic.o \
	f_ibm_sh.o \
	f_min.o \
	pad.o \
	print.o \
	printf.o \
	println.o \
	printn.o \
	puts.o \
	rand.o \
	realloc.o \
	reverse.o \
	scanf.o \
	scroll_b.o \
	scroll_s.o \
	scroll_w.o \
	serial.o \
	set_bk_t.o \
	set_data.o \
	set_prop.o \
	set_spr.o \
	set_wi_t.o \
	set_xy_t.o \
	sgb.o \
	sprint.o \
	sprintf.o \
	sprintln.o \
	sprintn.o \
	strcat.o \
	strcmp.o \
	strcpy.o \
	strlen.o \
	strncat.o \
	strncmp.o \
	strncpy.o \
	tolower.o \
	toupper.o \
	gprintf.o \
	gprintln.o \
	gprintn.o \
	gprint.o \
	clock.o \
	time.o \
	sample.o


all:	$(OBJS)

# Precompile some files for distribution
prep-dist: clean gb.lib $(PRECOMPILE) make.bat

make.bat: clean
	echo "REM Generated from Makefile using 'make make.bat'" >> make.bat
	for i in *.s; do echo ..\\bin\\lcc -c -o `basename $$i .s`.o $$i >> make.bat; done 
	for i in *.c; do echo ..\\bin\\lcc -c -o `basename $$i .c`.o $$i >> make.bat; done 

gb.lib: 
	rm -f gb.lib
	for i in $(OBJS); do echo $$i >> gb.lib; done

%.s: %.ms
	maccer -o $@ $<

%.o:	%.c
	$(CC) -c -o $@ $<

%.o:	%.s
	$(CC) -c -o $@ $<

clean:
	rm -f *.o *.lst *.map *.gb *~ $(PRECOMPILE) gb.lib make.bat
