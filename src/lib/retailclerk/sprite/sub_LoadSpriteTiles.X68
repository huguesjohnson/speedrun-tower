LoadSpriteZeroTiles:
	bsr.w	WaitVBlank	; added to resolve issue running in Genecyst
	move.w	#$2700,sr		; disable interrupts
	lea	SpriteZeroTilesStart,a0	; set address of first tile to load
	move.w	#SPRITE_VDP,d1	; setup call to BuildVRAMWriteAddress
	bsr.w	BuildVRAMWriteAddress	; build the VRAM write address
	moveq	#$8,d0	; number of tiles in a sprite tileset
	bsr.w	LoadTiles	; branch to LoadTiles subroutine
	move.w	#$2000,sr	; re-enable interrupts
	rts

LoadPlayerSpriteTiles:
	bsr.w	WaitVBlank	; added to resolve issue running in Genecyst
	move.w	#$2700,sr		; disable interrupts
	; **************************************************************************
	; this part is customized for Speedrun Tower
	; to support having multiple player sprites
	; **************************************************************************
	lea	PC00SpriteTilesStart,a0	; set address of first tile to load
	clr.l	d1 ; clear d1
	move.w	(MEM_PC_ID),d1
	mulu.w	#$0C00,d1
	adda.l	d1,a0
	; write tiles to VDP
	clr.l	d1 ; clear d1
	move.w	#PLAYER_SPRITE_VDP,d1	; setup call to BuildVRAMWriteAddress
	bsr.w	BuildVRAMWriteAddress	; build the VRAM write address
	move.w	#SPRITE_TILESET_LWORDS,d0	; number of tiles in a sprite tileset
	bsr.w	LoadTiles	; branch to LoadTiles subroutine
	move.w	#$2000,sr	; re-enable interrupts
	rts
