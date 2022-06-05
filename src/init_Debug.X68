	if	_DEBUG_

; 54 possible options
DebugTable:
	dc.l	LaunchDebug00
	dc.l	LaunchDebug01
	dc.l	LaunchDebug02
	dc.l	LaunchDebug03
	dc.l	LaunchDebug04
	dc.l	LaunchDebug05
	dc.l	LaunchDebug06
	dc.l	LaunchDebug07
	dc.l	LaunchDebug08
	dc.l	LaunchDebug09
	dc.l	LaunchDebug10
	dc.l	LaunchDebug11
	dc.l	LaunchDebug12
	dc.l	LaunchDebug13
	dc.l	LaunchDebug14
	dc.l	LaunchDebug15
	dc.l	LaunchDebug16
	dc.l	LaunchDebug17
	dc.l	LaunchDebug18
	dc.l	LaunchDebug19
	dc.l	LaunchDebug20
	dc.l	LaunchDebug21
	dc.l	LaunchDebug22
	dc.l	LaunchDebug23
	dc.l	LaunchDebug24
	dc.l	LaunchDebug25
	dc.l	LaunchDebug26
	dc.l	LaunchDebug27
	dc.l	LaunchDebug28
	dc.l	LaunchDebug29
	dc.l	LaunchDebug30
	dc.l	LaunchDebug31
	dc.l	LaunchDebug32	
	dc.l	LaunchDebug33
	dc.l	LaunchDebug34
	dc.l	LaunchDebug35	
	dc.l	LaunchDebug36
	dc.l	LaunchDebug37	
	dc.l	LaunchDebug38
	dc.l	LaunchDebug39
	dc.l	LaunchDebug40	
	dc.l	LaunchDebug41
	dc.l	LaunchDebug42
	dc.l	LaunchDebug43
	dc.l	LaunchDebug44
	dc.l	LaunchDebug45
	dc.l	LaunchDebug46
	dc.l	LaunchDebug47
	dc.l	LaunchDebug48
	dc.l	LaunchDebug49
	dc.l	LaunchDebug50
	dc.l	LaunchDebug51
	dc.l	LaunchDebug52
	dc.l	LaunchDebug53

ProcessDebugScreen:
	; process start press
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_START,d6	; test if the start button was pressed
	beq.s	ProcessDebugScreenTestDpad	; start not pressed, branch
	lea	DebugTable,a5	; point to the table
	move.w	(MEM_MENU_SELECTION),d7	; copy scene ID to d7
	mulu.w	#LWORD_SIZE,d7	; multiply by lword size to get offset
	adda.w	d7,a5	; move to offset location
	move.w	#$0000,(MEM_MENU_SELECTION)	; clear menu selection
	; clear debug flag	
	move.l	(MEM_GAME_STATE),d7	; copy game state to d7
	bclr.l	#STATE_FLAG_DEBUG_MENU,d7 ; set debug menu flag
	move.l	d7,(MEM_GAME_STATE)	; save updated game state
	move.l	(a5),a6	; a5 has the address of the subroutine to jump to
	jsr	(a6)	; jump to location of code to process this event
	bra.w	ExitProcessDebugScreen	; exit
ProcessDebugScreenTestDpad:
	; process dpad press
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_UP,d6	; test if the up button was pressed
	bne.s	ProcessDebugScreenDecrementSelector	; up pressed, branch
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_DOWN,d6	; test if the down button was pressed
	bne.s	ProcessDebugScreenIncrementSelector	; down pressed, branch
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_LEFT,d6	; test if the left button was pressed
	bne.s	ProcessDebugScreenLeftRight	; left pressed, branch
	move.b	(MEM_CONTROL_PRESSED),d6	; copy pressed buttons to d6
	andi.b	#BUTTON_RIGHT,d6	; test if the right button was pressed
	bne.s	ProcessDebugScreenLeftRight	; right pressed, branch
	bra.w	ProcessDebugScreenMoveSelector
