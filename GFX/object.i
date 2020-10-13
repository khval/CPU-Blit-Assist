; $VER: object.i 1.0 (02.02.20)
;
; object.i
; 
; Include file defining the Blitter/Soft blitting object structure.
;
;
; Author: Jeroen Knoester
; Version: 1.0
; Revision: 20200202
;
; Assembled using VASM in Amiga-link mode.
; TAB size = 4 spaces

	IFND	GFX_OBJECT_I
GFX_OBJECT_I	SET	1

; External references
	XREF	SetupBaseObject
	XREF	SetupObject
	
; Structures
 STRUCTURE	BaseObject,0
	UWORD	bobj_bltsize			; Blitter BLTSIZE value
 	UWORD	bobj_width				; Width in longwords*
	UWORD	bobj_height				; CPU height in lines * planes
	UWORD	bobj_image_offset		; CPU image offset in bytes
	UWORD	bobj_dest_offset		; CPU destination offset in bytes
	LABEL	bobj_SIZEOF

; *) bobj_width is used by ComboBlitBobOpt/CPUBlitBobOpt as # of bitplanes
;    instead.
	
 STRUCTURE	Object,0
	STRUCT	obj_base,bobj_SIZEOF	; Base object settings
	APTR	obj_image_ptr			; Pointer to image
	APTR	obj_mask_ptr			; Pointer to mask
	LABEL	obj_SIZEOF

	ENDC	; GFX_OBJECT_I
; End of File