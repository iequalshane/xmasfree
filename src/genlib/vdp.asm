
;==============================================================
; INITIAL VDP REGISTER VALUES
;==============================================================
vdp_registers:
	dc.b 0x14 ; 0x00: H interrupt on, palettes on
	dc.b 0x74 ; 0x01: V interrupt on, display on, DMA on, Genesis mode on
	dc.b 0x30 ; 0x02: Pattern table for Scroll Plane A at VRAM 0xC000 (bits 3-5 = bits 13-15)
	dc.b 0x00 ; 0x03: Pattern table for Window Plane at VRAM 0x0000 (disabled) (bits 1-5 = bits 11-15)
	dc.b 0x07 ; 0x04: Pattern table for Scroll Plane B at VRAM 0xE000 (bits 0-2 = bits 11-15)
	dc.b 0x78 ; 0x05: Sprite Attribute Table at VRAM 0xF000 (bits 0-6 = bits 9-15)
	dc.b 0x00 ; 0x06: Unused
	dc.b 0x00 ; 0x07: Background colour: bits 0-3 = colour, bits 4-5 = palette
	dc.b 0x00 ; 0x08: Unused
	dc.b 0x00 ; 0x09: Unused
	dc.b 0x00 ; 0x0A: Frequency of Horiz. interrupt in Rasters (number of lines travelled by the beam)
	dc.b 0x00 ; 0x0B: External interrupts off, V scroll per-page, H scroll per-page
	dc.b 0x81 ; 0x0C: Shadows and highlights off, interlace off, H40 mode (320 x 224 screen res)
	dc.b 0x3F ; 0x0D: Horiz. scroll table at VRAM 0xFC00 (bits 0-5)
	dc.b 0x00 ; 0x0E: Unused
	dc.b 0x02 ; 0x0F: Autoincrement 2 bytes
	dc.b 0x01 ; 0x10: Scroll plane size: 64x32 tiles
	dc.b 0x00 ; 0x11: Window Plane X pos 0 left (pos in bits 0-4, left/right in bit 7)
	dc.b 0x00 ; 0x12: Window Plane Y pos 0 up (pos in bits 0-4, up/down in bit 7)
	dc.b 0xFF ; 0x13: DMA length lo byte
	dc.b 0xFF ; 0x14: DMA length hi byte
	dc.b 0x00 ; 0x15: DMA source address lo byte
	dc.b 0x00 ; 0x16: DMA source address mid byte
	dc.b 0x80 ; 0x17: DMA source address hi byte, memory-to-VRAM mode (bits 6-7)
	
	even
	
;==============================================================
; CONSTANTS
;==============================================================
	
; VDP port addresses
vdp_control				equ 0x00C00004
vdp_data				equ 0x00C00000
vdp_hvcounter			equ 0x00C00008

; VDP commands
vdp_cmd_vram_write		equ 0x40000000
vdp_cmd_cram_write		equ 0xC0000000
vdp_cmd_vsram_write		equ 0x40000010

; VDP memory addresses
; according to VDP registers 0x2, 0x4, 0x5, and 0xD (see table above)
vram_addr_tiles			equ 0x0000
vram_addr_plane_a		equ 0xC000
vram_addr_plane_b		equ 0xE000
vram_addr_sprite_table	equ 0xF000
vram_addr_hscroll		equ 0xFC00
vram_addr_vscroll

; Screen width and height (in pixels)
vdp_screen_width		equ 0x0140
vdp_screen_height		equ 0x00E0 ; NTSC, 0x00F0 for PAL

; The plane width and height (in tiles)
; according to VDP register 0x10 (see table above)
vdp_plane_width			equ 0x40
vdp_plane_height		equ 0x20

; The size of the sprite plane (512x512 pixels)
vdp_sprite_plane_width	equ 0x0200
vdp_sprite_plane_height	equ 0x0200

; The sprite border (invisible area left + top) size
vdp_sprite_border_x		equ 0x80
vdp_sprite_border_y		equ 0x80

; Hardware version address
hardware_ver_address	equ 0x00A10001

; TMSS
tmss_address			equ 0x00A14000
tmss_signature			equ 'SEGA'

; The size of a word and longword
; These aren't really VDP related but I don't have a good location
; to put these yet.
size_word				equ 0x2
size_long				equ 0x4

; The size of one palette (in bytes, words, and longwords)
size_palette_b			equ 0x20
size_palette_w			equ size_palette_b/size_word
size_palette_l			equ size_palette_b/size_long

; The size of one graphics tile (in bytes, words, and longwords)
size_tile_b				equ 0x20
size_tile_w				equ size_tile_b/size_word
size_tile_l				equ size_tile_b/size_long

; The size of a sprite attribute table in bytes
size_sprite_attribute_b	equ 0x8

;==============================================================
; VRAM WRITE MACROS
;==============================================================
	
; Set the VRAM (video RAM) address to write to next
VDP_SetVRAMWrite: macro addr
	move.l  #(vdp_cmd_vram_write)|((\addr)&$3FFF)<<16|(\addr)>>14, vdp_control
	endm
	
; Set the CRAM (colour RAM) address to write to next
VDP_SetCRAMWrite: macro addr
	move.l  #(vdp_cmd_cram_write)|((\addr)&$3FFF)<<16|(\addr)>>14, vdp_control
	endm

; Set the VSRAM (vertical scroll RAM) address to write to next
VDP_SetVSRAMWrite: macro addr
	move.l  #(vdp_cmd_vsram_write)|((\addr)&$3FFF)<<16|(\addr)>>14, vdp_control
	endm