ProcessDebugScreenIncrementSelector:
	cmpi.w	#$001A,(MEM_MENU_SELECTION)
	bne.s	.1
	move.w	#$0000,(MEM_MENU_SELECTION)
	bra.w	ProcessDebugScreenMoveSelector
.1
	add.w	#$0001,(MEM_MENU_SELECTION)
	bra.w	ProcessDebugScreenMoveSelector
ProcessDebugScreenDecrementSelector:
	cmpi.w	#$0000,(MEM_MENU_SELECTION)
	bne.s	.1
	move.w	#$001A,(MEM_MENU_SELECTION)
	bra.w	ProcessDebugScreenMoveSelector
.1
	sub.w	#$0001,(MEM_MENU_SELECTION)
	bra.w	ProcessDebugScreenMoveSelector
ProcessDebugScreenLeftRight:
	cmpi.w	#$001A,(MEM_MENU_SELECTION)
	bgt.s	.1
	add.w	#$001B,(MEM_MENU_SELECTION)
	bra.w	ProcessDebugScreenMoveSelector
.1
	sub.w	#$001B,(MEM_MENU_SELECTION)
	bra.w	ProcessDebugScreenMoveSelector
ProcessDebugScreenMoveSelector:
	; move selector sprite based on menu selection
	move.w	(MEM_MENU_SELECTION),d7	; copy current value to d7
	cmpi.w	#$001B,d7
	blt.s	.1
	sub.w	#$001B,d7
.1
	mulu.w	#$0008,d7	; rows are 8 apart
	add.w	#$0088,d7	; first row is 128
	move.l	#VDP_VRAM_WRITE_SPRITE,d6	; add to sprite table address
	move.l	d6,(VDP_CONTROL)	; set write location in VDP
	move.w	d7,(VDP_DATA)	; copy the new y-coordinate
	add.l	#$00060000,d6	; move to x-coordinate
	move.l	d6,(VDP_CONTROL)	; set write location in VDP
	cmpi.w	#$001B,(MEM_MENU_SELECTION)
	blt.s	.2
	move.w	#$0120,(VDP_DATA)	; copy the new x-coordinate
	bra.s	ExitProcessDebugScreen
.2
	move.w	#$0080,(VDP_DATA)	; copy the new x-coordinate
ExitProcessDebugScreen:
	rts

LaunchDebug00:
LaunchDebug01:
LaunchDebug02:
LaunchDebug03:
LaunchDebug04:
LaunchDebug05:
LaunchDebug06:
LaunchDebug07:
LaunchDebug08:
LaunchDebug09:
LaunchDebug10:
LaunchDebug11:
LaunchDebug12:
LaunchDebug13:
LaunchDebug14:
LaunchDebug15:
LaunchDebug16:
LaunchDebug17:
LaunchDebug18:
LaunchDebug19:
LaunchDebug20:
LaunchDebug21:
LaunchDebug22:
LaunchDebug23:
LaunchDebug24:
LaunchDebug25:
LaunchDebug26:
LaunchDebug27:
LaunchDebug28:
LaunchDebug29:
LaunchDebug30:
LaunchDebug31:
LaunchDebug32:
LaunchDebug33:
LaunchDebug34:
LaunchDebug35:
LaunchDebug36:
LaunchDebug37:
LaunchDebug38:
LaunchDebug39:
LaunchDebug40:	
LaunchDebug41:
LaunchDebug42:
LaunchDebug43:
LaunchDebug44:
LaunchDebug45:
LaunchDebug46:
LaunchDebug47:
LaunchDebug48:
LaunchDebug49:
LaunchDebug50:
LaunchDebug51:
LaunchDebug52:
LaunchDebug53:
	bra.w	NewGame

DebugNotImplemented:
	; prevent freezing - also this will be throwaway later
	move.l	(MEM_GAME_STATE),d7	; copy game state to d7
	bset.l	#STATE_FLAG_DEBUG_MENU,d7 ; set debug menu flag
	move.l	d7,(MEM_GAME_STATE)	; save updated game state
	bra.w	MainGameLoop

	endif
