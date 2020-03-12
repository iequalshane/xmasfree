;==============================================================
; All game content goes here. Be aware of data alignment.
;==============================================================

;==============================================================
; Sound FX and Music
;==============================================================
	include "src/xmasfree/audio/instru.asm"		; Instruments for sound and music

; Sound Effects
content_sfx_bounce_wall:
    dc.b    $EA,$1A,$4A,$01,$2A,$04 ; Lock PSG Ch3; Note Off PSG Ch3; Set Instr PSG Chn3; Set Vol PSG Chn3
    dc.b    $0A,1*36,$FE,2 ; Note on PSG channel #3 ; Delay ticks
    dc.b    $FF, $FF ; Stop playback
    even

content_sfx_bounce_paddle:
    dc.b    $EA,$1A,$4A,$01,$2A,$04 ; Lock PSG Ch3; Note Off PSG Ch3; Set Instr PSG Chn3; Set Vol PSG Chn3
    dc.b    $0A,2*36,$FE,2 ; Note on PSG channel #3 ; Delay ticks
    dc.b    $FF, $FF ; Stop playback
    even

content_sfx_score:
    dc.b    $EA,$1A,$4A,$01,$2A,$04 ; Lock PSG Ch3; Note Off PSG Ch3; Set Instr PSG Chn3; Set Vol PSG Chn3
    dc.b    $0A,1*48,$FE,4 ; Note on PSG channel #3 ; Delay ticks
    dc.b    $FF, $FF ; Stop playback
    even

; Background music
content_bgm_music:
	include  "src/xmasfree/audio/jingle.asm"
    even
;==============================================================
; The sprite graphics tiles.
;==============================================================

content_tiles:
	include "src/shared/tiles/shane.asm"		; Shane logo from intro
	include "src/xmasfree/tiles/paused.asm"		; Text shown when game is paused
    include "src/xmasfree/tiles/snow.asm"
    include "src/xmasfree/tiles/santa.asm"
    include "src/xmasfree/tiles/obst.asm"
    include "src/xmasfree/tiles/presents.asm"
    include "src/xmasfree/tiles/numbers.asm"
    include "src/xmasfree/tiles/life.asm"
    include "src/xmasfree/tiles/gameover.asm"

;==============================================================
; Map data for scroll planes.
;==============================================================
content_maps:
 	include "src/shared/maps/shanemap.asm"	; Map for Plane A for Shane logo in intro
