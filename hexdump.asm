
;	Program:	Hexdump
;	Author:		Giuseppe Manzo
;	Updated:	2023-09-23
;
;	compile with:
;		nasm  -f elf32 -g  -o hexdump.o hexdump.asm
;		ld  -m  elf_i386  -o hexdump hexdump.o
;

global _start

section .data
        HexStr: db "0123456789ABCDEF"
		Len:	equ 16


		; given a Buffer offset 'off' ( [Buffer + off] ):
		;+ (off + 3) * 3      -> pointer to the bytes's Least Significant Nibble (LSN)
		;+ (off + 3) * 3 - 1  -> pointer to the bytes's Most Significant Nibble (MSN)

		;                          1  1  1  2  2  2  3  3  3  3  4  4  4
		;                 3  6  9  2  5  8  1  4  7  0  3  6  9  2  5  8
        FormatStr: db "  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ", 0Ah
		FormatLen: equ $-FormatStr
		; the position of the '\n' for each Buffer read is (1 + last_index) * 3 + 1
		;+ after every write such position must be 'cleared' alas set to ' ' (ASCII 020h)

section .bss
		Buffer:	resb	Len

section .text

_start:
	nop

Read:	mov eax, 3			; sys_read
		mov ebx, 0			; read from stdin
		mov	ecx, Buffer		; read into Buffer
		mov edx, Len		; read at most Len bytes
		int 80h				; kernel
		
		cmp eax, 0			; compare sys_read return with 0
		jz Exit				;+	if 0 (EOF) exit program
		
		cmp eax, 0			; compare sys_read return with 0
		jb Exit				;+	if below 0 exit program 


Setup:  mov esi, eax            ; save # bytes read
        mov ecx, eax

Scan:   dec ecx                 ;+ out of # bytes read            ;
        xor eax, eax
        xor ebx, ebx
        xor edi, edi

        ; FormatStr of LSN
        mov edi, ecx
        shl edi, 1
        add edi, ecx

        mov al, [Buffer, ecx]

        mov bl, al
        and bl, 0Fh

        mov bl, [HexStr + ebx]
        mov [FormatStr + edi], bl

        ; MSB
        dec edi
        shr al, 4
        mov bl, [HexStr + eax]
        mov [FormatStr + edi], bl

        jecxz Write


Write:  inc edi
        inc edi
        mov byte [FormatStr + edi], 0Ah
        inc edi
        mov eax, 4
        mov ebx, 1
        mov ecx, FormatStr
        mov edx, edi
        int 80h

        dec edi
        mov byte [FormatStr + edi], 020h

        ;jecxz Write

Exit:
	mov		eax, 01h		; exit()
	xor		ebx, ebx		; errno
	int		80h






