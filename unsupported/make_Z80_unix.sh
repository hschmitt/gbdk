#! /bin/csh -v

#setenv Z80DK $HOME/Z80DK-2.0/
setenv Z80DK /tmp/Z80DK-2.0/

setenv ROOT $PWD
setenv LCC_DIR $ROOT/lcc
setenv Z80_DIR $ROOT/z80
setenv Z80_SRC $Z80_DIR/src
setenv Z80_ETC $Z80_DIR/etc
setenv ASM_DIR $ROOT/as
setenv LNK_DIR $ROOT/link

setenv BLD_DIR /tmp/unix

mkdir -p $Z80DK/bin
mkdir -p $Z80DK/include
mkdir -p $Z80DK/lib
mkdir -p $Z80DK/doc
mkdir -p $Z80DK/man/man1
mkdir -p $Z80DK/examples
cp -rf $ROOT/include-z80/* $Z80DK/include
cp -rf $ROOT/lib-z80/* $Z80DK/lib
cp -rf $ROOT/doc-z80/* $Z80DK/doc
cp -rf $LCC_DIR/doc/lcc.1 $Z80DK/man/man1
cp -rf $ROOT/examples-z80/* $Z80DK/examples

rm -rf $BLD_DIR
mkdir -p $BLD_DIR

cd $LCC_DIR
make -f $Z80_SRC/makefile CC=cc LD=cc CFLAGS='-g -DUNIX -DSDK -DLCCDIR=\"$(Z80DK)\" -I$(Z80_SRC)' Z80_SRC=$Z80_SRC BUILDDIR=$BLD_DIR HOSTFILE=$Z80_ETC/z80-unix.c rcc cpp lcc
mv $BLD_DIR/rcc $Z80DK/bin
mv $BLD_DIR/cpp $Z80DK/bin
mv $BLD_DIR/lcc $Z80DK/bin

cd $BLD_DIR
make -f $ASM_DIR/Makefile CC=gcc LD=gcc CFLAGS='-funsigned-char -DUNIX -DSDK' SRC=$ASM_DIR
mv $BLD_DIR/as $Z80DK/bin
make -f $LNK_DIR/Makefile CC=gcc LD=gcc CFLAGS='-funsigned-char -DUNIX -DSDK' SRC=$LNK_DIR
mv $BLD_DIR/link $Z80DK/bin
