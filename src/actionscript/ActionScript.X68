;*******************************************************************************
; used for lookup table conditions that are unreachable
;*******************************************************************************
ActionScriptNullEvent:
	rts

;*******************************************************************************
; used for lookup table conditions that only ever show default look text
;*******************************************************************************
ActionScriptDefaultInteract:
	bsr.w	ShowDefaultText
	rts

;*******************************************************************************
; default exit scene handler
;*******************************************************************************
DefaultExitScene:
	; trying to prevent NPC sprites from changing direction
	move.w	#$FFFF,(MEM_ACTION_TARGET_NPCID)
	; determine which exit is being used based on sprite direction
	move.w	(MEM_PLAYER_SPRITE_DIRECTION),d6	; copy player direction to d6
	mulu.w	#$2,d6	; multiply by 2 to get offset
	lea	MEM_ACTIVE_SCENE_EXIT_S,a6	; point a6 to the first exit
	adda.l	d6,a6	; add offset
	move.w	(a6),d6	; copy location to d6
	; this check shouldn't be needed unless I made a catastrophic error
	cmpi.w	#$FFFF,d6	; is this a valid exit?
	beq.w	ExitDefaultExit	; if not a valid exit then exit subroutine
	;---------------------------------------------------------------------------
	; determine which floor to connect to based on the exit
	; 0 = next step in the guaranteed path
	; 1 = previous step in the guaranteed path
	; 2 = connection in the random path
	;---------------------------------------------------------------------------
	move.w	#$2700,sr ; disable interrupts
	; d0 will have the "random" number used to determine where the exit goes
	clr.l d0 ; I burned too much time debugging problems from not doing this	
	move.w	(MEM_RANDOM_3),d0 ; copy the "random" number to d0
	move.w	(MEM_ACTIVE_SCENE_ID),d1 ; copy the active sceneid to d1
	lsl.w	#4,d1 ; shift the sceneid over from #$000f to #$00f0
	or.w	d1,d0 ; d0 now has #$rrf0 - need it to have #$rrfd
	; determine which exit the player sprite is taking
	move.w	#$0000,(MEM_EXITING_DOOR_NUM) ; start with 0 by default
	move.w	(MEM_PLAYER_SPRITE_X),d1 ; copy sprite x to d1
	cmpi.w	#EXIT0_MAX_X,d1 ; test against max x for exit0
	ble.s	.lookupexit ; less than, nothing else to do
.exit1
	cmpi.w	#EXIT1_MAX_X,d1 ; test against max x for exit1
	bgt.s	.exit2 ; greater than, must be the last exit
	or.w	#$0001,d0 ; second exit, add 1
	move.w	#$0001,(MEM_EXITING_DOOR_NUM) ; update which door number is used
	bra.s	.lookupexit
.exit2
	or.w	#$0002,d0 ; third exit, add 2
	move.w	#$0002,(MEM_EXITING_DOOR_NUM) ; update which door number is used
.lookupexit
	divu	#$0003,d0
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	move.w	d0,(MEM_EXITING_DOOR_PATH) ; save which path the player is on
	move.w	(MEM_ACTIVE_SCENE_ID),d1 ; copy the active sceneid to d1
	cmpi.w	#$0000,d1 ; scene 00?
	beq.s	.lookupexitfloor00
	cmpi.w	#$000F,d1 ; scene 0F?
	beq.s	.lookupexitfloor0F
	; not floor 00 or 0F, carry-on	
	bra.w	.findenterpath
; deal with floors 00 and 0F only having two doors & paths
.lookupexitfloor00
	move.w	(MEM_RANDOM_3),d0
	lsr.w	#4,d0
	divu	#$0002,d0	
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	; -------------------------------------------------------
	; d0 should now have 0 or 1
	; 0 = door 0000 is random, door 0002 is guaranteed path
	; 1 = door 0010 is guaranteed path, door 0002 is random
	; -------------------------------------------------------
	move.w	(MEM_EXITING_DOOR_NUM),d1
	cmpi.w	#$0000,d1
	bne.s	.lookupexitfloor00door2
.lookupexitfloor00door0
	; start with random as default
	move.w	#PATH_RANDOM_PAIR,(MEM_EXITING_DOOR_PATH)
	cmpi.w	#$0000,d0 ; is d0 = 0?
	beq.w	.findenterpath
	move.w	#PATH_GUARANTEED_NEXT,(MEM_EXITING_DOOR_PATH)
	bra.w	.findenterpath	
.lookupexitfloor00door2
	move.w	#PATH_GUARANTEED_NEXT,(MEM_EXITING_DOOR_PATH)
	cmpi.w	#$0000,d0 ; is d0 = 0?
	beq.w	.findenterpath
	move.w	#PATH_RANDOM_PAIR,(MEM_EXITING_DOOR_PATH)
	bra.w	.findenterpath	
