; $VER: cpublit.asm 1.0 (15.02.20)
;
; cpublit.asm
; 
; Contains CPU blitting routines for the example program.
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
	include cpublit.i
	include	object.i
	include tilemap.i
	include displaybuffers.i
	include	bobs.i
	
		; CPU blitting routines
		section code,code
		cnop	0,4					; Force alignment
		; Routine: CPUBlitBob
		; This routine implements a cookie-cut algorithm using the CPU. The
		; routine is generic, allowing objects of any width. It requires an 
		; object structure (see object.i), which contains base information on 
		; the object to blit.
		;
		; D0 - X (long)
		; D1 - Y (long)
		; D2 - A/D Modulo
		; A0 - object structure
		; A2 - destination
		; A3 - restore pointers
		;
		; Result:
		; A3: updated
		; D0-D5/A0-A2/A5: trashed
CPUBlitBob
		movem.l	d6/d7/a4,-(sp) 		; Stack

		mulu	#fg_mod,d1			; Y offset (CPU & Blitter)
		
		; X-shift (CPU & Blitter)
		moveq	#31,d5
		and.w	d0,d5				; CPU shift right

		; Blitter offset
		asr.w	#3,d0				; D0 = X offset
		add.l	d0,d1				; D1 = offset (Blitter)
		
		; Restore pointers
		move.l	fg_buf3,a4
		add.w	fg_offset,a4
		lea.l	0(a4,d1.l),a4
		move.l	a4,(a3)+			; Store restore pointer 1
		
		; Determine destination address
		lea.l	0(a2,d1.l),a2
		move.l	a2,(a3)+			; Store restore pointer 2
		
		move.l	a3,-(sp)			; Push restore pointers to stack
		
		; Fetch CPU width, height
		move.l	bobj_width(a0),d3

		; Fetch CPU mask & image
		movem.l	obj_image_ptr(a0),a0/a1
		
		; Set CPU shift left
		moveq	#32,d6
		sub.w	d5,d6				; Set left shift
		
		; Align CPU to 32 bits
		move.l	a2,d0	
		and.w	#$fffc,d0
		move.l	d0,a2
		
		; CPU width & number of lines
		move.w	d3,a5				; Number of lines
		swap	d3
		move.w	d3,a3				; Width in longwords
		subq	#1,a3
		
		; CPU modulo adjustment
		add.w	#2,d2
		and.w	#$fffc,d2			; Round modulo up
		move.w	d2,a4				; Modulo
		
		; CPU cookie cut loop (longword aligned)
		; Register usage overview:
		;	D0	Mask
		;	D1	Mask remainder
		;	D2	Source
		;	D3	Source remainder / Destination
		;	D4	Intermediate result
		;	D5	Right shift value
		;	D6	Left shift value
		;	D7	Width (loop variable)
		;	A0	Mask
		;	A1	Image
		;	A2	Destination
		;	A3	Longwords of width
		;	A4	Modulo between lines
		;	A5	Number of lines (loop variable)
.lines_loop
		move.w	a3,d7				; D7 = width loop value

		; Clear mask & source remainder
		moveq	#0,d1
		moveq	#0,d3

