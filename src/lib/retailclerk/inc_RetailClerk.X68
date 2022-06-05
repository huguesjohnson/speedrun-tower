	;---------------------------------------------------------------------------
	; reusable code for the retail clerk series of games
	;---------------------------------------------------------------------------
	; i/o
	include	'lib/retailclerk/io/sub_ReadJoypads.X68'
	include 'lib/retailclerk/io/sub_SaveLoad.X68'	
	; graphics
	include	'lib/retailclerk/graphics/sub_BuildVRAMWriteAddress.X68'
	include	'lib/retailclerk/graphics/sub_ClearVRAM.X68'
	include	'lib/retailclerk/graphics/sub_DrawTileset.X68'
	include	'lib/retailclerk/graphics/sub_FadeInFadeOut.X68'
	include	'lib/retailclerk/graphics/sub_LoadPalettes.X68'
	include	'lib/retailclerk/graphics/sub_LoadTiles.X68'
	; event handling
	include	'lib/retailclerk/event/sub_BuildActionTableOffset.X68'
	include 'lib/retailclerk/event/sub_FindActionTarget.X68'
	include	'lib/retailclerk/event/sub_ProcessAction.X68'
	include	'lib/retailclerk/event/sub_ProcessIntroScreen.X68'
	include 'lib/retailclerk/event/sub_ProcessScriptedEvent.X68'
	include	'lib/retailclerk/event/sub_QueueScriptedEvent.X68'
	; sprite handling
	include	'lib/retailclerk/sprite/sub_FixSprites.X68'
	include	'lib/retailclerk/sprite/sub_FlipSpriteMapPosition.X68'
	include	'lib/retailclerk/sprite/sub_LoadPlayerSprite.X68'
	include	'lib/retailclerk/sprite/sub_LoadSpriteTiles.X68'
	include	'lib/retailclerk/sprite/sub_MovePlayer.X68'
	include	'lib/retailclerk/sprite/sub_MoveSprite.X68'
	include	'lib/retailclerk/sprite/sub_OrderSprites.X68'
	include	'lib/retailclerk/sprite/sub_ReloadSpriteTiles.X68'
	include	'lib/retailclerk/sprite/sub_SetActiveSpriteMapRowCol.X68'
	include	'lib/retailclerk/sprite/sub_SetDefaultSpriteOrder.X68'
	include	'lib/retailclerk/sprite/sub_SetSpriteLink.X68'
	include	'lib/retailclerk/sprite/sub_SetSpriteLinks.X68'
	include	'lib/retailclerk/sprite/sub_SetSpritePattern.X68'
	include	'lib/retailclerk/sprite/sub_StopSprite.X68'
	include	'lib/retailclerk/sprite/sub_TestSpriteCollision.X68'
	include	'lib/retailclerk/sprite/sub_UpdateSpriteSortTable.X68'
	; scene handling
	include 'lib/retailclerk/scene/sub_BuildNPCObjectList.X68'
	include 'lib/retailclerk/scene/sub_DrawScene.X68'
	include 'lib/retailclerk/scene/sub_LoadScene.X68'
	include 'lib/retailclerk/scene/sub_ReloadCurrentScene.X68'
	; dialog handling
	include	'lib/retailclerk/dialog/sub_ClearDialog.X68'
	include	'lib/retailclerk/dialog/sub_ProcessDialog.X68'
	include	'lib/retailclerk/dialog/sub_ResetDialog.X68'
	include	'lib/retailclerk/dialog/sub_SetDialogOpening.X68'
	include	'lib/retailclerk/dialog/sub_ShowInteractDialog.X68'
	; inventory handling
	include	'lib/retailclerk/inventory/sub_ClearPlayerInventory.X68'
	include	'lib/retailclerk/inventory/sub_Inventory.X68'
