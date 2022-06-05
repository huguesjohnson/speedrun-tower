NewGame:

	move.w	#$2700,sr ; disable interrupts

;-------------------------------------------------------------------------------
; init SRAM
;-------------------------------------------------------------------------------
	bsr.w	InitSRAM

InitCounters:
	move.w	#$0000,(MEM_VBLANK_COUNTER)
	move.w	#$0000,(MEM_MAINLOOP_COUNTER)
	move.w	#$0000,(MEM_FRAME_COUNTER)

InitGameState:
	and.l	#$00000000,d0
	bset.l	#STATE_FLAG_TITLE_SCREEN,d0 ; set title screen flag
	move.l	d0,(MEM_GAME_STATE) ; save game state
	and.w	#$0000,(MEM_DAY) ; starting day is zero
	move.w	#OBJECTIVE_00,(MEM_OBJECTIVE) ; initial objective
	and.l	#$00000000,(MEM_GLOBAL_EVENT_FLAGS) ; clear event flags
	and.l	#$00000000,(MEM_DAY_EVENT_FLAGS) ; clear event flags
	and.l	#$00000000,(MEM_SCENE_BGM) ; clear BGM
	and.w	#$0000,(MEM_CONTROL_PRESSED) ; buttons pressed
	move.w	#$FFFF,(MEM_STORY_EVENT1_SCENE_ID) ; no story events
	move.w	#$FFFF,(MEM_STORY_EVENT2_SCENE_ID) ; no story events
	move.w	#$FFFF,(MEM_OPTIONAL_EVENT1_SCENE_ID) ; no optional events
	move.w	#$FFFF,(MEM_OPTIONAL_EVENT2_SCENE_ID) ; no optional events
	move.w	#$FFFF,(MEM_OPTIONAL_EVENT3_SCENE_ID) ; no optional events
	bsr.w	ClearPlayerInventory ; clear player inventory
	;---------------------------------------------------------------------------
	; these are specific to this demo
	;---------------------------------------------------------------------------
	move.l	#$00000001,(MEM_ROOMS_VISITED)
	and.l	#$00000000,(MEM_DIALOG_EVENTS)
	and.l	#$00000000,(MEM_STORY_EVENTS)
	and.w	#$0000,(MEM_PC_ID)

;-------------------------------------------------------------------------------
; load the initial NPC locations
;-------------------------------------------------------------------------------
	bsr.w	InitNPCLocations

	move.w	#$2000,sr ; re-enable interrupts
;-------------------------------------------------------------------------------
; load the initial scene
;-------------------------------------------------------------------------------
	clr	d6
DisplayLegalScene:
	lea	SceneLegal,a6	; address of the scene for the title screen
	bsr.w	LoadScene	; branch to LoadScene subroutine
	bsr.w	FadeIn	; fade in to the intro scene
	move.w	#LEGAL_SCREEN_LOOP,d7	; use d7 for loop control
DisplayLegalSceneLoop:
	move.b	(MEM_CONTROL_6_HELD),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_Z,d6	; test if the Z button is held
	bne.w	LoadTitleScene	; Z button is held, skip scene
	bsr.w	WaitVBlank	; wait for vblank
	dbf	d7,DisplayLegalSceneLoop	; loop

LoadTitleScene:
	if _DEBUG_
	lea	SceneTitleDebug,a6	; address of the scene for the title screen
	else
	lea	SceneTitle,a6	; address of the scene for the title screen
	endif
	bsr.w	LoadScene	; branch to LoadScene subroutine
	bsr.w	FadeIn	; fade in to the intro scene

;-------------------------------------------------------------------------------
; load and setup the sprites
;-------------------------------------------------------------------------------
	move.w	#$2700,sr	; disable interrupts

; sprite zero is used on the menu screen
LoadSpriteZero:
	lea     SpriteZeroDefinition,a0	; store address of sprite definition
	moveq	#$01,d0	; 1 sprite = 2 longs
	move.l	#VDP_VRAM_WRITE_SPRITE,(VDP_CONTROL) ; set write location
LoadSpriteZeroLoop:
	move.l  (a0)+,(VDP_DATA)
	dbra    d0,LoadSpriteZeroLoop

; move sprite zero off the screen
	;---------------------------------------------------------------------------
	; update y
	;---------------------------------------------------------------------------
	move.l	#VDP_VRAM_WRITE_SPRITE,d6	; add to sprite table address
	move.l	d6,(VDP_CONTROL)	; set write location in VDP
	move.w	#0000,(VDP_DATA)	; copy the new y-coordinate
	;---------------------------------------------------------------------------
	; update x
	;---------------------------------------------------------------------------
	add.l	#$00060000,d6	; move to x-coordinate
	move.l	d6,(VDP_CONTROL)	; set write location in VDP
	move.w	#0000,(VDP_DATA)	; copy the new x-coordinate

InitPlayerSprite:
	; player	
	move.w	#$0001,(MEM_PLAYER_SPRITE_ID)	; player sprite is the 2nd entry
	move.w	#SPRITE_PLAYER_INIT_X,(MEM_PLAYER_SPRITE_X)	; starting x location
	move.w	#SPRITE_PLAYER_INIT_Y,(MEM_PLAYER_SPRITE_Y)	; starting y location
	move.w	#SPRITE_PLAYER_PATTERN,(MEM_PLAYER_SPRITE_PATTERN_INDEX) ; pattern
	move.w	#DIRECTION_DOWN,(MEM_PLAYER_SPRITE_DIRECTION)	; direction
	move.w	#$0000,(MEM_PLAYER_SPRITE_FRAME)	; frame
	; setting SPRITE_STEP_COUNTER to SPRITE_ANIMATION_STEPS forces movement
	; animation to trigger the next time the sprite moves
	move.w	#SPRITE_ANIMATION_STEPS,(MEM_PLAYER_SPRITE_STEP_COUNTER)

	move.w	#$2000,sr		; re-enable interrupts
