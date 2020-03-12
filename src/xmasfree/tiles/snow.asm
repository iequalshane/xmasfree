;==============================================================
; TILES FOR SNOW WITH VARIATIONS
;==============================================================
; TODO: Add some variation
tiles_snow:
	dc.l	0x1111111d
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x1111d111
	dc.l	0x11111111
	dc.l	0x11111111

	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111

	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111

	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111
	dc.l	0x11111111

tiles_snow_end
tiles_snow_size_b	equ (tiles_snow_end-tiles_snow)	; Size in bytes
tiles_snow_size_w	equ (tiles_snow_size_b/2)	; Size in words
tiles_snow_size_l	equ (tiles_snow_size_b/4)	; Size in longwords
tiles_snow_size_t	equ (tiles_snow_size_b/32)	; Size in tiles