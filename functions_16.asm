; Various sub-routines that will be useful to the boot loader code	

; Output Carriage-Return/Line-Feed (CRLF) sequence to screen using BIOS

Console_Write_CRLF:
	mov 	ah, 0Eh						; Output CR
    mov 	al, 0Dh
    int 	10h
    mov 	al, 0Ah						; Output LF
    int 	10h
    ret

; Write to the console using BIOS.
; 
; Input: SI points to a null-terminated string

Console_Write_16:
	mov 	ah, 0Eh						; BIOS call to output value in AL to screen

Console_Write_16_Repeat:
	lodsb								; Load byte at SI into AL and increment SI
    test 	al, al						; If the byte is 0, we are done
	je 		Console_Write_16_Done
	int 	10h							; Output character to screen
	jmp 	Console_Write_16_Repeat

Console_Write_16_Done:
    ret

; Write string to the console using BIOS followed by CRLF
; 
; Input: SI points to a null-terminated string

Console_WriteLine_16:
	call 	Console_Write_16
	call 	Console_Write_CRLF
	ret
	
; Output the value within bx as an unsigned integer value
;
; Input: BX points to the unsigned value to be displayed

Console_Write_Integer:
	mov		si, IntBuffer + 4	; SI points to the location in memory we will store digits
	mov		ax, bx				; Move the value to be stored into the AX register, as this is what operations are performed on
GetDigit:
	xor		dx, dx				; Clear dx register
	mov		cx, 10				; We will be dividing by 10, so store it in the cx register
	div 	cx					; Divide by cx register (10)
	add		dl, 48				; Add to the remained 48 (so we can get the ascii character)
	mov		[si], dl			; Move to the location mentioned in SI the value within dl
	dec		si					; Go to one value lower in memory, to store the next most significant bit
	cmp		ax, 0				; If we have no more bits to divide then move on
	jne		GetDigit
	inc		si					; Go back up a bit in SI since we would be 1 lower than the actual start otherwise
	call 	Console_Write_16
	ret

IntBuffer	db '     ', 0
	
; Write a the value within bx as 4 hex values
;
; Input: BX points to the value to be displayed

Console_Write_Hex:
	push	cx
	push	ax
	push	si
	push	bx
	
	mov		cx, 4		; 4 Hex values to be output - counter
HexLoop:
	rol		bx, 4		; Rotate the register right (values pushed out and put onto the left)
	mov		si, bx		; Place the value we are editing into si
	and		si,	000fh	; Run mask to get least significant hex
	mov		al, byte[si + HexChars]		; Get the ascii char that represents this hex
	mov		ah, 0Eh		; Bios call to output the value in AL to the screen
	int		10h			; Interupt
	dec		cx			; Decrease the value in cx by 1
	jnz		HexLoop		; If not Zero, jump back to the start of the loop
	
	pop		bx
	pop		si
	pop		ax
	pop		cx
	
	ret
	
HexChars	db '0123456789ABCDEF', 0