ReloadSpriteTiles:
	bsr.w	LoadSpriteZeroTiles
	bsr.w	LoadPlayerSpriteTiles
	; this gets the player tiles back but sprite is in wrong position
	bsr.w	LoadPlayerSprite
	; player will be back at default location
	move.l	#PLAYER_SPRITE_VDP_Y,(VDP_CONTROL)	; set write location in VDP
	move.w	(MEM_PLAYER_SPRITE_Y),(VDP_DATA)	; copy the new y-coordinate
	move.l	#PLAYER_SPRITE_VDP_X,(VDP_CONTROL)	; set write location in VDP
	move.w	(MEM_PLAYER_SPRITE_X),(VDP_DATA)	; copy the new y-coordinate
	move.w	#$2700,sr		; disable interrupts
	bsr.w	LoadSceneLoadNPCSprites
	; needed to get all sprites displaying
	bsr.w	SetSpriteLinks
	move.w	#$2000,sr		; re-enable interrupts
	rts
