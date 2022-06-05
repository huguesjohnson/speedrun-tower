	;---------------------------------------------------------------------------
	; reusable code for the retail clerk series of games
	;---------------------------------------------------------------------------
	include	'lib/retailclerk/inc_RetailClerk.X68'
	
	;---------------------------------------------------------------------------
	; things specific to this demo
	;---------------------------------------------------------------------------
	include	'sub_BuildPaths.X68'
	include	'sub_BuildStatusScreen.X68'
	include	'sub_BuildCharacterSelectScreen.X68'
	include	'sub_EndDemo.X68'
	include 'sub_InitNPCLocations.X68'
	include 'sub_ProcessStatusScreen.X68'
	include	'sub_ProcessTitleScreen.X68'
	include	'sub_ProcessCharacterSelectScreen.X68'

	if _DEBUG_
	include	'init_Debug.X68'
	endif
