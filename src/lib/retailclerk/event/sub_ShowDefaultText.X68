ShowDefaultText:
	move.l	(MEM_DIALOG_FLAGS),d7	; copy current dialog state to d7
	move.w	(MEM_ACTION_TARGET_OBJID),d6	; move target object ID to d6
	; determine whether this is an object or NPC
	andi.w	#OBJ_SCENE_BASE,d6	; and d6 against base object value
	beq.s	.npc	; branch if zero (not an object)
	; object
	lea	DefaultObjectDescriptionTableStart,a6	; point to default object text table
	; calculate and add offset to text pointer
	clr d6	; out of paranoia
	move.w	(MEM_ACTION_TARGET_OBJID),d6	; move target object ID to d6
	andi.w	#$0FFF,d6	; clear the base value
	mulu.w	#LWORD_SIZE,d6	; multiple by LWORD_SIZE
	adda.l	d6,a6	; add offset to pointer
	bra.s	.setupdialog
.npc	; npc
	lea	CharacterInteractTextTableStart,a6 ; a6 -> text table
	bset.l	#DIALOG_FLAG_STYLE_TITLED,d7	; set the titled flag
	; calculate and add offset to text pointer
	; something like ((CharacterId*NumberOfDays)+(CurrentDay*LWORD_SIZE))
	clr d6	; out of paranoia
	move.w	(MEM_ACTION_TARGET_OBJID),d6	; move target object ID to d6
	andi.w	#$0FFF,d6	; clear the base value
	mulu.w	#DAY_COUNT_X4,d6	; multiply by number of days
	move.w	(MEM_DAY),d5	; copy current day to d5
	mulu.w	#LWORD_SIZE,d5	; multiply by LWORD_SIZE
	add.w	d5,d6	; add to d6
	adda.l	d6,a6	; add offset to pointer
.setupdialog
	;---------------------------------------------------------------------------
	; setup the dialog
	;---------------------------------------------------------------------------
	move.l	(a6),(MEM_DIALOG_TEXT)	; copy value at a6 to MEM_DIALOG_TEXT
	; set dialog flags to display the dialog
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7	; change state to opening
	move.l	d7,(MEM_DIALOG_FLAGS)	; save changes made to the game state
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7	; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts
