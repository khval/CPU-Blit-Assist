; $VER: CPU_Blitting_Assist.asm 1.0 (15.02.20)
;
; CPU_Blitting_Assist.asm
; Example showing the CPU assisting the Blitter for blitting bobs. This file
; could probably benefit from being split into several smaller ones.
;
; Note: this example freezes the cache during the restoring of bobs when using
; combined blitting. After restoring, the cache is unfrozen. This provides a 
; (rather) small amount of extra performance. This freezing/unfreezing of the
; cache only affects 68020/68030 processors and normal cache settings are 
; restored afterwards. Even though it will not cause any problems on 68040 or 
; 68060 processors, you may want to remove this code.
;
; Doing so will not lower the number of objects the example can draw on the
; A1200. It will only lower the number of free raster lines slightly.
; 
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200215
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes (OS includes assume at least NDK 1.3) 
	include exec/types.i
	include	exec/exec.i
;	include libs/exec_lib.i
	include hardware/custom.i
	include hardware/cia.i
	include hardware/dmabits.i
	include hardware/intbits.i
	
	include	debug.i
	include CPU_Blit_Assist.i
	include tilemap.i
	include blitter.i
	include cpublit.i
	include displaybuffers.i
	include copperlists.i
	include bobs.i
	include font.i
	include background.i
	include object.i
	include titletext.i
	include	cia_timer.i

	include performance.i

; Performance defines
PERF_SINGLE			EQU	0	; Set to one to enable single-bob comparisons
PERF_FRAME			EQU	0	; Set to one to enable full-frame timer

; Custom chips offsets
custombase			EQU	$dff000
;ciabase				EQU	$bfe000
ciaa				EQU	$bfe001
potgor				EQU	$016
ciaa_pra			EQU $bfe001
bit_joyb1			EQU 7
bit_joyb2			EQU 14
bit_mouseb1			EQU	6
bit_mouseb2			EQU	10

; External references
	XREF	WaitEOF
	XREF	WaitRaster
	
; Start of code
		section code,code

		; Main code starts here
_main	move.l	$4.w,a6				; Fetch sysbase

		; Allocate all memory
		bsr		AllocAll
		bne		error
		
		; Save CIA values for later restoring
		lea.l	ciabase+1,a5			; CIA A
		lea.l	cia_save(pc),a4

		move.b	ciacra(a5),d0
		move.b	ciaicr(a5),d1
		move.b	d0,(a4)				; Store CIA control value
		move.b	d1,1(a4)			; Store CIA IC value

		; Set custombase here
		lea.l	custombase,a6
		
		; Activate blitter DMA
DMAVal	SET		DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)
		; Wait on blitter
		BlitWait a6
		move.l	#$ffffffff,bltafwm(a6)	; Preset blitter mask value
		
		; Set initial palette
		lea.l	tpalette,a0
		bsr		SetInitialPal
		
		; Fill in missing parts of initial copper list
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		bsr		SetFGPtrs	; Set bitplane pointers for foreground		
		bsr		SetSBPtrs	; Set up bitplane pointers for subbuffer
		lea.l	tpalette,a0
		bsr		SetFGPal	; Set up text palette
		bsr		SetSBPal	; Set up subbuffer palette
		
		; Clear foregrounds
		; Blitsize is given as BLTSIZV<<16|BLTSIZH.
		move.l #(buffer_height*8)<<16|((display_width+(32*2))/16),d0
		move.l	fg_buf1,a0
		bsr		BlitClearScreen
		move.l	fg_buf2,a0
		bsr		BlitClearScreen

		; Fill starting data for subbuffer
		bsr		DrawSubBuffer

		; Wait on blitter
		BlitWait a6
		
		; Add title screen text
		lea.l	fg_buf1,a4
		moveq	#1,d7
		
		; Loop over the FG buffers.
.ttxt_lp
		move.l	(a4)+,a1
		lea.l	2(a1),a1				; Skip to starting position
		lea.l	titletxt,a3
		moveq	#6,d3
		move.l	#buffer_modulo*6,d5		; Note: top word must be empty
		moveq	#buffer_modulo,d6		; Note: top word must be empty
		bsr		PlotTextMultiCPU
		dbra	d7,.ttxt_lp
		
		; Add subbuffer text
		move.l	sb_buf,a1
		lea.l	2(a1),a1				; Skip to starting position
		lea.l	(subbuffer_modulo*3)*4(a1),a1	; Offset Y by 4 pixels
		lea.l	subtxt,a3
		moveq	#3,d3
		moveq	#subbuffer_modulo*3,d5		; Note: top word must be empty
		moveq	#subbuffer_modulo,d6		; Note: top word must be empty
		bsr		PlotTextMultiCPU
		
		; Enable DMA
DMAVal	SET		DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER
		move.w	#DMAVal,dmacon(a6)

		; Activate copper list
		lea.l	clist1,a0
		move.l	a0,cop1lc(a6)
		move.w	#1,copjmp1(a6)
		
		move.w	#$0c40,$106(a6)		; Reset BPLCON3 to default
		move.w	#$0000,$180(a6)		; Set background to black
		
