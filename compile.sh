./vasmm68k-mot -Felf -spaces -no-opt -o hello.o hello.asm
./m68k-elf-ld --entry=start -o hello -T hello.ld hello.o
# ./vasmm68k-mot -m68000 -Fbin -spaces -no-opt -nocase -o program program.asm
