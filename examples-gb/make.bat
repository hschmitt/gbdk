..\bin\lcc -Wa-l -Wl-m -o space.gb space.s

..\bin\lcc -Wa-l -Wl-m -o galaxy.gb galaxy.c

..\bin\lcc -Wa-l -Wl-m -o paint.gb paint.c

..\bin\lcc -Wa-l -Wl-m -o rand.gb rand.c

..\bin\lcc -Wa-l -Wl-m -o rpn.gb rpn.c

..\bin\lcc -Wa-l -Wl-m -o sound.gb sound.c

..\bin\lcc -Wa-l -Wl-m -o comm.gb comm.c

..\bin\lcc -Wa-l -Wl-m -o filltest.gb filltest.c

..\bin\lcc -Wa-l -Wl-m -o samptest.gb samptest.c

..\bin\lcc -Wa-l -Wl-m -o fonts.gb fonts.c

..\bin\lcc -Wa-l -c -o banks.o banks.c
..\bin\lcc -Wa-l -Wf-ba0 -c -o bank_0.o bank_0.c
..\bin\lcc -Wa-l -Wf-bo1 -Wf-ba1 -c -o bank_1.o bank_1.c
..\bin\lcc -Wa-l -Wf-bo2 -Wf-ba2 -c -o bank_2.o bank_2.c
..\bin\lcc -Wa-l -Wf-bo3 -Wf-ba3 -c -o bank_3.o bank_3.c
..\bin\lcc -Wl-m -Wl-yt2 -Wl-yo4 -Wl-ya4 -o banks.gb banks.o bank_0.o bank_1.o bank_2.o bank_3.o

..\bin\lcc -Wa-l -c -o ram_fn.o ram_fn.c
..\bin\lcc -Wl-m -Wl-g_inc_ram=0xD000 -Wl-g_inc_hiram=0xFFA0 -o ram_fn.gb ram_fn.o