.width_loop
		; Get raw mask and prepare for use
		move.l	(a1)+,d0			; Fetch mask
		move.l	d0,d4				; Copy to D4		
		lsr.l	d5,d0				; Shift right
		or.l	d1,d0				; Combine result with mask remainder (mask ready)
		lsl.l	d6,d4				; Shift left (remainder ready)
		move.l	(a0)+,d2			; Fetch source (here for performance)
		move.l	d4,d1				; Keep mask remainder in D1

		; Prepare raw source for use
		move.l	d2,d4				; Copy to D4
		lsr.l	d5,d2				; Shift right
		or.l	d3,d2				; Combine result with source remainder (source ready)

		; Get background and combine with mask & source
		move.l	(a2),d3				; Fetch destination
		not.l	d0
		and.l	d0,d3				; Mask out background
		or.l	d2,d3				; Combine result with source image (destination ready)

		; Write result to background
		move.l	d3,(a2)+			; Store result
		lsl.l	d6,d4				; Shift left (source remainder ready)
		move.l	d4,d3				; Keep source remainder in D3

		; Loop back (width)
		dbra	d7,.width_loop

		; Deal with remainder
		move.l	(a2),d0				; Fetch destination
		not.l	d1
		and.l	d1,d0				; Mask out background (mask remainder)
		or.l	d3,d0				; Combine (source remainder)
		move.l	d0,(a2)				; Store result

		; Apply modulo
		add.l	a4,a2
		
		; Loop back (lines)
		subq	#1,a5
		cmp.w	#0,a5
		bne		.lines_loop

		; Done
		move.l	(sp)+,a3			; Stack
		movem.l	(sp)+,d6/d7/a4		; Stack
		rts
		
		; Routine: CPUBlitBobOpt
		; This routine implements a cookie-cut algorithm using the CPU. It is 
		; optimized and can only be used for single longword wide bobs. The 
		; optimisation prefetches the bob mask and reuses the prefetched mask 
		; for all bitplanes. It requires an object structure (see object.i), 
		; which contains base information on the object to blit.
		;
		; D0 - X (long)
		; D1 - Y (long)
		; D2 - A/D Modulo
		; A0 - object structure
		; A2 - destination
		; A3 - restore pointers
		;
		; Result:
		; A3: updated
		; D0-D5/A0-A2/A5: trashed
CPUBlitBobOpt
		movem.l	d6/d7/a4/a6,-(sp)	; Stack

		mulu	#fg_mod,d1			; Y offset (CPU & Blitter)
		
		; X-shift (CPU & Blitter)
		moveq	#31,d5
		and.w	d0,d5				; CPU shift right

		; Blitter offset
		asr.w	#3,d0				; D0 = X offset
		add.l	d0,d1				; D1 = offset (Blitter)
		
		; Restore pointers
		move.l	fg_buf3,a4
		add.w	fg_offset,a4
		lea.l	0(a4,d1.l),a4
		move.l	a4,(a3)+			; Store restore pointer 1
		
		; Determine destination address
		lea.l	0(a2,d1.l),a2
		move.l	a2,(a3)+			; Store restore pointer 2
		
		move.l	a3,-(sp)			; Push restore pointer to stack
		
		; Fetch CPU width, height
		move.l	bobj_width(a0),d3

		; Fetch CPU mask & image
		movem.l	obj_image_ptr(a0),a0/a1
		
		; Set CPU shift left
		moveq	#32,d6
		sub.w	d5,d6				; Set left shift
		
		; Align CPU to 32 bits
		move.l	a2,d0	
		and.w	#$fffc,d0
		move.l	d0,a2
		
		; CPU plane count, number of lines & mask modulo
		move.w	d3,a5				; Number of lines
		swap	d3
		move.w	d3,a3				; Number of bitplanes
		move.w	d3,d7
		asl.w	#2,d7
		move.w	d7,a6				; Mask modulo
		subq	#1,a3
		
		; CPU modulo adjustment
		add.w	#2,d2
		and.w	#$fffc,d2			; Round modulo up
		move.w	d2,a4				; Modulo
		
		; CPU cookie cut loop (longword aligned)
		; Register usage overview:
		;	D0	Mask
		;	D1	Mask remainder
		;	D2	Source
		;	D3	Destination
		;	D4	Source remainder
		;	D5	Right shift value
		;	D6	Left shift value
		;	D7	Width (loop variable)
		;	A0	Mask
		;	A1	Image
		;	A2	Destination
		;	A4	Modulo between lines
		;	A5	Number of lines (loop variable)
		;	A6	Modulo between mask lines
.lines_loop
		move.l	(a1),d0				; Fetch mask
		add.w	a6,a1				; Apply mask modulo
		move.l	d0,d1				; Copy to D1
		lsr.l	d5,d0				; Shift right (mask ready)
		lsl.l	d6,d1				; Shift left (remainder ready)
		not.l	d0					; Invert mask
		not.l	d1					; Invert remainder

		move.w	a3,d7 				; D7 = bitplanes loop variable

