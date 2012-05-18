#! /bin/csh -v

setenv GBDK \\\\\\\\GBDK-2.0\\\\\\\\
setenv TMP_DIR \\\\\\\\TEMP
#setenv DOS $HOME/GBDK-dos/GBDK-2.0
setenv DOS /tmp/GBDK-dos/GBDK-2.0

setenv ROOT $PWD
setenv LCC_DIR $ROOT/lcc
setenv Z80_DIR $ROOT/z80
setenv Z80_SRC $Z80_DIR/src
setenv Z80_ETC $Z80_DIR/etc
setenv ASM_DIR $ROOT/as
setenv LNK_DIR $ROOT/link

setenv BLD_DIR /tmp/dos

mkdir -p $DOS/bin
mkdir -p $DOS/include
mkdir -p $DOS/lib
mkdir -p $DOS/doc
mkdir -p $DOS/examples
cp -rf $ROOT/include-gb/* $DOS/include
cp -rf $ROOT/lib-gb/* $DOS/lib
cp -rf $ROOT/doc-gb/* $DOS/doc
cp -rf $ROOT/examples-gb/* $DOS/examples
troff -man -a $LCC_DIR/doc/lcc.1 > $DOS/doc/lcc.doc
foreach i ($DOS/doc/* $DOS/include/* $DOS/lib/* $DOS/examples/* $DOS/examples/*/*)
	if (-f $i && $i:e != "gbr") then
		echo $i
		unix2dos $i $i
	endif
end

rm -rf $BLD_DIR
mkdir -p $BLD_DIR

cd $LCC_DIR
make -f $Z80_SRC/makefile CC=cc LD=cc Z80_SRC=$Z80_SRC BUILDDIR=$BLD_DIR lburg
make -f $Z80_SRC/makefile CC=gcc-dos LD=gcc-dos CFLAGS='-DDOS -DSDK -DGAMEBOY -DWIN32 -D_P_WAIT=P_WAIT -D_spawnvp=spawnvp -DLCCDIR=\"$(GBDK)\" -I$(Z80_SRC)' TEMPDIR=$TMP_DIR Z80_SRC=$Z80_SRC BUILDDIR=$BLD_DIR HOSTFILE=$Z80_ETC/gb-dos.c rcc cpp lcc
mv $BLD_DIR/rcc.exe $DOS/bin
mv $BLD_DIR/cpp.exe $DOS/bin
mv $BLD_DIR/lcc.exe $DOS/bin

cd $BLD_DIR
make -f $ASM_DIR/Makefile CC=gcc-dos LD=gcc-dos CFLAGS='-funsigned-char -DDOS -DSDK -DGAMEBOY' SRC=$ASM_DIR
mv $BLD_DIR/as.exe $DOS/bin
make -f $LNK_DIR/Makefile CC=gcc-dos LD=gcc-dos CFLAGS='-funsigned-char -DDOS -DSDK -DGAMEBOY' SRC=$LNK_DIR
mv $BLD_DIR/link.exe $DOS/bin
