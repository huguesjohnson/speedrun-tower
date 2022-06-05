;-------------------------------------------------------------------------------
; These sub-routines are not entirely my original code.
; 3-button controller read is based off various samples (see credits file).
; Although most of those are based on Sega's documentation sent to developers.
; There's kind of just one way to read controllers on the Genesis anyway.
; And then later via brute force trial & error I added 6-button support.
;-------------------------------------------------------------------------------
ReadJoypads:
	move.w	#$2700,sr		; disable interrupts
	lea	CTRL_1_DATA,a0		; load address to read controller 1 data
	bsr.s	ReadJoypad		; read first joypad
	; code to read second joypad, not used for this demo
	; addq.w	#2,a0		; switch to second joypad data
	; bsr.s	ReadJoypad		; read second joypad
	move.w	#$2000,sr		; re-enable interrupts
	rts
	
ReadJoypad:
	;---------------------------------
	; set counter to 1 + TH high
	;---------------------------------
	move.b	#$40,(a0)	; set TH high
	nop					; bus synchronization
	nop					; bus synchronization
	move.b	(a0),d0		; get joypad data - C/B/Dpad
	andi.b	#%00111111,d0	; C/B/Dpad in low 6 bits
	;---------------------------------
	; set counter to 2 + TH low
	;---------------------------------
	move.b	#$00,(a0)	; set TH low
	nop					; bus synchronization
	nop					; bus synchronization
	move.b	(a0),d1		; get joypad data - Start/A
	lsl.b	#2,d1		; shift them so they are at the 2 highest bits
	andi.b	#%11000000,d1	; Start/A in high 2 bits - clear others
	or.b	d1,d0		; merge values from both registers
	not.b	d0			; flip bits so 0 means not pressed, and 1 means pressed
	move.b	d0,d1		; copy current buttons to d1
	move.b	(MEM_CONTROL_HELD),d2		; copy the last previously read buttons
	eor.b	d2,d0		; flip buttons being pressed now
	move.b	d1,(MEM_CONTROL_HELD)	; store held buttons
	and.b	d1,d0		; AND with current buttons
	move.b	d0,(MEM_CONTROL_PRESSED)	; store pressed buttons
	;-------------------------------------------------------------------------
	; if this is a 3 button controller skip the remaining steps 
	;-------------------------------------------------------------------------
	tst.b	(MEM_CONTROL_1_6BUTTON)	; is this zero?
	bne.s	ReadJoypad6	; zero means 3 button controller
	and.w	#$0000,(MEM_CONTROL_6_HELD)
	and.w	#$0000,(MEM_CONTROL_6_PRESSED)
	rts
ReadJoypad6:
	;---------------------------------
	; set counter to 3 + TH high
	;---------------------------------
	move.b	#$40,(a0)	; set TH high
	nop					; bus synchronization
	nop					; bus synchronization
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
	;---------------------------------	
	move.b	#$00,(a0)	; set TH low
	nop					; bus synchronization
	nop					; bus synchronization
	;---------------------------------
	; set counter to 7 + TH high
	;---------------------------------	
	move.b	#$40,(a0)	; set TH high
	nop					; bus synchronization
	nop					; bus synchronization
	move.b	(a0),d0		; get joypad data - x/y/z/mode
	not.b	d0			; flip bits so 0 means not pressed, and 1 means pressed
	and.b	#%00001111,d0	; x/y/z/mode are in lowest 4 bits
	move.b	d0,d1		; copy current buttons to d1
	move.b	(MEM_CONTROL_6_HELD),d2		; copy the last previously read buttons
	eor.b	d2,d0		; flip buttons being pressed now
	move.b	d1,(MEM_CONTROL_6_HELD)	; store held buttons
	and.b	d1,d0		; AND with current buttons
	move.b	d0,(MEM_CONTROL_6_PRESSED)	; store pressed buttons
	;---------------------------------
	; set counter to 8 + TH low
	;---------------------------------	
	move.b	#$00,(a0)	; set TH low
	nop					; bus synchronization
	nop					; bus synchronization
	;---------------------------------
	; set counter to 9 + TH high
	;---------------------------------
	move.b	#$40,(a0)	; set TH high
	nop					; bus synchronization
	nop					; bus synchronization
	;---------------------------------
	; done reading controller
	;---------------------------------
ExitReadJoypad:
	rts
