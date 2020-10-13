; $VER: displaybuffers.i 1.0 (15.02.20)
;
; displaybuffers.i
; 
; Include file for displaybuffer constants
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200215
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Buffers
	XREF	fg_buf1
	XREF	fg_buf2
	XREF	fg_buf3
	XREF	sb_buf
	XREF	bg_buf1
	XREF	bg_buf2

; Buffer constants
display_width		EQU	288
buffer_width		EQU	320
buffer_screens		EQU	50
buffer_height		EQU	224+(32*2)
buffer_scroll_hgt	EQU buffer_height+buffer_screens
buffer_size			EQU	(buffer_width+(32*2))*buffer_scroll_hgt/8 ; 304x224+ bob space
buffer_modulo		EQU	(buffer_width+(32*2))/8					; Width in bytes
subbuffer_height	EQU	16
subbuffer_size		EQU	buffer_width*subbuffer_height/8
subbuffer_modulo	EQU	buffer_width/8
fg_mod				EQU	buffer_modulo*6
sb_mod	 			EQU	subbuffer_modulo*3

; AGA 4x display modulo: ((width/8)*depth-1)+(width/8)-(fetch_width/8)-8*scroll
; note: fetch_width is the nearest multiple of 64 (rounded up) of the display_width
fg_disp_mod			EQU	(buffer_modulo*5)+(buffer_modulo-(buffer_width/8))
sb_disp_mod			EQU	subbuffer_modulo*2

; OCS display modulos: ((width/8)*depth-1)+(width/8)-(display_width/8)-2*scroll
fg_disp_mod_ocs		EQU	(buffer_modulo*3)+(buffer_modulo-(display_width/8))-2
sb_disp_mod_ocs		EQU	subbuffer_modulo*2
; End of File

; A few notes about AGA displays in 4x fetch mode and display windows
; AGA in 4x mode fetches 64 pixels per fetch and can't start fetching on all
; DDFSTRT values. Supported values for DDFSTRT/STOP are below.
;
; Address Locations: $38 $40 $48 $50 $58 $60 $68 $70 $78 $80 $88 $90 $98 $a0 $a8 $b0 $b8 $c0 $c8 $d0 $d8
; x1 fetch mode: SRT |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |STP
; x2 fetch mode: SRT |       |       |       |       |       |       |       |       |       |STP
; x4 fetch mode: SRT |               |               |               |               |STP
; Table courtesy of Ross @ EAB.
;
; The direct consequence of this is that a screen that is not a multiple of
; 64 pixels wide and is centered will have started fetching data before 
; anything is visible. Meaning that the addresses used for X values need to
; shift. For a 288 pixel wide screen this amounts to shifting by 2 bytes as
; the screen is shifted right by 16 pixels from the default starting position
;
; Also note that alignment restrictions mean that 4xAGA needs bitmaps to be
; aligned on 64 bit boundaries, even when scrolling. So a scrolling AGA screen
; needs to use AGA's 64 pixel shifting or do some memory copying.