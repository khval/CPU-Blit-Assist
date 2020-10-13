; $VER: tiles.asm 1.0 (16.09.18)
;
; tiles.asm
; Subbuffer tiles
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20180916
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include tiles.i
		
		section	gfxdata,data_c
		cnop	0,2

sb_tiles INCBIN "data/sb_tiles_raw"	
; End of File