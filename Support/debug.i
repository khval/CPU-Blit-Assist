; $VER: debug.i 0.1 (12.10.14)
;
; debug.i
; 
; Macros to aid in debugging
;
; Author: Jeroen Knoester
; Version: 0.1
; Revision: 20141012
;
; Assembled using VASM in Amiga-link mode.
;

	IFND	PPLIB_DEBUG_I
PPLIB_DEBUG_I	SET	1

	; Debug macros
	
	; Macro DBGPause
	; This macro pauses non-interrupt code so that the debugger
	; can be used to inspect the program state. Note that this
	; macro does not store condition codes.
	;
	; Pressing left mouse button resumes the program.
DBGPause	MACRO						
.\@_inf		btst    #6,$bfe001				; Check left mouse button (via hardware)
			bne		.\@_inf
.\@_done	btst	#6,$bfe001
			beq		.\@_done				; Wait until no longer pressed
			ENDM
			
DBGPauseCol	MACRO						
.\@_inf		move.w	#\1,$dff180
			btst    #6,$bfe001				; Check left mouse button (via hardware)
			bne		.\@_inf
.\@_done	move.w	#\1,$dff180
			btst	#6,$bfe001
			beq		.\@_done				; Wait until no longer pressed
			ENDM

	ENDC	; PP_DEBUG_I
	
	; Macro DBGBreakPnt
	; This macro writes to a specified memory adress.
	; By setting up the debugger to watch for accesses to this
	; addres, breakpoints can be simulated
DBGBreakPnt	MACRO
			move	PP_DBGBRKPOINT,PP_DBGBRKPOINT
			ENDM

; Constants
PP_DBGBRKPOINT	EQU	$8					; Memory adress accessed to generate breakpoint

; End of File