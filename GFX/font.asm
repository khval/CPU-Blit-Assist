; $VER: font.asm 1.5 (16.09.18)
;
; font.asm
; 
; Simple font routines (8x8) for printing debug messages etc.
; Supports both standard and inverted printing.
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20180916
;
; Assembled using VASM in Amiga-link mode.
;

; External references

	; Includes  
	include exec/types.i
	include libs/exec_lib.i
	include hardware/custom.i
	include hardware/dmabits.i
	include hardware/intbits.i

	include	debug.i
	include font.i

; Start of code
			section	code,code
; Font routines
			; Routine PlotCharCPU
			; This routine plots a single character to the given
			; bitmap at the given location.
			;
			; Note: this is not optimised, use it for debugging only!
			;
			; A0 - Pointer to fontdata
			; A1 - Pointer to destination bitmap
			; D0 - Character to plot
			; D1 - X location (in 8x8 cells)
			; D2 - Y location (in 8x8 cells)
			; D3 - Depth
			; D4 - Colour
			; D5 - Bitmap width in bytes
			; D6 - Bitmap plane size in bytes
PlotCharCPU	movem.l	d0-d7/a0-a2,-(sp)		; Deal with stack

			; Calculate offset for bitmap
			move.w	d2,d7
			asl.w	#3,d7
			mulu	d5,d7					; D7 = Y offset
			add.l	d1,d7					; D7 = X/Y offset
			
			; Calculate offset for character list
			asl.w	#3,d0
			
			; Loop over planes
			subq	#1,d3
			
.loop		asr.w	#1,d4						; Shift the palette colour
			bcc		.erase

			; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			lea.l	0(a0,d0),a2
			
			; Draw a character
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,0(a1,d1.l)
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop
			
			movem.l	(sp)+,d0-d7/a0-a2		; Deal with stack
			rts
			
.erase		; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			move.l	#0,a2
			
			; Draw a character
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			add.l	d2,d1
			move.b	#0,0(a1,d1.l)
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop

			movem.l	(sp)+,d0-d7/a0-a2		; Deal with stack
			rts
			
			; Routine: PlotInvertedCharCPU
			; As PlotCharCPU, but all one bits are displayed as zero bits
			; and vice versa.
PlotInvertedCharCPU
			movem.l	d0-d7/a0-a3,-(sp)		; Deal with stack

			; Calculate offset for bitmap
			move.w	d2,d7
			asl.w	#3,d7
			mulu	d5,d7					; D7 = Y offset
			add.l	d1,d7					; D7 = X/Y offset
			
			; Calculate offset for character list
			asl.w	#3,d0
			
			; Loop over planes
			subq	#1,d3
			
.loop		asr.w	#1,d4						; Shift the palette colour
			bcs		.erase

			; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			lea.l	0(a0,d0),a2
			
			; Draw a character
			move.l	d7,a3
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			add.l	d2,d1
			move.b	(a2)+,d7
			not.b	d7
			move.b	d7,0(a1,d1.l)
			move.l	a3,d7
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop
			
			movem.l	(sp)+,d0-d7/a0-a3		; Deal with stack
			rts
			
.erase		; Fetch all offsets/adresses
			move.l	d5,d2
			move.l	d7,d1
			
			; Draw a character
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			add.l	d2,d1
			move.b	#$ff,0(a1,d1.l)
			
			add.l	d6,d7					; Update screen offset
			dbra	d3,.loop

			movem.l	(sp)+,d0-d7/a0-a3		; Deal with stack
			rts
			
			; Routine PlotTextCPU
			; This routine plots a given string to the given
			; bitmap. It uses PlotCharCPU to do so. No range
			; checking is done and the Y coordinate is never
			; updated.
			;
			; Note: this is not optimised, use it for debugging only!
			;
			; A0 - Pointer to fontdata
			; A1 - Pointer to destination bitmap
			; A2 - List of characters to plot
			; D0 - Length of string
			; D1 - Starting X location (in 8x8 cells)
			; D2 - Y location (in 8x8 cells)
			; D3 - Depth
			; D4 - Colour
			; D5 - Bitmap width in bytes
			; D6 - Bitmap plane size in bytes
PlotTextCPU	movem.l	d0-d7/a0-a6,-(sp)		; Deal with stack

			move.w	d0,d7
			subq	#1,d7
			moveq	#0,d0
			
.loop		move.b	(a2)+,d0				; Fetch character
			sub.b	#32,d0					; Convert to ASCII
			bmi		.cnt					; Skip invalid characters
			jsr		PlotCharCPU
