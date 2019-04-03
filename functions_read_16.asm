;%include "functions_16.asm" 				; These are already included in the program before this file

; Reads a decimal unsigned integer value (16 bits, i.e 65,535 max)
;
; Output: BX, the constructed integer value
; Output: DX, has a value of 1 if there was a problem
Console_Read_Integer:
	mov		cx, 10							; We will be multiplying by 10
	xor		dx, dx
	xor		bx, bx
Console_Read_Integer_Loop:
	xor		ah, ah							; AH = 0, instruct we are reading a character
	int 	16h								; Interupt for reading a character, AH contains scan_code. AL contains ASCII value
	
	cmp 	ah, 1Ch							; Check if the pressed key was enter, move to checking the integer for being valid
	je		Finish_Integer
	
	mov 	ah, 0Eh							; Print the entered character on the screen
	int 	10h
	
	cmp		al, 30h							; Check the ASCII value of entered character is equal or above '0'
	jb		Print_ReadInt_Error
	cmp 	al, 39h							; Check the ASCII value of entered character is equal or below '9'
	ja		Print_ReadInt_Error

	push	ax								; Store the current AX register (the entered number) since we need to this register for mul
	mov		ax, bx
	mul		cx								; Multiply the current total value by 10 (move everything to the left, so 10s become 100s - next value will always be single)
	mov		bx, ax
	pop		ax								; Restore the entered number from the stack
	
	sub		al, 30h							; Subtract 30hex to convert from ASCII
	add		bl, al							; Add the integer entered to the BL (BX) register
	
	jmp 	Console_Read_Integer_Loop		; Loop to get the next character
Finish_Integer:								
	call	Console_Write_CRLF
	ret
Print_ReadInt_Error:
	mov		dx, 1
	call	Console_Write_CRLF	
	mov		si, read_int_error				; Prints a message saying that the entered value is invalid
	jmp		Console_WriteLine_16			; WriteLine will return us to the correct place, no need for ret

read_int_error	db 'ERROR: Please Enter a Decimal Integer using Digits Between 0 and 9 Only!', 0

; Displays the contents of a sector to the console
;
; Input: Requested from the user
Console_Read_Sector:
	mov		si, msg_request_initial_sector	; Display message
	call	Console_Write_16
	call	Console_Read_Integer			; Get value (returned in bx)
	
	cmp		dx, 1							; If DX if 1, there was a problem getting the integer
	je		Console_Read_Sector
	
	cmp		bx, word [bpbTotalSectors]		; Dont accept values above the total amount of sectors
	jge		Console_Read_Sector				; Let the user try again
	
	mov		[starting_sector_no], bx
Request_Amount:
	mov		si, msg_request_amount_sector	; Display message
	call	Console_Write_16
	call	Console_Read_Integer			; Get value (returned in bx)
	
	cmp		dx, 1							; If DX if 1, there was a problem getting the integer
	je		Request_Amount
	
	cmp		bx, 23							; Further work needs to be done to allow loading more than 23 sectors at a time
	ja		Request_Amount
	
	mov		cx, bx							; CX will be used for amount of sectors to read (done first as we need to check we dont try reading beyond max sectors)
	push	cx								; Store total amount of sectors temporarily
	
	mov		ax, [starting_sector_no]		; Retrieve the starting sector number and place it into AX
	
	add		bx, ax							; Find the last sector we will manipulate
	sub		bx, 1							; Subtract 1 since 2880 and reading 1 sector would make us think 2881 is the last sector. When 2880 is the last
	cmp		bx, word[bpbTotalSectors]		; Ensure it is below/equal to total sectors
	ja		Request_Amount
		
; Responsible for actually displaying the sector in the console							
	%define ACTIVE_SECTOR	0D00h

	push	word ACTIVE_SECTOR
	pop		es
	xor		bx, bx							; Set es:bx to 0D00:0
	call	ReadSectors

	push	word ACTIVE_SECTOR				; Reset es:bx
	pop		es
	xor		bx, bx							; Set es:bx to 0D00:0
	
	pop		cx								; Restore the total amount of sectors to read	
Display_Sector:
	push	cx								; Store the total amount of sectors
	mov		cx, 2							; We split a Sector of 32 lines into two sets of 16	
