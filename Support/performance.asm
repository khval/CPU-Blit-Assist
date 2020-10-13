; $VER: performance.asm 1.0 (15.02.20)
;
; Performance.asm
; This file contains routines to test the optimal split between Blitter and
; CPU for cookie-cut and copy blits.
;
; A few notes on meauring performance using these routines:
;	1) The routines only test a single blit per CIA timing result. While
;	   this results in the correct split between CPU and Blitter to be 
;	   determined, it does not give an accurate display of the real world
;	   improvement in performance. These routines somewhat underestimate 
;      the gains made.
;	2) As these routines below only measure the blitting routines, they 
;      can slightly underreport the optimum split. For copy blits this does 
;	   not turn out to make a difference, but for cookie cut blits, it does.
;	   With the current code, a small performance gain can be realised by 
;	   adding a single line to the CPU part (deducting it from the Blitter).
;
; Note: currently has lots of doubled code. This can be made neater by moving
;       some of it into separate routines.
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
	include hardware/cia.i

	include blitter.i
	include comboblit.i
	include object.i
	include performance.i
	include cia_timer.i
		
	include debug.i
		
	XREF	WaitRaster
		
		section	code,code			
		; Routine: PerformanceTestBob
		; This routine uses the CIA to measure which split of lines between
		; CPU/Blitter delivers optimum performance for the given object size.
		; Result of the test are stored in bob_bobject.
		;
		; Note: this routine assumes that the variable fg_buf1 exists and 
		;		contains a pointer to freely usable chip memory of at least
		;		the same size as the requested blit. It also assumes that the
		;		variables bob & mask exist and point to chip memory.
		; 
		; D0 - Bob width in words (including shift)
		; D1 - Bob height in lines
		; D2 - Number of bitplanes
		; D3 - Destination modulo
		; A0 - Restore pointers
PerformanceTestBob
		movem.l	d0-d7/a0-a6,-(sp)		; Stack

		; Initialize variables
		lea.l	blitter_lines,a1
		clr.w	(a1)					; blitter_lines
		clr.w	2(a1)					; cpu_lines
		clr.w	4(a1)					; result
		move.w	d2,6(a1)				; bitplanes
		move.w	d0,8(a1)				; width
		move.l	a0,10(a1)				; Restore pointers
		
		; Initialize base bob object
		lea.l	bob_bobject,a0
		move.w	d0,d7
		asr.w	#1,d7
		bsr		SetupBaseObject
		
		; Initialize performance test object
		lea.l	perf_object,a0
		lea.l	bob_bobject,a1
		move.l	bob,a2
		lea.l	mask,a3
		bsr		SetupObject
		clr.w	bobj_image_offset(a0)
		clr.w	bobj_dest_offset(a0)
		
		; Initialize loop
		move.w	d1,d0					; Set number of Blitter lines
		subq	#1,d0
		moveq	#1,d1					; Set number of CPU lines


		; Wait until Blitter done
		BlitWait a6

		; Loop over both counters
.loop
		; Push counters to stack
		movem.l	d0/d1,-(sp)

		; Update performance object
		lea.l	perf_object,a0
		mulu.w	bitplanes,d1			
		move.w	d1,bobj_height(a0)		; CPU lines value
		asl.w	#6,d0
		mulu.w	bitplanes,d0
		or.w	width,d0				
		move.w	d0,bobj_bltsize(a0)		; BLTSIZE value

		; Fetch CIA & start the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStart						; Start measuring performance
		
		moveq	#0,d0					; X
		moveq	#0,d1					; Y
		move.l	#0,d2					; Set modulo to 0 during test
		lea.l	perf_object,a0			; Fetch bob object
		move.l	fg_buf1,a2				; Set destination
		move.l	restore,a3				; Get restore pointer
		move.l	#$ffff0000,bltafwm(a6)	; Set mask for completeness
		; Start Blitter & CPU
		bsr		ComboBlitBob
		
		; Wait until Blitter done
		BlitWait a6

		; Fetch the CIA and stop the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStop							; Stop measuring performance

		; Test result vs best so far
		lea.l	result,a5				; Fetch best result so far
		
		cmp.w	(a5),d0					; Compare with current result
		bls		.no_update
		
		; Update results if needed
		move.w	d0,(a5)					; Result
		move.w	6(sp),-2(a5)			; Number of CPU lines
		move.w	2(sp),-4(a5)			; Number of Blitter lines
		