.lookupexitfloor0F
	move.w	(MEM_RANDOM_3),d0
	lsr.w	#5,d0 ; different from 00 on purpose
	divu	#$0002,d0	
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	; -------------------------------------------------------
	; d0 should now have 0 or 1
	; 0 = door 0000 is random, door 0001 is guaranteed path
	; 1 = door 0000 is guaranteed path, door 0001 is random
	; -------------------------------------------------------
	move.w	(MEM_EXITING_DOOR_NUM),d1
	cmpi.w	#$0000,d1
	bne.s	.lookupexitfloor0Fdoor1
.lookupexitfloor0Fdoor0
	; start with random as default
	move.w	#PATH_RANDOM_PAIR,(MEM_EXITING_DOOR_PATH)
	cmpi.w	#$0000,d0 ; is d0 = 0?
	beq.w	.findenterpath
	move.w	#PATH_GUARANTEED_PREVIOUS,(MEM_EXITING_DOOR_PATH)
	bra.w	.findenterpath	
.lookupexitfloor0Fdoor1
	move.w	#PATH_GUARANTEED_PREVIOUS,(MEM_EXITING_DOOR_PATH)
	cmpi.w	#$0000,d0 ; is d0 = 0?
	beq.w	.findenterpath
	move.w	#PATH_RANDOM_PAIR,(MEM_EXITING_DOOR_PATH)
	bra.w	.findenterpath	
.findenterpath	
	; now figure out which path this will be in the corresponding room
	move.w (MEM_EXITING_DOOR_PATH),d0 ; even though it's probably there already 
	cmpi.w	#PATH_GUARANTEED_NEXT,d0 ; are we on the guaranteed path?
	bne.s	.enterpath1
.enterpath0
	; if the player is exiting g-next the corresponding door will be g-previous
	move.w	#PATH_GUARANTEED_PREVIOUS,(MEM_ENTERING_DOOR_PATH)
	bra.s	.findsceneid 
.enterpath1
	cmpi.w	#PATH_GUARANTEED_PREVIOUS,d0 ; are we on the guaranteed path?
	bne.s	.enterpath2
	; if the player is exiting g-previous the corresponding door will be g-next
	move.w	#PATH_GUARANTEED_NEXT,(MEM_ENTERING_DOOR_PATH)
	bra.s	.findsceneid 
.enterpath2
	; the only other option unless I did something dumb
	move.w	#PATH_RANDOM_PAIR,(MEM_ENTERING_DOOR_PATH)
.findsceneid 
	move.w	(MEM_EXITING_DOOR_PATH),d0
	cmpi.w	#PATH_RANDOM_PAIR,d0
	beq.w	.findscenerand
	cmpi.w	#PATH_GUARANTEED_PREVIOUS,d0
	beq.w	.findsceneprevg
.findscenenextg ; exiting on next step in guaranteed path
	move.w	(MEM_ACTIVE_SCENE_ID),d0 ; copy current scene id to d0
	lea	MEM_GUARANTEED_ORDER,a0 ; point to list of guaranteed path
.findscenenextgloop
	move.w	(a0)+,d1 ; copy step in path
	cmp.w	d0,d1 ; is it the current floor?
	bne.w	.findscenenextgloop ; loop if not
	move.w	(a0),(MEM_ENTERING_SCENE_ID)
	bra.w	.findenteringdoor
.findsceneprevg ; exiting on previous step in guaranteed path
	move.w	(MEM_ACTIVE_SCENE_ID),d0 ; copy current scene id to d0
	lea	MEM_GUARANTEED_ORDER,a0 ; point to list of guaranteed path
.findsceneprevgloop
	move.w	(a0)+,d1 ; copy step in path
	cmp.w	d0,d1 ; is it the current floor?
	bne.w	.findsceneprevgloop ; loop if not
	suba.l	#4,a0 ; point to the previous item
	move.w	(a0),(MEM_ENTERING_SCENE_ID)
	bra.w	.findenteringdoor
.findscenerand ; exiting on random path
	move.w	(MEM_ACTIVE_SCENE_ID),d0 ; copy current scene id to d0
	lea	MEM_RANDOM_ORDER,a0 ; point to list of random connections
.findscenerandloop
	move.w	(a0)+,d1 ; copy first part of pair
	move.w	(a0)+,d2 ; copy second part of pair
	cmp.w	d0,d1 ; is the current scene in the first part of the pair?
	beq.s	.findscenerandloop1 ; branch if so
	cmp.w	d0,d2 ; is the current scene in the second part of the pair?
	beq.s	.findscenerandloop2 ; branch if so
	bra.w	.findscenerandloop ; otherwise keep looking
.findscenerandloop1
	; d1 has current scene, d2 has matching pair
	move.w	d2,(MEM_ENTERING_SCENE_ID)
	bra.s	.findenteringdoor
