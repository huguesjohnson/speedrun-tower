ProcessAction:
; not 100% if this is always needed now or just for respond events
; re-add this later if something goofy happens
;ProcessActionResetDialog:
;	bsr.w	ResetDialog	; reset the dialog
	; if the target is an NPC - the resulting dialog should be titled
	move.w	(MEM_ACTION_TARGET_OBJID),d7	; copy action target to d7
	andi.w	#OBJ_NPC_BASE,d7	; and against base npc ID
	beq.s	ProcessActionBuildActionTableOffset	; target is not an NPC
	;---------------------------------------------------------------------------
	; interacting with a character
	;---------------------------------------------------------------------------
	; have the NPC face the player
	move.w (MEM_ACTION_TARGET_NPCID),d7	; copy NPC target ID to d7
	cmpi.w	#$FFFF,d7	; test if it is -1
	beq.s	ProcessActionBuildActionTableOffset	; skip if -1
	lea	MEM_NPC0_SPRITE_ID,a6	; point a6 to the first NPC sprite
	move.w	(MEM_ACTION_TARGET_NPCID),d6	; copy target NPC id to d6
	mulu.w	#NPC_RECORD_SIZE,d6	; multiply by NPC_RECORD_SIZE to get offset
	adda.l	d6,a6	; move to target NPC sprite
	; save current NPC direction
	move.w	(STRUCT_SPRITE_DIRECTION,a6),(MEM_ACTION_TARGET_NPC_DIRECTION)
	; copy player direction to NPC direction
	move.w	(MEM_PLAYER_SPRITE_DIRECTION),(STRUCT_SPRITE_DIRECTION,a6)
	; flip the last bit to reverse direction
	eor.w	#$0001,(STRUCT_SPRITE_DIRECTION,a6)
	bsr.w	StopSprite	; stop moving the sprite
ProcessActionBuildActionTableOffset:
	bsr.w	BuildActionTableOffset	; build action table offset
	; determine which action table to use	
	lea	ActionTableStart,a5 ; to action table (night)
	adda.w	(MEM_ACTION_TABLE_OFFSET),a5	; move to offset location
	move.l	(a5),a6	; a5 has the address of the subroutine to jump to
	jsr	(a6)	; jump to location of code to process this event
	;---------------------------------------------------------------------------
	; returning from the action
	; if the dialog is now titled style then some extra setup is needed
	;---------------------------------------------------------------------------
	; to do - determine what (if anything) still needs to be done here now 
	; this is the code from Retail Clerk '89 which may not apply now
	;move.l	(MEM_DIALOG_FLAGS),d7	; copy flags to d7
	;btst.l	#DIALOG_FLAG_STYLE_TITLED,d7	; test if flag is set
	;beq.s	ExitProcessAction
	;bset.l	#DIALOG_FLAG_TEXT_TITLE_DRAWING,d7	; change state to title drawing
	;move.l	d7,(MEM_DIALOG_FLAGS)	; save updated flags
	;bsr.w	ClearDialog	; clear the dialog
	;move.l	#(VDP_VRAM_WRITE_A+DIALOG_TITLE_ROWCOL),(MEM_DIALOG_VDP)
	;bsr.w	ProcessDialogLookupNPCName	; lookup the NPC name

ExitProcessAction:
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bclr.l	#STATE_FLAG_ACTION,d7 ; clear action flag
	move.l	d7,(MEM_GAME_STATE)	; save it back
	rts
