	.global generate4
generate4:
	@ Setup:
		push 	{R1-R12}	        @ Save contents of registers through R0 - R7
		mov		R2,#4		@ Length of the binary data word is 4 bits long (i.e. R2 = R0.length())

	@ Defining the max size of a binary number for this program:
		mov		R3,R0	        @ R3 will hold a copy of input word to be displayed
		mov		R6,#3
	
	@ More preparation for the findDataBits loop:
		mov		R4,#0	        @ Used to mask off 1 bit at a time for display
		mov		R2,#1	        @ Number of characters to be displayed at a time (1 binary digit/character at a time)
		mov		R8,#3		@ R8 is a counter integer to determine which data-word bit to calculate

@ Subroutine to find the 4 original data-bits D0-D3
@ --------------------------------------------------------------------------------------------------------------------------------------------
findDataBits: 
		and		R1,R2,R3, lsr R6 @ (R1 = R2 and R3(lsr by R6)) - selects either "0" or "1"  to  be  displayed
		subs		R6,#1		 @ Decrement number of bits remaining to display for each loop
		cmp		R8,#3			
		beq 		tx3bit		@ If (R1 == 3) --> go to tx3bit...
		cmp		R8,#2			
		beq 		tx2bit		@ Else If (R1 == 2) --> go to tx2bit...
		cmp		R8,#1			
		beq		tx1bit		@ Else If (R1 == 1) --> go to tx1bit...
		cmp		R8,#0			
		beq		tx0bit		@ Else If (R1 == 0) --> go to tx0bit...

@ Find the 4-bits from the data word, and then put them into registers R9-R12:
@	R9   = Data-bit D0 --> tx0bit
@	R10 = Data-bit D1 --> tx1bit
@	R11 = Data-bit D2 --> tx2bit
@ 	R12 = Data-bit D3 --> tx3bit
@ --------------------------------------------------------------------------------------------------------------------------------------------
tx3bit:	mov		R12,R1		@ Store bit D3 in R12
		sub		R8,#1		@ Increment R10 by 1 (R1=3)
		b		findDataBits	@ Go back to loop and find more data-bits

tx2bit:	mov		R11,R1		@ Store bit D2 in R11
		sub		R8,#1		@ Increment R10 by 1 (R1=3)
		b		findDataBits	@ Go back to loop and find more data-bits

tx1bit:	mov		R10,R1		@ Store bit D1 in R10
		sub		R8,#1		@ Increment R10 by 1 (R1=2)
		b		findDataBits	@ Go back to loop and find more data-bits

tx0bit:	mov		R9,R1		@ Store bit D0 in R9
		b		tx4bit		@ Go find the check-bits now that all data-bits are found

@ Compute the 3 check-bits, and then put them into registers R6-R8:
@	R6 = Check-bit (D2^D3)^D0 --> tx4bit
@	R7 = Check-bit (D2^D3)^D1 --> tx5bit
@	R8 = Check-bit (D1^D3)^D0 --> tx6bit
@ --------------------------------------------------------------------------------------------------------------------------------------------
tx4bit:	eor		R6,R11,R12	@ Store first xor gate calculation in R6
		eor		R6,R6,R9		@ Store second xor gate calculation in R6
		
tx5bit:	eor		R7,R11,R12	@ Store first xor gate calculation in R6
		eor		R7,R7,R10	@ Store second xor gate calculation in R6
		
txt6bit:	eor		R8,R10,R12	@ Store first xor gate calculation in R6
		eor		R8,R8,R9		@ Store second xor gate calculation in R6
		
		lsl		R8,#6		@ Get the tx6 bit by left shifting R8 6 times
		lsl		R7,#5		@ Get the tx5 bit by left shifting R7 5 times
		lsl		R6,#4		@ Get the tx4 bit by left shifting R6 4 times
		add		R6,R7		@ Add the check-bits together: (R6 = R6 + R7)
		add		R6,R8		@ Add the check-bits together: (R6 = R6 + R8)
		add		R0,R6,R3		@ Add the original data-bits and the check-bits together: (R0 = R6 + R3)
		
		pop		{R1-R12}		@ Restore saved register contents
		bx		LR
