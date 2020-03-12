;==============================================================
; GAMEPLAY FUNCTIONS
;==============================================================

; Positional scale constants
pos_shift_amount	equ 0x2
pos_scale_amount	equ 0x4

; Player constants
player_height			equ 0x20
player_width			equ 0x20
player_start_pos_x		equ (vdp_sprite_border_x+vdp_screen_width/2-player_width/2)*pos_scale_amount
player_start_pos_y		equ (vdp_sprite_border_y+64-player_height/2)*pos_scale_amount
player_max_move_speed_x equ 0x5
player_max_move_speed_y equ 0x5
player_acceleration		equ 0x1
player_start_lives		equ 0x3 ; Number of lives before game over
player_life_pos_x		equ vdp_sprite_border_x+8 ; Location of player life icons
player_life_pos_y		equ vdp_sprite_border_x+8 

; Score constants
score_pos_x				equ vdp_sprite_border_x+260 ; Location of the score in the UI
score_pos_y				equ vdp_sprite_border_y+8
dist_per_point			equ 0x100 ; How far the player must travel south per point
points_per_present		equ 0xA ; How many points collecting a present is worth

; Paused text sprite positions
paused_x				equ vdp_sprite_border_x+vdp_screen_width/2-68
paused_y				equ vdp_sprite_border_y+96

; Game over sprite positions
gameover_pos_x			equ vdp_sprite_plane_width/2-32
gameover_pos_y			equ vdp_sprite_plane_height/2-32

; Direction constants
direction_west			equ 0x0
direction_southwest		equ 0x1
direction_south			equ 0x2
direction_southeast		equ 0x3
direction_east			equ 0x4

; Collison constants
collision_state_none	equ 0x0
collision_state_falling	equ 0x1
collision_state_stuck	equ 0x2
collision_immune_time	equ 0x78 ; 120 frames / 3 seconds
collision_fall_time		equ 0x30 ; 48 frames / 1 second
collision_stuck_time	equ 0x78 ; 120 frames / 2 seconds

; Obstacle and present list constants
dist_per_obstacle		equ 0x9*pos_scale_amount 	; How often new obstacles appear
num_obstacles_max		equ 0x30
dist_per_present		equ 0x40*pos_scale_amount 	; How often new presents appear
num_presents_max		equ 0x10

; Palette for gameplay
palette_game:
	dc.w	0x0000
	dc.w	0x0eee
	dc.w	0x0202
	dc.w	0x0006
	dc.w	0x022a
	dc.w	0x0224
	dc.w	0x0226
	dc.w	0x08ac
	dc.w	0x02cc
	dc.w	0x02a4
	dc.w	0x0242
	dc.w	0x0642
	dc.w	0x0ca4
	dc.w	0x0cca
	dc.w	0x0666
	dc.w	0x0224

; Number of palettes to write to CRAM
game_palette_count	equ 0x1

;==============================================================
; STRUCTURES
;==============================================================
	STRUCT_BEGIN Entity
	STRUCT_MEMBER PosX,w,1
	STRUCT_MEMBER PosY,w,1
	STRUCT_MEMBER IsActive,w,1
	STRUCT_MEMBER TileId,w,1
	STRUCT_END

;==============================================================
; MEMORY MAP
;==============================================================
	rsset ram_base
ram_player_entity			rs.b Entity_Struct_Size ; The player entity
ram_player_direction		rs.w 1  ; 0 = W, 1 = SW, 2 = S, 3 = SE, 4 = E
ram_player_collision_state	rs.w 1	; 0 = no collision, 1 = in air / falling, 2 = stuck in ground
ram_player_collision_timer	rs.w 1  ; if state = 0 and timer > 0 no collision allowed. Otherwise, time until fall or unstuck.
ram_player_score			rs.w 1	; Current player score
ram_player_lives			rs.w 1	; Number of remaining player lives before game over
ram_paused					rs.w 1  ; Indicates if game is currently paused
ram_gameover				rs.w 1	; Indicates if a player won
ram_dist_since_score		rs.w 1  ; Distance since last score point was added
ram_dist_since_obs_spawn	rs.w 1	; Distance south since last obstacle spawn
ram_dist_since_pres_spawn	rs.w 1	; Distance south since last present spawn
ram_next_obstacle			rs.w 1
ram_obstacle_list			rs.b Entity_Struct_Size*num_obstacles_max
ram_present_list			rs.b Entity_Struct_Size*num_presents_max