.planes_loop
		; Longword 1
		; Get raw source and prepare
		move.l	(a0)+,d2			; Fetch source

		move.l	d2,d4				; Copy to D1
		lsr.l	d5,d2				; Shift right (source ready)
		
		; Get background and combine with mask & source
		move.l	(a2),d3				; Fetch destination
		and.l	d0,d3				; Mask out background
		or.l	d2,d3				; Combine result with source image

		; Write result to background
		move.l	d3,(a2)+			; Store result
		lsl.l	d6,d4				; Shift left (remainder ready)

		; Deal with remainder (longword 2)
		move.l	(a2),d2
		and.l	d1,d2				; Mask out background
		or.l	d4,d2				; Combine (source remainder)
		move.l	d2,(a2)				; Store result

		; Apply modulo
		add.l	a4,a2

		; Loop back (planes)
		dbra	d7,.planes_loop

		; Loop back (lines)
		subq	#1,a5
		cmp.w	#0,a5
		bne		.lines_loop

		; Done
.done	move.l	(sp)+,a3			; Stack
		movem.l	(sp)+,d6/d7/a4/a6	; Stack
		rts
		
		; The macro below inserts a given number of move.l (a0)+,(a1)+
		; instructions
		;
		; \1 number of move.l commands to add
CPUCopyMacro	MACRO
		REPT \1
		move.l	(a1)+,(a2)+
		ENDR
				ENDM
		
		; Routine: CPUBlitCopy
CPUBlitCopy
		; This routine uses the CPU to do a standard copy blit (for use in 
		; restoring bobs). The routine supports bobs up to 20 longwords wide. 
		; It requires a base object structure (see object.i), which contains 
		; base information on the object to blit.
		;
		; D2 - Destination modulo (in bytes)
		; A0 - base object structure
		; A1 - source
		; A2 - destination
		;
		; Result:
		; D0-D5/A0-A2/A4-A5: trashed (D5 untrashed for width <=4)
		movem.l	d6/d7/a3/a6,-(sp) 	; Stack
		
		; Fetch CPU width, height
		move.l	bobj_width(a0),d3
		
		; Align CPU to 32 bits
		move.l	a2,d0	
		and.w	#$fffc,d0
		move.l	d0,a2
		
		; CPU modulo adjustment
		sub.w	#2,d2
		and.w	#$fffc,d2			; Round modulo down
		move.w	d2,d4				; Modulo in D4
		
		; CPU width & number of lines
		swap	d3
		move.w	d3,d2				; Width in D2
		swap	d3

		; Jump to correct sub-routine based on width
		jmp	.jmp_table(pc,d2*4)
	
.jmp_table
		bra.w	.done
		bra.w	.copy_w1
		bra.w	.copy_w2
		bra.w	.copy_w3
		bra.w	.copy_w4
		bra.w	.copy_w5
		bra.w	.copy_w6
		bra.w	.copy_w7
		bra.w	.copy_w8
		bra.w	.copy_w9
		bra.w	.copy_w10
		bra.w	.copy_w11
		bra.w	.copy_w12
		bra.w	.copy_w13
		bra.w	.copy_w14
		bra.w	.copy_w15
		bra.w	.copy_w16
		bra.w	.copy_w17
		bra.w	.copy_w18
		bra.w	.copy_w19
		bra.w	.copy_w20

		; Done
.done	movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts

		; 1 longword wide
.copy_w1
		subq	#1,d3	; Setup prior to loop

.line_loop_1
		CPUCopyMacro 1
		; Add modulo and loop back
		add.w	d4,a1
		add.w	d4,a2
		dbra	d3,.line_loop_1

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 2 longwords wide
.copy_w2
		subq	#1,d3	; Setup prior to loop

.line_loop_2
		CPUCopyMacro 2
		; Add modulo and loop back
		add.w	d4,a1
		add.w	d4,a2
		dbra	d3,.line_loop_2

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 3 longwords wide
.copy_w3
		subq	#1,d3	; Setup prior to loop