.findscenerandloop2
	; d1 has current scene, d1 has matching pair
	move.w	d1,(MEM_ENTERING_SCENE_ID)
;-------------------------------------------------------------------------------
; by now we know which scene to load and which path the player is on
; now we need to have the player exit through the corresponding door
;-------------------------------------------------------------------------------
.findenteringdoor
	move.w (MEM_ENTERING_SCENE_ID),d0
	; deal with floors 00 and 0F only having two doors & paths	
	cmpi.w	#$0000,d0 ; entering floor 00?
	beq.w	.enterfloor00 ; branch if so
	cmpi.w	#$000F,d0 ; entering floor 0F?
	beq.w	.enterfloor0F ; branch if so
	; otherwise default logic
.findenteringdoortest0 ; test if door 0 is the right door
	clr.l d0
	move.w	(MEM_RANDOM_3),d0 ; copy the "random" number to d0
	move.w	(MEM_ENTERING_SCENE_ID),d1 ; copy the entering sceneid to d1
	lsl.w	#4,d1 ; shift the sceneid over from #$000f to #$00f0
	or.w	d1,d0 ; d0 now has #$rrf0 - need it to have #$rrfd
	; determine which exit the player sprite is taking
	divu	#$0003,d0
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	move.w	(MEM_ENTERING_DOOR_PATH),d1
	cmp.w	d0,d1 ; is this the right path?
	bne.s	.findenteringdoortest1
	move.w	#$0000,(MEM_ENTERING_DOOR_NUM)
	bra.w	DefaultExitSceneLoadNewScene	
.findenteringdoortest1
	clr.l d0
	move.w	(MEM_RANDOM_3),d0 ; copy the "random" number to d0
	move.w	(MEM_ENTERING_SCENE_ID),d1 ; copy the entering sceneid to d1
	lsl.w	#4,d1 ; shift the sceneid over from #$000f to #$00f0
	or.w	d1,d0 ; d0 now has #$rrf0 - need it to have #$rrfd
	add.w	#$0001,d0 ; testing door 1
	; determine which exit the player sprite is taking
	divu	#$0003,d0
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	move.w	(MEM_ENTERING_DOOR_PATH),d1
	cmp.w	d0,d1 ; is this the right path?
	bne.s	.findenteringdoortest2
	move.w	#$0001,(MEM_ENTERING_DOOR_NUM)
	bra.w	DefaultExitSceneLoadNewScene	
.findenteringdoortest2
	; don't need to test at this point unless I add more doors
	move.w	#$0002,(MEM_ENTERING_DOOR_NUM)
	bra.w	DefaultExitSceneLoadNewScene
.enterfloor00
	move.w	(MEM_RANDOM_3),d0
	lsr.w	#4,d0
	divu	#$0002,d0	
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	; -------------------------------------------------------
	; d0 should now have 0 or 1
	; 0 = door 0000 is random, door 0002 is guaranteed path
	; 1 = door 0000 is guaranteed path, door 0002 is random
	; -------------------------------------------------------
	cmpi.w	#PATH_RANDOM_PAIR,(MEM_ENTERING_DOOR_PATH) ; entering random path?
	beq.s	.enterfloor00random
	; on the guaranteed path
	move.w	#$0002,(MEM_ENTERING_DOOR_NUM) ; default value (door 0002)
	cmpi.w	#$0001,d0 ; is d0=1?
	bne.w	DefaultExitSceneLoadNewScene ; use default value (door 0002)
	move.w	#$0000,(MEM_ENTERING_DOOR_NUM) ; use door 0000
	bra.w	DefaultExitSceneLoadNewScene
.enterfloor00random:
	move.w	#$0000,(MEM_ENTERING_DOOR_NUM) ; default value (door 0000)
	cmpi.w	#$0001,d0 ; is d0=1?
	bne.w	DefaultExitSceneLoadNewScene ; use default value (door 0000)
	move.w	#$0002,(MEM_ENTERING_DOOR_NUM) ; use door 0002
	bra.w	DefaultExitSceneLoadNewScene
.enterfloor0F
	move.w	(MEM_RANDOM_3),d0
	lsr.w	#5,d0 ; different from 00 on purpose
	divu	#$0002,d0	
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	; -------------------------------------------------------
	; d0 should now have 0 or 1
	; 0 = door 0000 is random, door 0002 is guaranteed path
	; 1 = door 0000 is guaranteed path, door 0002 is random
	; -------------------------------------------------------
	cmpi.w	#PATH_RANDOM_PAIR,(MEM_ENTERING_DOOR_PATH) ; entering random path?
	beq.s	.enterfloor0frandom
	; on the guaranteed path
	move.w	#$0002,(MEM_ENTERING_DOOR_NUM) ; default value (door 0002)
	cmpi.w	#$0001,d0 ; is d0=1?
	bne.w	DefaultExitSceneLoadNewScene ; use default value (door 0002)
	move.w	#$0000,(MEM_ENTERING_DOOR_NUM) ; use door 0000
	bra.w	DefaultExitSceneLoadNewScene
