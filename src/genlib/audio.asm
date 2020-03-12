;==============================================================
; Z80 Echo library for audio
;==============================================================
	include "external/echo/echo.68k"

;==============================================================
; AUDIO FUNCTIONS
;==============================================================

; Initializes the 
AUDIO_Init: macro
	lea	(EchoList), a0       ; Initialize Echo
    bsr	Echo_Init
    endm

AUDIO_PlaySFX: macro SFX_Addr
	lea     (SFX_Addr), a0
    bsr     Echo_PlaySFX
    endm

AUDIO_PlayBGM: macro BGM_Addr
	lea (BGM_Addr), a0
    bsr Echo_PlayBGM
    endm
