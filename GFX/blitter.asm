; $VER: blitter.asm 1.0 (15.02.20)
;
; blitter.asm
; 
; Contains blitter routines for the example program.
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200215
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes 
	include exec/types.i
	include hardware/custom.i
	include hardware/dmabits.i
	include hardware/intbits.i
	
	include	debug.i
	include blitter.i
	include tilemap.i
	include displaybuffers.i
	include	bobs.i
	
BLTSIZV	EQU	$05c
		
		; Blitting routines
		section code,code

		; Routine: BlitPattern
		; This routine blits a single word pattern to a given bitmap
		; D1 = word pattern to blit
		; D4 = DMOD value
		; D5 = BLTSIZE value
		; A2 = Destination bitmap
BlitPattern
		BlitWait a6
		move.l	bl_clear,bltcon0(a6)
		move.w	d4,bltdmod(a6)
		move.w	d1,bltadat(a6)
		move.l	a2,bltdpt(a6)
		move.w	d5,bltsize(a6)
		rts

		; Routine BlitCopy
		; This routine copies a given bitmap to a destination bitmap
		; D4 = ADMOD value
		; D5 = BLTSIZE value
		; A2 = Source bitmap
		; A3 = Destination bitmap
BlitCopy
		BlitWait a6
		move.l	bl_copy,bltcon0(a6)
		move.l	d4,bltamod(a6)
		move.l	a2,bltapt(a6)
		move.l	a3,bltdpt(a6)
		move.w	d5,bltsize(a6)
		rts
		
		; Routine BlitCopyIL
		; This routine copies a given bitmap to a destination bitmap
		; It uses the B & D channels rather than the A & D channels.
		; This combination means the Blitter uses less of the bus than usual.
		; D4 = Modulo value (high word is B modulo, low word is D modulo)
		; D5 = BLTSIZE value
		; A2 = Source bitmap
		; A3 = Destination bitmap
BlitCopyIL
		BlitWait a6
		move.l	bl_copyil,bltcon0(a6)
		move.l	d4,bltamod(a6)
		swap	d4
		move.l	d4,bltdmod(a6)
		move.l	a2,bltbpt(a6)
		move.l	a3,bltdpt(a6)
		move.w	d5,bltsize(a6)
		rts
		
		; Routine BlitBob
		; This routine copies a given bitmap to a destination bitmap
		; D2 = X
		; D3 = Y
		; D4 = ADMOD value
		; D5 = BLTSIZE value
		; A1 = restore pointers
		; A2 = Source bitmap
		; A4 = Mask bitmap
		; A5 = Destination bitmap
BlitBob	
		move.w	d2,-(sp)		; Stack
		mulu	#fg_mod,d3		; Y offset
		
		; X-shift
		lea.l	bl_bob,a0
		moveq	#15,d6
		and.w	d2,d6
		add.w	d6,d6
		add.w	d6,d6			; D6 = offset into bltcon table
		move.l	0(a0,d6),d6		; D6 = BLTCON0/1

		; Offset
		asr.w	#3,d2			; D2 = X offset
		add.l	d2,d3			; D3 = offset
		
		move.l	fg_buf3,a3
		move.w	fg_offset,d2
		lea.l	0(a3,d2),a3
		lea.l	0(a3,d3.l),a3
		move.l	a3,(a1)+		; Store restore pointer 1
		
		lea.l	0(a5,d3.l),a3
		move.l	a3,(a1)+		; Store restore pointer 2
		
		BlitWait a6
		move.l	d6,bltcon0(a6)
		move.l	d4,bltamod(a6)
		swap	d4
		move.l	d4,bltcmod(a6)
		swap	d4
		move.l	a4,bltapt(a6)
		move.l	a2,bltbpt(a6)
		move.l	a3,bltcpt(a6)
		move.l	a3,bltdpt(a6)
		move.w	d5,bltsize(a6)
		move.w	(sp)+,d2		; Stack
		rts

		; Routine: BlitClearScreen
		; This routine clears a given buffer (ECS/AGA only)
		; A0 = Pointer to buffer
		; D0 = blitsize H<<16|blitsize V
BlitClearScreen
		; Wait on Blitter
		BlitWait a6
		
		; Clear the buffer
		move.l	#$ffffffff,bltafwm(a6)
		move.l	bl_clear,bltcon0(a6)
		move.w	#$0000,bltdmod(a6)
		move.w	#$0000,bltadat(a6)
		move.l	a0,bltdpt(a6)
			
		; Start blit
		move.l d0,BLTSIZV(a6)
		rts
		
		; Routine BlitScreen
		; This routine copies a given bitmap to a destination bitmap 
		; (ECS/AGA only)
		; D4 = ADMOD value
		; D5 = blitsize H<<16|blitsize V
		; A2 = Source bitmap
		; A3 = Destination bitmap
BlitScreen
		BlitWait a6

		; Copy over the buffer
		move.l	#$ffffffff,bltafwm(a6)
		move.l	bl_copy,bltcon0(a6)
		move.l	d4,bltamod(a6)
		move.l	a2,bltapt(a6)
		move.l	a3,bltdpt(a6)
		move.l	d5,BLTSIZV(a6)
		rts
		
		section data,data
		cnop	0,2

		; Bltcon tables for bob minterms/shifts (base tables)
bl_bob		dc.l	$0fca0000,$1fca1000,$2fca2000,$3fca3000
			dc.l	$4fca4000,$5fca5000,$6fca6000,$7fca7000
			dc.l	$8fca8000,$9fca9000,$afcaa000,$bfcab000
			dc.l	$cfcac000,$dfcad000,$efcae000,$ffcaf000
bl_copy		dc.l	$09f00000,$19f01000,$29f02000,$39f03000
			dc.l	$49f04000,$59f05000,$69f06000,$79f07000
			dc.l	$89f08000,$99f09000,$a9f0a000,$b9f0b000
			dc.l	$c9f0c000,$d9f0d000,$e9f0e000,$f9f0f000
bl_copyil	dc.l	$05cc0000,$15cc1000,$25cc2000,$35cc3000
			dc.l	$45cc4000,$55cc5000,$65cc6000,$75cc7000
			dc.l	$85cc8000,$95cc9000,$a5cca000,$b5ccb000
			dc.l	$c5ccc000,$d5ccd000,$e5cce000,$f5ccf000
bl_clear	dc.l	$01f00000,$11f01000,$21f02000,$31f03000
			dc.l	$41f04000,$51f05000,$61f06000,$71f07000
			dc.l	$81f08000,$91f09000,$a1f0a000,$b1f0b000
			dc.l	$c1f0c000,$d1f0d000,$e1f0e000,$f1f0f000
; End of File

; Minterm for cookiecut = $fca
;A       B       C       D  BLTCON0  position 
;-       -       -       - ------------------
;0       0       0       0        0         
;0       0       1       0        1         
;0       1       0       1        2         
;0       1       1       1        3         
;1       0       0       0        4         
;1       0       1       1        5         
;1       1       0       1        6         
;1       1       1       1        7         
;
;11101100
;
;
; Minterm for BD copy = $5cc
;A       B       C       D  BLTCON0  position 
;-       -       -       - ------------------
;0       0       0       0        0         
;0       0       1       0        1         
;0       1       0       1        2         
;0       1       1       1        3         
;1       0       0       0        4         
;1       0       1       0        5         
;1       1       0       1        6         
;1       1       1       1        7  
;
; 11001100