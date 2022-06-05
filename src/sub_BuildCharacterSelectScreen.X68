;---------------------------------------------------------------------------
; this is all very hacky but there's no chance I will ever reuse any of it
; ok.. maybe I will and looking again it's not that bad
;---------------------------------------------------------------------------
BuildCharacterSelectScreen:
	;---------------------------------------------------------------------------
	; load sprite zero
	;---------------------------------------------------------------------------
	bsr.w	LoadSpriteZeroTiles	; load the tiles
	move.w	#$2700,sr		; disable interrupts
	; reload the sprite definition
	lea     SpriteZeroLowDefinition,a0	; store address of sprite definition
	moveq	#$01,d0	; 1 sprite = 2 longs
	move.l	#VDP_VRAM_WRITE_SPRITE,(VDP_CONTROL) ; set write location
.Loop:
	move.l  (a0)+,(VDP_DATA)
	dbra    d0,.Loop
	; move sprite zero to first item
	move.l	#VDP_VRAM_WRITE_SPRITE,d6 ; add to sprite table address
	move.l	d6,(VDP_CONTROL) ; set write location in VDP
	move.w	#$00D0,(VDP_DATA) ; copy the new y-coordinate
	;---------------------------------------------------------------------------
	; update x
	;---------------------------------------------------------------------------
	add.l	#$00060000,d6 ; move to x-coordinate
	move.l	d6,(VDP_CONTROL) ; set write location in VDP
	move.w	#$0090,(VDP_DATA) ; copy the new x-coordinate		
	;---------------------------------------------------------------------------
	; get a random-ish number to show random-ish names
	;---------------------------------------------------------------------------
	move.w	(MEM_RANDOM_1),d0 ; copy the "random" number captured at the title
	move.w	(MEM_MAINLOOP_COUNTER),d1 ; results will vary based on build
	add.w	d1,d0 ; add them for lack of a better idea
	move.w	d0,(MEM_RANDOM_3) ; this gets overwritten by this screen later
	move.w	#$0001,d0 ; two rows of text
	lea	VDP_VRAM_WRITE_A,a1	; initial drawing location	
	adda.l	#CHARACTER_SELECT0_ROW,a1 ; move to row of first name	
	adda.l	#CHARACTER_SELECT0_COL,a1 ; move to column of first name	
.bcssloopouter ; this loops twice 
	move.w	#$0003,d6 ; four columns of text
.bcssloopinner ; this loops four times
	lea	RandomPCNameTableStart,a6 ; point a6 to start of character name table
	clr.l d5 ; clear d5
	move.w	(MEM_RANDOM_3),d5 ; copy "random" number to d5
	divu	#CHARACTER_SELECT_MAX_NAME,d5 ; divide by max number of names
	clr.w d5 ; clear lower word
	swap.w	d5 ; swap remainder
	mulu.w	#LWORD_SIZE,d5 ; multiply by long size
	adda.l	d5,a6 ; move a6 to new location
	movea.l	(a6),a3 ; a6 is pointing to the text lookup table
	movea.l	a1,a4 ; copy address of a1 to a4
	move.w	#FONT_BASE_TILE_LOW+%0100000000000000,d1 ; font with palette 1
.nextchar
	clr.l	d7 ; clear out d7
	move.b	(a3),d7 ; copy current character to d7
	cmpi.b	#ETX,d7 ; is this the end of the text?
	beq.s	.nextcol
	sub.w	#$20,d7	; subtract 32 to get the character index
	add.w	d1,d7 ; add the base tile
	move.l	a4,(VDP_CONTROL) ; set VDP address
	move.w  d7,(VDP_DATA) ; copy the character to VPD
	; increment for next character
	adda.l	#$00000001,a3 ; move to next character in the string
	add.l	#$00020000,a4 ; move to the next column
	bra.s	.nextchar	; repeat until ETX is reached
.nextcol
	; this will flip between 0200 and 0204 in (I think) an unpredicable way
	move.l	(VDP_CONTROL),d7 ; move vpd_control status to d7
	swap	d7 ; high word seems to rarely change
	sub.w	#$000D,d7 ; subtract some prime value
	add.w	d7,(MEM_RANDOM_3) ; add it to the "random" number
	adda.l	#$00120000,a1 ; move to the next column
	dbra	d6,.bcssloopinner ; loop to next column
	; move to the next row
	lea	VDP_VRAM_WRITE_A,a1	; initial drawing location		
	adda.l	#CHARACTER_SELECT4_ROW,a1 ; move to row of first name	
	adda.l	#CHARACTER_SELECT4_COL,a1 ; move to column of first name	
	dbra	d0,.bcssloopouter ; loop
ExitBuildCharacterSelectScreen:
 	move.w	#$2000,sr	; re-enable interrupts
	rts
