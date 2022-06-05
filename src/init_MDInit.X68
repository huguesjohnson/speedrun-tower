;*******************************************************************************
; initialization
;*******************************************************************************
		
Start:

	move.w	#$2700,sr		; disable interrupts

SecurityCheck:
	move.b	(REG_HWVERSION),d0	; get the hardware version
	andi.b	#$0F,d0				; the last four bits contains the version
	beq.b	SkipSecurity		; skip the next instruction on v1 hardware
	move.l	#'SEGA',(REG_TMS)	; otherwise copy 'SEGA' to TMS register
SkipSecurity:

	if _ATGAMES_HACKS_
    ; AtGames audio fix
    ; based on: https://web.archive.org/web/20180901011803/https://bigevilcorporation.co.uk/2018/04/18/taming-the-atgames-firecore/
	move.w #$FFFF,($00000000)  ; Latch 0x0000
	move.b #$78,($00B00018)    ; Write new PSG frequency
	move.b #$26,($00B01054)    ; Write new FM frequency
	move.b #$20,($00B01055)    ; Write new FM clock
	move.w #$FFF7,($00000000)  ; Latch 0x0000
	endif

ClearRAM:
	lea	MEM_START,a0
	move.w	#(MEM_END-MEM_START),d1
ClearRAMLoop:
	move.w	#$0000,(a0)+
	dbf	d1,ClearRAMLoop

InitController:
	move.b	#$40,(CTRL_1_CONTROL)
	move.b	#$40,(CTRL_1_DATA)
	; --------------------------------------------------------------------------
	; This attempts to figure out what type of controller is connected
	; This is based off documentation provided by Sega to Genesis developers
	; Modified to also check whether a 6-button controller is present
	; --------------------------------------------------------------------------
	lea	CTRL_1_DATA,a0		; load address to read controller 1 data
	;---------------------------------
	; set counter to 1 + TH high
	;---------------------------------
	move.b	#$40,(a0)
	nop
	nop
	;---------------------------------
	; set counter to 2 + TH low
	;---------------------------------
	move.b	(a0),d0
	move.b	#$00,(a0)
	nop
	nop
	;---------------------------------
	; set counter to 3 + TH high
	;---------------------------------
	move.b	#$40,(a0)
	nop
	nop
	move.w	d0,d2
	lsr.b	#1,d0
	ror.w	#1,d0
	lsr.b	#1,d0
	rol.w	#1,d0
	ror.w	#1,d2
	lsr.b	#1,d2
	rol.w	#1,d2
	or.b	d2,d0
	and.w	#$03,d0
	lsl.b	#2,d0
	move.w	d1,d2
	lsr.b	#1,d1
	ror.w	#1,d1
	lsr.b	#1,d1
	rol.w	#1,d1
	ror.w	#1,d2
	lsr.b	#1,d2
	rol.w	#1,d2
	or.b	d2,d1
	and.w	#$03,d1
	or.b	d1,d0
	; -------------------------------------	
	; save the controller id
	; -------------------------------------	
	move.b	d0,(MEM_CONTROL_1_ID)
	;---------------------------------
	; set counter to 4 + TH low
	;---------------------------------
	move.b	#$00,(a0)	; set TH low
	nop					; bus synchronization
	nop					; bus synchronization
	;---------------------------------
	; set counter to 5 + TH high
	;---------------------------------	
	move.b	#$40,(a0)	; set TH high
	nop					; bus synchronization
	nop					; bus synchronization
	;---------------------------------
	; set counter to 6 + TH low
	; 6 button id is in counter 6
	;---------------------------------	
	move.b	#$00,(a0)	; set TH low
	nop					; bus synchronization
	nop					; bus synchronization
	move.b	(a0),d0	; copy controller data to d0
	cmpi.b	#%00110011,d0
	beq.s	ExitInitController
	move.b	#%111111,(MEM_CONTROL_1_6BUTTON)
ExitInitController:

InitVDP:
	lea	(VDPInitDataStart),a0	; load the address of the VDP init data to a0
	move.w	#(VDPInitDataEnd-VDPInitDataStart)/2,d1	; length of init data to d1
InitVDPDataLoop:
	move.w	(a0)+,(VDP_CONTROL)	; write the init data
	dbf	d1,InitVDPDataLoop		; decrement value of d1 and loop if not 0

ClearCRAM:
	move.l	#VDP_CRAM_WRITE,(VDP_CONTROL); set VDP ctrl to CRAM write
	move.w	#$003f,d1	; 3f = 63 = (64 palettes in CRAM - 1)
ClearCRAMLoop:
	if _DEBUG_
	move.w	#$FFFF,(VDP_DATA)
	else
	move.w	#$0000,(VDP_DATA)
	endif
	dbf	d1,ClearCRAMLoop

; clear VRAM - prevents garbage tiles from showing at boot on clone systems
	bsr.w	ClearVRAM	; clear VRAM

InitEcho:
	lea (EchoPointerList),a0
	jsr Echo_Init

	move.w	#$2000,sr		; re-enable interrupts
