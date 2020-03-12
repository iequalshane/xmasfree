
;==============================================================
; CONSTANTS
;==============================================================
max_sprite_count	equ 0x40

;==============================================================
; STRUCTURES
;==============================================================
	;STRUCT_BEGIN Sprite
	;STRUCT_MEMBER PosY,w,1
	;STRUCT_MEMBER SizeAndNextId,w,1
	;STRUCT_MEMBER PriorityPaletteFlipAndGfx,w,1
	;STRUCT_MEMBER PosX,w,1
	;STRUCT_END

;==============================================================
; MEMORY MAP
;==============================================================
ram_sprite_count			rs.w 1										; Current number of sprites
ram_sprite_list				rs.w 4*max_sprite_count	; A list of sprites

SPRITE_Init: macro
	move.w #0, ram_sprite_count
	endm

SPRITE_Flush: macro reg0,reg1,addreg0
	lea ram_sprite_list, \addreg0
	move.w ram_sprite_count, \reg0		; Get current sprite count
	add.w \reg0, \reg0					; Get offset to current sprite
    add.w \reg0, \reg0
    add.w \reg0, \reg0
    subi.w #5, \reg0
    move.b #0, (\addreg0,\reg0\.w)		; Set last sprite link to 0

	VDP_SetVRAMWrite vram_addr_sprite_table	; Start at the beginning of the sprite table in VRAM
	move.w ram_sprite_count, \reg0			; Loop through the sprites in RAM
	\@SpriteEndLoop:
	move.w (\addreg0)+, vdp_data
	move.w (\addreg0)+, vdp_data
	move.w (\addreg0)+, vdp_data
	move.w (\addreg0)+, vdp_data
	dbra \reg0, \@SpriteEndLoop
	move.w #0, ram_sprite_count
	endm

SPRITE_Add: macro reg0,reg1,addreg0,x_pos,y_pos,dimension_bits,priority_bit,palette_id,flip_x,flip_y,tile_id
	; Load and caculate sprite count and sprite list offset
	lea ram_sprite_list, \addreg0		; Start of sprites in RAM
	move.w ram_sprite_count, \reg0		; Get current sprite count
	move.w \reg0, \reg1					; Copy sprite count
	add.w \reg1, \reg1					; Get offset to current sprite
    add.w \reg1, \reg1
    add.w \reg1, \reg1
	lea (\addreg0,\reg1\.w), \addreg0
	addi.w #1, \reg0					; Increment and store new sprite count
	move.w \reg0, ram_sprite_count 
	; Store new sprite data
	move.w #\y_pos, (\addreg0)+			; Store Y position of sprite
	move.b #\dimension_bits, (\addreg0)+		; Store dimension of sprite
	move.b \reg0, (\addreg0)+					; Store link to next sprite (will remove for last sprite)
	move.w #(\priority_bit<<14|\palette_id<<13|\flip_x<<11|\flip_y<<10|\tile_id), (\addreg0)+	; Store prioty/palette/flip/tile
	move.w #\x_pos, (\addreg0)+			; Store X position of sprite
	endm

SPRITE_AddVarPos: macro reg0,reg1,addreg0,x_pos,y_pos,dimension_bits,priority_bit,palette_id,flip_x,flip_y,tile_id
	; Load and caculate sprite count and sprite list offset
	lea ram_sprite_list, \addreg0		; Start of sprites in RAM
	move.w ram_sprite_count, \reg0		; Get current sprite count
	move.w \reg0, \reg1					; Copy sprite count
	add.w \reg1, \reg1					; Get offset to current sprite
    add.w \reg1, \reg1
    add.w \reg1, \reg1
	lea (\addreg0,\reg1\.w), \addreg0
	addi.w #1, \reg0					; Increment and store new sprite count
	move.w \reg0, ram_sprite_count 
	; Store new sprite data
	move.w \y_pos, (\addreg0)+			; Store Y position of sprite
	move.b #\dimension_bits, (\addreg0)+		; Store dimension of sprite
	move.b \reg0, (\addreg0)+					; Store link to next sprite (will remove for last sprite)
	move.w #(\priority_bit<<14|\palette_id<<13|\flip_x<<11|\flip_y<<10), \reg1
	or.w \tile_id, \reg1
	move.w \reg1, (\addreg0)+	; Store prioty/palette/flip/tile
	move.w \x_pos, (\addreg0)+			; Store X position of sprite
	endm