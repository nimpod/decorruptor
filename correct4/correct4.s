@ OVERVIEW OF REGISTERS
@ ----------------------------------------------------------------    
@ R0   = original data-word
@ R1   = (A and !B and C) 	  --> andGate1 output
@ R2   = (!A and B and C) 	  --> andGate2 output
@ R3   = copy of original data-word
@ R4   = [((rx4^rx3)^rx2)^rx0] --> Circle A output
@ R5   = [((rx5^rx3)^rx2)^rx1] --> Circle B output
@* R6  = [((rx6^rx3)^rx1)^rx0] --> Circle C output  
@* R6  = Check-bit    		  --> rx6bit
@ R7   = Check-bit    		  --> rx5bit
@ R7   = (A and B and !C)	  --> andGate3 output
@* R8 = (A and B and C) 	  	  --> andGate4 output
@* R8 = Check-bit    		  --> rx4bit
@ R9   = Data-bit D0 		  --> rx0bit
@ R10 = Data-bit D1 		  --> rx1bit
@ R11 = Data-bit D2 		  --> rx2bit
@ R12 = Data-bit D3 		  --> rx3bit
@ ----------------------------------------------------------------

	.global correct4
correct4: push 	{R1-R12}	        	@ Save contents of registers through R0 - R7
		mov		R3,R0			@ R3 will hold a copy of input word to be displayed
		mov		R2,#1			@ Number of characters to be displayed at a time (1 binary digit/character at a time)

findDataBits:
		and		R6,R2,R3, lsr #6	@ (R1 = R2 and R3(lsr by 6)) - selects check-bit rx6
		and		R7,R2,R3, lsr #5	@ (R1 = R2 and R3(lsr by 5)) - selects check-bit rx5
		and		R8,R2,R3, lsr #4	@ (R1 = R2 and R3(lsr by 4)) - selects check-bit rx4
		and		R9,R2,R3, lsr #3	@ (R1 = R2 and R3(lsr by 3)) - selects data-bit rx3
		and		R10,R2,R3, lsr #2	@ (R1 = R2 and R3(lsr by 2)) - selects data-bit rx2
		and		R11,R2,R3, lsr #1	@ (R1 = R2 and R3(lsr by 1)) - selects data-bit rx1
		and		R12,R2,R3, lsr #0	@ (R1 = R2 and R3(lsr by 0)) - selects data-bit rx0
		b		circleA

@ Compute the outputs of the three circles A, B and C, and put them in registers R4-R6:
@ --------------------------------------------------------------------------------------------------------------------------------------------
circleA:	eor		R4,R8,R9			@ (A = rx4 ^ rx3) - first xor gate
		eor		R4,R10			@ (A = A ^ rx2) - second xor gate
		eor		R4,R4,R12		@ (A = A ^ rx0) - third xor gate. Circle A should output 0 if there were no errors to be corrected

circleB:	eor		R5,R7,R9			@ (B = rx5 ^ rx3) - first xor gate
		eor		R5,R10			@ (B = B ^ rx2) - second xor gate
		eor		R5,R11			@ (B = B ^ rx1) - third xor gate. Circle B should output 0 if there were no errors to be corrected

circleC:	eor		R6,R6,R9			@ (C = rx6 ^ rx3) - first xor gate
		eor		R6,R11			@ (C = C ^ rx3) - second xor gate
		eor		R6,R12			@ (C = C ^ rx0) - third xor gate. Circle C should output 0 if there were no errors to be corrected
		b		andGate1			

@ Compute the outputs of the and gates, then put them in registers R1-R2 and R7-R8:
@ --------------------------------------------------------------------------------------------------------------------------------------------
andGate1:mov		R8,R5			@ Making a copy of circle B (R5) for the inversion
		eor		R8,#1			@ Invert value of B (the not gate)
		and		R1,R4,R8
		and		R1,R6			@ (R1 = (R4 && R8) && R6) - Final output of andGate1. Should output 0 if there were no errors to be corrected

andGate2:mov		R8,R4			@ Making a copy of circle A (R4) for the inversion
		eor		R8,#1			@ Invert value of A (the not gate)
		and		R2,R8,R5
		and		R2,R6			@ (R2 = (R8 && R5) && R6) - Final output of andGate2. Should output 0 if there were no errors to be corrected

andGate3:mov		R8,R6			@ Making a copy of circle C (R6) for the inversion
		eor		R8,#1			@ Invert value of C (the not gate)
		and		R7,R4,R5
		and		R7,R8			@ (R7 = (R4 && R5) && R8) - Final output of andGate3. Should output 0 if there were no errors to be corrected

andGate4:and		R8,R4,R5		
		and		R8,R6			@ Final output of andGate4: (R8 = (R4 && R5) && R6). Should output 0 if there were no errors to be corrected

@ Compute the final corrected bits D0-D3:
@ --------------------------------------------------------------------------------------------------------------------------------------------
correctDataBits:
		eor		R12,R1			@ Reveal the D3 corrected bit (R12 = R12 xor R1)
		eor		R11,R2			@ Reveal the D2 corrected bit (R11 = R11 xor R2)
		eor		R10,R7			@ Reveal the D1 corrected bit (R10 = R10 xor R7)
		eor		R9,R8			@ Reveal the D0 corrected bit (R9 = R9 xor R8)
		
	@Get the data-bits by left shifting the registers:
		lsl		R9,#3			@ Get the rx3 bit by left shifting R12 3 times
		lsl		R10,#2			@ Get the rx2 bit by left shifting R11 2 times
		lsl		R11,#1			@ Get the rx1 bit by left shifting R10 1 times
		lsl		R12,#0			@ Get the rx0 bit by left shifting R9 0 times
	@Add the data-bits together:
		add		R9,R10			@ (R9 = R9 + R10)
		add		R9,R11			@ (R9 = R9 + R11)
		add		R9,R12			@ (R9 = R9 + R12)	
		mov		R0,R9
		
		pop		{R1-R12}		@ Restore saved register contents
		bx		LR				@ Return to calling program