.enterfloor0frandom:
	move.w	#$0000,(MEM_ENTERING_DOOR_NUM) ; default value (door 0000)
	cmpi.w	#$0001,d0 ; is d0=1?
	bne.w	DefaultExitSceneLoadNewScene ; use default value (door 0000)
	move.w	#$0002,(MEM_ENTERING_DOOR_NUM) ; use door 0002
DefaultExitSceneLoadNewScene:
	; get the scene id into d6 so the rest of this code doesn't change
	move.w	(MEM_ENTERING_SCENE_ID),d6 
	mulu.w	#$4,d6	; multiply by 4 to get offset
	lea	SceneDefinitionTable,a6	; point a6 to the scene definition table
	adda.l	d6,a6	; add offset
	move.l	(a6),a6	; have a6 point to the value at a6
	move.w	#$2000,sr ; re-enable interrupts
	bsr.w	LoadScene	; branch to LoadScene subroutine
	bsr.w	LoadPlayerSprite	; load the player sprite
	; move player to the correct position
	move.w	(MEM_PLAYER_SPRITE_DIRECTION),d6	; copy player direction to d6
	;---------------------------------------------------------------------------
	; adjust player sprite x/y
	;---------------------------------------------------------------------------
DefaultExitSceneTestDown:
	cmpi.w	#DIRECTION_DOWN,d6	; test for down
	bne.s	DefaultExitSceneTestUp	; direction is not down, test for up
	move.w	#SCENE_ENTER_TOP,(MEM_PLAYER_SPRITE_Y)	; update y location
DefaultExitSceneTestUp:
	;---------------------------------------------------------------------------
	; this part is different for speedrun tower
	;---------------------------------------------------------------------------
	cmpi.w	#DIRECTION_UP,d6	; test for up
	bne.s	DefaultExitSceneTestLeft	; direction is not up, test for left
	move.w	#SCENE_ENTER_TOP,(MEM_PLAYER_SPRITE_Y)	; update y location
	move.w	#DIRECTION_DOWN,(MEM_PLAYER_SPRITE_DIRECTION)
	cmpi.w	#$0002,(MEM_ENTERING_DOOR_NUM) ; entering door 0002?
	beq.s	.enterx2 ; branch if so
	cmpi.w	#$0001,(MEM_ENTERING_DOOR_NUM) ; etnering door 0001?
	beq.s	.enterx1 ; branch if so
.enterx0:
	move.w	#EXIT0_ENTER_X,(MEM_PLAYER_SPRITE_X)
	bra.s	.fixsprites	
.enterx1:
	move.w	#EXIT1_ENTER_X,(MEM_PLAYER_SPRITE_X)
	bra.s	.fixsprites	
.enterx2:
	move.w	#EXIT2_ENTER_X,(MEM_PLAYER_SPRITE_X)
.fixsprites:
	bra.w	DefaultExitSceneFixSprites	; exit
DefaultExitSceneTestLeft:
	cmpi.w	#DIRECTION_LEFT,d6	; test for left
	bne.s	DefaultExitSceneTestRight	; direction is not left, test for right
	move.w	#SCENE_ENTER_RIGHT,(MEM_PLAYER_SPRITE_X) ; update x location
	bra.s	DefaultExitSceneFixSprites	; exit
DefaultExitSceneTestRight:
	cmpi.w	#DIRECTION_RIGHT,d6	; test for right
	bne.s	DefaultExitSceneFixSprites	; should be unreachable
	move.w	#SCENE_ENTER_LEFT,(MEM_PLAYER_SPRITE_X)	; update x location
DefaultExitSceneFixSprites:
	bsr.w	FixSprites ; fix all the sprites
ExitDefaultExit:
	bsr.w	FadeIn ; fade in now that everything is loaded
	rts

;*******************************************************************************
; default enter scene handler
;*******************************************************************************
DefaultEnterScene:
	; this will break if >32 floors exist
	; in an odd way I hope that's a problem someday
	move.w	(MEM_ACTIVE_SCENE_ID),d6 ; copy current scene id to d6
	move.l	(MEM_ROOMS_VISITED),d7 ; copy rooms visited tracker to d7
	bset.l	d6,d7 ; set that this room is visited
	move.l	d7,(MEM_ROOMS_VISITED) ; save updated value
	; have player walk into the room
	lea ScriptedEventEnterSceneStart,a6	; point a6 to event to load
	bsr.w QueueScriptedEvent ; queue the event
	rts
	
;*******************************************************************************
; custom exit scene handlers
;*******************************************************************************
Floor00Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR00_00,d6 ; test if talking to npc00
	beq.s	.floor00npc0 ; if so branch
	bra.w	FloorDefault ; not npc0, use default text
