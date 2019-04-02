	.global _start
_start:	mov		R0,#0b1010111
		bl 		correct4
		mov		R7,#0
		svc		0
		.end
