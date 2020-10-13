; $VER: background.i 1.0 (26.01.20)
;
; background.i
; Include file for background.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200126
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; External references
	XREF	bground
	
; Constants
bground_bsize	EQU	(224*6)<<16|((288)/16)

; End of File