;-----------------------------------------
; Title screen wait
;-----------------------------------------
.title	DBGPause

		; Initialize random number sequence
		bsr		Randomize

		; DMA needs to be disabled for the performance tests
		; By doing it here already, the palette can be set without needing to
		; worry about the Copper resetting BPLCON3 mid-palette change.
		move.w	#DMAF_COPPER|DMAF_RASTER,dmacon(a6)
		; Set full palette
		
		lea.l	mpalette,a0
		bsr		SetFullPal

		; Set main palette bank 0 colours 0-7 (upper word only)
		lea.l	mpalette,a0
		bsr		SetFGPal

		; Do performance tests for CPU+Blitter cookie-cut and copy blits
	IF PERF_SINGLE=1
		; Measure and store baseline Blitter performance
		bsr		PerformanceTestBase
		move.w	d0,base_res_bob
		move.w	d1,base_res_copy
	ENDIF
		moveq	#3,d0			; Width in words (incl. 16 bit shift)
		moveq	#32,d1			; Height in lines
		moveq	#6,d2			; Number of bitplanes
		move.w	#fg_mod,d3		; Destination modulo
		lea.l	restore_ptrs,a0	; Restore pointers
		bsr		PerformanceTestBobOpt
	IF PERF_SINGLE=1
		; Store combined bob result
		move.w	result,cres_bob
	ENDIF
		bsr		PerformanceTestCopy
	IF PERF_SINGLE=1
		; Store combined copy result
		move.w	result,cres_copy
	ENDIF
		move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER,dmacon(a6)

		; Set up background images
		bsr		DrawBackground
		
	IF PERF_SINGLE=1
		; Print out results of performance check to subbuffer

		; Convert measured times to decimals
		lea.l	res_bob(pc),a0
		move.l	#$0000ffff,d0
		sub.w	cres_bob(pc),d0
		bsr		conv_to_dec
		
		lea.l	res_copy(pc),a0
		move.l	#$0000ffff,d0
		sub.w	cres_copy(pc),d0
		bsr		conv_to_dec
		
		lea.l	res_baseb(pc),a0
		move.l	#$0000ffff,d0
		sub.w	base_res_bob(pc),d0
		bsr		conv_to_dec
		
		lea.l	res_basec,a0
		move.l	#$0000ffff,d0
		sub.w	base_res_copy(pc),d0
		bsr		conv_to_dec
		
		; Print measured times
		move.l	sb_buf,a1
		lea.l	2(a1),a1				; Skip to starting position
		lea.l	(subbuffer_modulo*3)*4(a1),a1	; Offset Y by 4 pixels
		lea.l	result_txt,a3
		moveq	#3,d3
		moveq	#subbuffer_modulo*3,d5		; Note: top word must be empty
		moveq	#subbuffer_modulo,d6		; Note: top word must be empty
		bsr		PlotTextMultiCPU
		DBGPause
		
		; Restore subbuffer text
		lea.l	subtxt,a3
		bsr		PlotTextMultiCPU
		
		; Clear results to prevent confusion if PERF_FRAME is also on
		moveq	#6-1,d7
		lea.l	res_bob,a0
		lea.l	res_copy,a1
		lea.l	res_baseb,a2
		lea.l	res_basec,a3
.clrlp	move.b	#' ',(a0)+
		move.b	#' ',(a1)+
		move.b	#' ',(a2)+
		move.b	#' ',(a3)+
		dbra	d7,.clrlp
	ENDIF

		; Update subbuffer text
		move.l	sb_buf,a1
		lea.l	2(a1),a1				; Skip to starting position
		lea.l	(subbuffer_modulo*3)*4(a1),a1	; Offset Y by 4 pixels
		lea.l	subtxt_cpu,a3
		moveq	#3,d3
		moveq	#subbuffer_modulo*3,d5		; Note: top word must be empty
		moveq	#subbuffer_modulo,d6		; Note: top word must be empty
		bsr		PlotTextMultiCPU

	
;-----------------------------------------
; Main loop setup
;-----------------------------------------
		; Clear variables
		moveq	#0,d0
		move.w	d0,c2frame_cn
		move.w	#DSTATE_CPU_ONLY,demo_state
		move.w	d0,fg_offset
		
		; Clear blitter restore array
		move.w	#(bob_count_combo*2)-1,d7
		moveq	#0,d1
		lea.l	restore_ptrs,a2
.lp		move.l	d1,(a2)+
		move.l	d1,(a2)+
		dbra	d7,.lp
		
		; Initial bob values
		moveq	#bob_count_combo,d7
		bsr		SetupBobs
		
		; Set up combined blitting bob object
		lea.l	combo_bob,a0
		lea.l	bob_bobject,a1
		lea.l	bob,a2
		lea.l	mask,a3
		bsr		SetupObject
		
		; CPU only objects
		; These are set up manually because no base object exists yet
		; (base object is filled by the peformance test, which is not run for
		;  CPU or Blitter only blits)
		lea.l	cpu_bob,a0
		move.w	#1,bobj_width(a0)				; Width
		move.w	#32*6,bobj_height(a0)			; Height * bitplanes
		move.l	a2,obj_image_ptr(a0)			; Set image/mask pointers
		move.l	a3,obj_mask_ptr(a0)
		
		lea.l	cpu_copy,a0
		move.w	#2,bobj_width(a0)				; Width
		move.w	#32*6,bobj_height(a0)			; Height * bitplanes
		
;-----------------------------------------
; Main loop
;-----------------------------------------
mloop	BlitWait a6
	IF PERF_FRAME=1
		; Stop CIA timer and store full-frame result
		lea.l	ciabase+1,a5
		CIAStop
		move.w	d0,cres_bob
	ENDIF

		move.w	#$000,$180(a6)		; Clear any raster bar remaining
		move.w	#$2c,d0
		jsr		WaitRaster
		move.w	mloop_bar,$180(a6)
		move.w	#$ffff,bltalwm(a6)	; Preset blitter mask value
		
		; Update Copper bitplane pointers for double buffering
		move.w	c2frame_cn,d2
		addq	#1,d2
		cmp.w	#2,d2
		
		bne		.update_pointers
		moveq	#0,d2
		
.update_pointers
		move.w	d2,c2frame_cn
		
		moveq	#0,d1
		moveq	#0,d3
		bsr		SetFGPtrs
		
		move.l	fg_buf1,a2
		lea.l	0(a0,d2*4),a2		; Pointer to current buffer in A2
		
		; Check input
		bsr		ReadInput
		
		; Compare with previous input		
		cmp.w	input_result,d7
		beq		.inp_done				; Wait until input changes
		
		; Store current input result to prevent repeats
		move.w	d7,input_result
		
		; Test for the different options:
		; *) left mouse button toggles modes
		; *) right mouse button exits program
		; *) fire button button toggles raster bars

		; Test left mouse button
		btst	#10,d7
		beq		.tst_rgtbt

		; Toggle between demo states
		move.w	demo_state,d0
		addq.w	#1,d0
		cmp.w	#DSTATE_COMBINED,d0
		bls		.upd_state
		
		moveq	#DSTATE_CPU_ONLY,d0
		