;==============================================================
; INITAILIZE GAME
;==============================================================
InitGame:

	move.w #134, ram_rndseed ; TODO: Seed with delta frames from menu

	;==============================================================
	; Write the palettes to CRAM (colour memory)
	;==============================================================
	VDP_SetCRAMData palette_game,game_palette_count

	;==============================================================
	; Set up the scroll planes (nametables)
	;==============================================================

	; Fill plane A tiles
	VDP_SetVRAMWrite vram_addr_plane_a
	move.w #(vdp_plane_height*vdp_plane_width), d0
	@PlaneALp:
	; TODO: Randomize snow tiles
	move.w #(tile_id_snow), vdp_data
	dbra d0, @PlaneALp

	; TODO: Add obstacles to plane B
	; Fill plane B tiles
	;VDP_SetVRAMWrite vram_addr_plane_b
	;move.w #(vdp_plane_height*vdp_plane_width), d0
	;@PlaneBLp:
	;move.w #(some_tiles_todo), vdp_data
	;dbra d0, @PlaneBLp

	; Reset plane scroll positions
	VDP_SetVRAMWrite vram_addr_hscroll
	move.w #0x0000, vdp_data	; Plane A h-scroll
	move.w #0x0000, vdp_data	; Plane B h-scroll

	VDP_SetVSRAMWrite 0x0000
	move.w #0x0000, vdp_data	; Plane A v-scroll
	move.w #0x0000, vdp_data	; Plane B v-scroll

	;==============================================================
	; Set up the Sprite Attribute Tables (SAT)
	;==============================================================

	; Sprite attribute table addresses.
player_sprite_addr		equ vram_addr_sprite_table
krampus_sprite_addr		equ vram_addr_sprite_table+size_sprite_attribute_b

	; Start writing to the sprite attribute table in VRAM
	VDP_SetVRAMWrite vram_addr_sprite_table

	; Player sprite
	VDP_SetSprite player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x0,0x0,0x0,tile_id_santa

	; Paused text sprites
	VDP_SetSprite paused_x,paused_y,%1111,0xA,0x0,0x0,0x0,0x0,tile_id_paused
	VDP_SetSprite paused_x+32,paused_y,%1111,0xB,0x0,0x0,0x0,0x0,tile_id_paused+16
	VDP_SetSprite paused_x+64,paused_y,%1111,0xC,0x0,0x0,0x0,0x0,tile_id_paused+32
	VDP_SetSprite paused_x+96,paused_y,%1011,0x0,0x0,0x0,0x0,0x0,tile_id_paused+48

	;==============================================================
	; Intitialise variables in RAM
	;==============================================================
	move.w #player_start_pos_x, ram_player_entity+Entity_PosX
	move.w #player_start_pos_y, ram_player_entity+Entity_PosY
	move.w #2, ram_player_direction
	move.w #0, ram_player_collision_state
	move.w #0, ram_player_collision_timer
	move.w #player_start_lives, ram_player_lives
	move.w #0, ram_player_score
	move.w #0, ram_paused
	move.w #0, ram_gameover
	move.w #0, ram_dist_since_score
	move.w #0, ram_dist_since_obs_spawn
	move.w #0, ram_dist_since_pres_spawn
	move.w #0, ram_next_obstacle

	move.w #(num_obstacles_max-1), d0	; De-activate all obstacles
	lea ram_obstacle_list, a0		; Get start of obstacle list
	@ObstacleInitLoop:
	move.w #0, Entity_IsActive(a0)	; De-activate all obstacles
	lea Entity_Struct_Size(a0),a0 	; Next obstacle slot
	dbra d0, @ObstacleInitLoop

	move.w #(num_presents_max-1), d0	; De-activate all presents
	lea ram_present_list, a0		; Get start of present list
	@PresentInitLoop:
	move.w #0, Entity_IsActive(a0)	; De-activate all presents
	lea Entity_Struct_Size(a0),a0 	; Next present slot
	dbra d0, @PresentInitLoop

	; Start music
    AUDIO_PlayBGM content_bgm_music

    SPRITE_Init

	rts

