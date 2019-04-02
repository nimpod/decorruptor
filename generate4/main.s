	.global _start
_start:	mov		R0,#0b1100
		bl 		generate4
		mov		R7,#0
		svc		0
		.end
