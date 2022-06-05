InitNPCLocations:
	lea MEM_NPC_LOCATIONS,a0
	move.l	#$09000000,(a0)+	; location 00 (floor00)
	move.l	#$0A0B0000,(a0)+	; location 01 (floor01)
	move.l	#$0C0D0000,(a0)+	; location 02 (floor02)
	move.l	#$0E0F0000,(a0)+	; location 03 (floor03)
	move.l	#$10110000,(a0)+	; location 04 (floor04)
	move.l	#$00000000,(a0)+	; location 05 (floor05)
	move.l	#$12000000,(a0)+	; location 06 (floor06)
	move.l	#$13140000,(a0)+	; location 07 (floor07)
	move.l	#$15000000,(a0)+	; location 08 (floor08)
	move.l	#$16170000,(a0)+	; location 09 (floor09)
	move.l	#$18000000,(a0)+	; location 0A (floor0A)
	move.l	#$19000000,(a0)+	; location 0B (floor0B)
	move.l	#$1A000000,(a0)+	; location 0C (floor0C)
	move.l	#$1B000000,(a0)+	; location 0D (floor0D)
	move.l	#$1C1D0000,(a0)+	; location 0E (floor0E)
	move.l	#$1E1F0000,(a0)+	; location 0F (floor0F)
	move.l	#$09140D19,(a0)+	; location 10 (SceneCreditsProgram)
	move.l	#$0E1B1D0C,(a0)+	; location 11 (SceneCreditsGraphics)
	move.l	#$0A171F10,(a0)+	; location 12 (SceneCreditsSound)
	move.l	#$0F121815,(a0)+	; location 13 (SceneEndingBad)
	move.l	#$111C1613,(a0)+	; location 14 (SceneEndingGood)
	move.l	#$1A1E0000,(a0)+	; location 15 (SceneEndingPerfect)

	rts