.cnt		addq	#1,d1
			dbra	d7,.loop

			movem.l	(sp)+,d0-d7/a0-a6		; Deal with stack
			rts
			
			; Routine: PlotInvertedTextCPU
			; As PlotTextCPU, but all one bits are treated as zero bits and
			; vice versa.
PlotInvertedTextCPU	
			movem.l	d0-d7/a0-a6,-(sp)		; Deal with stack

			move.w	d0,d7
			subq	#1,d7
			moveq	#0,d0
			
.loop		move.b	(a2)+,d0				; Fetch character
			sub.b	#32,d0					; Convert to ASCII
			jsr		PlotInvertedCharCPU
			addq	#1,d1
			dbra	d7,.loop

			movem.l	(sp)+,d0-d7/a0-a6		; Deal with stack
			rts

			; Routine PlotTextMultiCPU
			; This routine plots a set of lines of text to the given bitmap.
			; It uses PlotTextCPU to plot the actual text.
			;
			; Note: this is not optimised, use it for debugging only!
			;
			; A1 - Pointer to destination bitmap
			; A3 - pointer to lines of text to plot.
			; D3 - Depth
			; D5 - Bitmap width in bytes
			; D6 - Bitmap plane size in bytes
PlotTextMultiCPU
			movem.l	d0-d7/a0-a6,-(sp)	; Stack
			lea.l	basicfont,a0
			move.w	(a3)+,d7			; Get loop counter
			subq	#1,d7
			
			; Loop over lines of text
.lp			movem.w	(a3)+,d0-d2
			move.w	(a3)+,d4
			exg		d0,d4			; Correct order for PlotTextCPU
			move.l	a3,a2
			bsr		PlotTextCPU
			lea.l	0(a3,d0),a3		; Next line
			dbra	d7,.lp
			movem.l	(sp)+,d0-d7/a0-a6	; Stack
			rts
			
			section	gfxdata,data_c
			cnop	0,2						; Is this needed?

