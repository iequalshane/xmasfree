;==============================================================
; General utility function and macros
;==============================================================

;==============================================================
; Structure Macros
;==============================================================

RS_ALIGN: macro
	if __RS&1
	rs.b 1
	endc
	endm

STRUCT_BEGIN: macro name
__STRUCT_NAME equs "\name\"
	rsset 0
	endm

STRUCT_INHERIT: macro name,parent
__STRUCT_NAME equs "\name\"
	rsset \parent\_Struct_Size
	endm

STRUCT_MEMBER: macro name,size,count
\__STRUCT_NAME\_\name rs.\size \count
	endm

STRUCT_END: macro
	RS_ALIGN
\__STRUCT_NAME\_Struct_Size rs.b 0
	endm

;==============================================================
; Random macro
;==============================================================
ram_rndseed	rs.l 1
ram_rndnum 	rs.w 3

RAND: macro reg0,reg1
	move.l	ram_rndseed,\reg1
	move.w	ram_rndnum,\reg0
	rol.l	#1,\reg1
	eor.w	\reg0,\reg1
	swap	\reg1
	eor.w	\reg1,\reg0
	rol.w	#1,\reg0
	eor.w	\reg0,\reg1
	swap	\reg1
	eor.w	\reg1,\reg0
	move.w	\reg0,ram_rndnum
	move.l	\reg1,ram_rndseed
	endm