.floor00npc0
	move.l	(MEM_STORY_EVENTS),d7 ; copy story events to d7
	btst.l	#STORY_FLAG_LOBBY_GUARD,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#STORY_FLAG_LOBBY_GUARD,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_STORY_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR00_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor01Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR01_00,d6 ; test if talking to npc00
	beq.s	.floor01npc0 ; if so branch
	cmpi.w	#OBJ_NPC_FLOOR01_01,d6 ; test if talking to npc01
	beq.s	.floor01npc1 ; if so branch
	bra.w	FloorDefault ; not npc1, use default text
.floor01npc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR01_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR01_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR01_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor01npc1
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR01_NPC01,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR01_NPC01,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR01_01,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor02Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR02_00,d6 ; test if talking to npc00
	beq.s	.floor02npc0 ; if so branch
	cmpi.w	#OBJ_NPC_FLOOR02_01,d6 ; test if talking to npc01
	beq.s	.floor02npc1 ; if so branch
	bra.w	FloorDefault ; not npc1, use default text
.floor02npc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR02_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR02_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR02_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor02npc1
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR02_NPC01,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR02_NPC01,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR02_01,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor03Interact: ; event flags are flipped due to my poor planning
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR03_00,d6 ; test if talking to npc00
	beq.s	.floor03npc0 ; if so branch
	cmpi.w	#OBJ_NPC_FLOOR03_01,d6 ; test if talking to npc01
	beq.s	.floor03npc1 ; if so branch
	bra.w	FloorDefault ; not npc1, use default text
.floor03npc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR03_NPC01,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR03_NPC01,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR03_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor03npc1
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR03_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR03_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR03_01,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor04Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR04_00,d6 ; test if talking to npc00
	beq.s	.floor04npc0 ; if so branch
	cmpi.w	#OBJ_NPC_FLOOR04_01,d6 ; test if talking to npc01
	beq.s	.floor04npc1 ; if so branch
	bra.w	FloorDefault ; not npc1, use default text
.floor04npc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR04_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR04_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR04_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor04npc1
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR04_NPC01,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR04_NPC01,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR04_01,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor05Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_SCENE_FLOOR05_NEXTSTEP,d6 ; test if interacting with object
	bne.w	FloorDefault ; show default text if not
	move.l	(MEM_STORY_EVENTS),d7 ; copy story flags to d7
	btst.l	#STORY_FLAG_NEXTSTEP,d7 ; test if the event already happened
	bne.s	.floor05allflags ; branch if set
	btst.l	#STORY_FLAG_FLOOR07,d7 ; test if trigger event happened
	bne.s	.floor05storyflag ; branch if set
.floor05noflags:
	lea StoryTextNPC_FLOOR05_NoFlags,a6 ; point a6 to the text to display
	bsr.w	SetupDialogScenery ; setup the dialog
	rts
.floor05storyflag:
	bset.l	#STORY_FLAG_NEXTSTEP,d7 ; set that the event happened
	move.l	d7,(MEM_STORY_EVENTS) ; save the updated flags
	lea StoryTextNPC_FLOOR05_StoryFlag,a6 ; point a6 to the text to display
	bsr.w	SetupDialogScenery ; setup the dialog
	rts	
.floor05allflags:
	bra.w	FloorDefault

Floor06Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR06_00,d6 ; test if talking to npc00
	beq.s	.floor06npc0 ; if so branch
	bra.w	FloorDefault ; not npc0, use default text
.floor06npc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR06_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR06_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR06_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor07Interact:
	move.l	(MEM_STORY_EVENTS),d7 ; copy story flags to d7
	btst.l	#STORY_FLAG_FLOOR07,d7 ; test if the event already happened
	bne.w	FloorDefault ; if event viewed, show default for everything
	; else test if interacting with either npc
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	; determine whether this is an object or NPC
	andi.w	#OBJ_SCENE_BASE,d6 ; and d6 against base object value
	bne.w	FloorDefault ; branch if not zero (object)	
	bset.l	#STORY_FLAG_FLOOR07,d7 ; set event flag
	move.l	d7,(MEM_STORY_EVENTS) ; save updated flags
	; setup scripted event
	lea ScriptedEventFloor07Start,a6	; point a6 to event to load
	bsr.w QueueScriptedEvent ; queue the event
	rts		

Floor08Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_SCENE_FLOOR08_PRINTER,d6 ; test if interacting with object
	beq.s	.floor08printer ; branch if so
	cmpi.w	#OBJ_NPC_FLOOR08_00,d6 ; test if interacting with npc
	beq.s	.floor08npc0 ; branch if so
	bra.w	FloorDefault ; show default text if not
