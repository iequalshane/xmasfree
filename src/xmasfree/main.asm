;==============================================================
; Space Tennis for the SEGA MEGA DRIVE/GENESIS
;==============================================================
; by iEqualShane
;==============================================================

; Scenes
scene_intro				equ 0x00
scene_menu				equ 0x01
scene_game				equ 0x02

;==============================================================
; MEMORY MAP
;==============================================================
; Shared ram between whole game
ram_current_scene		rs.w 1  ; Current scene [0 = intro, 1 = menu, 2 = game] (word)
ram_frame_count			rs.w 1	; Number of frame since intro started
ram_base                rs.b 0  ; End of shared ram

;==============================================================
; TILE IDs
;==============================================================
tile_id_blank			equ 0x00										; The blank tile at index 0
tile_id_shane			equ 0x01										; "SHANE" logo tile for background
tile_id_paused			equ (tile_id_shane+tiles_shane_size_t)			; Pause sprite tiles
tile_id_snow			equ (tile_id_paused+tiles_paused_size_t)		; Snow background tiles
tile_id_santa			equ (tile_id_snow+tiles_snow_size_t)			; Santa sprite tiles
tile_id_obstacles		equ (tile_id_santa+tiles_santa_size_t)			; Obstacles like trees and giant candy canes
tile_id_presents		equ (tile_id_obstacles+tiles_obstacles_size_t)	; Presents to collect
tile_id_numbers			equ (tile_id_presents+tiles_presents_size_t)	; Numbers for score
tile_id_life			equ (tile_id_numbers+tiles_numbers_size_t)		; Icon representing player lives
tile_id_gameover		equ (tile_id_life+tiles_life_size_t)			; Game Over text
tile_count				equ (tile_id_gameover+tiles_gameover_size_t)	; Total tiles to load (excl. blank)

;==============================================================
; CODE ENTRY POINT
;==============================================================
CPU_EntryPoint:
	;==============================================================
	; Initialise the Mega Drive
	;==============================================================

	VDP_Init

	; Initialise gamepad input
	PAD_Init

	; Initialize the audio system (ECHO)
	AUDIO_Init

	;==============================================================
	; Write the sprite tiles to VRAM
	;==============================================================
	
	; Setup the VDP to write to VRAM address 0x0020 (skips the first
	; tile, leaving it blank).
	VDP_SetVRAMWrite vram_addr_tiles+size_tile_b
	
	; Write all graphics tiles to VRAM
	lea    content_tiles, a0					; Move the address of the first graphics tile into a0
	move.w #(tile_count*size_tile_l)-1, d0		; Loop counter = 8 longwords per tile * num tiles (-1 for DBRA loop)
	@CharLp:									; Start of loop
	move.l (a0)+, vdp_data						; Write tile line (4 bytes per line), and post-increment address
	dbra d0, @CharLp							; Decrement d0 and loop until finished (when d0 reaches -1)

	;==============================================================
	; Intitialise variables in RAM
	;==============================================================
	move.w #0, ram_frame_count
	move.w #0, ram_gamepad_a_state
	move.w #0, ram_gamepad_b_state
	move.w #0, ram_gamepad_a_toggled
	move.w #0, ram_gamepad_b_toggled
	move.w #0, ram_current_scene

	;==============================================================
	; Initialise intro scene
	;==============================================================
    jsr InitIntro

	;==============================================================
	; Initialise status register and set interrupt level.
	;==============================================================
	move.w #0x2300, sr

	; Finished!
	
	;==============================================================
	; Loop forever
	;==============================================================
	; This loops forever, effectively ending our main routine,
	; but the VDP will continue to run of its own accord and
	; will still fire vertical and horizontal interrupts (which is
	; where our update code is), so the demo continues to run.
	;
	; For a game, it would be better to use this loop for processing
	; input and game code, and wait here until next vblank before
	; looping again. We only use vinterrupt for updates in this demo
	; for simplicity (because we don't yet have any timing code).
	@InfiniteLp:
	bra @InfiniteLp
	
;==============================================================
; INTERRUPT ROUTINES
;==============================================================

; Vertical interrupt - run once per frame (50hz in PAL, 60hz in NTSC)
INT_VInterrupt:

	; Read pad A state, result in format: 00SA0000 00CBRLDU
	PAD_ReadPad pad_data_a,ram_gamepad_a_state,ram_gamepad_a_toggled
	PAD_ReadPad pad_data_b,ram_gamepad_b_state,ram_gamepad_b_toggled

	; Update frame count
	move.w ram_frame_count, d2
	addi #1, d2
	move.w d2, ram_frame_count

	; Select scene to update
	move.w ram_current_scene, d1
	cmp #scene_intro, d1
	beq @SCENE_INTRO
	cmp #scene_menu, d1
	beq @SCENE_MENU
	cmp #scene_game, d1
	beq @SCENE_GAME

	@SCENE_INTRO:
	; Run intro updates
	jsr VUpdateIntro
	bra @SCENE_DONE

	@SCENE_MENU:
	; Run menu updates
	;jsr VUpdateMenu
	bra @SCENE_DONE

	@SCENE_GAME:
	; Run game upates
	jsr VUpdateGame

	@SCENE_DONE:
	rte

; Horizontal interrupt - run once per N scanlines (N = specified in VDP register 0xA)
INT_HInterrupt:

	move.w ram_current_scene, d1
	cmp #scene_intro, d1
	bne @HINT_DONE
	jsr HUpdateIntro

	@HINT_DONE:
	rte

; NULL interrupt - for interrupts we don't care about
INT_Null:
	rte

; Exception interrupt - called if an error has occured
CPU_Exception:
	; Just halt the CPU if an error occurred
	stop   #0x2700
	rte