;==============================================================
; UPDATE GAME
;==============================================================
; Called from the main game code every frame.
VUpdateGame:

	SPRITE_Flush d0,d1,a0	; Flush last frame's sprites to the VDP

	move.w ram_gamepad_a_state, d0
	move.w ram_gamepad_a_toggled, d2
	move.w ram_paused, d4
	move.w ram_gameover, d5

	; Temp code used to slow down updates
	;move.l #0, d2
	;move.w ram_frame_count, d2
	;MATH_Modulo 2, d2
	;cmp #0, d2
	;bgt @GamePaused

	move.w d0, d1
	and.w d2, d1

	cmp #1, d5 ; Are we in the game over screen? Start, A, B or C will restart the game
	bne @GameOn
	btst   #pad_button_start, d1	; Was start pressed?
	bne    @RestartGame
	btst   #pad_button_a, d1		; Was A pressed?
	bne    @RestartGame
	btst   #pad_button_b, d1		; Was B pressed?
	bne    @RestartGame
	btst   #pad_button_c, d1		; Was C pressed?
	bne    @RestartGame
	bra @GameOn
	@RestartGame:
	jsr InitGame
	;move.w #scene_menu, ram_current_scene
	bra @GamePaused
	@GameOn:

	; Check for start press to pause/unpause game
	btst   #pad_button_start, d1
	beq    @NoStartPressed
	AUDIO_PlaySFX content_sfx_bounce_paddle
	eor.w #1, d4 ; Toggle pause
	move.w d4, ram_paused
	cmp.w #1, d4
	bne @PausedStopped
	jsr Echo_PauseBGM
	; TODO: Show pause sprite
	bra @NoStartPressed
	@PausedStopped:
	jsr Echo_ResumeBGM
	; TODO: Hide pause sprite
	@NoStartPressed:

	; Skip updating if game is paused or on win/loss screen
	cmp #1, d4
	beq @GamePaused
	cmp #1, d5
	beq @GameOver

	; Run game upates
 	VDP_SetVRAMWrite vram_addr_sprite_table ; We're going to wite all our sprites each frame.

	;==============================================================
	; Manage present collisions.
	;==============================================================
	
	; Present collision check loop
	move.w #(num_presents_max-1), d3
	lea ram_present_list, a0	; Get start of present list
	@PresentCollisionLoop:
	move.w Entity_IsActive(a0), d4	; Check if the present is active
	cmp #1, d4
	bne @DonePresentCollision
	move.w Entity_PosX(a0), d4	; Get present position
	move.w Entity_PosY(a0), d5

	cmp #(player_start_pos_x-10*pos_scale_amount), d4
	blt @DonePresentCollision
	cmp #(player_start_pos_x+26*pos_scale_amount), d4
	bgt @DonePresentCollision
	cmp #(player_start_pos_y-10*pos_scale_amount), d5
	blt @DonePresentCollision
	cmp #(player_start_pos_y+26*pos_scale_amount), d5
	bgt @DonePresentCollision
	move.w #0, Entity_IsActive(a0)	; De-activate collided present
	add.w #20, ram_player_score
	AUDIO_PlaySFX content_sfx_bounce_paddle

	@DonePresentCollision:
	lea Entity_Struct_Size(a0),a0 ; Next present slot
	dbra d3, @PresentCollisionLoop

	;==============================================================
	; Manage obstacle collisions.
	;==============================================================
	move.w ram_player_collision_state, d1
	move.w ram_player_collision_timer, d3

	cmp #0, d3
	beq @NoCollisionTimer
	sub.w #1, d3
	move.w d3, ram_player_collision_timer
	@NoCollisionTimer:

	; Non collision state
	cmp #collision_state_none, d1
	bne @NoNonCollisionState
	cmp #0, d3
	bne @CollisionsDone	; Player is still immune to collisions
	
	; Collision check loop
	move.w #0, d6 ; Tracking collision
	move.w #(num_obstacles_max-1), d3
	lea ram_obstacle_list, a0	; Get start of obstacle list
	@ObstacleCollisionLoop:
	move.w Entity_IsActive(a0), d4	; Check if the obstacle is active
	cmp #1, d4
	bne @DoneObstacleCollision
	move.w Entity_TileId(a0), d4	; Check if this is a collidable tile id
	cmp #(tile_id_obstacles+5*16), d4
	bgt @DoneObstacleCollision
	move.w Entity_PosX(a0), d4	; Get obstacle position
	move.w Entity_PosY(a0), d5

	cmp #(player_start_pos_x-14*pos_scale_amount), d4
	blt @DoneObstacleCollision
	cmp #(player_start_pos_x+14*pos_scale_amount), d4
	bgt @DoneObstacleCollision
	cmp #(player_start_pos_y-16*pos_scale_amount), d5
	blt @DoneObstacleCollision
	cmp #(player_start_pos_y+10*pos_scale_amount), d5
	bgt @DoneObstacleCollision
	move.w #1, d6	; Oops, player collided
	AUDIO_PlaySFX content_sfx_bounce_wall
	bra @ObstacleCollisionLoopDone

	@DoneObstacleCollision:
	lea Entity_Struct_Size(a0),a0 ; Next obstacle slot
	dbra d3, @ObstacleCollisionLoop

	@ObstacleCollisionLoopDone:
	cmp #1, d6		; Did we collide?
	bne @CollisionsDone
	move.w #collision_state_falling, ram_player_collision_state	; Player hit an obstacle and is falling
	move.w #collision_fall_time, ram_player_collision_timer 	; Falling for a bit
	bra @StillFalling

	; Collision falling state
	@NoNonCollisionState:
	cmp #collision_state_falling, d1
	bne @NoFallingCollisionState
	cmp #0, d3
	bne @StillFalling
	move.w #collision_state_stuck, ram_player_collision_state	; Player is stuck in the snow
	move.w #collision_stuck_time, ram_player_collision_timer 	; Stuck for a bit
	AUDIO_PlaySFX content_sfx_score
	bra @StillStuck
	@StillFalling:
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x1,0x0,tile_id_santa+16
	move.w #0, d4 ; Falling southward
	move.w #(2*pos_scale_amount+pos_scale_amount/2), d5
	bra @DirDone

	; Collision stuck state
	@NoFallingCollisionState: ; collision_state_stuck
	cmp #0, d3
	bne @StillStuck
	cmp #0, ram_player_lives
	bgt @PlayerStillAlive
	move #1, ram_gameover
	SPRITE_Add d2,d3,a0,gameover_pos_x,gameover_pos_y,%1111,0x0,0x0,0x0,0x0,tile_id_gameover
	SPRITE_Add d2,d3,a0,gameover_pos_x+32,gameover_pos_y,%1111,0x0,0x0,0x0,0x0,tile_id_gameover+16
	SPRITE_Add d2,d3,a0,gameover_pos_x+64,gameover_pos_y,%1111,0x0,0x0,0x0,0x0,tile_id_gameover+32
	SPRITE_Add d2,d3,a0,gameover_pos_x+96,gameover_pos_y,%1111,0x0,0x0,0x0,0x0,tile_id_gameover+48
	bra @StillStuck
	@PlayerStillAlive:
	sub.w #1, ram_player_lives
	move.w #collision_state_none, ram_player_collision_state		; Player is unstuck
	move.w #collision_immune_time, ram_player_collision_timer 	; No collisions for a bit
	bra @CollisionsDone
	@StillStuck:
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x1,0x0,tile_id_santa+64
	move.w #0, d4 ; Not moving
	move.w #0, d5
	bra @DirDone

	@CollisionsDone:

	;==============================================================
	; Get the gamepad D-Pad input and adjust player direction
	;==============================================================
	move.w ram_player_direction, d3
	move.w d0, d1
	andi.w #(4|2|8), d1 ; mask LDR buttons

	; Left
	cmp #(4), d1
	bne @NoLeft
	;VDP_SetSprite player_start_pos_x,player_start_pos_y,%1111,0x0,0x0,0x0,0x1,0x0,tile_id_santa+32
	
	move.w #direction_west, d3
	bra @DPadDone

	; Left + Down
	@Noleft:
	cmp #(6), d1
	bne @NoLeftDown
	;VDP_SetSprite player_start_pos_x,player_start_pos_y,%1111,0x0,0x0,0x0,0x1,0x0,tile_id_santa+48
	
	move.w #direction_southwest, d3
	bra @DPadDone

	; Down
	@NoLeftDown:
	cmp #(2), d1
	bne @NoDown
	;VDP_SetSprite player_start_pos_x,player_start_pos_y,%1111,0x0,0x0,0x0,0x0,0x0,tile_id_santa
	
	move.w #direction_south, d3
	bra @DPadDone

	; Right + Down
	@NoDown:
	cmp #(0xa), d1
	bne @NoRightDown
	;VDP_SetSprite player_start_pos_x,player_start_pos_y,%1111,0x0,0x0,0x0,0x0,0x0,tile_id_santa+48
	
	move.w #direction_southeast, d3
	bra @DPadDone

	; Right
	@NoRightDown:
	cmp #(8), d1
	bne @DPadDone
	;VDP_SetSprite player_start_pos_x,player_start_pos_y,%1111,0x0,0x0,0x0,0x0,0x0,tile_id_santa+32
	
	move.w #direction_east, d3

	@DPadDone:

	move.w d3, ram_player_direction	; Store the new player direction

	;==============================================================
	; Update player position based on player direction
	;==============================================================
	move.w #0, d4
	move.w #0, d5
	
	; West
	cmp #direction_west, d3
	bne @NotWest
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x1,0x0,tile_id_santa+32
	move.w #(2*pos_scale_amount), d4
	move.w #(1*pos_scale_amount), d5
	bra @DirDone

	; South West
	@NotWest:
	cmp #direction_southwest, d3
	bne @NotSouthWest
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x1,0x0,tile_id_santa+48
	move.w #(1*pos_scale_amount), d4
	move.w #(2*pos_scale_amount), d5
	bra @DirDone

	; South
	@NotSouthWest:
	cmp #direction_south, d3
	bne @NotSouth
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x1,0x0,tile_id_santa
	move.w #(2*pos_scale_amount+pos_scale_amount/2), d5
	bra @DirDone

	; South East
	@NotSouth:
	cmp #direction_southeast, d3
	bne @NotSouthEast
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x0,0x0,tile_id_santa+48
	move.w #(-1*pos_scale_amount), d4
	move.w #(2*pos_scale_amount), d5
	bra @DirDone

	; East
	@NotSouthEast:
	cmp #direction_east, d3
	bne @DirDone
	SPRITE_Add d2,d3,a0,player_start_pos_x/pos_scale_amount,player_start_pos_y/pos_scale_amount,%1111,0x0,0x0,0x0,0x0,tile_id_santa+32
	move.w #(-2*pos_scale_amount), d4
	move.w #(1*pos_scale_amount), d5

	@DirDone:

	cmp #500, ram_player_score
	blt @DiffScale0
	cmp #1000, ram_player_score
	blt @DiffScale1
	cmp #2000, ram_player_score
	blt @DiffScale2
	cmp #5000, ram_player_score
	blt @DiffScale3

	@DiffScale4:
	add.w d4, d4   ; Increase speed by 100%
	add.w d5, d5
	bra @DiffScale0

	@DiffScale3:
	move.w d4, d6	; Increase speed by 75%
	move.w d4 ,d7
	lsr.w #1, d6
	lsr.w #2, d7
	add.w d6, d4
	add.w d7, d4
	move.w d5, d6
	move.w d5, d7
	lsr.w #1, d6
	lsr.w #2, d7
	add.w d6, d5
	add.w d7, d5
	bra @DiffScale0

	@DiffScale2:
	move.w d4, d6	; Increase speed by 50%
	lsr.w #1, d6
	add.w d6, d4
	move.w d5, d6
	lsr.w #1, d6
	add.w d6, d5
	bra @DiffScale0

	@DiffScale1:
	move.w d4, d6	; Increase speed by 25%
	lsr.w #2, d6
	add.w d6, d4
	move.w d5, d6
	lsr.w #2, d6
	add.w d6, d5

	@DiffScale0:

	; Update player position
	move.w ram_player_entity+Entity_PosX, d6
	move.w ram_player_entity+Entity_PosY, d7
	add.w d4, d6
	add.w d5, d7
	move.w d6, ram_player_entity+Entity_PosX
	move.w d7, ram_player_entity+Entity_PosY

	;==============================================================
	; Update scroll planes
	;==============================================================
	lsr.w #pos_shift_amount, d6		; Convert player position back to pixel space
	lsr.w #pos_shift_amount, d7		; Convert player position back to pixel space
	VDP_SetVRAMWrite vram_addr_hscroll
	move.w d6, vdp_data
	VDP_SetVSRAMWrite 0x0000
	move.w d7, vdp_data

	;==============================================================
	; Update player lives
	;==============================================================
	cmp  #1, ram_player_lives
	blt @LivesDone
	move.w #player_life_pos_x, d2
	move.w #player_life_pos_y, d3
	move.w #tile_id_life, d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1
	cmp #2, ram_player_lives
	blt @LivesDone
	add.w #18, d2
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1
	cmp #3, ram_player_lives
	blt @LivesDone
	add.w #18, d2
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1

	@LivesDone:

	;==============================================================
	; Update score
	;==============================================================
	move.l #0, d0
	move.w ram_player_score, d0
	move.w ram_dist_since_score, d6
	add.w d5, d6
	cmp #dist_per_point, d6
	blt @NoDistanceScore
	sub.w #dist_per_point, d6
	add.w #1, d0
	@NoDistanceScore:
	move.w d6, ram_dist_since_score
	move.w d0, ram_player_score

	move.w #score_pos_x, d2
	move.w #score_pos_y, d3
	move.l d0, d1
	;MATH_Modulo 10, d1
	divs.w #10000, d1
	muls.w #10000, d1
	sub.w d1, d0
	divs.w #10000, d1
	mulu.w #4, d1
	add.w #tile_id_numbers, d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1
	add.w #10, d2
	move.l d0, d1
	divs.w #1000, d1
	muls.w #1000, d1
	sub.w d1, d0
	divs.w #1000, d1
	mulu.w #4, d1
	add.w #tile_id_numbers, d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1
	add.w #10, d2
	move.l d0, d1
	divs.w #100, d1
	muls.w #100, d1
	sub.w d1, d0
	divs.w #100, d1
	mulu.w #4, d1
	add.w #tile_id_numbers, d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1
	add.w #10, d2
	move.l d0, d1
	divs.w #10, d1
	muls.w #10, d1
	sub.w d1, d0
	divs.w #10, d1
	mulu.w #4, d1
	add.w #tile_id_numbers, d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1
	add.w #10, d2
	mulu.w #4, d0
	add.w #tile_id_numbers, d0
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d0

	;==============================================================
	; Spawn presents
	;==============================================================
	move.w ram_dist_since_pres_spawn, d6
	add.w d5, d6

	cmp #dist_per_present, d6
	blt @DonePresentSpawn
	move.w #0, d6	; Reset distance since last present spawn
	; Time for a new present
	move.w #(num_presents_max-1), d0
	lea ram_present_list, a0	; Get start of present list
	@PresentSpawnLoop:
	move.w Entity_IsActive(a0), d1	; Check if the present is inactive
	cmp #0, d1
	bne @DonePresentActiveCheck

	move.w #1, Entity_IsActive(a0)	; Spawn new present
	move.w #(512*pos_scale_amount), Entity_PosY(a0)
	RAND d0, d1						; Randomly placed on X
	MATH_Modulo (512*pos_scale_amount), d0
	move.w d0, Entity_PosX(a0)
	RAND d0, d1						; Random present tile
	MATH_Modulo 4, d0
	mulu.w #4, d0
	addi.w #tile_id_presents, d0
	move.w d0, Entity_TileId(a0)
	bra @DonePresentSpawn

	@DonePresentActiveCheck:
	lea Entity_Struct_Size(a0),a0 ; Next present slot
	dbra d0, @PresentSpawnLoop

	@DonePresentSpawn:
	move d6, ram_dist_since_pres_spawn ; Store distance since last present spawn

	;==============================================================
	; Update presents
	;==============================================================
	move.w #(num_presents_max-1), d0
	lea ram_present_list, a0	; Get start of present list
	@PresentUpdateLoop:
	move.w Entity_IsActive(a0), d1	; Check if the present is active
	cmp #1, d1
	bne @DonePresentUpdate

	move.w Entity_PosX(a0), d2
	move.w Entity_PosY(a0), d3
	add.w d4, d2
	cmp #0, d2						; Keep X between 0-512
	blt @PresentXNotNegative
	addi.w #(512*pos_scale_amount), d2
	@PresentXNotNegative:
	MATH_Modulo (512*pos_scale_amount), d2
	sub.w d5, d3
	move.w d2, Entity_PosX(a0)
	move.w d3, Entity_PosY(a0)
	cmp #((vdp_sprite_border_y-32)*pos_scale_amount), d3	; Despawn present if it's off the top of the screen
	bgt @DonePresentDespawn
	move.w #0, Entity_IsActive(a0)

	@DonePresentDespawn:
	lsr.w #pos_shift_amount, d2	; Convert player position back to pixel space
	lsr.w #pos_shift_amount, d3	; Convert player position back to pixel space
	cmp #(0), d2				; Don't render sprites at 0 on X
	beq @DonePresentUpdate
	move.w Entity_TileId(a0), d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%0101,0x0,0x0,0x0,0x0,d1

	@DonePresentUpdate:
	lea Entity_Struct_Size(a0),a0 ; Next present slot
	dbra d0, @PresentUpdateLoop

	;==============================================================
	; Spawn obstacles
	;==============================================================
	move.w ram_dist_since_obs_spawn, d6
	add.w d5, d6

	cmp #150, ram_player_score
	blt @DiffScaleObs0
	cmp #300, ram_player_score
	blt @DiffScaleObs1
	cmp #dist_per_obstacle, d6
	blt @DoneObstacleSpawn
	bra @DiffScaleObsDone

	@DiffScaleObs1:
	cmp #(dist_per_obstacle*2), d6	; 50% as many obstacles until 300 points
	blt @DoneObstacleSpawn
	bra @DiffScaleObsDone

	@DiffScaleObs0:
	cmp #(dist_per_obstacle*4), d6	; 25% as many obstacles until 150 points
	blt @DoneObstacleSpawn

	@DiffScaleObsDone:
	; Time for a new obstacle

	move.w #0, d6	; Reset distance since last obstacle spawn

	; Get the next obstacle slot
	lea ram_obstacle_list, a0
	move.w ram_next_obstacle, d0
	mulu.w #Entity_Struct_Size, d0
	lea 0(a0,d0.w), a0

	; Increment the next obstace slot
	move.w ram_next_obstacle, d0
	addi.w #1, d0
	MATH_Modulo num_obstacles_max, d0
	move.w d0, ram_next_obstacle

	; Spawn new obstacle
	move.w #1, Entity_IsActive(a0)	
	move.w #(512*pos_scale_amount), Entity_PosY(a0)
	RAND d0, d1						; Randomly placed on X
	MATH_Modulo (512*pos_scale_amount), d0
	move.w d0, Entity_PosX(a0)
	RAND d0, d1						; Random obstacle tile
	MATH_Modulo 8, d0
	mulu.w #16, d0
	addi.w #tile_id_obstacles, d0
	move.w d0, Entity_TileId(a0)

	@DoneObstacleSpawn:
	move d6, ram_dist_since_obs_spawn ; Store distance since last obstacle spawn

	;==============================================================
	; Update obstacles
	;==============================================================
	; Get the next obstacle slot
	lea ram_obstacle_list, a0
	move.w ram_next_obstacle, d0
	mulu.w #Entity_Struct_Size, d0
	lea 0(a0,d0.w), a0

	move.w #(num_obstacles_max-1), d0
	@ObstacleUpdateLoop:
	lea -Entity_Struct_Size(a0),a0 ; Next obstacle slot
	cmpa.l #ram_obstacle_list, a0
	bge @NoObstacleLoopAround
	lea (ram_obstacle_list+Entity_Struct_Size*(num_obstacles_max-1)), a0
	@NoObstacleLoopAround:
	move.w Entity_IsActive(a0), d1	; Check if the obstacle is active
	cmp #1, d1
	bne @DoneObstacleUpdate

	move.w Entity_PosX(a0), d2
	move.w Entity_PosY(a0), d3
	add.w d4, d2
	cmp #0, d2						; Keep X between 0-512
	blt @XNotNegative
	addi.w #(512*pos_scale_amount), d2
	@XNotNegative:
	MATH_Modulo (512*pos_scale_amount), d2
	sub.w d5, d3
	move.w d2, Entity_PosX(a0)
	move.w d3, Entity_PosY(a0)
	cmp #((vdp_sprite_border_y-32)*pos_scale_amount), d3	; Despawn obstacle if it's off the top of the screen
	bgt @DoneObstacleDespawn
	move.w #0, Entity_IsActive(a0)

	@DoneObstacleDespawn:
	lsr.w #pos_shift_amount, d2	; Convert player position back to pixel space
	lsr.w #pos_shift_amount, d3	; Convert player position back to pixel space
	cmp #(0), d2				; Don't render sprites at 0 on X
	beq @DoneObstacleUpdate
	move.w Entity_TileId(a0), d1
	SPRITE_AddVarPos d6,d7,a1,d2,d3,%1111,0x0,0x0,0x0,0x0,d1

	@DoneObstacleUpdate:
	dbra d0, @ObstacleUpdateLoop

	bra @GameUpdateEnd

	@GameOver:

	@GamePaused:

	@GameUpdateEnd:

	rts
