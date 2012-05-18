# GBDK-2.0 Top level Makefile
# Michael Hope, Pascal Felber

.EXPORT_ALL_VARIABLES:

VERSION	= 2
PATCHLEVEL = 1
SUBLEVEL = 0

# Housekeeping
CONFIG_SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	else if [ -x /bin/bash ]; then echo /bin/bash; \
	else echo sh; fi ; fi)

TOPDIR	:= $(shell if [ "$$PWD" != "" ]; then echo $$PWD; else pwd; fi)

# See if the host OS has already been defined
ifeq (.target,$(wildcard .target))
include .target
endif

# If the host OS is still undefined, assume Unix
ifndef TARGETOS
TARGETOS = unix
endif

Z80 		:= $(TOPDIR)/z80
LCC		:= lcc-4.1
CFLAGS		:= -g #-O2 -fomit-frame-pointer -Wall

# Set HOSTCC and HOSTLD to the name of your systems native compiler
HOSTCC	 	:= gcc
HOSTCFLAGS	:= 
HOSTLD		:= gcc
HOSTLDFLAGS	:= 
HOSTE		:= 
MACCER		:= maccer

# If INDEXLIB is uncommented, then link will build an in-memory index of 
# the library files on the first pass.  This gives a 20x speed up on
# low end systems (386/2M) (Honest!)
INDEXLIB	= y

ifdef INDEXLIB
CFLAGS		:= $(CFLAGS) -DINDEXLIB -DMLH_MAP
endif

# Define DEBUG to include debugging information in the programs
DEBUG 		= y

ifdef DEBUG
CFLAGS		:= $(CFLAGS) -g
endif

SUBDIRS		:= as link maccer

# LCC dir is the root of where LCC will expect to find it's bins, include
#  files and libraries

# Currently supported platforms: rrgb, gb, gg, plain
ifndef PLATFORM
	PLATFORM	:= gb
endif

ifeq ($(PLATFORM), gb)
	PROCESSOR	:= gbz80
	CFLAGS	:= $(CFLAGS) -DGAMEBOY
endif
ifeq ($(PLATFORM), rrgb)
	PROCESSOR	:= gbz80
	CFLAGS	:= $(CFLAGS) -DGAMEBOY
endif
ifeq ($(PLATFORM), gg)
	PROCESSOR	:= z80
	CFLAGS	:= $(CFLAGS) -DGAMEGEAR
endif
ifeq ($(PLATFORM), z80)
	PROCESSOR	:= z80
endif

TARGET			= $(PROCESSOR)-$(PLATFORM)
TARGET_STRING		= \"$(TARGET)\"
SDK_VERSION		= $(VERSION).$(PATCHLEVEL).$(SUBLEVEL)
SDK_VERSION_STRING	= \"$(SDK_VERSION)\"
ifndef SDK_DIR
SDK_DIR			= $(HOME)
endif

BUILDDIR	:= $(TOPDIR)/build/$(TARGET)/$(SDK_VERSION)
DISTROOT	:= $(TOPDIR)/dist

############################################################
# Setup the compiler, flags and executable extension depending on the target
ifeq ($(TARGETOS), dos)
	CC		=  gcc-go32
	LD		=  gcc-go32
	HOSTFILE	=  $(Z80)/lcc/etc/dos.c
	DESTDIR		=  \\\\SDK\\\\$(TARGET)\\\\$(VERSION)-$(PATCHLEVEL)-$(SUBLEVEL)\\\\
	DIST		:= $(DISTROOT)/SDK/$(TARGET)/$(VERSION)-$(PATCHLEVEL)-$(SUBLEVEL)
	ARCHIVE		:= $(TOPDIR)/sdk-$(TARGET)-$(SDK_VERSION).zip
	LCCDIR		=  \"$(TESTDIR)\"
	CFLAGS		:= $(CFLAGS) -DDOS -DWIN32 -D_P_WAIT=P_WAIT -D_spawnvp=spawnvp

	# libemu is the 387 math co-pro emulator
	LDFLAGS		= -lemu
	E		= .exe
else
	CC		=  $(HOSTCC)
	LD		=  $(HOSTLD)
	E		=  $(HOSTE)
	HOSTFILE	=  $(Z80)/lcc/etc/unix.c
	DESTDIR		=  $(SDK_DIR)/SDK/$(TARGET)/$(SDK_VERSION)/
	DIST		:= $(DISTROOT)/SDK/$(TARGET)/$(SDK_VERSION)
	ARCHIVE		:= $(TOPDIR)/sdk-$(TARGET)-$(SDK_VERSION).tar
	CFLAGS		:= $(CFLAGS) -DUNIX
	LDFLAGS         = -lm
endif

LCCDIR		:= \"$(DESTDIR)\"

############################################################

CFLAGS		:= $(CFLAGS) -DSDK -DLCCDIR=$(LCCDIR) -DTARGET=$(TARGET) -DSDK_VERSION_STRING=$(SDK_VERSION_STRING)\
			-DTARGET_STRING=$(TARGET_STRING)

# Save the state for future cleans etc
all:
ifeq ($(TARGETOS), dos)
	echo "TARGETOS=dos" > $(TOPDIR)/.target
else
	echo "TARGETOS=unix" > $(TOPDIR)/.target
endif
	$(MAKE) binary

binary: lcc-binary
	for i in $(SUBDIRS); do $(MAKE) -C $$i; done

