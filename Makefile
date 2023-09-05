
hexdump:	hexdump.o
	ld  -m  elf_i386  -o hexdump hexdump.o

hexdump.o:	hexdump.asm
	nasm  -f elf32 -g  -o hexdump.o hexdump.asm

clean:
	rm hexdump hexdump.o


