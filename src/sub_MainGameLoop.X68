;*******************************************************************************
; main game loop
;*******************************************************************************
MainGameLoop:
	bsr.w	WaitVBlank ; wait for vblank to complete
	addq	#$1,(MEM_MAINLOOP_COUNTER) ; increment counter
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
;-------------------------------------------------------------------------------
; title screen
;-------------------------------------------------------------------------------
TestTitleScreen:
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	btst.l	#STATE_FLAG_TITLE_SCREEN,d7 ; test game state
	beq.s	TestDebugMenu ; not on the title screen, move to next test
	bsr.w	ProcessTitleScreen ; process the title screen
	bra.w	MainGameLoop ; return to start of game loop	
;-------------------------------------------------------------------------------
; debug menu
;-------------------------------------------------------------------------------
TestDebugMenu:
	if _DEBUG_
	btst.l	#STATE_FLAG_DEBUG_MENU,d7 ; test game state
	beq.s	TestSelectCharacterScreen ; move to next test
	bsr.w	ProcessDebugScreen
	bra.w	MainGameLoop ; return to start of game loop
	endif
;-------------------------------------------------------------------------------
; select character screen
;-------------------------------------------------------------------------------
TestSelectCharacterScreen:
	btst.l	#STATE_FLAG_CHARACTER_SELECT_SCREEN,d7 ; test game state
	beq.w	TestIntroScreen ; not on the intro screen, move to next test
	bsr.w	ProcessCharacterSelectScreen ; process screen
	bra.w	MainGameLoop ; return to start of game loop	
;-------------------------------------------------------------------------------
; day intro screen
;-------------------------------------------------------------------------------
TestIntroScreen:
	btst.l	#STATE_FLAG_INTRO_SCREEN,d7 ; test game state
	beq.w	TestEndScreen ; not on the intro screen, move to next test
	bsr.w	ProcessIntroScreen ; process intro screen
	bra.w	MainGameLoop ; return to start of game loop	
;-------------------------------------------------------------------------------
; end screen
;-------------------------------------------------------------------------------
TestEndScreen:
	btst.l	#STATE_FLAG_END_SCREEN,d7 ; test game state
	beq.s	TestPauseToggle	; not on the end screen, move to next test
	; no separate subroutine since the logic here is short
TestEndScreenTestStartPressed:
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6
	andi.b	#BUTTON_START,d6 ; test if the start button was pressed
	beq.w	MainGameLoop ; start button not pressed, loop
	; --------------------------------------------------------------------------
	; start button was pressed on the end screen - loop back to the beginning
	; --------------------------------------------------------------------------
	; clear MEM_CONTROL_PRESSED to prevent entering pause state immediately
	move.w	#$0000,(MEM_CONTROL_PRESSED)
EndScreenRestart:
	bra.w	NewGame	; restart
;-------------------------------------------------------------------------------
; pause/unpause
; -this is first because every game state from here on out can be paused
; -none of the screens tested before this can be paused
;-------------------------------------------------------------------------------
TestPauseToggle:
	; ---------------------------------------------------------
	; this test should never fail unless I did something bad
	; ---------------------------------------------------------
	btst.l	#STATE_FLAG_EXPLORING,d7 ; test game state
	beq.w	MainGameLoop ; start over
	;move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_START,d6	; test if the start button was pressed
	beq.s	TestPause	; start button is not pressed test if still paused
	; clear MEM_CONTROL_PRESSED to prevent pause state from flipping in loop
	move.w	#$0000,(MEM_CONTROL_PRESSED)
	btst.l	#STATE_FLAG_PAUSED,d7	; is the paused bit set?
	bne.s	Unpause	; if so branch to unpause 
Pause:
	bset.l	#STATE_FLAG_PAUSED,d7	; set the paused bit
	; flip to paused palette
	jsr	Echo_StopBGM	; pause the background music
SetPausedPalette:
	bsr.w	WaitVBlank	; wait to load palettes until VBlank
	lea	(MEM_SCENE_PALETTE),a0	; point a0 to the scene palette
	move.l	#VDP_CRAM_WRITE,(VDP_CONTROL) ; set up VDP write to CRAM
	moveq	#$003F,d0	; 64 words of palette data