# We copy the lcc distribution files to the build directory to avoid
# modifying the original lcc distribution
lcc-binary:
	mkdir -p $(BUILDDIR)/src/lcc
	cp $(LCC)/custom.mk $(BUILDDIR)/src/lcc
	cp -r $(LCC)/lburg $(BUILDDIR)/src/lcc
	cp -r $(LCC)/src $(BUILDDIR)/src/lcc
	cp -r $(LCC)/etc $(BUILDDIR)/src/lcc
	cp -r $(LCC)/cpp $(BUILDDIR)/src/lcc
	cp $(Z80)/lcc/makefile $(BUILDDIR)/src/lcc
	cp -r $(Z80)/lcc/lburg/* $(BUILDDIR)/src/lcc/lburg
	cp -r $(Z80)/lcc/src/* $(BUILDDIR)/src/lcc/src
	cp -r $(Z80)/lcc/etc/* $(BUILDDIR)/src/lcc/etc
	$(MAKE) -C $(BUILDDIR)/src/lcc CC=$(HOSTCC) LD=$(HOSTLD) CFLAGS="$(HOSTCFLAGS)" LDFLAGS="$(HOSTLDFLAGS)" lburg
	$(MAKE) -C $(BUILDDIR)/src/lcc LCCDIR=$(LCCDIR) rcc lcc cpp

dosify:
ifeq ($(TARGETOS), dos)
	for i in $(DIST)/* $(DIST)/doc/* $(DIST)/include/* $(DIST)/lib/* $(DIST)/examples/* $(DIST)/examples/*/*; \
	 do ( \
	  if [ -f $$i ] && [ `expr $$i : '.*\.\(.*\)' \| $$i` != "gbr" ] && [ `expr $$i : '.*\.\(.*\)' \| $$i` != "pdf" ]; then \
	   unix2dos $$i $$i; \
	  fi ); \
	 done
endif

# Prepare (precompile) any required files for distribution
dist-makefile:
	cp Makefile.head $(DIST)/lib/Makefile
	cd $(DIST)/lib; \
	for i in *.ms ; do echo "  " `basename $$i .ms`.s " \\" >> $(DIST)/lib/Makefile; done
	cat Makefile.mid >> $(DIST)/lib/Makefile
	cd $(DIST)/lib; \
	for i in *.ms ; do echo "  " `basename $$i .ms`.o " \\" >> $(DIST)/lib/Makefile; done
	cd $(DIST)/lib; \
	for i in *.s ; do echo "  " `basename $$i .s`.o " \\" >> $(DIST)/lib/Makefile; done
	cd $(DIST)/lib; \
	for i in *.c ; do echo "  " `basename $$i .c`.o " \\" >> $(DIST)/lib/Makefile; done
	cat Makefile.tail >> $(DIST)/lib/Makefile

prep-dist:
	$(MAKE) -C $(DIST)/lib prep-dist

makedirs:
	rm -rf $(DIST)
	mkdir -p $(DIST)/bin
	mkdir -p $(DIST)/doc
	mkdir -p $(DIST)/include
	mkdir -p $(DIST)/lib
	mkdir -p $(DIST)/examples

copyfiles:
	cp -rf include $(DIST)
	cp -rf doc-$(PLATFORM)/* $(DIST)/doc
	cp -rf doc/* $(DIST)/doc
	cp -rf lib/* $(DIST)/lib
	cp -rf lib/platform/$(PLATFORM)/* $(DIST)/lib
	cp -rf lib/processor/$(PROCESSOR)/* $(DIST)/lib
	cp -rf lib-gb/Makefile $(DIST)/lib
	cp -rf examples-$(PLATFORM)/* $(DIST)/examples
ifeq ($(TARGETOS), dos)
	cp gbdk.bat $(DIST)
	troff -man -a $(LCC)/doc/lcc.1 > $(DIST)/doc/lcc.doc
else
	cp $(LCC)/doc/lcc.1 $(DIST)/doc
endif
	chmod -R a+r $(DIST)

zdist:	dist
	rm -f $(ARCHIVE)
ifeq ($(TARGETOS), dos)
	cd $(DISTROOT); \
	zip -r $(ARCHIVE) *
else
	cd $(DISTROOT); \
	tar cf $(ARCHIVE) *
	gzip $(ARCHIVE)
endif

dist:	makedirs copyfiles dist-makefile prep-dist dosify
	rm -rf bin.zip
	cp $(BUILDDIR)/lcc$E $(DIST)/bin
	cp $(BUILDDIR)/rcc$E $(DIST)/bin
	cp $(BUILDDIR)/cpp$E $(DIST)/bin
	cp as/as$E           $(DIST)/bin
	cp link/link$E       $(DIST)/bin
	cp maccer/maccer$E   $(DIST)/bin
	rm -rf `find "dist" -name CVS`
	rm -rf `find "dist" \( -name \*\~ -o -name \*\# -o -name \*\% \) -print`

clean:
	for i in $(SUBDIRS); do $(MAKE) -C $$i clean; done
	rm -f `find . -name "*~"`
	$(MAKE) -C lib-$(PLATFORM) clean
	rm -rf $(BUILDDIR)
	rm -rf $(DIST)
	rm -f $(TOPDIR)/.target

install: dist
ifeq ($(TARGETOS), dos)
	@echo "Panic: dont know how to install on a DOS system"
else
	mkdir -p $(DESTDIR)
	cd $(DIST); tar cf - . | (cd $(DESTDIR); tar xf - )
endif
