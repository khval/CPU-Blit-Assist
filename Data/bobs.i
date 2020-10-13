; $VER: bobs.i 1.0 (15.02.20)
;
; bobs.i
; Include file for bobs.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200215
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; External references
	XREF	restore_ptrs
	XREF	bob
	XREF	mask
	XREF	mask_1bpl
	
; Constants
; Note: All bob counts chosen to be maximum before dropping to 25Hz
bob_count_cpu	EQU	8	; 8
bob_count_blt	EQU	17	; 17
bob_count_combo	EQU	19	; 19
bob_bsize		EQU	(32*6)<<6|3
bob_bwidth		EQU	6

; End of File