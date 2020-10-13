; $VER: tiles.i 1.0 (16.09.18)
;
; tiles.i
; Include file for tiles.asm
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20180916
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; External references
	XREF	sb_tiles
	
; Constants
tile_height		EQU	16
sb_tsize		EQU 16*3*2	; 16 lines/3 planes/1 word
sb_tbsize	EQU (16*3)<<6|1

; End of File