SetPausedPaletteLoop:
	move.w	(a0)+,d1	; get the next palette entry
	lsr	#1,d1	; shift color intensity
	;	      0000BBBSGGGSRRRS
	and.w	#%0000011001100110,d1	; prevent color overflow
	move.w	d1,(VDP_DATA)	; write the palette entry
	dbf	d0,SetPausedPaletteLoop	; decrement d0 and loop
	bra.s	UpdatePause	; save the paused state
Unpause:
	bclr.l	#STATE_FLAG_PAUSED,d7	; clear the paused bit
	jsr	Echo_ResumeBGM	; unpause the background music
	bsr.w	WaitVBlank	; wait to load palettes until VBlank
	lea	(MEM_SCENE_PALETTE),a0	; point to scene palette
	moveq	#$0004,d0	; number of palettes to load
	move.l	#VDP_CRAM_WRITE,d1	; initial write address
	bsr.w	LoadPalettes	; branch to LoadPalettes subroutine
	move.w	#$0000,(MEM_FRAME_COUNTER)	; reset frame counter
UpdatePause:
	move.l	d7,(MEM_GAME_STATE)	; save the new paused state
TestPause:
	btst.l	#STATE_FLAG_PAUSED,d7	; test if paused
	beq.s	TestAction	; not paused, move to next test
	bra.w	MainGameLoop	; paused, return to start of game loop
;-------------------------------------------------------------------------------
; determine if there is an action queued
;-------------------------------------------------------------------------------
TestAction:
	btst.l	#STATE_FLAG_ACTION,d7 ; test game state
	beq.w	TestScriptedEvent	; no action queued, move to next test
	bsr.w	ProcessAction	; process the pending action
	;---------------------------------------------------------------------------
	; setup action event for entering a scene if appropriate
	; there's one catch to this implementation..
	; if the player tries to leave a scene but is blocked this event will fire
	;---------------------------------------------------------------------------
	cmpi.w	#ACTION_EXIT_SCENE,(MEM_ACTION_ID) ; test if last action was exiting
	bne.w	MainGameLoop ; if not then back to the start of the game loop
	move.w	(MEM_ACTIVE_SCENE_ID),d7 ; copy current scene id to d7
	cmpi.w	#MAX_SCENE_ID,d7 ; check against my own stupidity
	bgt.w	MainGameLoop ; if not then back to the start of the game loop
	move.l	(MEM_GAME_STATE),d7 ; copy game state to d7
	bset.l	#STATE_FLAG_ACTION,d7 ; set the action flag
	move.l	d7,(MEM_GAME_STATE) ; save it back
	move.w	#ACTION_ENTER_SCENE,(MEM_ACTION_ID) ; set the action id
	bra.w	MainGameLoop ; return to start of game loop
;-------------------------------------------------------------------------------
; determine if there is a scripted event to process
;-------------------------------------------------------------------------------
TestScriptedEvent:
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	btst.l	#STATE_FLAG_SCRIPTED_EVENT,d7 ; test game state
	beq.w	TestDialog	; not in a scripted event, move to next test
	btst.l	#STATE_FLAG_DIALOG,d7 ; test if we need to wait for a dialog
	bne.w	TestDialogUpdateFrequency	; wait for dialog interaction to finish
	;---------------------------------------------------------------------------
	; dialog is not displaying - process next scripted event
	;---------------------------------------------------------------------------
	bsr.w	ProcessScriptedEvent
	bra.w	MainGameLoop
;-------------------------------------------------------------------------------
; determine if the player is opening or interacting with a dialog
;-------------------------------------------------------------------------------
TestDialog:
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	btst.l	#STATE_FLAG_DIALOG,d7 ; test game state
	beq.w	TestStatusScreen	; dialog not displaying, move to next test
TestDialogUpdateFrequency:
	move.b	(MEM_CONTROL_6_HELD),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_Z,d6	; test if the Z button is held
	bne.s	.1	; Z button is held, skip test
	cmpi.w	#DIALOG_UPDATE_FREQUENCY,(MEM_FRAME_COUNTER); is it time to update?
	blt.s	TestDialogOpen	; branch if it's not time to move
	; how would this test ever be different than the previous one?
	; what was I thinking here? commenting out for now
	;blt.w	MainGameLoop	; branch if it's not time to move