.no_update
		; Pull counters from stack
		movem.l	(sp)+,d0-d1
		
		; Update counters and resume loop
		subq	#1,d0
		addq	#1,d1
		cmp.w	#0,d0
		bne		.loop
		
		; Read final result and update bob_bobject accordingly
		lea.l	bob_bobject,a0
		move.w	cpu_lines,d0
		mulu.w	bitplanes,d0			
		move.w	d0,bobj_height(a0)		; CPU lines value
		move.w	blitter_lines,d1
		mulu	bobj_width(a0),d1
		mulu	bitplanes,d1
		asl.w	#2,d1				
		move.w	d1,bobj_image_offset(a0); Source offset in bytes
		move.w	bobj_dest_offset(a0),d1
		mulu	blitter_lines,d1
		move.w	d1,bobj_dest_offset(a0)	; Destination offset in bytes
		move.w	blitter_lines,d1
		mulu	bitplanes,d1
		asl.w	#6,d1
		or.w	width,d1				
		move.w	d1,bobj_bltsize(a0)		; BLTSIZE value

		movem.l	(sp)+,d0-d7/a0-a6		; Stack
		rts
		
		; Routine: PerformanceTestBobOpt
		; This routine uses the CIA to measure which split of lines between
		; CPU/Blitter delivers optimum performance for the given object size.
		; Result of the test are stored in bob_bobject.
		;
		; This routine is mostly identical to the PerformanceTestBob routine,
		; apart from changes as required for the call to ComboBlitBobOpt.
		;
		; Note: this routine assumes that the variable fg_buf1 exists and 
		;		contains a pointer to freely usable chip memory of at least
		;		the same size as the requested blit. It also assumes that the
		;		variables bob & mask exist and point to chip memory.
		; 
		; D1 - Bob height in lines
		; D2 - Number of bitplanes
		; D3 - Destination modulo
		; A0 - Restore pointers
PerformanceTestBobOpt
		movem.l	d0-d7/a0-a6,-(sp)		; Stack
		
		; Initialize variables
		move.w	#3,d0					; Width is always 3 words
		lea.l	blitter_lines,a1
		clr.w	(a1)					; blitter_lines
		clr.w	2(a1)					; cpu_lines
		clr.w	4(a1)					; result
		move.w	d2,6(a1)				; bitplanes
		move.w	d0,8(a1)				; width
		move.l	a0,10(a1)				; Restore pointers
		
		; Initialize base bob object
		lea.l	bob_bobject,a0
		move.w	d2,d7
		bsr		SetupBaseObject
		
		; Initialize performance test object
		lea.l	perf_object,a0
		lea.l	bob_bobject,a1
		move.l	bob,a2
		lea.l	mask,a3
		bsr		SetupObject
		clr.w	bobj_image_offset(a0)
		clr.w	bobj_dest_offset(a0)
		
		; Initialize loop
		move.w	d1,d0					; Set number of Blitter lines
		subq	#1,d0
		moveq	#1,d1					; Set number of CPU lines

		; Wait until Blitter done
		BlitWait a6

		; Loop over both counters
.loop
		; Push counters to stack
		movem.l	d0/d1,-(sp)

		; Update performance object
		lea.l	perf_object,a0
		move.w	d1,bobj_height(a0)		; CPU lines value
		asl.w	#6,d0
		mulu.w	bitplanes,d0
		or.w	width,d0				
		move.w	d0,bobj_bltsize(a0)		; BLTSIZE value

		; Fetch CIA & start the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStart						; Start measuring performance
		
		moveq	#0,d0					; X
		moveq	#0,d1					; Y
		move.l	#0,d2					; Set modulo to 0 during test
		lea.l	perf_object,a0			; Fetch bob object
		move.l	fg_buf1,a2				; Set destination
		move.l	restore,a3				; Get restore pointer
		move.l	#$ffff0000,bltafwm(a6)	; Set mask for completeness
	
		; Start Blitter & CPU
		bsr		ComboBlitBobOpt
				
		; Wait until Blitter done
		BlitWait a6

		; Fetch the CIA and stop the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStop							; Stop measuring performance

		; Test result vs best so far
		lea.l	result,a5				; Fetch best result so far
		
		cmp.w	(a5),d0					; Compare with current result
		bls		.no_update
		
		; Update results if needed
		move.w	d0,(a5)					; Result
		move.w	6(sp),-2(a5)			; Number of CPU lines
		move.w	2(sp),-4(a5)			; Number of Blitter lines
		