.upd_state
		move.w	d0,demo_state
		
		; Update subbuffer text
		lea.l	subtxt_blitter,a3
		cmp.w	#DSTATE_BLITTER_ONLY,d0
		beq		.upd_sub
		bmi		.state_cpu
		
		lea.l	subtxt_combo,a3
		bra		.upd_sub
		
.state_cpu
		lea.l	subtxt_cpu,a3

.upd_sub
		move.l	sb_buf,a1
		lea.l	2(a1),a1				; Skip to starting position
		lea.l	(subbuffer_modulo*3)*4(a1),a1	; Offset Y by 4 pixels
		moveq	#3,d3
		moveq	#subbuffer_modulo*3,d5		; Note: top word must be empty
		moveq	#subbuffer_modulo,d6
		bsr		PlotTextMultiCPU

		; Redraw backgrounds
		bsr		DrawBackground
		
		; Reset restore array
		lea.l	restore_ptrs,a0
		moveq	#0,d0
		moveq	#(bob_count_combo*2)-1,d7
.lp		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d7,.lp
		
		; Reset all bobs movement
		moveq	#bob_count_combo,d7
		bsr		SetupBobs

		; Skip to next frame
		bra		mloop				; Done for this frame
		
.tst_rgtbt
		; Test right mouse button
		btst	#11,d7
		beq		.tst_fire
		bra		.done
		
		; Test fire button
.tst_fire
		btst	#8,d7
		beq		.inp_done
		
	IF PERF_FRAME=1
		; Report measured full-frame time
		lea.l	res_basec(pc),a0
		move.l	#$0000ffff,d0
		sub.w	cres_bob(pc),d0
		bsr		conv_to_dec
		
		move.l	sb_buf,a1
		lea.l	2(a1),a1				; Skip to starting position
		lea.l	(subbuffer_modulo*3)*4(a1),a1	; Offset Y by 4 pixels
		lea.l	result_txt,a3
		moveq	#3,d3
		moveq	#subbuffer_modulo*3,d5		; Note: top word must be empty
		moveq	#subbuffer_modulo,d6		; Note: top word must be empty
		bsr		PlotTextMultiCPU
		DBGPause
	ENDIF

		; Toggle raster bars
		move.w	mloop_bar,d0
		tst.w	d0
		beq		.bars_on
		
		; Switch bars off
		clr.w	mloop_bar
		clr.w	cpu_bar
		clr.w	blitter_bar
		clr.w	combo_bar
		bra		.inp_done
		
.bars_on
		; Switch bars on
		move.w	#MLOOP_COL,mloop_bar
		move.w	#CPU_COL,cpu_bar
		move.w	#BLITTER_COL,blitter_bar
		move.w	#COMBO_COL,combo_bar
		
		; Run demo state
.inp_done
		move.w	demo_state,d0
		jmp		.jmp_table(pc,d0.w*4)
		
.jmp_table
		bra.w	CPUOnly
		bra.w	BlitterOnly
		bra.w	Combined

		; Deallocate memory
.done	BlitWait a6
		move.l	$4.w,a6
		bsr		FreeAll
		
		; Exit program
		; CIA usage breaks keyboard on exit, restore CIA values here
		lea.l	ciabase+1,a5			; CIA A
		lea.l	cia_save(pc),a4
		move.b	(a4),ciacra(a5)		; Restore CIA A control value
		move.b	1(a4),ciaicr(a5)	; Restore CIA A IC value

		; Remaining code to restore keyboard
		moveq	#-1,d0
		move.b	d0,ciatblo(a5)		; TB=$ffff
		move.b	d0,ciatbhi(a5)
		move.b	#$8f,ciaicr(a5)		; enable CIA-A interrupts for AmigaOS
		
error	lea.l	custombase,a6
		rts
		
CPUOnly
		; Update bobs
		moveq	#bob_count_cpu,d7
		bsr		UpdateBobs

	IF PERF_FRAME=1
		; Start CIA timer to measure full-frame time
		lea.l	ciabase+1,a5
		CIAStart
	ENDIF
	
		move.w	cpu_bar,$180(a6)
		
		; Setup to restore bobs
		moveq	#bob_count_cpu-1,d7
		move.w	#(bob_count_cpu*8),d2
		btst	#0,c2frame_cn+1	; Select restore pointers
		bne		.fgbf1

		moveq	#0,d2
.fgbf1	lea.l	restore_ptrs,a3
		lea.l	0(a3,d2),a3
		
		move.l	#(buffer_modulo-bob_bwidth),d6
		; Restore bobs
.lp		move.l	d6,d2
		lea.l	cpu_copy,a0
		move.l	(a3)+,a1
		move.l	(a3)+,a2
		tst.l	a1
		beq		.drawbobs	; Skip if NULL pointer found
		
		bsr		CPUBlitCopyOpt
		dbra	d7,.lp
		
.drawbobs
		; Setup to draw new bobs
		moveq	#bob_count_cpu-1,d7
		move.w	#(bob_count_cpu*8),d2
		moveq	#1,d3
		btst	#0,c2frame_cn+1	; Select restore pointers
		bne		.fgbf2

		moveq	#0,d2
		moveq	#0,d3
.fgbf2	lea.l	restore_ptrs,a3
		lea.l	0(a3,d2),a3
		lea.l	fg_buf1,a4
		move.l	0(a4,d3.w*4),a4
		move.l	#buffer_modulo-6,d6
		
		; Draw new bobs