.line_loop_3
		CPUCopyMacro 3
		; Add modulo and loop back
		add.w	d4,a1
		add.w	d4,a2
		dbra	d3,.line_loop_3

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 4 longwords wide
.copy_w4
		subq	#1,d3	; Setup prior to loop

.line_loop_4
		CPUCopyMacro 4
		; Add modulo and loop back
		add.w	d4,a1
		add.w	d4,a2
		dbra	d3,.line_loop_4
		
		; 5 longwords wide
.copy_w5		
		subq	#1,d3	; Setup prior to loop

.line_loop_5
		movem.l	(a1)+,d0-d2/d5-d6
		movem.l	d0-d2/d5-d6,(a2)
		; Add modulo and loop back
		lea.l	20(a1,d4.w),a1
		lea.l	20(a2,d4.w),a2
		dbra	d3,.line_loop_5

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts

		; 6 longwords wide
.copy_w6		
		subq	#1,d3	; Setup prior to loop

.line_loop_6
		movem.l	(a1)+,d0-d2/d5-d7
		movem.l	d0-d2/d5-d7,(a2)
		; Add modulo and loop back
		lea.l	24(a1,d4.w),a1
		lea.l	24(a2,d4.w),a2
		dbra	d3,.line_loop_6

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 7 longwords wide
.copy_w7	
		subq	#1,d3	; Setup prior to loop

.line_loop_7
		movem.l	(a1)+,d0-d2/d5-d7/a0
		movem.l	d0-d2/d5-d7/a0,(a2)
		; Add modulo and loop back
		lea.l	28(a1,d4.w),a1
		lea.l	28(a2,d4.w),a2
		dbra	d3,.line_loop_7

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 8 longwords wide
.copy_w8		
		subq	#1,d3	; Setup prior to loop

.line_loop_8
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3
		movem.l	d0-d2/d5-d7/a0/a3,(a2)
		; Add modulo and loop back
		lea.l	32(a1,d4.w),a1
		lea.l	32(a2,d4.w),a2
		dbra	d3,.line_loop_8

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 9 longwords wide
.copy_w9		
		subq	#1,d3	; Setup prior to loop

.line_loop_9
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3/a4
		movem.l	d0-d2/d5-d7/a0/a3/a4,(a2)
		; Add modulo and loop back
		lea.l	36(a1,d4.w),a1
		lea.l	36(a2,d4.w),a2
		dbra	d3,.line_loop_9

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 10 longwords wide
.copy_w10	
		subq	#1,d3	; Setup prior to loop

.line_loop_10
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a5
		movem.l	d0-d2/d5-d7/a0/a3-a5,(a2)
		; Add modulo and loop back
		lea.l	40(a1,d4.w),a1
		lea.l	40(a2,d4.w),a2
		dbra	d3,.line_loop_10

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 11 longwords wide
.copy_w11	
		subq	#1,d3	; Setup prior to loop

.line_loop_11
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_11

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts

		; 12 longwords wide
.copy_w12	
		subq	#1,d3	; Setup prior to loop

.line_loop_12
		CPUCopyMacro 1
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_12

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 13 longwords wide
.copy_w13	
		subq	#1,d3	; Setup prior to loop

.line_loop_13
		CPUCopyMacro 2
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_13

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 14 longwords wide
.copy_w14	
		subq	#1,d3	; Setup prior to loop

.line_loop_14
		CPUCopyMacro 3
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_14

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 15 longwords wide
.copy_w15	
		subq	#1,d3	; Setup prior to loop

.line_loop_15
		CPUCopyMacro 4
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_15

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 16 longwords wide
.copy_w16	
		subq	#1,d3	; Setup prior to loop

.line_loop_16
		movem.l	(a1)+,d0-d2/d5-d6
		movem.l	d0-d2/d5-d6,(a2)
		lea.l	20(a1),a1
		lea.l	20(a2),a2
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_16

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 17 longwords wide
.copy_w17	
		subq	#1,d3	; Setup prior to loop

