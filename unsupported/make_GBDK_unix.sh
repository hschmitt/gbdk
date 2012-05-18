#! /bin/csh -v

#setenv GBDK $HOME/GBDK-2.0/
setenv GBDK /tmp/GBDK-2.0/

setenv ROOT $PWD
setenv LCC_DIR $ROOT/lcc
setenv Z80_DIR $ROOT/z80
setenv Z80_SRC $Z80_DIR/src
setenv Z80_ETC $Z80_DIR/etc
setenv ASM_DIR $ROOT/as
setenv LNK_DIR $ROOT/link

setenv BLD_DIR /tmp/unix

mkdir -p $GBDK/bin
mkdir -p $GBDK/include
mkdir -p $GBDK/lib
mkdir -p $GBDK/doc
mkdir -p $GBDK/man/man1
mkdir -p $GBDK/examples
cp -rf $ROOT/include-gb/* $GBDK/include
cp -rf $ROOT/lib-gb/* $GBDK/lib
cp -rf $ROOT/doc-gb/* $GBDK/doc
cp -rf $LCC_DIR/doc/lcc.1 $GBDK/man/man1
cp -rf $ROOT/examples-gb/* $GBDK/examples

rm -rf $BLD_DIR
mkdir -p $BLD_DIR

cd $LCC_DIR
make -f $Z80_SRC/makefile CC=cc LD=cc CFLAGS='-g -DUNIX -DSDK -DGAMEBOY -DLCCDIR=\"$(GBDK)\" -I$(Z80_SRC)' Z80_SRC=$Z80_SRC BUILDDIR=$BLD_DIR HOSTFILE=$Z80_ETC/gb-unix.c rcc cpp lcc
mv $BLD_DIR/rcc $GBDK/bin
mv $BLD_DIR/cpp $GBDK/bin
mv $BLD_DIR/lcc $GBDK/bin

cd $BLD_DIR
make -f $ASM_DIR/Makefile CC=gcc LD=gcc CFLAGS='-funsigned-char -DUNIX -DSDK -DGAMEBOY' SRC=$ASM_DIR
mv $BLD_DIR/as $GBDK/bin
make -f $LNK_DIR/Makefile CC=gcc LD=gcc CFLAGS='-funsigned-char -DUNIX -DSDK -DGAMEBOY' SRC=$LNK_DIR
mv $BLD_DIR/link $GBDK/bin
