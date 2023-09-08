
;	Program:	Hexdump
;	Author:		Giuseppe Manzo
;	Updated:	2023-09-08
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
		;+ (off * 3) + 3      -> pointer to the bytes's Least Significant Nibble (LSN)
		;+ (off * 3) + 3 - 1  -> pointer to the bytes's Most Significant Nibble (MSN)

		;                          1  1  1  2  2  2  3  3  3  3  4  4  4
		;                 3  6  9  2  5  8  1  4  7  0  3  6  9  2  5  8
        FormatStr: db "  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
		; the position of the '\n' for each Buffer read is (1 + last_index) * 3 + 1
		;+ after every write such position must be 'cleared' alas set to ' ' (ASCII 020h)

section .bss
		Buffer:	resb	Len      ; reserve Len bytes for read

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

		; In the Setup keep # bytes read in two places:
		;+ one for thee Scan loop and one for the Write
Setup:  mov esi, eax            ; mov eax in esi
        mov ecx, eax            ; mov eax in ecx

        ; Every Scan loop is controlled by ecx counter
        ;+ which is decremented each iteration.
        ; eax is # bytes before the first loop
        ;+ so it must be decremented immediately
        ;+ in order to start as the last index of
        ;+ Buffer (off by one rule)
        ;+ terminate with 0
Scan:   dec ecx                 ; decrement ecx
        xor eax, eax            ; zeroing eax
        xor ebx, ebx            ; zeroing ebx

        ; Buffer + ecx is always a position between the first
        ;+ byte read and the last byte read included
        mov al, byte [Buffer + ecx]     ; save the current byte

        ; Find the LSN char value
        mov bl, al                      ; copy al
        and bl, 0Fh                     ; mask to get the LSN
        mov bl, byte [HexStr + ebx]     ; copy the matching character from HexStr

        ; Find the target position in FormatStr for current LSN
        ;+ by the formula: (offset * 3) + 3. See above
        mov edx, ecx            ; save ecx
        shl edx, 1              ; shift left one to multiply by two
        add edx, ecx            ; add saved addend to multiply by three
        add edx, 3              ; add 3

        ; Now edx is (offset * 3) + 3
        ;+ so copy the character to position
        mov byte [FormatStr + edx], bl  ; copy bl to current FormatStr position

        ; Work the MSN char value
        mov bl, al                      ; copy the read byte in bl again
        shr bl, 4                       ; shift right by 4 to get the MSN
        mov bl, byte [HexStr + ebx]     ; copy the matching character from HexStr

        ; Find the target position in FormatStr for current MSN
        ;+ by decrementi (offset *3) + 3 by one. See above
        dec edx

        ; Now edx is (offset * 3) + 3 - 1
        ;+ so copy the character to position
        mov byte [FormatStr + edx], bl

        ; Check loop condition.
        ;+ In case ecx is 0 its time to write
        ;+ otherwise next loop iteration
        jecxz Write     ; jump to Write if ecx is 0
        jmp Scan        ; jump to Scan

        ; Write only the setted FormatStr plus a newline
        ;+ In order to know how many bytes to write
        ;+ take the saved # of bytes and compute again
        ;+ the (offset * 3) + 3 formula. This will print
        ;+ only the byex characters, so the final value must be
        ;+ incremented to include a newline character.
        ; However this could use some optimization since
        ;+ every line will be always the same length except
        ;+ for the last line which could be less than 16 bytes
        ;+ if the size of the input is 16 * n + m with m < 16
Write:  dec esi                 ; decrement esi (off by one rule)
        mov edx, esi            ; copy esi to edx ti save addend
        shl esi, 1              ; shift esi by one to multiply by two
        add esi, edx            ; add edx to multiply by three
        add esi, 3              ; add 3

        ; Now esi is the last index of FormatStr
        inc esi                                 ; increment esi to make space for a newline character
        mov byte [FormatStr + esi], 0Ah         ; put the newline in place

        inc esi                 ; increment esi to make it the length from the last index
        mov eax, 4              ; sys_write
        mov ebx, 1              ; write to stdout
        mov ecx, FormatStr      ; write from FormatStr
        mov edx, esi            ; write esi charachter
        int 80h                 ; kernel

        jmp Read                ; Next read

Exit:
	mov eax, 1     ; sys_exit
	mov ebx, 0     ; exit with status 0
	int	80h        ; kernel






