; $VER: object.asm 1.0 (02.02.20)
;
; object.asm
; 
; Contains support routines for dealing with the object structs.
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200202
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

; Includes 
	include exec/types.i

	include object.i
	include	debug.i

		; Code start
		section code,code
		; Routine: SetupBaseObject
		; This routine sets up a base object with the given parameters
		;
		; D3 - Destination modulo
		; D7 - Width of object in longwords
SetupBaseObject
		move.w	d7,bobj_width(a0)
		clr.w	bobj_height(a0)
		clr.w	bobj_image_offset(a0)
		move.w	d3,bobj_dest_offset(a0)
		clr.w	bobj_bltsize(a0)
		rts
		
		; Routine: SetupObject
		; This routine sets up an object at the given location.
		; It uses a base object to get the required information.
		;
		; A0 - Pointer to object
		; A1 - Pointer to base object
		; A2 - Image pointer
		; A3 - Mask pointer
SetupObject
		move.w	bobj_width(a1),bobj_width(a0)
		move.w	bobj_height(a1),bobj_height(a0)
		move.w	bobj_image_offset(a1),bobj_image_offset(a0)
		move.w	bobj_dest_offset(a1),bobj_dest_offset(a0)
		move.w	bobj_bltsize(a1),bobj_bltsize(a0)

		move.l	a2,obj_image_ptr(a0)
		move.l	a3,obj_mask_ptr(a0)
		rts
; End of File