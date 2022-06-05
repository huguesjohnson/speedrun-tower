ProcessStatusScreen:
;-------------------------------------------------------------------------------
; this is called ProcessStatusScreen because in RC89 there was one status screen
; that name is a little confusing in RC90+ because it's really 
; a multi-page menu screen with 'status' being one of the pages 
;
; a couple notes about handling multiple buttons pressed in the same frame...
; (mostly for myself as I will forget why I did things this way)
; tl;dr - if multiple buttons are pressed in the same frame one of them "wins"
;
; If the B button is pressed then no other buttons are processed
; This is because cancelling the screen overrides anything else
;
; The d-pad is processed before the A and C buttons
; If the d-pad is pressed the A and C buttons are skipped in that frame
; This is to avoid activating an unintented menu selection 
; The d-pad order of precidence is Up->Down->Left->Right for no reason
;
; A and C have the same function
; If both are pressed in the same frame it's treated like one button press
;-------------------------------------------------------------------------------
	clr.w	d6	; lazy workaround to prevent some bugs
	move.b	(MEM_CONTROL_PRESSED),d6 ; copy pressed buttons to d6
	; if no buttons have been pressed then there's no action to take
	beq.w	ExitProcessStatusScreen ; exit
;-------------------------------------------------------------------------------
; test for B button (cancelling the menu screen)
;-------------------------------------------------------------------------------
	move.w	d6,d7 ; copy d6 to d7 since the value will be modified
	and.w	#BUTTON_B,d7 ; test if the B button was pressed
	beq.s	ExitProcessStatusScreen ; B button is not pressed
CancelStatusScreen:
	move.l	(MEM_GAME_STATE),d7 ; copy current game state to d7
	bclr.l	#STATE_FLAG_STATUS_SCREEN,d7 ; update game state
	move.l	d7,(MEM_GAME_STATE) ; save updated game state
	bsr.w	ReloadCurrentScene ; reload the current scene
ExitProcessStatusScreen:
	move.w	#$0000,(MEM_CONTROL_PRESSED)	; clear pressed buttons
	rts