;==============================================================
; Write the palettes to CRAM (colour memory)
;==============================================================
VDP_SetCRAMData: macro paletteAddr,paletteCount
	; Setup the VDP to write to CRAM address 0x0000 (first palette)
	VDP_SetCRAMWrite 0x0000
	
	; Write the palettes to CRAM
	lea    paletteAddr, a0				; Move palette address to a0
	move.w #(paletteCount*size_palette_w)-1, d0	; Loop counter = 8 words in palette (-1 for DBRA loop)
	\@PalLp:							; Start of loop
	move.w (a0)+, vdp_data			; Write palette entry, post-increment address
	dbra d0, \@PalLp					; Decrement d0 and loop until finished (when d0 reaches -1)
	endm

;==============================================================
; SET SPRITE ATTRIBUTE TABLE MACRO
;==============================================================
; Writes a sprite attribute structure to VRAM
;VDP_SetSprite:
;	x_pos,			; X pos on sprite plane
;	y_pos,			; Y pos on sprite plane
;	dimension_bits,	; Sprite tile dimensions (4 bits)
;	next_id,		; Next sprite index in linked list
;	priority_bit,	; Draw priority
;	palette_id,		; Palette index
;	flip_x,			; Flip horizontally
;	flip_y,			; Flip vertically
;	tile_id,		; First tile index
VDP_SetSprite: macro x_pos,y_pos,dimension_bits,next_id,priority_bit,palette_id,flip_x,flip_y,tile_id
	move.w #y_pos, vdp_data
	move.w #(\dimension_bits<<8|\next_id), vdp_data
	move.w #(\priority_bit<<14|\palette_id<<13|\flip_x<<11|\flip_y<<10|\tile_id), vdp_data
	move.w #x_pos, vdp_data
	endm

VDP_SetSpriteVarPos: macro x_pos,y_pos,dimension_bits,next_id,priority_bit,palette_id,flip_x,flip_y,tile_id
	move.w #\y_pos_reg, vdp_data
	move.w #(\dimension_bits<<8|\next_id), vdp_data
	move.w #(\priority_bit<<14|\palette_id<<13|\flip_x<<11|\flip_y<<10|\tile_id), vdp_data
	move.w #\x_pos, vdp_data
	endm

;==============================================================
; SET SPRITE POSITION MACRO
;==============================================================
; Writes sprite position to sprite attribute structure in VRAM
;VDP_SetSpritePos:
;	sprite_addr,	; Address of sprite in VRAM
;	pos_x_reg,		; X position of sprite (register)
;	pos_y_reg,		; Y position of sprite (register)
VDP_SetSpritePos: macro sprite_addr,pos_x_reg,pos_y_reg
	VDP_SetVRAMWrite \sprite_addr	; Ball sprite Y value
	move.w \pos_y_reg, vdp_data
	VDP_SetVRAMWrite \sprite_addr+0x0006	; Ball sprite X value
	move.w \pos_x_reg, vdp_data
	endm

VDP_SetSpriteTile: macro sprite_addr,tile_id_reg
	VDP_SetVRAMWrite \sprite_addr+0x0004
	move.w \tile_id_reg, vdp_data
	endm

VDP_SetSpriteLinkedTile: macro sprite_addr,dimension_bits,next_id
	VDP_SetVRAMWrite \sprite_addr+0x0002
	move.w #(\dimension_bits<<8|\next_id), vdp_data
	endm

;==============================================================
; VDP Functions
;==============================================================

; Poke the TMSS to show "LICENSED BY SEGA..." message and allow us to
; access the VDP (or it will lock up on first access).
VDP_WriteTMSS:

	move.b hardware_ver_address, d0			; Move Megadrive hardware version to d0
	andi.b #0x0F, d0						; The version is stored in last four bits, so mask it with 0F
	beq    @SkipTMSS						; If version is equal to 0, skip TMSS signature
	move.l #tmss_signature, tmss_address	; Move the string "SEGA" to 0xA14000
	@SkipTMSS:

	; Check VDP
	move.w vdp_control, d0					; Read VDP status register (hangs if no access)
	
	rts

; Set VDP registers
VDP_LoadRegisters:

	lea    vdp_registers, a0		; Load address of register table into a0
	move.w #0x18-1, d0			; 24 registers to write (-1 for loop counter)
	move.w #0x8000, d1			; 'Set register 0' command to d1

	@CopyRegLp:
	move.b (a0)+, d1			; Move register value from table to lower byte of d1 (and post-increment the table address for next time)
	move.w d1, vdp_control		; Write command and value to VDP control port
	addi.w #0x0100, d1			; Increment register #
	dbra   d0, @CopyRegLp		; Decrement d0, and jump back to top of loop if d0 is still >= 0
	
	rts

; Clear all 64k of VRAM
VDP_ClearVRAM:
	; Setup the VDP to write to VRAM address 0x0000 (start of VRAM)
	VDP_SetVRAMWrite 0x0000

	; Write 0's across all of VRAM
	move.w #(0x00010000/size_word)-1, d0	; Loop counter = 64kb, in words (-1 for DBRA loop)
	@ClrVramLp:								; Start of loop
	move.w #0x0, vdp_data					; Write a 0x0000 (word size) to VRAM
	dbra   d0, @ClrVramLp					; Decrement d0 and loop until finished (when d0 reaches -1)
	rts

VDP_Init: macro
	; Write the TMSS signature (if a model 1+ Mega Drive)
	jsr VDP_WriteTMSS

	; Load the initial VDP registers
	jsr VDP_LoadRegisters

	; Clear VRAM. You don't really need to clear all of VRAM but it's
	; nice for debugging.
	;jsr VDP_ClearVRAM
	endm