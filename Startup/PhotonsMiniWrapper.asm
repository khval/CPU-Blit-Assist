; Startup code
; This is a slightly altered version of:
;    *** MiniWrapper 1.04 by Photon ***
;
; - wrapper now calls _main instead of demo
; - wrapper now enters supervisor mode prior
;   to calling main and leaves supervisor mode
;	prior to returning
; - The WaitEOF routine now waits for line $137
; - Now exits with an error if using a 68000/68010
; - Now exits with an error if using OCS/ECS
;
; TAB size = 4 spaces

	include exec/types.i
	include	exec/exec.i
	include exec/execbase.i
	include hardware/custom.i
	include	debug.i

	XDEF	WaitEOF
	XDEF	WaitRaster
	
; Custom chips offsets
custombase			EQU	$dff000

		move.l	4.w,a6			;Exec library base address in a6
		bsr		FetchCPUType
		tst.w	d6
		beq		.err68k
		
		bsr		FetchChipsetType
		tst.w	d6
		beq		.erraga
		
		sub.l	a4,a4
		btst	#0,297(a6)		;68000 CPU?
		beq.s	.yes68k
		lea		.GetVBR(PC),a5	;else fetch vector base address to a5
		jsr		_LVOSupervisor(a6)			;enter Supervisor mode

;    *--- save view+coppers ---*

.yes68k	lea 	.GfxLib(PC),a1	;either way return to here and open
		jsr 	_LVOOldOpenLibrary(a6)		;graphics library
		tst.l 	d0				;if not OK,
		beq 	.quit			;exit program.
		move.l 	d0,a5			;a5=gfxbase

		move.l	a5,a6
		move.l	34(a6),-(sp)
		sub.l	a1,a1			;blank screen to trigger screen switch
		jsr		_LVOLoadView(a6)		;on Amigas with graphics cards

;    *--- save int+dma ---*

		lea		$dff000,a6
		bsr		WaitEOF			;wait out the current frame
		move.l	$1c(a6),-(sp)	;save intena+intreq
		move.w	2(a6),-(sp)		;and dma
		move.l	$6c(a4),-(sp)	;and also the VB int vector for sport.
		bsr		AllOff			;turn off all interrupts+DMA

;    *--- call main ---*

		move.l	4.w,a6
		jsr		_LVOSuperState(a6)		; Enter supervisor state
		move.l	d0,save_stack

		movem.l	a4-a6,-(sp)
		jsr		_main			;call main
		movem.l	(sp)+,a4-a6
		
		move.l	save_stack,d0
		jsr		_LVOUserState(a6)
		lea.l	$dff000,a6

;   *--- restore all ---*

		bsr.s	WaitEOF			;wait out the demo's last frame
		bsr.s	AllOff			;turn off all interrupts+DMA
		move.l	(sp)+,$6c(a4)	;restore VB vector
		move.l	38(a5),$80(a6)	;and copper pointers
		move.l	50(a5),$84(a6)
		addq.w	#1,d2			;$7fff->$8000 = master enable bit
		or.w	d2,(sp)
		move.w	(sp)+,$96(a6)	;restore DMA
		or.w	d2,(sp)
		move.w	(sp)+,$9a(a6)	;restore interrupt mask
		or.w	(sp)+,d2
		bsr.s	IntReqD2		;restore interrupt requests

		move.l	a5,a6
		move.l	(sp)+,a1
		jsr		_LVOLoadView(a6)		;restore OS screen

;    *--- close lib+exit ---*

		move.l	a6,a1			;close graphics library
		move.l	4.w,a6
		jsr		_LVOCloseLibrary(a6)
.quit	moveq	#0,d0			;clear error return code to OS
		rts						;back to AmigaDOS/Workbench.

.GetVBR	dc.w	$4e7a,$c801		;hex for "movec VBR,a4"
		rte						;return from Supervisor mode
		
		; Error: requires 68020+
.err68k	lea.l	txt_68k(pc),a0
		bsr		PrintError
		bra		.quit
		
		; Error: requires AGA
.erraga	lea.l	txt_aga(pc),a0
		bsr		PrintError
		bra		.quit

.GfxLib	dc.b "graphics.library",0,0

WaitEOF:				;wait for end of frame
		bsr.s WaitBlitter
		move.w #$137,d0
