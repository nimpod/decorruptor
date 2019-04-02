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
@ R10 = not used 
@ R11 = not used
@ R12 = not used

	.global generate16
generate16:
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
		
	@ position 1st part of data-word
		mov		R5,R1		@ copy the data-word
		lsr		R5,#0		@ right shift it		   (xxxxxxxxxxxxxxxxxxxx{0})
		and		R5,#0b1		@ mask 1st part
		lsl		R5,#2		@ position it	 	   (xxxxxxxxxxxxxxxxxx{0}xx)
		mov		R2,R5		@ 			  R2 = (xxxxxxxxxxxxxxxxxx{0}xx)
		
	@ position 2nd part of data-word
		mov		R5,R1		@ copy the data-word
		lsr		R5,#1		@ right shift it		   (xxxxxxxxxxxxxxxxxxx{011})
		and		R5,#0b111	@ mask 2nd part
		lsl		R5,#4		@ positon it		   (xxxxxxxxxxxxxxxxx{011}xx)
		add		R2,R5		@ 			  R2 = (xxxxxxxxxxxxx{011}x{0}xx)
			
	@ position 3rd part of data-word
		mov		R5,R1		@ copy the data-word
		lsr		R5,#4		@ right shift it 	   (xxxxxxxxxxxxxxx{1110001})
		and		R5,#0b1111111@ mask 3rd part
		lsl		R5,#8		@ positon it		   (xxxxxxxxxx{1110001}xxxxx)
		add		R2,R5		@ 			  R2 = (xxxxxx{1110001}x{011}x{0}xx)
		
	@ position 4th part of data-word
		mov		R5,R1		@ copy the data-word
		lsr		R5,#11		@ right shift it		   (xxxxxxxxxxxxxxxxx{10100})
		and		R5,#0b11111	@ mask the 4th part
		lsl		R5,#16		@ left shift it 		   ({10100}xxxxxxxxxxxxxxxx)
		add		R2,R5		@ 			  R2 = ({10100}x{1110001}x{011}x{0}xx)
	
	@preperation for loop:
		mov		R1,R2		@ recopy the full 21-bit number back into R1
		mov		R2,#0		@ reset the register because it will be used later
		mov		R5,#0		@ reset the register because it will be used later
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
exitProg:	mov		R0,R1		@ recopy the new modified 21-bit number back in 
		pop		{R1-R12}		@ restore saved register contents
		bx		LR			@ return to calling program

positionCheckBit:
		and		R8,#0b1		@ was the number even or odd? if(even) --> R8=1 : if(odd) --> R8=1
		cmp		R4,#1		@ if on row1
		beq		shiftBit0		@ go and right shift it by 1
		cmp		R4,#2		@ if on row2
		beq		shiftBit1		@ go and right shift it by 1
		cmp		R4,#3		@ if on row3
		beq		shiftBit3		@ go and right shift it by 3
		cmp		R4,#4		@ if on row4
		beq		shiftBit7		@ go and right shift it by 7
		cmp		R4,#5		@ if on row5
		beq		shiftBit15		@ go and right shift by 15
nextRow:	add		R4,#1		@ increment the representation of a row number
		cmp		R4,#6		@ are we on the final row?
		beq		exitProg		@ if yes --> exit program
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

shiftBit0:lsl		R8,#0
		add		R1,R8
		b		nextRow		

shiftBit1:lsl		R8,#1		@ position the bit correctly
		add		R1,R8		@ add it to the 21-bit data-word
		b		nextRow		@ go back and compute next row

shiftBit3:lsl		R8,#3		@ position the bit correctly
		add		R1,R8		@ add it to the 21-bit data-word
		b		nextRow		@ go back and compute next row

shiftBit7:lsl		R8,#7		@ position the bit correctly
		add		R1,R8		@ add it to the 21-bit data-word
		b		nextRow		@ go back and compute next row

shiftBit15:lsl	R8,#15		@ position the bit correctly
		add		R1,R8		@ add it to the 21-bit data-word
		b		nextRow		@ go back and compute next row
		.end