.lp1	lea.l	bobs,a0			; Fetch bobs
		lea.l	0(a0,d7*8),a0
		lea.l	0(a0,d7*8),a0	; Correct entry
		moveq	#0,d0			; Force upper word to be clear
		moveq	#0,d1			; Force upper word to be clear
		move.w	bob_X(a0),d0	; Fetch X
		move.w	bob_Y(a0),d1	; Fetch Y

		; Now draw
		lea.l	cpu_bob,a0
		move.l	d6,d2
		move.l	a4,a2
		bsr		CPUBlitBobOpt
		dbra	d7,.lp1
		
		bra		mloop

BlitterOnly
		; Update bobs
		moveq	#bob_count_blt,d7
		bsr		UpdateBobs

	IF PERF_FRAME=1
		; Start CIA timer to measure full-frame time
		lea.l	ciabase+1,a5
		CIAStart
	ENDIF

		move.w	blitter_bar,$180(a6)
		
		; Setup to restore bobs
		moveq	#bob_count_blt-1,d7
		move.w	#(bob_count_blt*8),d2
		btst	#0,c2frame_cn+1	; Select restore pointers
		bne		.fgbf1

		moveq	#0,d2
.fgbf1	lea.l	restore_ptrs,a1
		lea.l	0(a1,d2),a1
		
		; Set modulo, blitter size & mask
		move.l	#(buffer_modulo-bob_bwidth)<<16|(buffer_modulo-bob_bwidth),d4
		move.w	#bob_bsize,d5
		move.w	#$ffff,bltalwm(a6)
		
		; Restore bobs
.lp		move.l	(a1)+,a2
		move.l	(a1)+,a3
		tst.l	a2
		beq		.drawbobs	; Skip if NULL pointer found
		
		bsr		BlitCopy
		dbra	d7,.lp
		
.drawbobs
		; Setup to draw new bobs
		moveq	#bob_count_blt-1,d7
		move.w	#(bob_count_blt*8),d2
		moveq	#1,d3
		btst	#0,c2frame_cn+1	; Select restore pointers
		bne		.fgbf2

		moveq	#0,d2
		moveq	#0,d3
.fgbf2	lea.l	restore_ptrs,a1
		lea.l	0(a1,d2),a1
		lea.l	fg_buf1,a5
		move.l	0(a5,d3*4),a5
		move.l	#$fffe<<16|buffer_modulo-6,d4
		move.w	#bob_bsize,d5
		
		
		; Set mask
		BlitWait a6
		move.w	#$0000,bltalwm(a6)
		
		; Draw new bobs
.lp1	lea.l	bobs,a2			; Fetch bobs
		lea.l	0(a2,d7*8),a2
		lea.l	0(a2,d7*8),a2	; Correct entry
		moveq	#0,d0			; Force upper word to be clear
		move.w	bob_X(a2),d2	; Fetch X
		move.w	bob_Y(a2),d3	; Fetch Y

		; Now draw
		lea.l	bob,a2
		lea.l	mask,a4
		bsr		BlitBob
		dbra	d7,.lp1
		
		bra		mloop
		
Combined
		; Update bobs
		moveq	#bob_count_combo,d7
		bsr		UpdateBobs

	IF PERF_FRAME=1
		; Start CIA timer to measure full-frame time
		lea.l	ciabase+1,a5
		CIAStart
	ENDIF
		
		move.w	combo_bar,$180(a6)
	
		; Setup to restore bobs
		moveq	#bob_count_combo-1,d7
		move.w	#(bob_count_combo*8),d2
		btst	#0,c2frame_cn+1	; Select restore pointers
		bne		.fgbf1

		moveq	#0,d2
.fgbf1	lea.l	restore_ptrs,a3
		lea.l	0(a3,d2.w),a3
		
		; Set modulo & mask
		move.l	#(buffer_modulo-bob_bwidth)<<16|(buffer_modulo-bob_bwidth),d6
		move.w	#$ffff,bltalwm(a6)
		
		; Fetch & prep CACR value
		movec	cacr,d5
		bset	#1,d5

		; Restore bobs
.lp		move.l	d6,d2
		lea.l	copy_bobject,a0
		move.l	(a3)+,a1
		move.l	(a3)+,a2
		tst.l	a2
		beq		.drawbobs		; Skip if NULL pointer found
		
		bsr		ComboBlitCopyOpt
		movec	d5,cacr			; Freeze the cache on 68020/68030
								; (slightly improves performance on A1200)
		dbra	d7,.lp

		; Restore CACR
		bclr	#1,d5
		movec	d5,cacr			; Unfreeze the cache

.drawbobs
		; Setup to draw new bobs
		moveq	#bob_count_combo-1,d7
		move.w	#(bob_count_combo*8),d2
		moveq	#1,d3
		btst	#0,c2frame_cn+1	; Select restore pointers
		bne		.fgbf2

		moveq	#0,d2
		moveq	#0,d3
.fgbf2	lea.l	restore_ptrs,a3
		lea.l	0(a3,d2.w),a3
		lea.l	fg_buf1,a4
		move.l	0(a4,d3.w*4),a4
		move.l	#$fffe<<16|buffer_modulo-6,d6

		; Set mask
		BlitWait a6
		move.w	#$0000,bltalwm(a6)
		
		; Draw new bobs
.lp1	lea.l	bobs(pc),a0		; Fetch bobs
		lea.l	0(a0,d7.w*8),a0
		lea.l	0(a0,d7.w*8),a0	; Correct entry
		moveq	#0,d0			; Force upper word to be clear
		move.w	bob_X(a0),d0	; Fetch X
		move.w	bob_Y(a0),d1	; Fetch Y
		
		; Now draw
		lea.l	combo_bob(pc),a0
		move.l	d6,d2
		move.l	a4,a2
		bsr		ComboBlitBobOpt
		dbra	d7,.lp1
		
		bra		mloop
		
