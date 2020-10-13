; $VER: tilemap.asm 1.0 (16.09.18)
;
; tilemap.asm
; 
; This file contains tilemap data and support functions for drawing from the 
; tilemap.
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20180916
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

	include debug.i
	include	displaybuffers.i
	include blitter.i
	include tiles.i
	include tilemap.i

		section code,code
		; Routine: DrawSubBuffer
		; This routine draws the Sub Buffer tiles
DrawSubBuffer
		; Fetch the tilemap, tiles and subbuffer
		lea.l	sb_tile_map,a0
		lea.l	sb_tiles,a1
		move.l	sb_buf,a3
		lea.l	2(a3),a3		; Shift forward due to AGA 4x fetch alignment
		
		; Set up registers for BlitCopy
		move.l	#subbuffer_modulo-2,d4
		move.w	#sb_tbsize,d5
		
		; Loop over tiles
		moveq	#(display_width/16)-1,d7
.lp		move.w	(a0)+,d1		; Fetch tile
		mulu	#sb_tsize,d1
		lea.l	0(a1,d1),a2		; Source
		bsr		BlitCopy
		lea.l	2(a3),a3		; Move to next spot in destination
		dbra	d7,.lp
		rts
		
		section data,data
		cnop	0,2

		; Tilemaps
		; 18x1 tiles for subbuffer
sb_tile_map		dc.w	$0,$1,$1,$1,$1,$1,$1,$2,$1,$1,$1,$1,$1,$2,$1,$1,$1,$3	; Line 1
; End of File