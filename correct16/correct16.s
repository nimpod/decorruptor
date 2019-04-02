@ OVERVIEW OF REGISTERS USING---------------
@ R0   = original data-word
@ R1   = copy of R0
@ R2   = 1, the number of digits to be dealt with per loop
@ R3   = 21, the loop counter
@ R4   = row number
@ R5   = a single bit from the data-word 
@ R6   = a single bit from whichever bit-makser is being used
@ R7   = one of the bit-maskers
@ R8   = temp storage for the number of valid 1s that appears for a row
@ R9   = temp storage for the 21-bit bit masker pattern
@ R10 = temp storage for xoring the check-bits to find the corrupted bit
@ R11 = temp storage for different powers of 2
@ R12 = position of corrupted bit

	.global correct16
correct16:
		push	{R1-R12}		@ save contents of regsisters R0 through R12
	@ reset registers so they can be initialised safely
		mov		R1,#0
		mov		R2,#0
		mov		R3,#0
		mov		R4,#0
		mov		R5,#0
		mov		R6,#0
		mov		R7,#0
		mov		R8,#0
		mov		R9,#0
		mov		R10,#0
		mov		R11,#0
		mov		R12,#0
		
		mov		R1,R0		@ R1 will hold a copy of the 16-bit data word being stored in R0
		mov		R2,#1		@ the number of digits to be dealt with per loop
		mov		R4,#1		@ R4 represents row number
		
chooseRow:
		mov		R8,#0		@ reset the number that will represent the number of 1s in a row
		mov		R3,#21		@ reset loop counter to 21 for each row
		ldr		R9,=0b101010101010101010101
		cmp		R4,#1		@ Is it row1?
		moveq	R7,R9		@ if yes --> move bit masker for row1 into R7
		ldr		R9,=0b001100110011001100110
		cmp		R4,#2		@ Is it row2?
		moveq	R7,R9		@ if yes --> move bit masker for row2 into R7
		ldr		R9,=0b110000111100001111000
		cmp		R4,#3		@ Is it row2?
		moveq	R7,R9		@ if yes --> move bit masker for row3 into R7
		ldr		R9,=0b000000111111110000000
		cmp		R4,#4		@ Is it row2?
		moveq	R7,R9		@ if yes --> move bit masker for row4 into R7
		ldr		R9,=0b111111000000000000000
		cmp		R4,#5		@ Is it row2?
		moveq	R7,R9		@ if yes --> move bit masker for row5 into R7
		b		rowProcess	@ go and dothe row process for the chosen row

positionCheckBit:
		and		R8,#0b1		@ was the number even or odd? if(even) --> R8=0 : if(odd) --> R8=1
		cmp		R4,#1		@ if on row1
		beq		correctBit0	@ go and compare check-bit r1 with d0
		cmp		R4,#2		@ if on row2
		beq		correctBit1	@ go and compare check-bit r2 with d1
		cmp		R4,#3		@ if on row3
		beq		correctBit3	@ go and compare check-bit r3 with d3
		cmp		R4,#4		@ if on row4
		beq		correctBit7	@ go and compare check-bit r4 with d7 
		cmp		R4,#5		@ if on row5
		beq		correctBit15	@ go and compare check-bit r5 with d15
nextRow:	add		R4,#1		@ increment the representation of a row number
		cmp		R4,#6		@ are we on the final row?
		beq		correctCorruptedBit	@ if yes --> go and correct the corrupted bit
		b		chooseRow	@ if no --> choose the next row

rowProcess:
		sub		R3,#1				@ decrement the loop counter by 1
		cmp		R3,#0				@ Are there more bits to find?
		beq		positionCheckBit		@ if no --> go position the check-bit in the 21-bit data-word
		and		R5,R2,R1, lsr R3		@ select the next bit (from the left) of the data-word
		and		R6,R2,R7, lsr R3		@ select the next bit (from the left) of the bit masker currently in use
		cmp		R6,#1
		beq		countNumberOfOnes	@ if the bit selected from the bit masker is 1 (or x according the diagram), then countNumberOfOnes
		b		rowProcess			@ otherwise do not count the number, and go to next bit
		
countNumberOfOnes:
		adds		R8,R5				@ if rowprocess validated, then increment R5 by whatever R11 currently holds
		cmp		R3,#15				@ are we currently on a check-bit position?
		beq		changeNumberOfOnes	@ if yes --> change the number of ones in R8
		cmp		R3,#7				@ are we currently on a check-bit position?
		beq		changeNumberOfOnes	@ if yes --> change the number of ones in R8
		cmp		R3,#3				@ are we currently on a check-bit position?
		beq		changeNumberOfOnes	@ if yes --> change the number of ones in R8
		cmp		R3,#1				@ are we currently on a check-bit position?
		beq		changeNumberOfOnes	@ if yes --> change the number of ones in R8
		cmp		R3,#0				@ are we currently on a check-bit position?
		beq		changeNumberOfOnes	@ if yes --> change the number of ones in R8
		b		rowProcess			@ if no --> continue with the row process

changeNumberOfOnes:
		cmp		R5,#1					@ was the bit a 1?
		beq		decrementNumberOfOnes	@ if yes --> decrement the number of ones in R8
		b		rowProcess				@ if no --> continue with row process
		
