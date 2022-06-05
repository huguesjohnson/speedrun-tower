ProcessTitleScreen:
TestTitleScreenTestStartPressed:
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_START,d6	; test if the start button was pressed
	beq.w	ExitProcessTitleScreen
	; clear MEM_CONTROL_PRESSED to prevent entering pause state immediately
	move.w	#$0000,(MEM_CONTROL_PRESSED)
	; --------------------------------------------------------------------------
	; start button was pressed on the title screen
	; --------------------------------------------------------------------------
	move.w	(MEM_VBLANK_COUNTER),(MEM_RANDOM_1) ; save the 1st "random" number
	bclr.l	#STATE_FLAG_TITLE_SCREEN,d7 ; clear game state flag
	tst.w	(MEM_MENU_SELECTION)	; which item was selected?
TestTitleLoadNewGame:
	bset.l	#STATE_FLAG_CHARACTER_SELECT_SCREEN,d7 ; set intro screen flag
	move.l	d7,(MEM_GAME_STATE)	; save updated game state
	lea	SceneCharacterSelect,a6	; address of the scene for the char select screen
	bsr.w	LoadScene ; branch to LoadScene subroutine
	bsr.w	BuildCharacterSelectScreen ; build text or whatever
	bsr.w	FadeIn ; fade in to the new scene
ExitProcessTitleScreen:
	rts

