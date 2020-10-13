; $VER: background.asm 1.0 (26.01.20)
;
; background.asm
; The background used during the example
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200126
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include background.i
		
		section	gfxdata,data_c
		cnop	0,2

bground INCBIN "data/background_6bpl_raw"
; End of File