decrementNumberOfOnes:
		subs		R8,R5		@ if the bit from the bit pattern was not an x, then take decrement R8 by whatever was found in the data-word
		b		rowProcess	@ go back to process the row

correctBit0:
		mov		R11,#1		@ the power of 2 that represents row1 --> 2^0 = 1
		mov		R9,R1		@ temporarily copy R1 into R9
		lsr		R9,#0		@ isolate the bit we are looking for
		and		R9,#0b1		@ mask R9 to get the bit
		eor		R10,R9,R8	@ if the two numbers (R9, R8) are the same, no change. If different, an error occured
		cmp		R10,#1		@ was there a difference
		beq		errorOccured	@ if yes --> an error occured
		b		nextRow		@ if no --> no errors, continue onto next row

correctBit1:
		mov		R11,#2		@ the power of 2 that represents row1 --> 2^1 = 2
		mov		R9,R1		@ temporarily copy R1 into R9
		lsr		R9,#1		@ isolate the bit we are looking for
		and		R9,#0b1		@ mask R9 to get the bit
		eor		R10,R9,R8	@ if the two numbers (R9, R8) are the same, no change. If different, an error occured
		cmp		R10,#1		@ was there a difference
		beq		errorOccured	@ if yes --> an error occured
		b		nextRow		@ if no --> no errors, continue onto next row

correctBit3:
		mov		R11,#4		@ the power of 2 that represents row1 --> 2^2 = 4
		mov		R9,R1		@ temporarily copy R1 into R9
		lsr		R9,#3		@ isolate the bit we are looking for
		and		R9,#0b1		@ mask R9 to get the bit
		eor		R10,R9,R8	@ if the two numbers (R9, R8) are the same, no change. If different, an error occured
		cmp		R10,#1		@ was there a difference
		beq		errorOccured	@ if yes --> an error occured
		b		nextRow		@ if no --> no errors, continue onto next row

correctBit7:
		mov		R11,#8		@ the power of 2 that represents row1 --> 2^3 = 8
		mov		R9,R1		@ temporarily copy R1 into R9
		lsr		R9,#7		@ isolate the bit we are looking for
		and		R9,#0b1		@ mask R9 to get the bit
		eor		R10,R9,R8	@ if the two numbers (R9, R8) are the same, no change. If different, an error occured
		cmp		R10,#1		@ was there a difference
		beq		errorOccured	@ if yes --> an error occured
		b		nextRow		@ if no --> no errors, continue onto next row

correctBit15:
		mov		R11,#16		@ the power of 2 that represents row1 --> 2^4 = 16
		mov		R9,R1		@ temporarily copy R1 into R9
		lsr		R9,#15		@ isolate the bit we are looking for
		and		R9,#0b1		@ mask R9 to get the bit
		eor		R10,R9,R8	@ if the two numbers (R9, R8) are the same, no change. If different, an error occured
		cmp		R10,#1		@ was there a difference
		beq		errorOccured	@ if yes --> an error occured
		b		nextRow		@ if no --> no errors, continue onto next row
		
errorOccured:
		add		R12,R11		@ count the power of 2 for the row that had an error
		b		nextRow
		
correctCorruptedBit:
		@ reset registers R3-R11
		mov		R3,#0
		mov		R4,#0
		mov		R5,#0
		mov		R6,#0
		mov		R7,#0
		mov		R8,#0
		mov		R9,#0
		mov		R10,#0
		mov		R11,#0
		@ correct the bit that was corrupted
		sub		R12,#1
		and		R3,R2,R1,lsr R12	@ finds the corrupted bit, and put it in R3. It exists R12 positions along
		cmp		R3,#0
		beq		positionWhenZero
		b		positionWhenOne

positionWhenZero:
		eor		R3,#1			@ correct the corrupted bit by inverting it
		lsl		R3,R12			@ position the corrected bit R12 positions along
		add		R1,R3			@ add the corrected bit to the complete version of R1
		b		reformatOutput
		
positionWhenOne:
		mov		R4,R1			@ make a temporary copy of the 21-bit data-word
		lsr		R4,R12			@ select the corrupted bit
		and		R4,#0b1			@ mask it to select the corrupted bit
		lsl		R4,R12
		ldr		R7,=0b111111111111111111111
		eor		R4,R7			@ invert it
		and		R1,R4
		b		reformatOutput	@
		
@ subroutine to convert the 21-bit data-word back into its original 16-bit form, WITH a corrected corrupt bit
reformatOutput:
	@ reposition the 1st section of the 16-bit data-word
		mov		R5,R1
		lsr		R5,#2
		and		R5,#0b1
		mov		R6,R5
	@ reposition the 2nd subsection of the 16-bit data-word
		mov		R5,R1
		lsr		R5,#4
		and		R5,#0b111
		lsl		R5,#1
		add		R6,R5
	@ reposition the 3rd subsection of the 16-bit data-word
		mov		R5,R1
		lsr		R5,#8
		and		R5,#0b1111111
		lsl		R5,#4
		add		R6,R5
	@ reposition the 4th (and final) subsection of the 16-bit
		mov		R5,R1
		lsr		R5,#16
		and		R5,#0b11111
		lsl		R5,#11
		add		R6,R5
		
		mov		R0,R6			@ recopy the new modified 21-bit number back in 
		pop		{R1-R12}			@ restore saved register contents
		bx		LR				@ return to calling program
		.end