.floor08printer:
	move.l	(MEM_STORY_EVENTS),d7 ; copy story flags to d7
	btst.l	#STORY_FLAG_BADGE,d7 ; test if the event already happened
	bne.w	FloorDefault ; branch if set
	btst.l	#STORY_FLAG_LOBBY_GUARD,d7 ; test if trigger event happened
	beq.w	FloorDefault ; branch if not
	; now the player is finding the badge
	bset.l	#STORY_FLAG_BADGE,d7 ; set that the event happened
	move.l	d7,(MEM_STORY_EVENTS) ; save updated flags
	lea StoryTextNPC_FLOOR08_GetBadge,a6 ; point a6 to the text to display
	bsr.w	SetupDialogScenery ; setup the dialog
	rts
.floor08npc0:
	move.l	(MEM_STORY_EVENTS),d7 ; copy story flags to d7
	btst.l	#STORY_FLAG_BADGE,d7 ; test if the event already happened
	bne.s	.floor08allflags ; branch if set
	btst.l	#STORY_FLAG_LOBBY_GUARD,d7 ; test if the event already happened
	bne.s	.floor08storyflag ; branch if set
	bra.w	FloorDefault ; if neither set then show default text
.floor08storyflag:
	lea StoryTextNPC_FLOOR08_StoryFlag,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor08allflags:
	lea StoryTextNPC_FLOOR08_AllFlags,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor09Interact:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR09_00,d6 ; test if talking to npc00
	beq.s	.floor09npc0 ; if so branch
	cmpi.w	#OBJ_NPC_FLOOR09_01,d6 ; test if talking to npc01
	beq.s	.floor09npc1 ; if so branch
	bra.w	FloorDefault ; not npc1, use default text
.floor09npc0:
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR09_NPC00,d7 ; test if dialog happened
	bne.w	FloorDefault ; event happened, use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR09_NPC00,d7 ; set dialog happened
	move.l	d7,(MEM_DIALOG_EVENTS) ; save updated flags
	lea StoryTextNPC_FLOOR09_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor09npc1:
	move.l	(MEM_STORY_EVENTS),d7 ; copy story events to d7
	btst.l	#STORY_FLAG_COFFEE,d7 ; test if last flag is set
	bne.s	.floor09npc1allflags ; branch if set
	btst.l	#STORY_FLAG_RADIO,d7 ; test if trigger flag is set
	bne.s	.floor09npc1storyflag ; branch if set
.floor09npc1noflags:
	bra.w	FloorDefault ; use default text
.floor09npc1storyflag:
	bset.l	#STORY_FLAG_COFFEE,d7 ; set flag
	move.l	d7,(MEM_STORY_EVENTS) ; save updated flags
	lea StoryTextNPC_FLOOR09_01_StoryFlag,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor09npc1allflags:
	lea StoryTextNPC_FLOOR09_01_AllFlags,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor0AInteract:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR0A_00,d6 ; test if talking to npc00
	beq.s	.floor0Anpc ; if so branch
	bra.w	FloorDefault ; not npc1, use default text
.floor0Anpc:
	move.l	(MEM_STORY_EVENTS),d7 ; copy story events to d7
	btst.l	#STORY_FLAG_HAMMER,d7 ; test if last flag is set
	bne.s	.floor0Anpcallflags ; branch if set
	btst.l	#STORY_FLAG_FLOOR0E,d7 ; test if trigger flag is set
	bne.s	.floor0Anpcstoryflag ; branch if set
.floor0Anpcnoflags:
	bra.w	FloorDefault ; use default text
.floor0Anpcstoryflag:
	bset.l	#STORY_FLAG_HAMMER,d7 ; set flag
	move.l	d7,(MEM_STORY_EVENTS) ; save updated flags
	lea StoryTextNPC_FLOOR0A_StoryFlag,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
.floor0Anpcallflags:
	lea StoryTextNPC_FLOOR0A_AllFlags,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor0BInteract:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR0B_00,d6 ; test if talking to npc00
	beq.s	.floor0bnpc0 ; if so branch
	bra.w	FloorDefault ; not npc0, use default text
.floor0bnpc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR0B_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR0B_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR0B_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor0CInteract:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR0C_00,d6 ; test if talking to npc00
	beq.s	.floor0cnpc ; if so branch
	bra.w	FloorDefault ; not npc0, use default text
.floor0cnpc
	move.l	(MEM_STORY_EVENTS),d7 ; copy story events to d7
	btst.l	#STORY_FLAG_RADIO,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = event viewed = use default text
	bset.l	#STORY_FLAG_RADIO,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_STORY_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR0C_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor0DInteract:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR0D_00,d6 ; test if talking to npc00
	beq.s	.floor0dnpc0 ; if so branch
	bra.w	FloorDefault ; not npc0, use default text
.floor0dnpc0
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR0D_NPC00,d7 ; test if 1st dialog viewed
	bne.w	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR0D_NPC00,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR0D_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts

Floor0EInteract:
	move.l	(MEM_STORY_EVENTS),d7 ; copy story flags to d7
	btst.l	#STORY_FLAG_FLOOR0E,d7 ; test if the event already happened
	bne.w	FloorDefault ; if event viewed, show default for everything
	; else test if interacting with either npc
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	; determine whether this is an object or NPC
	andi.w	#OBJ_SCENE_BASE,d6 ; and d6 against base object value
	bne.w	FloorDefault ; branch if not zero (object)	
	bset.l	#STORY_FLAG_FLOOR0E,d7 ; set event flag
	move.l	d7,(MEM_STORY_EVENTS) ; save updated flags
	; setup scripted event
	lea ScriptedEventFloor0EStart,a6	; point a6 to event to load
	bsr.w QueueScriptedEvent ; queue the event
	rts	

Floor0FInteract:
	move.w	(MEM_ACTION_TARGET_OBJID),d6 ; move target object ID to d6
	cmpi.w	#OBJ_NPC_FLOOR0F_00,d6 ; test if talking to npc00
	beq.s	.floor0fnpc0 ; if so branch
	cmpi.w	#OBJ_NPC_FLOOR0F_01,d6 ; test if talking to npc01
	beq.s	.floor0fnpc1 ; if so branch
	bra.s	FloorDefault ; not npc1, use default text
.floor0fnpc0
	lea	StoryTextNPC_FLOOR0F_2Choice,a6 ; load dialog text	
	bsr.w	Setup2ChoiceDialog
	rts
.floor0fnpc1
	move.l	(MEM_DIALOG_EVENTS),d7 ; copy dialog events to d7
	btst.l	#DIALOGEVENT_FLAG_FLOOR0F_NPC01,d7 ; test if 1st dialog viewed
	bne.s	FloorDefault ; bit set = dialog viewed = use default text
	bset.l	#DIALOGEVENT_FLAG_FLOOR0F_NPC01,d7 ; set bit to indicated viewed
	move.l	d7,(MEM_DIALOG_EVENTS) ; save the updated event flags
	lea StoryTextNPC_FLOOR0F_00,a6 ; point a6 to the text to display
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
	
Floor0FRespond:
	bsr.w	ResetDialog
	cmpi.w	#$0000,(MEM_MENU_RESPONSE) ; is the menu selection 0?
	bne.s	.response1
.response0
	bsr.w	ResetDialog
	; prevent the dialog from showing
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bclr.l	#STATE_FLAG_DIALOG,d7 ; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7	
	bsr.w	SetupEndGame
	rts
.response1
	lea	StoryTextNPC_FLOOR0F_Response1,a6
	bsr.w	SetupDialogNPC ; setup the dialog
	rts
	
FloorDefault:
	bsr.w ShowDefaultText
	rts

SetupDialogNPC:
	;---------------------------------------------------------------------------
	; setup the dialog
	;---------------------------------------------------------------------------
	move.l	a6,(MEM_DIALOG_TEXT) ; copy value at a6 to MEM_DIALOG_TEXT
	; set dialog flags to display the dialog
	move.l	(MEM_DIALOG_FLAGS),d7 ; copy current dialog state to d7
	bset.l	#DIALOG_FLAG_STYLE_TITLED,d7 ; set the titled flag
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7 ; change state to opening
	move.l	d7,(MEM_DIALOG_FLAGS) ; save changes made to the game state
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7 ; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts
	
Setup2ChoiceDialog:
	move.l	a6,(MEM_DIALOG_TEXT) ; copy address to MEM_DIALOG_TEXT	
	move.l	(MEM_DIALOG_FLAGS),d7 ; copy dialog flags to d7
	; set 2 choice style
	bset.l	#DIALOG_FLAG_STYLE_TEXT_2CHOICE,d7 ; set text choice flag
	; set dialog flags to display the dialog	
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7 ; change state to opening
	bset.l	#DIALOG_FLAG_STYLE_TITLED,d7 ; set the titled flag
	move.l	d7,(MEM_DIALOG_FLAGS) ; save updated dialog flags
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7	; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts	
	
SetupDialogScenery:
	;---------------------------------------------------------------------------
	; setup the dialog
	;---------------------------------------------------------------------------
	move.l	a6,(MEM_DIALOG_TEXT)	; copy value at a6 to MEM_DIALOG_TEXT
	; set dialog flags to display the dialog
	move.l	(MEM_DIALOG_FLAGS),d7 ; copy current dialog state to d7
	bclr.l	#DIALOG_FLAG_STYLE_TITLED,d7 ; clear the titled flag
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7 ; change state to opening
	move.l	d7,(MEM_DIALOG_FLAGS) ; save changes made to the game state
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7 ; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts	