;---------------------------------------------
; Support routines follow
;---------------------------------------------
	
		; Routine ReadInput
		; From eab.abime.net, reads joystick port 2
		; and checks left & right mouse buttons.
		;
		; Adapted slightly:
		;	- changed result table
		;	- reset potgo at end of read
		;	- conversion table renamed and moved into data section
		;	- changed registers used and cleared result register on call
		;
		; Result table:
		;	Up			-	   1
		;	Down		-	   2
		;	Left		-	   4
		;	Right		-	   8
		;	Fire 1		-	 256
		;	Fire 2		-	 512
		;	Left mouse	-	1024
		;	Right mouse	-	2048
		; Multiple directions/buttons are or'd together
		;
		; A6: custombase
		; Returns
		; D7: joystick/left mouse button value
ReadInput
		movem.l	a0/a3,-(sp)					; Stack
		lea.l	ciaa,a0
		moveq	#0,d7
		btst	#bit_joyb2&7,potinp(a6)

		seq		d7
		add.w	d7,d7

		btst	#bit_joyb1,ciapra(a0)
		seq		d7
		add.w	d7,d7

		move.w	joy1dat(a6),d6
		ror.b	#2,d6
		lsr.w	#6,d6
		and.w	#%1111,d6
		lea.l	joystick,a3
		move.b	0(a3,d6.w),d7
		
		; Read left mouse button
		btst	#bit_mouseb1,ciapra(a0)
		bne		.rmb
		
		bset	#10,d7
		
		; Read right mouse button
.rmb	btst	#bit_mouseb2,potgor(a6)
		bne		.done
		
		bset	#11,d7
			
		; Reset 2nd buttons for next call
.done	move.w	#$cc00,potgo(a6)
		movem.l	(sp)+,a0/a3					; Stack
		rts
	
		; Routine RND
		; This routine creates a psuedorandom number
		; 
		; Code from http://eab.abime.net/showpost.php?p=679815&postcount=8
		; Author: Meynaf
		;
		; D1 - Range (from 0 to D1-1, D1=0 is full 32 bit range)
		;
		; Result:
		; D0 - Psuedorandom number in given range
RND
		move.l	d2,-(a7)			; Stack
		move.l	seed,d0
		move.w	$dff006,d2
		swap	d2
		move.b	$bfe801,d2
		lsl.w	#8,d2
		move.b	$bfd800,d2
		add.l	d2,d0
		mulu.l	#$59fa769f,d2:d0
		add.l	d2,d0
		addi.l	#$4a5be021,d0
		ror.l	#6,d0
		move.l	d0,seed
		tst.l	d1					; 0 -> d0=full rnd32
		beq.s	.nul
		moveq	#0,d2
		divu.l	d1,d2:d0
		move.l	d2,d0				; Modulo
.nul	movem.l	(a7)+,d2			; Stack
		rts
		
		; Routine Randomize
		; This routine initializes the pseudorandom number generator
		; Code from http://eab.abime.net/showpost.php?p=679815&postcount=8
		; Author: Meynaf
Randomize
		movem.l	d0/d7/a2/a3,-(sp)	; Stack

		lea.l	$dff000,a2			; custom chips
		lea.l	$dc0000,a3			; internal clock
		moveq	#15,d7				; (16 regs)
		move.w	(a2),d0
		swap	d0
		move.w	$6(a2),d0			; VHPOSR
.loop
		rol.l	#5,d0
		add.w	(a3),d0
		addq.l	#4,a3
		dbf		d7,.loop
		add.l	$a(a2),d0
		rol.l	#7,d0
		add.l	$12(a2),d0
		move.l	d0,seed
		
		movem.l	(sp)+,d0/d7/a2/a3	; Stack
		rts
	
		; Routine SetupBobs
		; This routine sets up the given number of bobs to their initial
		; locations, speeds and directions.
		;
		; D7 - number of bobs to set up
SetupBobs
		movem.l	d0/d1/a0,-(sp)	; Stack
		
		; Fetch bobs
		lea.l	bobs(pc),a0
	
		; Set loop variable
		subq	#1,d7
		
		; Loop over each bob, setting up a random value for position & speed
.lp		move.l	#$e00001,d1		; Max X position generated = 224
		bsr		RND
		add.l	#$200000,d0		; Add 32 for a range of 32-256.
		move.l	d0,(a0)+		; Store X
		move.l	#$a00001,d1		; Max Y position generated = 160
		bsr		RND
		add.l	#$200000,d0		; Add 32 for a range of 32-192
		move.l	d0,(a0)+		; Store Y
		move.l	#$80001,d1		; Max X speed generated = 8
		bsr		RND
		sub.l	#$40000,d0		; Subtract 4 for a range of -4 to 4
		move.l	d0,(a0)+		; Store DX
		move.l	#$80001,d1		; Max Y speed generated = 8
		bsr		RND
		sub.l	#$40000,d0		; Subtract 4 for a range of -4 to 4
		move.l	d0,(a0)+		; Store DY
		dbra	d7,.lp
		
		movem.l	(sp)+,d0/d1/a0	; Stack
		rts
		
		; Routine UpdateBobs
		; This routine updates the location of the given number of bobs. When
		; reaching screen boundaries, the bobs will change direction.
		;
		; D7 - number of bobs to set up
UpdateBobs
		movem.l	d0-d7/a0,-(sp)		; Stack

		; Fetch bobs
		lea.l	bobs(pc),a0
	
		; Set loop variables
		subq	#1,d7
		move.l	#$1100000,d4		; Set max X to 272
		move.l	#$c00000,d5			; Set max Y to 192
		move.l	#$100000,d6			; Set min X to 16
		
		; Loop over all bobs
.lp		movem.l	(a0),d0-d3			; Read bob data
		
		; Update X
		add.l	d2,d0
		cmp.l	d6,d0				; Test for negative X
		bls		.min_x
		
		cmp.l	d4,d0				; Test for X>256
		bgt		.max_x
		
		; Update Y
.do_y	add.l	d3,d1
		tst.l	d1					; Test for negative Y
		bmi		.min_y
		
		cmp.l	d5,d1				; Test for Y>192
		bgt		.max_y
		
		; Write results