.1	
	move.w	#$0000,(MEM_FRAME_COUNTER)	; reset counter to 0	
	bsr.w	ProcessDialog	; dialog is set, jump to process dialog sub-routine
	bra.w	MainGameLoop	; return to start of game loop
TestDialogOpen:
	; if the dialog is open then update frequency is ignored
	move.l	(MEM_DIALOG_FLAGS),d7	; copy current game state to d7
	btst.l	#DIALOG_FLAG_TEXT_OPEN,d7 ; test if the dialog is open
	beq.w	MainGameLoop	; dialog is not open, move to next test
	; else branch to process dialog
	bsr.w	ProcessDialog	; dialog is set, jump to process dialog sub-routine
	bra.w	MainGameLoop	; return to start of game loop
;-------------------------------------------------------------------------------
; determine if the player is on the status screen
;-------------------------------------------------------------------------------
TestStatusScreen:
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	btst.l	#STATE_FLAG_STATUS_SCREEN,d7 ; test game state
	beq.s	TestExploring	; not in status screen, move to next test
	;---------------------------------------------------------------------------
	; player is on the status screen
	;---------------------------------------------------------------------------
	bsr.w	ProcessStatusScreen	; branch to process the status screen
	move.w	#$0000,(MEM_FRAME_COUNTER)	; reset frame counter
	bra.w	MainGameLoop	; return to start of game loop
;-------------------------------------------------------------------------------
; determine if the player is in free exploration mode
; there "shouldn't" be a way to reach here unless that's the case
;-------------------------------------------------------------------------------
TestExploring:
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	btst.l	#STATE_FLAG_EXPLORING,d7	; test game state
	beq.w	MainGameLoopEnd	; not exploring, branch
TestCButtonPressed:	; test if the player pressed the C button
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_C,d6	; test if the C button was pressed
	beq.w	TestAButtonPressed	; C button is not pressed
	; start loading the status screen
	move.w	#MENU_PAGE_STATUS,(MEM_MENU_SCREEN_PAGE)
	lea	SceneMenuStatus,a6	; address of the scene for the map screen
	adda.l	#$2,a6	; skip scene id before branching to DrawScene
	bsr.w	DrawScene	; branch to subroutine to draw the scene
	bsr.w	BuildStatusScreen	; build the status screen
	bsr.w	FadeIn	; fade in the status screen
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_STATUS_SCREEN,d7	; update game state
	move.l	d7,(MEM_GAME_STATE)	; save updated game state
	bra.w	MainGameLoop	; go back the start of the game loop
TestAButtonPressed: ; test if the player pressed the A button
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_A,d6	; test if the A button was pressed
	beq.w	MainGameLoopUpdateSprites	; A button is not pressed
	;---------------------------------------------------------------------------
	; build event table address and branch to code
	;---------------------------------------------------------------------------
	; clear MEM_CONTROL_PRESSED to prevent state from flipping in loop
	move.w	#$0000,(MEM_CONTROL_PRESSED)
	lea	MEM_PLAYER_SPRITE_ID,a6	; point a6 to player sprite
	bsr.w	StopSprite ; stop the player sprite
	bsr.w	BuildNPCObjectList	; update the location of NPCs
	bsr.w	FindActionTarget	; find the target of the player's action
	cmpi.w	#OBJ_NOTHING,(MEM_ACTION_TARGET_OBJID)	; is the target nothing?
	beq.s	NoActionTarget	; branch if no target
	; queue the event	
	move.w	#ACTION_INTERACT,(MEM_ACTION_ID)
	move.l	(MEM_GAME_STATE),d7	; copy game state to d7
	bset.l	#STATE_FLAG_ACTION,d7	; set the action flag
	move.l	d7,(MEM_GAME_STATE)	; save it back
	bra.w	MainGameLoop	; return to start of game loop
NoActionTarget: 	; if target is 0 then display the default message
	lea	DialogTextNothing,a6	; load default text
	move.l	a6,MEM_DIALOG_TEXT	; copy address to MEM_DIALOG_TEXT
	bsr.w	SetDialogOpening	; set dialog state to opening
	bra.w	MainGameLoop	; return to start of game loop
