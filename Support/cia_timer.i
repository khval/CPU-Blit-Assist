; $VER: ciatiming.i 1.0 (13.02.20)
;
; ciatiming.asm
; This file contains macro's to stop and start the CIA timer.
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200213
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
	include hardware/cia.i
	
	IFND	CIA_TIMER_I
CIA_TIMER_I	SET	1
		
; Custom chip offsets
ciabase		EQU	$bfe000

		section	code,code
		
		; CIA timer start & CIA timer stop macro's
CIAStart	MACRO
		; Set up CIA timer A for one shot mode
		move.b	ciacra(a5),d0
		and.b	#%11000000,d0			; Keep bits 6&7 as is
		or.b    #%00001000,d0			; Set for one-shot mode
		move.b	d0,ciacra(a5)
        move.b	#%01111111,ciaicr(a5)	; Clear all CIA interrupts
		
		; Set up timer value (low byte first)
		move.b	#$ff,ciatalo(a5)
		move.b	#$ff,ciatahi(a5)
			ENDM
			
CIAStop		MACRO
		; Stop timer & fetch result
		bclr	#0,ciacra(a5)
		moveq	#0,d6
		moveq	#0,d7
		move.b	ciatalo(a5),d6
		move.b	ciatahi(a5),d7
		asl.w	#8,d7
		or.w	d7,d6
		move.w	d6,d0
			ENDM
			
	ENDC	; CIA_TIMER_I
; End of File