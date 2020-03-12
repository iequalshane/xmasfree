;==============================================================
; INTRO FUNCTIONS
;==============================================================

; How long the intro runs for in frames
intro_duration	equ 380

palette_intro:
	DC.W	0x0000
	dc.w	0x0744
	dc.w	0x0855
	dc.w	0x0A88
	dc.w	0x0EEE
	dc.w	0x0EEE
	dc.w	0x0633
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000
	dc.w	0x0000

palette_intro_count equ 0x1

InitIntro:
	;==============================================================
	; Write the palettes to CRAM (colour memory)
	;==============================================================
	VDP_SetCRAMData palette_intro,palette_intro_count

	;==============================================================
	; Clear sprite data
	;==============================================================
	VDP_SetVRAMWrite vram_addr_sprite_table
	VDP_SetSprite 0x0,0x0,%0000,0x0,0x0,0x0,0x0,0x0,0x0

	;==============================================================
	; Set up the scroll planes (nametables)
	;==============================================================
	VDP_SetVRAMWrite vram_addr_plane_a
	move.w #(vdp_plane_height*vdp_plane_width), d0
	lea map_shane, a0
	@PlaneALp:
	move.w (a0)+, d1
	add.w #(tile_id_shane), d1
	move.w d1, vdp_data
	dbra d0, @PlaneALp

	; Reset plane scroll positions
	VDP_SetVRAMWrite vram_addr_hscroll
	move.w #0x0000, vdp_data	; Plane A h-scroll
	move.w #0x0000, vdp_data	; Plane B h-scroll

	VDP_SetVSRAMWrite 0x0000
	move.w #0x0210, vdp_data	; Plane A v-scroll ; Oops, not centered
	move.w #0x0000, vdp_data	; Plane B v-scroll
	rts


VUpdateIntro:
	; Count down until the intro is done
	move.w ram_frame_count, d2
	addi #1, d2
	move.w d2, ram_frame_count
	cmp #intro_duration, d2
	blt @VUpdateIntroDone
	jsr InitGame
	move.w #scene_game, ram_current_scene

	@VUpdateIntroDone:
	rts

HUpdateIntro:
	move.w ram_frame_count, d2
	move.w #0, d0
	move.b vdp_hvcounter, d0
	add.w d2, d0
	mulu  #5, d0
	MATH_Modulo sine_table_size_b, d0
	lea sine_table, a0
	adda d0, a0
	move.b (a0), d0
	;	sub.w #0x80, d0
	divs d2, d0
	add.w #(480-vdp_sprite_border_x/2), d0 ; Oops didn't center this properly
	VDP_SetVRAMWrite vram_addr_hscroll
	move.w d0, vdp_data
	rts