WaitRaster:				;Wait for scanline d0. Trashes d1.
.l:		move.l 4(a6),d1
		lsr.l #1,d1
		lsr.w #7,d1
		cmp.w d0,d1
		bne.s .l			;wait until it matches (eq)
		rts

AllOff	move.w	#$7fff,d2		;clear all bits
		move.w	d2,$96(a6)		;in DMACON,
		move.w	d2,$9a(a6)		;INTENA,
IntReqD2
		move.w	d2,$9c(a6)		;and INTREQ
		move.w	d2,$9c(a6)		;twice for A4000 compatibility
		rts

WaitBlitter						;wait until blitter is finished
		tst.w	(a6)			;for compatibility with A1000
.loop:	btst	#6,2(a6)
		bne.s	.loop
		rts
		
		; Routine: FetchCPUType
		; Detects whether the Amiga has a 68020 or higher
		; Returns:
		; D6 = 0 is 68000/68010, 1 = 68020+
FetchCPUType
		move.l	d0,-(sp)			; Stack
		
		moveq	#0,d6				; Assume 68000/68010
		
		; Test CPU using Exec Attention Flags
		move.w	AttnFlags(a6),d0
		and.w	#%111001110,d0		; Exclude 68010, FPU's and unknown bits
		tst.w	d0
		beq		.done
		
		moveq	#1,d6				; 68020 or higher
		
.done	move.l	(sp)+,d0			; Stack
		rts
		
		; Routine: FetchChipsetType
		; Detects whether the Amiga has OCS/ECS or AGA
		; Returns:
		; D6 = 0 is OCS/ECS, 1 = AGA+
FetchChipsetType
		movem.l	d0/a6,-(sp)			; Stack
				
		lea.l	custombase,a6		; Custom chip base
		moveq	#0,d6				; Assume OCS/ECS
		
		; Test for AGA using bit nine of VPOSR register
		move.w	vposr(a6),d0
		btst	#9,d0
		beq		.no_aga
		
		moveq	#1,d6
.no_aga	movem.l	(sp)+,d0/a6			; Stack
		rts
		
		; Routine: PrintError
		; Uses DOS to print a given error message
		; A0 - pointer to error message
PrintError
		move.l	a6,-(sp)
		move.l	a0,-(sp)
		bsr		OSOpenDos
		tst.w	d0
		bne		.no_dos
		
		move.l	dosbase(pc),a6
		jsr		_LVOOutput(a6)
		move.l	d0,d1
		move.l	(sp)+,a2
		moveq	#0,d3
		move.w	(a2)+,d3
		move.l	a2,d2
		jsr		_LVOWrite(a6)
		
		bsr		OSCloseDos
.done	move.l	(sp)+,a6
		rts
		
.no_dos	move.l	(sp)+,a0
		bra		.done
		
		; Routine: OSOpenDos
		; Opens the DOS.library if needed
		;
		; Returns
		; D0 = 0 is OK, non zero is error
OSOpenDos
		move.l	a6,-(sp)		; Stack
		
		move.l	$4.w,a6			; Execbase
		lea.l	dosname(pc),a1
		moveq	#0,d0
		jsr		_LVOOpenLibrary(a6)
		lea.l	dosbase(pc),a0
		move.l	d0,(a0)
		beq		.error
		
		moveq	#0,d0		
.done	move.l	(sp)+,a6		; Stack
		rts
		
.error	moveq	#1,d1
		bra		.done
		
		; Routine: OSCloseDos
		; Closes the DOS.library if needed
OSCloseDos
		movem.l	a1/a6,-(sp)
		
		move.l	dosbase(pc),a1
		cmp.l	#0,a1
		beq		.error
		
		move.l	$4.w,a6			; Execbase
		jsr		_LVOCloseLibrary(a6)
		moveq	#0,d0
		
.done	movem.l	(sp)+,a1/a6
		rts
		
.error	moveq	#1,d1
		bra		.done
		
dosbase	dc.l	0
dosname dc.b	"dos.library",0,0
		cnop 0,2
txt_68k	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"This program requires a 68020 and the AGA chipset to run.",10,0,0
.txtend
		cnop	0,2
txt_aga	dc.w	.txtend-.txtstrt
.txtstrt
		dc.b	"This program requires the AGA chipset to run.",10,0,0
.txtend
		cnop	0,2
save_stack	dc.l	0
; End of File