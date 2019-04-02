	.global _start
_start:	ldr		R0,=0b110100101010101110100	@ 16-bit data word 101000110000100110000
		bl 		correct16
		mov		R7,#0
		svc		0
		.end