;*******************************************************************************
; end the game
;*******************************************************************************
SetupEndGame:
	; --------------------------------------------------------------------------
	; test if the player did all required interactions
	; all floors, not all events = "bad" ending
	; not all floors, not all events = "good" ending
	; all floors, all events = "perfect" ending
	; it's ultimately subjective which of these are truly good or bad
	; --
	; here's some debug code that's commented out
	; move.l	#ALL_ROOMS_VISITED,(MEM_ROOMS_VISITED)
	; move.l	#ALL_DIALOG_EVENTS_VIEWED,(MEM_DIALOG_EVENTS)
	; move.l	#ALL_STORY_EVENTS_VIEWED,(MEM_STORY_EVENTS)
	; --------------------------------------------------------------------------
	move.l	(MEM_ROOMS_VISITED),d7
	cmpi.l	#ALL_ROOMS_VISITED,d7
	blt.s	.fastending ; the player did not visit every floor
	; test if the player completed all the events
	move.l	(MEM_DIALOG_EVENTS),d7
	cmpi.l	#ALL_DIALOG_EVENTS_VIEWED,d7
	blt.s	.badending ; the player did not view all dialog events
	move.l	(MEM_STORY_EVENTS),d7
	cmpi.l	#ALL_STORY_EVENTS_VIEWED,d7
	blt.s	.badending ; the player did not view all story events
.perfectending
	lea	ScriptedEventPerfectEndingStart,a6	; point a6 to event to load
	bra.s	.queue
.badending
	; queue scripted event
	lea	ScriptedEventBadEndingStart,a6	; point a6 to event to load
	bra.s	.queue
.fastending
	cmpi.l	#FAST_PATH,d7 ; is this is fastest path?
	bne.s	.goodending ; branch if not
	cmpi.w	#$0000,(MEM_EXITING_DOOR_NUM) ; exit through the closest door?	
	bne.s	.goodending ; branch if not
	; queue scripted event
	lea	ScriptedEventFastEndingStart,a6	; point a6 to event to load
	bra.s	.queue
.goodending
	lea ScriptedEventGoodEndingStart,a6	; point a6 to event to load
.queue
	bsr.w QueueScriptedEvent	; queue the event
	rts

EndGame:
	; set the end game flag
	move.l	(MEM_GAME_STATE),d7	; copy game state
	and.l	#$0000,d7	; clear all other flags
	bset.l	#STATE_FLAG_END_SCREEN,d7 ; set end screen state flag	
	move.l	d7,(MEM_GAME_STATE)	; save updated game state
	rts

;*******************************************************************************
; show dialogs
;*******************************************************************************
ShowDialog:
	move.l	a6,MEM_DIALOG_TEXT ; copy address to MEM_DIALOG_TEXT	
	move.l	(MEM_DIALOG_FLAGS),d7 ; copy dialog flags to d7
	bclr.l	#DIALOG_FLAG_STYLE_TEXT_2CHOICE,d7 ; set text choice flag
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7 ; change state to opening
	bset.l	#DIALOG_FLAG_STYLE_TITLED,d7 ; set the titled flag
	move.l	d7,(MEM_DIALOG_FLAGS) ; save updated dialog flags
	; set dialog flags to display the dialog
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7	; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts
	
Show2ChoiceDialog:
	move.l	a6,MEM_DIALOG_TEXT ; copy address to MEM_DIALOG_TEXT	
	move.l	(MEM_DIALOG_FLAGS),d7 ; copy dialog flags to d7
	bset.l	#DIALOG_FLAG_STYLE_TEXT_2CHOICE,d7 ; set text choice flag
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7 ; change state to opening
	bset.l	#DIALOG_FLAG_STYLE_TITLED,d7 ; set the titled flag
	move.l	d7,(MEM_DIALOG_FLAGS) ; save updated dialog flags
	; set dialog flags to display the dialog
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7	; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts
	
Show4ChoiceDialog:
	move.l	a6,MEM_DIALOG_TEXT ; copy address to MEM_DIALOG_TEXT	
	move.l	(MEM_DIALOG_FLAGS),d7 ; copy dialog flags to d7
	bset.l	#DIALOG_FLAG_STYLE_TEXT_4CHOICE,d7 ; set text choice flag
	bset.l	#DIALOG_FLAG_TEXT_OPENING,d7 ; change state to opening
	bset.l	#DIALOG_FLAG_STYLE_TITLED,d7 ; set the titled flag
	move.l	d7,(MEM_DIALOG_FLAGS) ; save updated dialog flags
	; set dialog flags to display the dialog
	move.l	(MEM_GAME_STATE),d7	; copy current game state to d7
	bset.l	#STATE_FLAG_DIALOG,d7	; set the dialog bit
	move.l	d7,(MEM_GAME_STATE) ; copy game state back to d7
	rts	
	
;*******************************************************************************
; default text for interact events
;*******************************************************************************
	include	'lib/retailclerk/event/sub_ShowDefaultText.X68'