.no_update
		; Pull counters from stack
		movem.l	(sp)+,d0-d1
		
		; Update counters and resume loop
		subq	#1,d0
		addq	#1,d1
		cmp.w	#0,d0
		bne		.loop
		
		; Adding a single line to the CPU improves performance. This might be
		; caused by the Blitter wait in the next blit triggering while there 
		; still is a notable amount of work left for the Blitter. It's 
		; possible this improvement is dependent on the size of the blit. It's
		; certainly dependent on the loop that blits all the bobs. So check on
		; real hardware if this code is changed!
		add.w	#1,cpu_lines
		sub.w	#1,blitter_lines
		
		; Read final result and update bob_bobject accordingly
		lea.l	bob_bobject,a0
		move.w	cpu_lines,d0
		move.w	d0,bobj_height(a0)		; CPU lines value
		move.w	blitter_lines,d1
		mulu	bitplanes,d1
		asl.w	#2,d1				
		move.w	d1,bobj_image_offset(a0); Source offset in bytes
		move.w	bobj_dest_offset(a0),d1
		mulu	blitter_lines,d1
		move.w	d1,bobj_dest_offset(a0)	; Destination offset in bytes
		move.w	blitter_lines,d1
		mulu	bitplanes,d1
		asl.w	#6,d1
		or.w	width,d1				
		move.w	d1,bobj_bltsize(a0)		; BLTSIZE value

		movem.l	(sp)+,d0-d7/a0-a6		; Stack
		rts
		
		; Routine: PerformanceTestCopy
		; This routine uses the CIA to measure which split of lines between
		; CPU/Blitter delivers optimum performance for the given object size.
		; Result of the test are stored in copy_bobject.
		;
		; This routine is mostly identical to the PerformanceTestBob routine,
		; apart from changes as required for the call to ComboBlitCopy.
		;
		; Note: this routine assumes that the variable fg_buf1 exists and 
		;		contains a pointer to freely usable chip memory of at least
		;		the same size as the requested blit. It also assumes that the
		;		variable fg_buf2 exists and contains a pointer to freely 
		;		usable chip memory of at least the same size as the requested 
		;		blit.
		; 
		; D0 - Bob width in words (including shift)
		; D1 - Bob height in lines
		; D2 - Number of bitplanes
		; D3 - Destination modulo
PerformanceTestCopy
		movem.l	d0-d7/a0-a6,-(sp)		; Stack
		
		; Initialize variables
		lea.l	blitter_lines,a1
		clr.w	(a1)					; blitter_lines
		clr.w	2(a1)					; cpu_lines
		clr.w	4(a1)					; result
		move.w	d2,6(a1)				; bitplanes
		move.w	d0,8(a1)				; width
		
		; Initialize base bob object
		lea.l	copy_bobject,a0
		move.w	d0,d7
		asr.w	#1,d7
		add.w	#1,d7					; Make sure remainder is included
		bsr		SetupBaseObject
		
		; Initialize performance test object
		lea.l	perf_object,a0
		lea.l	copy_bobject,a1
		bsr		SetupObject
		clr.w	bobj_image_offset(a0)
		clr.w	bobj_dest_offset(a0)
		
		; Initialize loop
		move.w	d1,d0					; Set number of Blitter lines
		subq	#1,d0
		moveq	#1,d1					; Set number of CPU lines

		; Wait until Blitter done
		BlitWait a6

		; Loop over both counters
.loop
		; Push counters to stack
		movem.l	d0/d1,-(sp)
		
		; Update performance object
		lea.l	perf_object,a0
		mulu.w	bitplanes,d1			
		move.w	d1,bobj_height(a0)		; CPU lines value
		asl.w	#6,d0
		mulu.w	bitplanes,d0
		or.w	width,d0				
		move.w	d0,bobj_bltsize(a0)		; BLTSIZE value

		; Fetch CIA & start the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStart						; Start measuring performance

		moveq	#0,d0					; X
		moveq	#0,d1					; Y
		move.l	#0,d2					; Set modulo to 0 during test
		
		lea.l	perf_object,a0			; Fetch bob object
		move.l	fg_buf1,a1				; Set source
		move.l	fg_buf2,a2				; Get destination
		move.l	#$ffffffff,bltafwm(a6)	; Set mask for completeness
		; Start Blitter & CPU
		bsr		ComboBlitCopyOpt
		
		; Wait until Blitter done
		BlitWait a6

		; Fetch the CIA and stop the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStop							; Stop measuring performance

		; Test result vs best so far
		lea.l	result,a5				; Fetch best result so far
		
		cmp.w	(a5),d0					; Compare with current result
		bls		.no_update
		
		; Update results if needed
		move.w	d0,(a5)					; Result
		move.w	6(sp),-2(a5)			; Number of CPU lines
		move.w	2(sp),-4(a5)			; Number of Blitter lines
		
