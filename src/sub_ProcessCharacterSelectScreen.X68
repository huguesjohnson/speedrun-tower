ProcessCharacterSelectScreen:
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6
	beq.w	ExitProcessCharacterSelectScreen ; exit if nothing pressed	
	andi.b	#BUTTON_START,d6 ; test if the start button was pressed
	bne.w	ProcessCharacterSelectScreenStartPressed
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6
	andi.b	#BUTTON_LEFT,d6 ; test if the left button was pressed
	bne.w	ProcessCharacterSelectScreenLeftPressed
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6
	andi.b	#BUTTON_RIGHT,d6 ; test if the right button was pressed
	bne.w	ProcessCharacterSelectScreenRightPressed
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6	
	andi.b	#BUTTON_UP,d6 ; test if the up button was pressed
	bne.w	ProcessCharacterSelectScreenUpPressed
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6
	andi.b	#BUTTON_DOWN,d6 ; test if the down button was pressed
	bne.w	ProcessCharacterSelectScreenDownPressed
	; reached if some other button was pressed
	bra.w	ExitProcessCharacterSelectScreen
ProcessCharacterSelectScreenLeftPressed:	
	move.w	(MEM_PC_ID),d7 ; copy current PC ID to D7
	cmpi.w	#$0000,d7
	beq.s	.leftzero
	cmpi.w	#$0004,d7
	beq.s	.leftfour
	sub.w	#$0001,d7
	bra.w	ProcessCharacterSelectScreenUpdateSelectorXY
.leftzero
	move.w	#$0003,d7
	bra.w	ProcessCharacterSelectScreenUpdateSelectorXY
.leftfour	
	move.w	#$0007,d7
	bra.w	ProcessCharacterSelectScreenUpdateSelectorXY
ProcessCharacterSelectScreenRightPressed:
	move.w	(MEM_PC_ID),d7 ; copy current PC ID to D7
	cmpi.w	#$0003,d7
	beq.s	.rightthree
	cmpi.w	#$0007,d7
	beq.s	.rightseven
	add.w	#$0001,d7
	bra.w	ProcessCharacterSelectScreenUpdateSelectorXY
.rightthree
	move.w	#$0000,d7
	bra.w	ProcessCharacterSelectScreenUpdateSelectorXY
.rightseven
	move.w	#$0004,d7
	bra.w	ProcessCharacterSelectScreenUpdateSelectorXY
ProcessCharacterSelectScreenUpPressed:
ProcessCharacterSelectScreenDownPressed:
	move.w	(MEM_PC_ID),d7 ; copy current PC ID to D7
	cmpi.w	#$0003,d7
	bgt.s	.gtthree
	add.w	#$0004,d7
	bra.s	ProcessCharacterSelectScreenUpdateSelectorXY
.gtthree
	sub.w	#$0004,d7
ProcessCharacterSelectScreenUpdateSelectorXY:
	move.w	d7,(MEM_PC_ID) ; save the new value
	lea	CharacterSelectMenuLocationTable,a6	; point a6 to the lookup table for the menu	
	;---------------------------------------------------------------------------
	; move the selector to the right position in the menu
	;---------------------------------------------------------------------------
	mulu.w	#LWORD_SIZE,d7 ; multiply by LWORD_SIZE to get offset
	adda.l	d7,a6 ; move to offset
	;---------------------------------------------------------------------------
	; update y
	;---------------------------------------------------------------------------
	move.l	#VDP_VRAM_WRITE_SPRITE,d6 ; add to sprite table address
	move.l	d6,(VDP_CONTROL) ; set write location in VDP
	move.w	(a6)+,(VDP_DATA) ; copy the new y-coordinate
	;---------------------------------------------------------------------------
	; update x
	;---------------------------------------------------------------------------
	add.l	#$00060000,d6 ; move to x-coordinate
	move.l	d6,(VDP_CONTROL) ; set write location in VDP
	move.w	(a6),(VDP_DATA) ; copy the new x-coordinate	
	bra.s	ExitProcessCharacterSelectScreen
ProcessCharacterSelectScreenStartPressed:
	; clear MEM_CONTROL_PRESSED to prevent entering pause state immediately
	move.w	#$0000,(MEM_CONTROL_PRESSED)
	; --------------------------------------------------------------------------
	; start button was pressed on the character select screen
	; --------------------------------------------------------------------------
	move.w	(MEM_VBLANK_COUNTER),(MEM_RANDOM_3) ; save the 3rd "random" number
	bclr.l	#STATE_FLAG_CHARACTER_SELECT_SCREEN,d7 ; clear game state flag
	bset.l	#STATE_FLAG_INTRO_SCREEN,d7 ; set intro screen flag
	move.l	d7,(MEM_GAME_STATE)	; save updated game state
	lea	SceneIntro00,a6	; address of the scene for the intro screen
	bsr.w	LoadScene	; branch to LoadScene subroutine
	bsr.w	FadeIn	; fade in to the new scene
ExitProcessCharacterSelectScreen:
	rts
