tiles_life:
	dc.l 0x00000000
	dc.l 0x02202200
	dc.l 0x21121120
	dc.l 0x24124120
	dc.l 0x24424420
	dc.l 0x24424420
	dc.l 0x24424420
	dc.l 0x24414420

	dc.l 0x24444420
	dc.l 0x24424422
	dc.l 0x24424424
	dc.l 0x24424424
	dc.l 0x24424424
	dc.l 0x24424424
	dc.l 0x24424424
	dc.l 0x02202202

	dc.l 0x00000000
	dc.l 0x00002220
	dc.l 0x00024112
	dc.l 0x00024412
	dc.l 0x00024442
	dc.l 0x00024442
	dc.l 0x00024442
	dc.l 0x00024442

	dc.l 0x00002420
	dc.l 0x22002420
	dc.l 0x41202420
	dc.l 0x41200200
	dc.l 0x24200000
	dc.l 0x24202220
	dc.l 0x44202420
	dc.l 0x22002220

tiles_life_end
tiles_life_size_b	equ (tiles_life_end-tiles_life)
tiles_life_size_w	equ (tiles_life_size_b/2)
tiles_life_size_l	equ (tiles_life_size_b/4)
tiles_life_size_t	equ (tiles_life_size_b/32)