; Basic font (8x8)
basicfont	dc.b $00,$00,$00,$00,$00,$00,$00,$00
			dc.b $18,$18,$18,$18,$00,$00,$18,$00
			dc.b $66,$66,$66,$00,$00,$00,$00,$00
			dc.b $66,$66,$ff,$66,$ff,$66,$66,$00
			dc.b $18,$3e,$60,$3c,$06,$7c,$18,$00
			dc.b $62,$66,$0c,$18,$30,$66,$46,$00
			dc.b $3c,$66,$3c,$38,$67,$66,$3f,$00
			dc.b $06,$0c,$18,$00,$00,$00,$00,$00
			dc.b $0c,$18,$30,$30,$30,$18,$0c,$00
			dc.b $30,$18,$0c,$0c,$0c,$18,$30,$00
			dc.b $00,$66,$3c,$ff,$3c,$66,$00,$00
			dc.b $00,$18,$18,$7e,$18,$18,$00,$00
			dc.b $00,$00,$00,$00,$00,$18,$18,$30
			dc.b $00,$00,$00,$7e,$00,$00,$00,$00
			dc.b $00,$00,$00,$00,$00,$18,$18,$00
			dc.b $00,$03,$06,$0c,$18,$30,$60,$00
			dc.b $3c,$66,$6e,$76,$66,$66,$3c,$00
			dc.b $18,$18,$38,$18,$18,$18,$7e,$00
			dc.b $3c,$66,$06,$0c,$30,$60,$7e,$00
			dc.b $3c,$66,$06,$1c,$06,$66,$3c,$00
			dc.b $06,$0e,$1e,$66,$7f,$06,$06,$00
			dc.b $7e,$60,$7c,$06,$06,$66,$3c,$00
			dc.b $3c,$66,$60,$7c,$66,$66,$3c,$00
			dc.b $7e,$66,$0c,$18,$18,$18,$18,$00
			dc.b $3c,$66,$66,$3c,$66,$66,$3c,$00
			dc.b $3c,$66,$66,$3e,$06,$66,$3c,$00
			dc.b $00,$00,$18,$00,$00,$18,$00,$00
			dc.b $00,$00,$18,$00,$00,$18,$18,$30
			dc.b $0e,$18,$30,$60,$30,$18,$0e,$00
			dc.b $00,$00,$7e,$00,$7e,$00,$00,$00
			dc.b $70,$18,$0c,$06,$0c,$18,$70,$00
			dc.b $3c,$66,$06,$0c,$18,$00,$18,$00
			dc.b $3c,$66,$6e,$6e,$60,$62,$3c,$00
			dc.b $18,$3c,$66,$7e,$66,$66,$66,$00
			dc.b $7c,$66,$66,$7c,$66,$66,$7c,$00
			dc.b $3c,$66,$60,$60,$60,$66,$3c,$00
			dc.b $78,$6c,$66,$66,$66,$6c,$78,$00
			dc.b $7e,$60,$60,$78,$60,$60,$7e,$00
			dc.b $7e,$60,$60,$78,$60,$60,$60,$00
			dc.b $3c,$66,$60,$6e,$66,$66,$3c,$00
			dc.b $66,$66,$66,$7e,$66,$66,$66,$00
			dc.b $3c,$18,$18,$18,$18,$18,$3c,$00
			dc.b $1e,$0c,$0c,$0c,$0c,$6c,$38,$00
			dc.b $66,$6c,$78,$70,$78,$6c,$66,$00
			dc.b $60,$60,$60,$60,$60,$60,$7e,$00
			dc.b $63,$77,$7f,$6b,$63,$63,$63,$00
			dc.b $66,$76,$7e,$7e,$6e,$66,$66,$00
			dc.b $3c,$66,$66,$66,$66,$66,$3c,$00
			dc.b $7c,$66,$66,$7c,$60,$60,$60,$00
			dc.b $3c,$66,$66,$66,$66,$3c,$0e,$00
			dc.b $7c,$66,$66,$7c,$78,$6c,$66,$00
			dc.b $3c,$66,$60,$3c,$06,$66,$3c,$00
			dc.b $7e,$18,$18,$18,$18,$18,$18,$00
			dc.b $66,$66,$66,$66,$66,$66,$3c,$00
			dc.b $66,$66,$66,$66,$66,$3c,$18,$00
			dc.b $63,$63,$63,$6b,$7f,$77,$63,$00
			dc.b $66,$66,$3c,$18,$3c,$66,$66,$00
			dc.b $66,$66,$66,$3c,$18,$18,$18,$00
			dc.b $7e,$06,$0c,$18,$30,$60,$7e,$00
			dc.b $3c,$30,$30,$30,$30,$30,$3c,$00
			dc.b $00,$60,$30,$18,$0c,$06,$03,$00
			dc.b $3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
			dc.b $00,$18,$3c,$7e,$18,$18,$18,$18
			dc.b $00,$00,$00,$00,$00,$00,$00,$ff
			dc.b $60,$30,$18,$00,$00,$00,$00,$00
			dc.b $00,$00,$3c,$06,$3e,$66,$3e,$00
			dc.b $00,$60,$60,$7c,$66,$66,$7c,$00
			dc.b $00,$00,$3c,$60,$60,$60,$3c,$00
			dc.b $00,$06,$06,$3e,$66,$66,$3e,$00
			dc.b $00,$00,$3c,$66,$7e,$60,$3c,$00
			dc.b $00,$0e,$18,$3e,$18,$18,$18,$00
			dc.b $00,$00,$3e,$66,$66,$3e,$06,$7c
			dc.b $00,$60,$60,$7c,$66,$66,$66,$00
			dc.b $00,$18,$00,$38,$18,$18,$3c,$00
			dc.b $00,$06,$00,$06,$06,$06,$06,$3c
			dc.b $00,$60,$60,$6c,$78,$6c,$66,$00
			dc.b $00,$38,$18,$18,$18,$18,$3c,$00
			dc.b $00,$00,$66,$7f,$7f,$6b,$63,$00
			dc.b $00,$00,$7c,$66,$66,$66,$66,$00
			dc.b $00,$00,$3c,$66,$66,$66,$3c,$00
			dc.b $00,$00,$7c,$66,$66,$7c,$60,$60
			dc.b $00,$00,$3e,$66,$66,$3e,$06,$06
			dc.b $00,$00,$7c,$66,$60,$60,$60,$00
			dc.b $00,$00,$3e,$60,$3c,$06,$7c,$00
			dc.b $00,$18,$7e,$18,$18,$18,$0e,$00
			dc.b $00,$00,$66,$66,$66,$66,$3e,$00
			dc.b $00,$00,$66,$66,$66,$3c,$18,$00
			dc.b $00,$00,$63,$6b,$7f,$3e,$36,$00
			dc.b $00,$00,$66,$3c,$18,$3c,$66,$00
			dc.b $00,$00,$66,$66,$66,$3e,$0c,$78
			dc.b $00,$00,$7e,$0c,$18,$30,$7e,$00
			dc.b $1c,$30,$30,$60,$30,$30,$1c,$00
			dc.b $18,$18,$18,$18,$18,$18,$18,$18
			dc.b $38,$0c,$0c,$06,$0c,$0c,$38,$00
			dc.b $00,$32,$4c,$00,$00,$00,$00,$00

; End of File