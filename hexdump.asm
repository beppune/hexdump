
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
		;+ (1 + off) * 3      -> pointer to the bytes's Least Significant Nibble (LSN)
		;+ (1 + off) * 3 - 1  -> pointer to the bytes's Most Significant Nibble (MSN)

		;                         1  1  1  2  2  2  3  3  3  3  4  4  4
		;                3  6  9  2  5  8  1  4  7  0  3  6  9  2  5  8
        FormatStr: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ", 0Ah
		FormatLen: equ $-FormatStr
		; the position of the '\n' for each Buffer read is (1 + last_index) * 3 + 1
		;+ after every write such position must be 'cleared' alas set to ' ' (ASCII 020h)

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
		
Setup:  mov edi, FormatStr  ; save FormatStr base pointer
        mov esi, HexStr     ; save HexStr base pointer
        mov edx, eax        ; save # read bytes
        mov ecx, eax        ; save eax for pointer to Buffer
        
Scan:   xor eax, eax            ; zero eax
        xor ebx, ebx            ; zero ebx
        dec ecx                 ; decrement index Buffer
                                ;+  first dec will make it pint to the last read byte

        ; ecx contains the current Buffer offset

        ; save the current value ([Buffer + ecx])
        mov bl, [Buffer + ecx]          ; copy [Buffer + ecx] in al

        ; Get the LSN and put the matching Hex value into FormatStr
        and bl, 0Fh                     ; mask the LSN
        mov bl, [HexStr + ebx]          ; get the matching Hex value
        ; now bl/ebx contains the character

        ; compute the LSN destination [(1 + offset) * 3. See comment at FormatStr
        mov edi, ecx                    ; copy the offset in edi
        inc edi                         ; increment offset by one (1 + offset)
        mov eax, edi                    ; save the factor in eax
        shl edi, 1                      ; shift 1 right to multiply by 2
        add edi, eax                    ; add factor to multiply by 3

        mov [FormatStr + edi], bl       ; copy the character to the computed position

        ; Get the LSN and put the matching Hex value into FormatStr
        mov bl, [Buffer + ecx]          ; copy current pointer Buffer value
        shr bl, 04h                     ; shift to get the MSN
        mov bl, [HexStr + ebx]           ; get the matching Hex value

        ; compute the MSN destination [(1 + offset) * 3 - 1]. See comment at FormatStr
        dec edi                         ; decrement edi
        mov [FormatStr + edi], bl       ; copy the character to the computed position

        jecxz Write             	; if ecx is 0 we scanned the last pointer and it's time to write
        jmp Scan                	;+  else next iteration of Scan
        
Write:  mov byte [FormatStr + edx], 0Ah    ; append '\n' to Buffer
        inc edx                         ; increment # bytes to include '\n'
        mov eax, 4                      ; sys_write
        mov ebx, 1                      ; write to stdout
        ;mov edx,edx                    ; write Buffer + '\n'
        int 80h                         ; kernel
        
        mov byte [Buffer + edx], 020h   ; clear with space in FormatStr

        jmp Read                        ; next read

Exit:
	mov		eax, 01h		; exit()
	xor		ebx, ebx		; errno
	int		80h

