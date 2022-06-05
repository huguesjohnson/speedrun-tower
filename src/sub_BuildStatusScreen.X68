;---------------------------------------------------------------------------
; this is all very hacky but there's no chance I will ever reuse any of it
;---------------------------------------------------------------------------
BuildStatusScreen:
	move.w	#$2700,sr ; disable interrupts
	;---------------------------------------------------------------------------
	; check rooms visited
	; if I was smarter this would be one loop
	;---------------------------------------------------------------------------
	move.w	#STATUS_MENU_CHECKED_PATTERN,d0	; base pattern
	; a1 has the drawing location for the checkbox
	lea	VDP_VRAM_WRITE_A,a1	; initial drawing location
	adda.l	#$01840000,a1 ; move to location of first checkbox
	lea	MenusTableStart,a6 ; start of text table
	move.w	#$0000,(MEM_LOOP_COUNTER)
	move.w	#$0000,(MEM_BIT_COUNTER)
	move.l	(MEM_ROOMS_VISITED),d7
.loop
	; a4 has the drawing location for the text
	movea.l	a1,a4 ; copy address of a1 to a4
	adda.l	#$00020000,a4 ; move a4 over one column
	; test if this floor has been visited
	move.w	(MEM_BIT_COUNTER),d1 ; copy loop counter to d1
	btst.l	d1,d7 ; test if this floor was visited
	beq.s	.notseen ; branch if not visited
	; draw the checked box
	move.w	#$0000,d1 ; repeat
	lea	Pattern8x8,a0 ; pattern to draw
	bsr.w	DrawTileset ; branch to DrawTileset subroutine
	; draw the text label
	movea.l	(a6),a3 ; a6 is pointing to the text lookup table
	move.w	#FONT_BASE_TILE_LOW+%0100000000000000,d1 ; font with palette 1
.nextchar
	clr	d7 ; clear out d7
	move.b	(a3),d7 ; copy current character to d7
	cmpi.b	#ETX,d7 ; is this the end of the text?
	beq.s	.testloop
	sub.w	#$20,d7	; subtract 32 to get the character index
	add.w	d1,d7 ; add the base tile
	move.l	a4,(VDP_CONTROL) ; set VDP address
	move.w  d7,(VDP_DATA) ; copy the character to VPD
	; increment for next character
	adda.l	#$00000001,a3 ; move to next character in the string
	add.l	#$00020000,a4 ; move to the next column
	bra.s	.nextchar	; repeat until ETX is reached
	bra.s	.testloop ; test if we need to loop again
.notseen
	adda.l	#$00800000,a1 ; move down a row
.testloop
	move.l	(MEM_ROOMS_VISITED),d7 ; this is hacky
	adda.l	#$00000004,a6 ; move to the next row in the text lookup table
	add.w	#$0001,(MEM_LOOP_COUNTER) ; increment loop counter
	add.w	#$0001,(MEM_BIT_COUNTER) ; increment bit counter
	move.l	a1,d1 ; copy the address of a1 to d1
	cmp.w	#STATUS_MENU_MAX_FLOORS,(MEM_LOOP_COUNTER) ; last floor?
	blt	.loop ; loop until the last floor
	move.l	(MEM_STORY_EVENTS),d7 ; this is hacky
	cmp.w	#STATUS_MENU_MAX_FLOORS,(MEM_LOOP_COUNTER) ; time to shift?
	beq.s	.shifttostoryevents ; repoint everything to look at story events
	cmp.w	#STATUS_MENU_MAX_STORY_EVENTS,(MEM_LOOP_COUNTER) ; last event?
	blt	.loop ; loop until the last event
	move.l	(MEM_DIALOG_EVENTS),d7 ; this is hacky
	cmp.w	#STATUS_MENU_MAX_STORY_EVENTS,(MEM_LOOP_COUNTER) ; time to shift?
	beq.s	.shifttodialogevents ; repoint everything to look at dialog events
	cmp.w	#STATUS_MENU_MAX_DIALOG_EVENTS,(MEM_LOOP_COUNTER) ; last event?
	blt	.loop ; loop until the last event	
	; finally done
	bra.s ExitBuildStatusScreen ; exit
.shifttostoryevents
	lea	VDP_VRAM_WRITE_A,a1	; initial drawing location
	adda.l	#$01800000,a1 ; move to location of first checkbox
	adda.l	#$002C0000,a1 ; move to location of first checkbox
	move.w	#$0000,(MEM_BIT_COUNTER) ; reset bit counter
	bra.w	.loop ; continue looping
.shifttodialogevents
	move.w	#$0000,(MEM_BIT_COUNTER) ; reset bit counter
	bra.w	.loop ; continue looping
ExitBuildStatusScreen:
	; move sprite zero off the screen
	clr	d6	; done out of paranoia
	;---------------------------------------------------------------------------
	; update y
	;---------------------------------------------------------------------------
	move.l	#VDP_VRAM_WRITE_SPRITE,d6	; add to sprite table address
	move.l	d6,(VDP_CONTROL)	; set write location in VDP
	move.w	#$0000,(VDP_DATA)	; copy the new y-coordinate
	;---------------------------------------------------------------------------
	; update x
	;---------------------------------------------------------------------------
	add.l	#$00060000,d6	; move to x-coordinate
	move.l	d6,(VDP_CONTROL)	; set write location in VDP
	move.w	#$0000,(VDP_DATA)	; copy the new x-coordinate
	; now exit
	move.w	#$2000,sr	; re-enable interrupts
	rts
