; $VER: SPR_Layer.i 1.0 (15.02.20)
;
; SPR_Layer.i
; 
; Include file for main file. 
; Based on earlier code.
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200215
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; External references
	XDEF	_main

	XREF	c2frame_cn
	XREF	fg_offset
	
; Constants
DSTATE_CPU_ONLY		EQU	0
DSTATE_BLITTER_ONLY	EQU	1
DSTATE_COMBINED		EQU	2

MLOOP_COL			EQU	$770
CPU_COL				EQU	$077
BLITTER_COL			EQU	$700
COMBO_COL			EQU	$707

; Structures
 STRUCTURE Bob,0
	ULONG	bob_X
	ULONG	bob_Y
	ULONG	bob_DX
	ULONG	bob_DY
	LABEL	bob_SIZEOF
	
; End of File