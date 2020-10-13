; $VER: titletext.asm 1.0 (09.02.20)
;
; titletext.asm
; Title screen text
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200209
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes
		include titletext.i

		; Title screen text
titletxt		dc.w	19					; Count
				dc.w	6,7,0				; Colour, X, Y
				dc.w	.line1_end-.line1	; Length of text line
.line1			dc.b	"CPU Assisted Blitting"
			cnop 0,2	; Realign
.line1_end
				dc.w	9,0,3
				dc.w	.line2_end-.line2
.line2			dc.b	"This program shows the difference in"
			cnop 0,2	; Realign
.line2_end
				dc.w	9,0,4
				dc.w	.line3_end-.line3
.line3			dc.b	"speed between three methods of"
			cnop 0,2	; Realign
.line3_end
				dc.w	9,0,5
				dc.w	.line4_end-.line4
.line4			dc.b	"blitting bobs: using CPU, Blitter or"
			cnop 0,2	; Realign
.line4_end
				dc.w	9,0,6
				dc.w	.line5_end-.line5
.line5			dc.b	"both combined."
			cnop 0,2	; Realign
.line5_end
				dc.w	9,0,8
				dc.w	.line6_end-.line6
.line6			dc.b	"It runs in 6 bitplanes and uses the"
			cnop 0,2	; Realign
.line6_end
				dc.w	9,0,9
				dc.w	.line7_end-.line7
.line7			dc.b	"AGA chipset's 4x fetch mode. No"
			cnop 0,2	; Realign
.line7_end
				dc.w	9,0,10
				dc.w	.line8_end-.line8
.line8			dc.b	"sprites or scrolling are used."
			cnop 0,2	; Realign
.line8_end
				dc.w	9,0,11
				dc.w	.line9_end-.line9
.line9			dc.b	"All (soft) bobs use all 6 bitplanes."
			cnop 0,2	; Realign
.line9_end
				dc.w	9,0,13
				dc.w	.line10_end-.line10
.line10			dc.b	"Correct results require using a real"
			cnop 0,2	; Realign
.line10_end
				dc.w	9,0,14
				dc.w	.line11_end-.line11
.line11			dc.b	"A1200. Accelerators or emulators can"
			cnop 0,2	; Realign
.line11_end
				dc.w	9,0,15
				dc.w	.line12_end-.line12
.line12			dc.b	"overestimate program performance."
			cnop 0,2	; Realign
.line12_end
				dc.w	11,0,17
				dc.w	.line13_end-.line13
.line13			dc.b	"More info? See sourcecode or readme."
			cnop 0,2	; Realign
.line13_end
				dc.w	12,0,19
				dc.w	.line14_end-.line14
.line14			dc.b	"Instructions:"
			cnop 0,2	; Realign
.line14_end
				dc.w	12,0,20
				dc.w	.line15_end-.line15
.line15			dc.b	"* Joystick button toggles whether"
			cnop 0,2	; Realign
.line15_end
				dc.w	12,2,21
				dc.w	.line16_end-.line16
.line16			dc.b	"timing bars are shown or hidden"
			cnop 0,2	; Realign
.line16_end
				dc.w	12,0,22
				dc.w	.line17_end-.line17
.line17			dc.b	"* Left mouse button switches modes"
			cnop 0,2	; Realign
.line17_end
				dc.w	12,0,23
				dc.w	.line18_end-.line18
.line18			dc.b	"* Right mouse button exits program"
			cnop 0,2	; Realign
.line18_end
				dc.w	11,2,26
				dc.w	.line19_end-.line19
.line19			dc.b	"Press left mouse button to begin."
			cnop 0,2	; Realign
.line19_end


; End of File