Display_16Lines:
	push	cx								; Push the amount of times left to display 16 lines
	mov		ah, 0Eh							; We want 10h to display characters
	mov		cx, 16							; The amount of lines to display before displaying an equal amount after that
Display_Line:
	push	es								; Store the position of the start of the line
	push	bx								; We need to come back here to display in ASCII
	
	push	cx
	mov		cx, 16							; We display 32 hex, in groups of 2 for readability. So do this 16 times
;Display_Offset
	call	Console_Write_Hex				; Display the offset contained in bx
	mov		al, ' '							; Seperating character
	int		10h
Display_HexPair:
	push	cx								; Store the amount of lines to display again
	
	mov		cx, 2
Display_HexVal:
	xor		si, si							; Write the value at es:bx (well the byte from that position) as a hex value
	xor		dx, dx
	mov		dl, byte[es:bx]
	
	mov		al, dl							; Output first part of the character
	rol		al, 4
	mov		si, ax
	and		si, 000fh
	mov		al, byte[si + hex_chars]
	int		10h	
	
	mov		al, dl							; Output the second part of the character
	mov		si, ax
	and		si, 000fh
	mov		al, byte[si + hex_chars]
	int		10h	
	
	add		bx, 0001h						; Add to the offset we are reading from, so we move to the next byte
;EndOfHexVal
	mov		al, ' '							; Seperating character
	int		10h
	
	pop		cx								; Restore the amount of hex to display
	dec		cx
	jnz		Display_HexPair
;EndOfHexPair
	mov		al, ' '							; Seperating character
	int		10h
;Display ASCII of this line
	pop		cx								; Restore the amount of lines to display
	
	pop		bx								; Restore the start of the line position
	pop		es
	
	push	cx								; Store the amount of lines again, (we just needed to skip this for now)
	push	es								; Store es:bx again, we will want to have the line start position once more
	push	bx
	
	mov		cx, 16							; 32 hex, i.e. 16 ascii characters
Display_Character:
	mov		al, byte [es:bx]
	cmp		al, 19h
	ja		Display_Character_Final
	mov		al, '_'							; If the ASCII values is less than 20h, we replace it with _
Display_Character_Final:
	int		10h
	add		bx, 0001h						; Add to the offset we are reading from, so we move to the next character
	dec		cx
	jnz		Display_Character
;EndOfDisplayASCII of this line

	call	Console_Write_CRLF				; End the line
	
	pop		bx								; Return to the line start position again
	pop		es
	add		bx, 0010h						; Offset BX
	
	pop		cx								; Restore the amount of lines
	dec		cx								; This compares the amount of lines remaining
	jnz		Display_Line
;EndOfLine
	
;Continue?
	pop		cx								; Get the amount of 16 lines we have left to print
	
	mov		si, press_to_cont				; Display continue message and await input
	call	Console_WriteLine_16
	xor		ax,ax
	int		16h
	
	dec		cx
	jnz		Display_16Lines
	call	Console_Write_CRLF

; Continue if more sectors are queued to be read
	pop		cx								; Get the remaining amount of sectors to be read
	dec		cx
	jnz		Display_Sector
		
; This is the end of displaying the sector to the console
	
Request_Another:
	mov		si, msg_request_another			; Display message
	call	Console_Write_16
	
	xor		ah, ah							; Get user input
	int 	16h
	
	cmp		ah, 15h							; If Y entered (use scan code as Y != y)
	je		Console_Read_Sector				; Repeat method
	
	cmp		ah, 31h							; If N not entered (i.e. anything but N or Y)
	jne		Request_Another					; Request an answer again
	call	Console_Write_CRLF
	ret										; If it was N, we are done
	
msg_request_initial_sector	db 'Starting Sector (<2880): ', 0
msg_request_amount_sector	db 'Amount of Sectors to Read (<24): ', 0
msg_request_another			db 'Would You Like to Read Another Sector (Y/N)? ',13,10,0			; 13,10 is CRLF (saves us calling the method)
press_to_cont				db 'Press any key to continue...', 0

hex_chars					db '0123456789ABCDEF', 0
starting_sector_no			db 0