.line_loop_17
		movem.l	(a1)+,d0-d2/d5-d7
		movem.l	d0-d2/d5-d7,(a2)
		lea.l	24(a1),a1
		lea.l	24(a2),a2
		movem.l	(a1)+,d0-d2/d5-d7/a0/a3-a6
		movem.l	d0-d2/d5-d7/a0/a3-a6,(a2)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_17

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 18 longwords wide
.copy_w18	
		subq	#1,d3	; Setup prior to loop

.line_loop_18
		movem.l	(a1)+,d0-d2/d5-d7/a0
		movem.l	d0-d2/d5-d7/a0,(a2)
		lea.l	28(a1),a1
		lea.l	28(a2),a2
		movem.l	(a0)+,d0-d2/d5-d7/a2-a6
		movem.l	d0-d2/d5-d7/a2-a6,(a1)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_18

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 19 longwords wide
.copy_w19	
		subq	#1,d3	; Setup prior to loop

.line_loop_19
		movem.l	(a0)+,d0-d2/d5-d7/a0/a3
		movem.l	d0-d2/d5-d7/a0/a3,(a1)
		lea.l	32(a1),a1
		lea.l	32(a2),a2
		movem.l	(a0)+,d0-d2/d5-d7/a2-a6
		movem.l	d0-d2/d5-d7/a2-a6,(a1)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_19

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; 20 longwords wide
.copy_w20	
		subq	#1,d3	; Setup prior to loop

.line_loop_20
		movem.l	(a0)+,d0-d2/d5-d7/a0/a3/a4
		movem.l	d0-d2/d5-d7/a0/a3/a4,(a1)
		lea.l	36(a1),a1
		lea.l	36(a2),a2
		movem.l	(a0)+,d0-d2/d5-d7/a2-a6
		movem.l	d0-d2/d5-d7/a2-a6,(a1)
		; Add modulo and loop back
		lea.l	44(a1,d4.w),a1
		lea.l	44(a2,d4.w),a2
		dbra	d3,.line_loop_20

		; Done
		movem.l	(sp)+,d6/d7/a3/a6	; Stack
		rts
		
		; Routine: CPUBlitCopyOpt
		; This routine uses the CPU to do a standard copy blit (for use in 
		; restoring bobs). This is an optimized routine that only supports two
		; longword wide blits. It requires a base object structure (see 
		; object.i), which contains base information on the object to blit.
		;
		; D2 - Destination Modulo
		; A0 - base object structure
		; A1 - source
		; A2 - destination
		;
		; Result:
		; D0-D4/A0-A2/A4-A5: trashed
CPUBlitCopyOpt
		movem.l	d6/d7,-(sp) 	; Stack
		
		; Fetch source offset and destination offset
		move.l	bobj_image_offset(a0),d4
		
		move.l	a2,d0					; Prep for alignment
		and.w	#$fffc,d0				; Align destination to 32 bits
		swap	d4						; Source/destination offset in D4
		add.w	d4,a1					; Add offset to source
		move.l	a1,d1					; Prep for alignment
		and.w	#$fffc,d1				; Align source to 32 bits
		move.l	d0,a2					; Destination in A2
		add.w	d4,a2					; Add offset to destination
		move.l	d1,a1					; Source in A1
		subq.w	#2,d2					; Prep for modulo rounding
		
		; Fetch height
		move.w	bobj_height(a0),d3
		
		; CPU modulo adjustment
		and.w	#$fffc,d2			; Round modulo down
		move.w	d2,d4				; Modulo in D4
		
		; 2 longwords wide copy
.copy_w2
		asr.w	#1,d3
		subq	#1,d3	; Setup prior to loop

.line_loop_2
		CPUCopyMacro 2
		; Add modulo and loop back
		add.w	d4,a1
		add.w	d4,a2
		
		CPUCopyMacro 2				; Doubled for performance
		; Add modulo and loop back
		add.w	d4,a1
		add.w	d4,a2
		
		dbra	d3,.line_loop_2

		; Done
.done	movem.l	(sp)+,d6/d7	; Stack
		rts
; End of File