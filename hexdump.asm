
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

section .bss
		Buffer:	resb	Len

section .text

_start:
	nop

Read:		mov eax, 3			; sys_read
		mov ebx, 0			; read from stdin
		mov	ecx, Buffer		; read into Buffer
		mov edx, Len		; read at most Len bytes
		int 80h				; kernel
		
		cmp eax, 0			; compare sys_read return with 0
		jz Exit				;+	if 0 (EOF) exit program
		
		cmp eax, 0			; compare sys_read return with 0
		jb Exit				;+	if below 0 exit program 
		
Setup:  mov edi, Buffer     ; save Buffer base pointer
        mov esi, HexStr     ; save HexStr base pointer
        mov edx, eax        ; save # read bytes
        mov ecx, eax        ; save eax for pointer to Buffer
        
Scan:   xor eax, eax            ; zero eax
        xor ebx, ebx            ; zero ebx
        dec ecx                 ; decrement index Buffer
                                ;+  first dec will make it pint to the last read byte (# bytes - 1 = last index)
        
        ; byte [Buffer + ecx] contains a single byte to match with HexStr
        mov al,  [Buffer + ecx]		; mov in al the content of current Buffer pointer
        mov bl,  [HexStr + eax]    	; mov in ebx matching HexStr byte pointed by current pointer
        mov byte [Buffer + ecx], bl  	; mov the matching HexStr value to same poisition in Buffer
        
        jecxz Write             	; if ecx is 0 we scanned the last pointer and it's time to write
        jmp Scan                	;+  else next iteration of Scan
        
Write:  mov byte [Buffer + edx], 0Ah    ; append '\n' to Buffer
        inc edx                         ; increment # bytes to include '\n'
        mov eax, 4                      ; sys_write
        mov ebx, 1                      ; write to stdout
        ;mov edx,edx                    ; write Buffer + '\n'
        int 80h                         ; kernel
        
        jmp Read                        ; next read

Exit:
	mov		eax, 01h		; exit()
	xor		ebx, ebx		; errno
	int		80h

