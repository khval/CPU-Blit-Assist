; $VER: bobs.asm 1.0 (15.02.20)
;
; bobs.asm
; Bob data
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200215
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include bobs.i
		
		section	data,data
		; 2 pointers per bob/per frame (2 frames needed)
restore_ptrs	blk.l	bob_count_combo*4
		
		section	gfxdata,data_c
		cnop	0,4
		
bob			INCBIN "data/bob_6bpl_raw"
mask		INCBIN "data/mask_6bpl_raw"
; End of File