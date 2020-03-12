MATH_Modulo: macro value,outreg
	divu.w #(value), \outreg
	clr.w \outreg
	swap \outreg
	endm

sine_table:
	dc.b 0x80
	dc.b 0x86
	dc.b 0x8c
	dc.b 0x92
	dc.b 0x98
	dc.b 0x9e
	dc.b 0xa5
	dc.b 0xaa
	dc.b 0xb0
	dc.b 0xb6
	dc.b 0xbc
	dc.b 0xc1
	dc.b 0xc6
	dc.b 0xcb
	dc.b 0xd0
	dc.b 0xd5
	dc.b 0xda
	dc.b 0xde
	dc.b 0xe2
	dc.b 0xe6
	dc.b 0xea
	dc.b 0xed
	dc.b 0xf0
	dc.b 0xf3
	dc.b 0xf5
	dc.b 0xf8
	dc.b 0xfa
	dc.b 0xfb
	dc.b 0xfd
	dc.b 0xfe
	dc.b 0xfe
	dc.b 0xff
	dc.b 0xff
	dc.b 0xff
	dc.b 0xfe
	dc.b 0xfe
	dc.b 0xfd
	dc.b 0xfb
	dc.b 0xfa
	dc.b 0xf8
	dc.b 0xf5
	dc.b 0xf3
	dc.b 0xf0
	dc.b 0xed
	dc.b 0xea
	dc.b 0xe6
	dc.b 0xe2
	dc.b 0xde
	dc.b 0xda
	dc.b 0xd5
	dc.b 0xd0
	dc.b 0xcb
	dc.b 0xc6
	dc.b 0xc1
	dc.b 0xbc
	dc.b 0xb6
	dc.b 0xb0
	dc.b 0xaa
	dc.b 0xa5
	dc.b 0x9e
	dc.b 0x98
	dc.b 0x92
	dc.b 0x8c
	dc.b 0x86
	dc.b 0x80
	dc.b 0x79
	dc.b 0x73
	dc.b 0x6d
	dc.b 0x67
	dc.b 0x61
	dc.b 0x5a
	dc.b 0x55
	dc.b 0x4f
	dc.b 0x49
	dc.b 0x43
	dc.b 0x3e
	dc.b 0x39
	dc.b 0x34
	dc.b 0x2f
	dc.b 0x2a
	dc.b 0x25
	dc.b 0x21
	dc.b 0x1d
	dc.b 0x19
	dc.b 0x15
	dc.b 0x12
	dc.b 0xf
	dc.b 0xc
	dc.b 0xa
	dc.b 0x7
	dc.b 0x5
	dc.b 0x4
	dc.b 0x2
	dc.b 0x1
	dc.b 0x1
	dc.b 0x0
	dc.b 0x0
	dc.b 0x0
	dc.b 0x1
	dc.b 0x1
	dc.b 0x2
	dc.b 0x4
	dc.b 0x5
	dc.b 0x7
	dc.b 0xa
	dc.b 0xc
	dc.b 0xf
	dc.b 0x12
	dc.b 0x15
	dc.b 0x19
	dc.b 0x1d
	dc.b 0x21
	dc.b 0x25
	dc.b 0x2a
	dc.b 0x2f
	dc.b 0x34
	dc.b 0x39
	dc.b 0x3e
	dc.b 0x43
	dc.b 0x49
	dc.b 0x4f
	dc.b 0x55
	dc.b 0x5a
	dc.b 0x61
	dc.b 0x67
	dc.b 0x6d
	dc.b 0x73
	dc.b 0x79
sine_table_end
sine_table_size_b	equ (sine_table_end-sine_table)	; Size in bytes
sine_table_size_w	equ (sine_table_size_b/2)	; Size in words
sine_table_size_l	equ (sine_table_size_b/4)	; Size in longwords
sine_table_size_t	equ (sine_table_size_b/32)	; Size in tiles