;-------------------------------------------------------------------------------
; determine if sprites need to be moved and move them
;-------------------------------------------------------------------------------
MainGameLoopUpdateSprites:
	; if Z button is held then skip the test
	move.b	(MEM_CONTROL_6_HELD),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_Z,d6	; test if the Z button is held
	bne.s	.1	; Z button is held, skip test
	; test if it's time to move sprites
	cmpi.w	#SPRITE_MOVE_FREQUENCY,(MEM_FRAME_COUNTER); is it time to move?
	blt.w	MainGameLoopEnd	; exit if it's not time to move
.1
	; move the player sprite
	move.w	#$0000,(MEM_FRAME_COUNTER)	; reset counter to 0
	bsr.w	MovePlayer	; move the player sprite
	; move NPCs
	tst.w	(MEM_ACTIVE_NPC_COUNT)	; are there any NPCs to move?
	beq.w	MainGameLoop	; return to start of game loop if no NPCs
	move.w	(MEM_ACTIVE_NPC_COUNT),(MEM_NPC_LOOP_COUNTER)	; setup loop control
	lea	MEM_NPC0_SPRITE_ID,a5	; point to first NPC
MainGameLoopUpdateNPCSpritesLoop:
	; if STRUCT_SPRITE_MOVE_FREQUENCY = $FFFF then don't move the sprite
	cmpi.w	#$FFFF,(STRUCT_SPRITE_MOVE_FREQUENCY,a5)	; test
	beq.s	MainGameLoopUpdateNPCSpritesLoopEnd	; branch if equal
	cmpi.w	#$0000,(STRUCT_SPRITE_MOVEMENT_COUNTER,a5)	; is the NPC moving?
	bne	.2	; if MOVEMENT_COUNTER > 0 then the sprite is moving
	; test if it's time for them to move again
	move.w	(MEM_VBLANK_COUNTER),d6	; copy vblank counter
	and.w	(STRUCT_SPRITE_MOVE_FREQUENCY,a5),d6	; and against it
	cmp.w	(STRUCT_SPRITE_MOVE_FREQUENCY,a5),d6	; test 
	bne.s	MainGameLoopUpdateNPCSpritesLoopEnd ; not time to move
	move.w	#NPC_SPRITE_MOVE_STEPS,(STRUCT_SPRITE_MOVEMENT_COUNTER,a5)	; reset
	; set the direction
	addq	#$2,(STRUCT_SPRITE_MOVE_INDEX,a5)	; increment index of movement
	move.w	(STRUCT_SPRITE_MOVE_PATTERN_LENGTH,a5),d6
	cmp.w	(STRUCT_SPRITE_MOVE_INDEX,a5),d6	; end of the array?
	bge.s	.1	; not at the end of the array
	move.w	#$0000,(STRUCT_SPRITE_MOVE_INDEX,a5)	; reset to zero
.1
	move.l	(STRUCT_SPRITE_MOVE_PATTERN,a5),a6
	adda	(STRUCT_SPRITE_MOVE_INDEX,a5),a6
	move.w	(a6),(STRUCT_SPRITE_DIRECTION,a5)
.2	; decrement NPC movement counter and test if they should stop moving
	subq	#$0001,(STRUCT_SPRITE_MOVEMENT_COUNTER,a5)	; decrement counter
	bne	.3	; if MOVEMENT_COUNTER=0 now then we need to stop the sprite
	move.l a5,a6	; setup call to StopSprite
	bsr.w	StopSprite ; stop the sprite
	bra.s	MainGameLoopUpdateNPCSpritesLoopEnd ; done updating this sprite
.3	; move the NPC sprite
	move.l a5,a6	; setup call to MoveSprite
	bsr.w	MoveSprite	; branch to move MoveSprite
	; did the sprite move successfully?
	tst.w	(MEM_COLLISION_RESULT)	; test result of last collision
	beq.s	MainGameLoopUpdateNPCSpritesLoopEnd ; done updating this sprite	
	addq	#$0001,(STRUCT_SPRITE_MOVEMENT_COUNTER,a5)	; rollback counter
MainGameLoopUpdateNPCSpritesLoopEnd:
	; move to next NPC sprite
	adda.l	#NPC_RECORD_SIZE,a5	; increment a5	
	; apparently dbra doesn't work against a memory address
	subq	#$1,(MEM_NPC_LOOP_COUNTER)	; decrement loop counter
	bgt.w	MainGameLoopUpdateNPCSpritesLoop	; branch
	; done looping through NPC sprites
MainGameLoopEnd:
	bra.w	MainGameLoop	; return to start of game loop