.no_update
		; Pull counters from stack
		movem.l	(sp)+,d0-d1
		
		; Update counters and resume loop
		subq	#1,d0
		addq	#1,d1
		cmp.w	#0,d0
		bne		.loop
		
		; Adding/subtracting CPU lines does not improve performance for copy
		; blits, presumably due to the smaller size and inefficient blit mode.
		
		; Read final result and update bob_object accordingly
		lea.l	copy_bobject,a0
		move.w	cpu_lines,d0
		mulu.w	bitplanes,d0			
		move.w	d0,bobj_height(a0)		; CPU lines value
		move.w	bobj_dest_offset(a0),d1
		mulu	blitter_lines,d1
		move.w	d1,bobj_dest_offset(a0)	; Destination offset in bytes
		move.w	d1,bobj_image_offset(a0); Source offset in bytes
		move.w	blitter_lines,d1
		mulu	bitplanes,d1
		asl.w	#6,d1
		or.w	width,d1				
		move.w	d1,bobj_bltsize(a0)		; BLTSIZE value

		movem.l	(sp)+,d0-d7/a0-a6		; Stack
		rts

		; Routine: PerformanceTestBase
		; This routine tests the performance of the Blitter for drawing
		; a given size of object. Both cookie-cut and copy will be tested.
		;
		; Note: this routine is not used in the example, it's use was 
		;       determining the base level performance of the Blitter for the
		;		standard blitting routines.
		;
		; Note: this routine assumes that the variable fg_buf1 exists and 
		;		contains a pointer to freely usable chip memory of at least
		;		the same size as the requested blit. It also assumes that the
		;		variables bob & mask exist and point to chip memory.
		; 
		; D0 - Bob width in words (including shift)
		; D1 - Bob height in lines
		; D2 - Number of bitplanes
		; D3 - Destination modulo
		;
		; Result:
		; D0 - Cookie-cut result
		; D1 - Copy result
PerformanceTestBase
		movem.l	d2-d7/a0-a6,-(sp)		; Stack
		
		; Wait on Blitter first
		BlitWait a6
		
		; Test cookie-cut blit first		
		; Fetch CIA & start the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStart						; Start measuring performance
		
		move.l	#$ffff0000,bltalwm(a6)
		move.l	#0,d2					; X
		move.l	#0,d3					; Y
		move.l	#0,d4					; Set modulo to 0 during test
		move.w	#(32*6)<<6|3,d5			; BLTSIZE
		lea.l	restore_ptrs,a1
		lea.l	bob,a2
		lea.l	mask,a4
		move.l	fg_buf1,a5
		; Start the Blitter
		bsr		BlitBob
		
		; Wait until Blitter done
		BlitWait a6

		; Fetch the CIA and stop the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStop							; Stop measuring performance
		move.w	d0,-(sp)				; Store result
		
		; Test copy blit second
		; Fetch CIA & start the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStart						; Start measuring performance
		
		move.l	#$ffffffff,bltalwm(a6)
		move.l	#0,d4					; Set modulo to 0 during test
		move.w	#(32*6)<<6|3,d5			; BLTSIZE
		move.l	fg_buf1,a2				; Source
		lea.l	1154(a2),a3				; Destination
		bsr		BlitCopy

		; Wait until Blitter done
		BlitWait a6

		; Fetch the CIA and stop the timer
		lea.l	ciabase+1,a5			; CIA A
		CIAStop							; Stop measuring performance
		move.w	d0,d1					; Store result
		
		; Restore cookie-cut result and exit
		move.w	(sp)+,d0
		
		movem.l	(sp)+,d2-d7/a0-a6		; Stack
		rts
		
		section	data,data
blitter_lines	dc.w	0
cpu_lines		dc.w	0
result			dc.w	0
bitplanes		dc.w	0
width			dc.w	0
restore			dc.l	0

		cnop 0,4
		nop		; Force odd alignment
bob_bobject		blk.b	bobj_SIZEOF
		cnop 0,4
		nop		; Force odd alignment
copy_bobject	blk.b	bobj_SIZEOF
		cnop 0,4
		nop		; Force odd alignment
perf_object		blk.b	obj_SIZEOF
; End of File