.do_write
		movem.l	d0-d3,(a0)
		lea.l	16(a0),a0
		
		dbra	d7,.lp

		movem.l	(sp)+,d0-d7/a0		; Stack
		rts
		
.min_x
		move.l	d6,d0				; Reset X to minimum
		neg.l	d2					; Flip X direction
		bra		.do_y
		
.max_x
		move.l	d4,d0				; Reset X to maximum
		neg.l	d2					; Flip X direction
		bra		.do_y
		
.min_y
		moveq	#0,d1				; Reset Y to 0
		neg.l	d3					; Flip Y direction
		bra		.do_write
		
.max_y
		move.l	d5,d1				; Reset Y to maximum
		neg.l	d3					; Flip Y direction
		bra		.do_write
		
	
		; Routine DrawBackground
		; This routine blits the background image onto each of the three buffers
		;
		; A6 - Custombase
DrawBackground
		movem.l	d4/d5/d7/a0/a2/a3,-(sp)	; Stack

		; Preset loop values
		lea.l	fg_buf1,a0
		moveq	#2,d7
		move.l	#12,d4				; Blitter AD modulo value
		move.l	#bground_bsize,d5	; Blitter size value
		lea.l	bground,a2			; Source image
		
		; Loop over each of the three buffers
.lp		move.l	(a0)+,a3			; Destination bitmap
		lea.l	2(a3),a3			; Skip to starting location
		bsr		BlitScreen
		dbra	d7,.lp
		
		; Wait until Blitter is finished
		BlitWait a6
		
		movem.l (sp)+,d4/d5/d7/a0/a2/a3	; Stack
		rts
	
		; Routine SetFGPtrs
		; This routine sets the foreground bitplane pointers into the
		; copperlist.
		;
		; D1 - copperlist index
		; D2 - FG buffers index
		; D3 - FG offset
