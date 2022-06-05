BuildPaths:
	move.w	#$2700,sr ; disable interrupts

	if _DEBUG_
	move.w	#$029A,(MEM_RANDOM_1)
	move.w	#$2304,(MEM_RANDOM_2)
	move.w	#$0100,(MEM_RANDOM_3)
	endif

	;---------------------------------------------------------------------------
	; clean-up the "random" numbers out of paranoia
	; ok, really more like out of laziness
	; there are a few conditions I don't want to debug
	;---------------------------------------------------------------------------
	move.w	(MEM_RANDOM_1),d6
	and.w	#$0FFF,d6
	cmpi.w	#$0010,d6
	bgt.s	.1
	move.w	#$3FFF,d7
	sub.w	d6,d7
	move.w	d7,(MEM_RANDOM_1)
.1
	move.w	(MEM_RANDOM_2),d6
	and.w	#$0FFF,d6
	cmpi.w	#$0010,d6
	bgt.s	.2
	move.w	#$3FFF,d7
	sub.w	d6,d7
	move.w	d7,(MEM_RANDOM_2)
.2
	move.w	(MEM_RANDOM_3),d6
	and.w	#$00FF,d6
	lsl.w	#8,d6
	cmpi.w	#$3F00,d6
	ble.s	.3
	move.w	#$3F00,d7
	sub.w	d7,d6
.3
	move.w	d6,(MEM_RANDOM_3)
	
	;---------------------------------------------------------------------------
	; build the guaranteed path
	;---------------------------------------------------------------------------	
	; build the floor queue
	lea	MEM_FLOOR_QUEUE,a0
	move.w	#$0001,(a0)+
	move.w	#$0002,(a0)+
	move.w	#$0003,(a0)+
	move.w	#$0004,(a0)+
	move.w	#$0005,(a0)+
	move.w	#$0006,(a0)+
	move.w	#$0007,(a0)+
	move.w	#$0008,(a0)+
	move.w	#$0009,(a0)+
	move.w	#$000A,(a0)+
	move.w	#$000B,(a0)+
	move.w	#$000C,(a0)+
	move.w	#$000D,(a0)+
	move.w	#$000E,(a0)+
	move.w	#$0000,(a0)+
	move.w	#$0000,(a0)+
	; use d7 to count the number of rooms that need to be sorted
	move.w	#$000E,d7 ; 14 rooms to sort since floors 0 and F are in fixed positions
	; build the guaranteed path
	lea MEM_GUARANTEED_ORDER,a1 ; point a1 to the guaranteed order
	move.w	#$0000,(a1)+ ; floor 0 is always first
BuildGuaranteedOrder:
	clr d0 ; clr done out of paranoia
	move.w	(MEM_RANDOM_1),d0
	clr	d1 ; clr done out of paranoia
	move.w	d7,d1 ; copy the value in d7 (floor counter) to d1
	divu	d1,d0 ; divu does divide + mod
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	move.w	d0,d1 ; need this value again later
	; move to the index in d0 on the floor queue
	mulu.w	#WORD_SIZE,d0 ; multiply by LWORD_SIZE to get offset
	lea MEM_FLOOR_QUEUE,a0 ; point a0 to the start of the floor queue	
	adda.l	d0,a0 ; move to offset
	move.w	(a0),(a1)+ ; copy the value from floor queue to guaranteed path
	; adjust the floor queue
	lea (2,a0),a2 ; point a2 to the word past the current entry in the floor queue
	move.w	d7,d6 ; move current size of list to d6
	sub.w	d1,d6 ; subtract the index of the item being removed
ReorderFloorQueue1:
	move.w (a2)+,(a0)+ ; shift values down
	dbra d6,ReorderFloorQueue1
	dbra d7,BuildGuaranteedOrder
	move.w	#$000F,(-2,a1) ; floor F is always last

	;---------------------------------------------------------------------------
	; build the random path
	;---------------------------------------------------------------------------	
	; re-build the floor queue
	lea	MEM_FLOOR_QUEUE,a0
	move.w	#$0001,(a0)+
	move.w	#$0002,(a0)+
	move.w	#$0003,(a0)+
	move.w	#$0004,(a0)+
	move.w	#$0005,(a0)+
	move.w	#$0006,(a0)+
	move.w	#$0007,(a0)+
	move.w	#$0008,(a0)+
	move.w	#$0009,(a0)+
	move.w	#$000A,(a0)+
	move.w	#$000B,(a0)+
	move.w	#$000C,(a0)+
	move.w	#$000D,(a0)+
	move.w	#$000E,(a0)+
	move.w	#$000F,(a0)+
	move.w	#$0000,(a0)+
	; use d7 to count the number of rooms that need to be sorted
	move.w	#$000F,d7 ; 15 rooms to sort since floors 0 and F are in fixed positions
	; build the guaranteed path
	lea MEM_RANDOM_ORDER,a1 ; point a1 to the random order
	move.w	#$0000,(a1)+ ; floor 0 is always first
BuildRandomOrder:
	clr d0 ; clr done out of paranoia
	move.w	(MEM_RANDOM_2),d0
	clr	d1 ; clr done out of paranoia
	move.w	d7,d1 ; copy the value in d7 (floor counter) to d1
	divu	d1,d0 ; divu does divide + mod
	clr.w	d0 ; clear the quotient part
	swap	d0 ; move modulus to lower word
	move.w	d0,d1 ; need this value again later
	; move to the index in d0 on the floor queue
	mulu.w	#WORD_SIZE,d0 ; multiply by LWORD_SIZE to get offset
	lea MEM_FLOOR_QUEUE,a0 ; point a0 to the start of the floor queue	
	adda.l	d0,a0 ; move to offset
	move.w	(a0),(a1)+ ; copy the value from floor queue to random path
	; adjust the floor queue
	lea (2,a0),a2 ; point a2 to the word past the current entry in the floor queue
	move.w	d7,d6 ; move current size of list to d6
	sub.w	d1,d6 ; subtract the index of the item being removed
ReorderFloorQueue2:
	move.w (a2)+,(a0)+ ; shift values down
	dbra d6,ReorderFloorQueue2
	; now move the first item in the floor queue to the random list
	lea MEM_FLOOR_QUEUE,a0 ; point a0 to the start of the floor queue		
	move.w	(a0),(a1)+ ; copy the value from floor queue to random path	
	lea (2,a0),a2 ; point a2 to the word past the current entry in the floor queue
	move.w	d7,d6 ; move current size of list to d6
ReorderFloorQueue3:
	move.w (a2)+,(a0)+ ; shift values down
	dbra d6,ReorderFloorQueue3
	sub.w	#$0002,d7
	bge.w	BuildRandomOrder
	move.w	#$0000,d7	
ExitBuildPaths:
	move.w	#$2000,sr ; re-enable interrupts
	rts