SetFGPtrs
		move.l	a1,-(sp)			; Stack
		lea.l	clist1,a1
		lea.l	bpptrs_o(a1),a1		; Get copperlist & offset
		lea.l	fg_buf1,a2
		move.l	0(a2,d2*4),d1			; Get foreground buffer bitmap
		add.l	d3,d1
		
		; Update copperlist foreground bitplane pointers in a loop
		move.w	d1,6(a1)
		swap	d1
		move.w	d1,2(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,14(a1)
		swap	d1
		move.w	d1,10(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,22(a1)
		swap	d1
		move.w	d1,18(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,30(a1)
		swap	d1
		move.w	d1,26(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,38(a1)
		swap	d1
		move.w	d1,34(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,46(a1)
		swap	d1
		move.w	d1,42(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,54(a1)
		swap	d1
		move.w	d1,50(a1)
		swap	d1
		add.l	#buffer_modulo,d1
		move.w	d1,62(a1)
		swap	d1
		move.w	d1,58(a1)
		swap	d1
		
		move.l	(sp)+,a1			; Stack
		rts
		
		; SetSBPtrs
		; This routine sets the sub buffer bitplane pointers into the
		; copperlist.
SetSBPtrs
		move.l	sb_buf,d0			; Get sub buffer bitmap
		lea.l	sbptrs,a0
		
		; Update copperlist subbuffer bitplane pointers in a loop
		moveq	#2,d7
.lp		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#subbuffer_modulo,d0
		lea.l	8(a0),a0
		dbra	d7,.lp
		rts
		
		; Routine SetFGPal
		; This routine fills the foreground palette values into the copper list
		; (First 8 colours of bank 0 only, upper words only)
		; A0 - pointer to palette data
SetFGPal
		move.l	#pal1,a1
		move.w	#color+2,d5
		lea.l	2(a0),a0
		
		; Upper words bank 0
		moveq	#6,d7
.pallp	move.w	d5,(a1)+
		move.w	(a0)+,(a1)+
		addq.w	#2,d5
		dbra	d7,.pallp
		rts
		
		; Routine: SetSBPal
		; This routine fills the subbuffer palette values into the copper list
SetSBPal
		move.l	#subpal,a0
		move.l	#pal2,a1
		move.w	#color+2,d5
		lea.l	2(a0),a0
		
		moveq	#6,d7
.spllp	move.w	d5,(a1)+
		move.w	(a0)+,(a1)+
		addq.w	#2,d5
		dbra	d7,.spllp
		rts
		
		; Routine SetInitialPal
		; This routine sets up the colours for bank 0, upper words only
SetInitialPal
		lea.l	$180(a6),a1
		move.w	#$0000,$106(a6)			; Set bank 0 upper words
		moveq	#31,d7
.pallp	move.w	(a0)+,(a1)+
		dbra	d7,.pallp
		rts
		
		; Routine SetFullPal
		; This routine sets up the colours for bank 0 and 1 of the AGA chipset 
		; (colours 0-63, both upper and lower words)
		;
		; A0 - pointer to palette data
		; A6 - Custombase
SetFullPal
		; Bank 0 - upper words
		lea.l	$180(a6),a1
		move.w	#$0000,$106(a6)			; Set bank 0
		moveq	#31,d7
.pallp	move.w	(a0)+,(a1)+
		dbra	d7,.pallp
		
		; Bank 1 - upper words
		lea.l	$180(a6),a1
		move.w	#$2000,$106(a6)			; Set bank 1
		moveq	#31,d7
.pallp2	move.w	(a0)+,(a1)+
		dbra	d7,.pallp2
		
		
		; Bank 0 - lower words
		lea.l	$180(a6),a1
		move.w	#$0200,$106(a6)			; Set bank 0 lower words
		moveq	#31,d7
.pallp3	move.w	(a0)+,(a1)+
		dbra	d7,.pallp3
		
		; Bank 1 - lower words
		lea.l	$180(a6),a1
		move.w	#$2200,$106(a6)			; Set bank 1 lower words
		moveq	#31,d7
.pallp4	move.w	(a0)+,(a1)+
		dbra	d7,.pallp4
		
		; Reset bank
		move.w	#$0000,$106(a6)			; Set bank 0
		rts
		
		; Routine: AllocAll
		; This routine allocates all memory
		; Returns:
		; D0 = 0 - OK
		;      1 - Error
AllocAll
		; Allocate memory for the 1st foreground buffer
		move.l	#(buffer_size*8)+16,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		move.l	d0,fg_buf1_alloc
		beq		.done
		
		; Move to next multiple of 8 bytes
		move.l	d0,d1
		and.l	#$f,d1
		cmp.w	#8,d1
		bcs		.align8_a
		
		; Below or at 8, so move to 8
		and.l	#$fffffff0,d0
		or.w	#$8,d0
		bra		.align_done_a

		; Above 8, so move to next multiple of 16
.align8_a
		and.l	#$fffffff0,d0
		add.l	#$10,d0

.align_done_a
		move.l	d0,fg_buf1
		
		; Allocate memory for the 2nd foreground buffer
		move.l	#(buffer_size*8)+16,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		move.l	d0,fg_buf2_alloc
		beq		error1

		; Move to next multiple of 8 bytes
		move.l	d0,d1
		and.l	#$f,d1
		cmp.w	#8,d1
		bcs		.align8_b
		
		; Below or at 8, so move to 8
		and.l	#$fffffff0,d0
		or.w	#$8,d0
		bra		.align_done_b

		; Above 8, so move to next multiple of 16
.align8_b
		and.l	#$fffffff0,d0
		add.l	#$10,d0
.align_done_b
		move.l	d0,fg_buf2

		; Allocate memory for the 3rd foreground buffer
		move.l	#(buffer_size*8)+16,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		move.l	d0,fg_buf3_alloc
		beq		error2

		; Move to next multiple of 8 bytes
		move.l	d0,d1
		and.l	#$f,d1
		cmp.w	#8,d1
		bcs		.align8_c
		
		; Below or at 8, so move to 8
		and.l	#$fffffff0,d0
		or.w	#$8,d0
		bra		.align_done_c

		; Above 8, so move to next multiple of 16
.align8_c
		and.l	#$fffffff0,d0
		add.l	#$10,d0
.align_done_c
		move.l	d0,fg_buf3
		
		; Allocate memory for the subbuffer buffer
		move.l	#(subbuffer_size*3)+16,d0
		move.l	#MEMF_CHIP,d1
		jsr		_LVOAllocMem(a6)
		move.l	d0,sb_buf_alloc
		beq		error3
		
		; Move to next multiple of 8 bytes
		move.l	d0,d1
		and.l	#$f,d1
		cmp.w	#8,d1
		bcs		.align8_d
		
		; Below or at 8, so move to 8
		and.l	#$fffffff0,d0
		or.w	#$8,d0
		bra		.align_done_d

		; Above 8, so move to next multiple of 16
.align8_d
		and.l	#$fffffff0,d0
		add.l	#$10,d0
.align_done_d
		move.l	d0,sb_buf
		
		moveq	#0,d0
		rts

		; No memory
.done	moveq	#1,d0
		rts
		
		; Routine: FreeAll
		; This routine frees all allocated memory
		; Returns
		; D0 = 1
FreeAll
		move.l	#(subbuffer_size*3)+16,d0
		move.l	sb_buf_alloc,a1
		jsr		_LVOFreeMem(a6)
		
error3	move.l	#(buffer_size*8)+16,d0
		move.l	fg_buf3_alloc,a1
		jsr		_LVOFreeMem(a6)
		
error2	move.l	#(buffer_size*8)+16,d0
		move.l	fg_buf2_alloc,a1
		jsr		_LVOFreeMem(a6)
		
error1	move.l	#(buffer_size*8)+16,d0
		move.l	fg_buf1_alloc,a1
		jsr		_LVOFreeMem(a6)
		
		moveq	#1,d0
		rts
		
		; Routine: CopyMem
		; This routine calls Exec CopyMem
		; A0 - source
		; A1 - destination
		; D0 - size
		; No registers trashed
CopyMem
		movem.l d0-d7/a0-a6,-(sp)	; Stack

		move.l	$4.w,a6
		jsr		_LVOCopyMem(a6)
		
		movem.l	(sp)+,d0-d7/a0-a6	; Stack
		rts
		
		; Converts binary to decimal digits
		; (up to five digits only)
		;
		; D0 - number to convert
		; A0 - string (5 characters)
conv_to_dec
		lea.l	5(a0),a0		; Move to last digit + 1
		moveq	#4,d7			; Repeat up to five digits
.lp		divu	#10,d0			; Divide result by ten
		tst.l	d0
		beq		.done

		swap	d0				
		move.w	d0,d1			; Get remainder
		add.w	#48,d1			; Convert to ASCII
		move.b	d1,-(a0)		; Store in string
		move.w	#0,d0			; Clear remainder
		swap	d0
		dbra	d7,.lp
.done	rts

		; Bitmap pointers
		
		; Foreground main buffer 1,2 & 3
		; Buffer size for FGM: 
		;	304x224x4 + room for bob cropping
		
fg_buf1_alloc	dc.l	0
fg_buf2_alloc	dc.l	0
fg_buf3_alloc	dc.l	0
sb_buf_alloc	dc.l	0
		
fg_buf1			dc.l	0
fg_buf2			dc.l	0
fg_buf3			dc.l	0

		; Sub buffer
		; Buffer size for FGS: 288x16x3
sb_buf			dc.l	0

fg_offset		dc.w	0
cia_save		dc.w	0

		cnop 0,4	; Force alignment
bobs			blk.b	bob_SIZEOF*bob_count_combo

		; Variables - objects
		cnop	0,4
		nop		; Force odd alignment
combo_bob		blk.b	obj_SIZEOF
		cnop	0,4
		nop		; Force odd alignment
cpu_bob			blk.b	obj_SIZEOF
		cnop	0,4
		nop		; Force odd alignment
cpu_copy		blk.b	obj_SIZEOF

		; Variables - counters
c2frame_cn		dc.w	0		; 2 Frame counter

		; Variables - other
seed			dc.l	0
demo_state		dc.w	0
input_result	dc.w	0

mloop_bar		dc.w	0
cpu_bar			dc.w	0
blitter_bar		dc.w	0
combo_bar		dc.w	0

; Below section is included to support reporting the measured performance.
	IF PERF_SINGLE|PERF_FRAME=1
cres_bob		dc.w	0
cres_copy		dc.w	0
base_res_bob	dc.w	0
base_res_copy	dc.w	0

result_txt	dc.w	6					; Count
			dc.w	6,1,0				; Colour, X, Y
			dc.w	rbob_end-res_bob	; Length of text line
res_bob		dc.b	"       "
			cnop 0,2	; Realign
rbob_end
			dc.w	6,7,0
			dc.w	rcopy_end-res_copy
res_copy	dc.b	"      "
			cnop 0,2	; Realign
rcopy_end
			dc.w	6,16,0
			dc.w	rbaseb_end-res_baseb
res_baseb	dc.b	"      "
			cnop 0,2	; Realign
rbaseb_end
			dc.w	6,21,0
			dc.w	rfiller_end-res_filler
res_filler	dc.b	"     "
			cnop 0,2	; Realign
rfiller_end
			dc.w	6,28,0
			dc.w	rbasec_end-res_basec
res_basec	dc.b	"      "
			cnop 0,2	; Realign
rbasec_end
			dc.w	6,33,0
			dc.w	rfiller2_end-res_filler2
res_filler2	dc.b	"  "
			cnop 0,2	; Realign
rfiller2_end
	ENDIF
		
;------------------------------------
; Data follows
;------------------------------------
		
		section data,data
		cnop	0,2
				; Joystick conversion values
joystick		dc.b    0,2,10,8,1,0,8,9,5,4,0,1,4,6,2,0
		cnop	0,2
		
		; Palette entries for title screen
tpalette		dc.w	$000,$223,$008,$500,$000,$445,$a21,$382
				dc.w	$778,$e50,$aab,$fa3,$5db,$fff,$0f8,$bbb
				dc.w	$000,$333,$444,$400,$040,$004,$888,$800
				dc.w	$080,$008,$aaa,$a00,$0a0,$00a,$fff,$777
		
mpalette		dc.w	$000,$0e3,$0d3,$0c2,$0b2,$0a1,$091,$081
				dc.w	$070,$060,$050,$040,$030,$020,$010,$fff
				dc.w	$eee,$ddd,$ddd,$ccc,$bbb,$aaa,$999,$888
				dc.w	$777,$777,$666,$555,$444,$333,$222,$222
				dc.w	$f00,$e00,$e00,$d00,$c00,$b00,$b00,$a00
				dc.w	$900,$800,$700,$700,$600,$500,$400,$400
				dc.w	$fdd,$fbb,$f99,$f77,$f55,$f44,$f22,$f00
				dc.w	$fa5,$f94,$f82,$f70,$e60,$c60,$b50,$940
			
mpalette_l		dc.w	$000,$08a,$060,$068,$060,$06e,$067,$061
				dc.w	$07d,$078,$075,$074,$072,$070,$070,$fff
				dc.w	$fff,$fff,$333,$333,$777,$bbb,$bbb,$fff
				dc.w	$fff,$333,$777,$777,$bbb,$bbb,$fff,$333
				dc.w	$f00,$f00,$300,$700,$b00,$f00,$300,$700
				dc.w	$b00,$b00,$f00,$300,$700,$b00,$f00,$000
				dc.w	$faa,$faa,$fff,$fff,$fff,$f00,$f00,$f00
				dc.w	$c8c,$c80,$c80,$c80,$4c0,$c00,$440,$cc0

		; Palette entries for subscreen (8 colours)
subpal			dc.w	$000,$440,$660,$880,$aa0,$cc0,$ee0,$000

		; Subbuffer text
subtxt			dc.w	3					; Count
				dc.w	6,2,0				; Colour, X, Y
				dc.w	.line1_end-.line1	; Length of text line
.line1		dc.b	"6BPL / 50HZ"
			cnop 0,2	; Realign
.line1_end
				dc.w	6,16,0
				dc.w	.line2_end-.line2
.line2			dc.b	"Objects: -"
			cnop 0,2	; Realign
.line2_end
				dc.w	6,28,0
				dc.w	.line3_end-.line3
.line3			dc.b	"   -"
			cnop 0,2	; Realign
.line3_end

subtxt_cpu
				dc.w	2					; Count
				dc.w	6,16,0
				dc.w	.line1_end-.line1
.line1			dc.b	"Objects: ",48+bob_count_cpu
			cnop 0,2	; Realign
.line1_end
				dc.w	6,28,0
				dc.w	.line2_end-.line2
.line2			dc.b	"  CPU  "
			cnop 0,2	; Realign
.line2_end
subtxt_blitter
				dc.w	2					; Count
				dc.w	6,16,0
				dc.w	.line1_end-.line1
.line1			dc.b	"Objects:",48+(bob_count_blt/10),48+(bob_count_blt-(bob_count_blt/10*10))
			cnop 0,2	; Realign
.line1_end
				dc.w	6,28,0
				dc.w	.line2_end-.line2
.line2			dc.b	"Blitter"
			cnop 0,2	; Realign
.line2_end
subtxt_combo
				dc.w	2					; Count
				dc.w	6,16,0
				dc.w	.line1_end-.line1
.line1			dc.b	"Objects:",48+(bob_count_combo/10),48+(bob_count_combo-(bob_count_combo/10*10))
			cnop 0,2	; Realign
.line1_end
				dc.w	6,28,0
				dc.w	.line2_end-.line2
.line2			dc.b	" Combo "
			cnop 0,2	; Realign
.line2_end
; End of File