; DISKID.ASM - The MOS Disk Label command

; Command format: DISKID [d:][volume label]				      

OPS		equ	80h	; location of operands
LABEL_LEN	equ	11	; length of filename

segment moss

	org	100h

moslabl:

	jmp	begin

vol_flag:	db	00h	; indicates if there is a current directory
xfcb:	db	0ffh,00h,00h,00h,00h,00h
vattri:	db	08h		; volume label attribute
drive1:	db	'?'		; reserved for existing dir label.
fname1:	db	'???????????',00h,24 dup(00h)	; xfcb for file delete
root:	db	'?:\',00h	; to change dir
drive:	db	'?:'
fname:	db	'\????????.???',00h	; buffer that filename is copied into.
savecx:	dw	00h		; save area
no_drv_spec:	db	01h	; flag to indicate no drive on comnd line
lbl_msg:	db	13,10,'Disk ID for drive ? is $    ' ;@@XLAT
lbl_name: db	15 dup(' ') ; message
	db	'$'
not_set:	db	'not set.      ',13,10,'$' ;@@XLAT
ns_len:	dw	$-not_set		; length of 'not_set' message
del_msg:	db	13,10,'Delete current Disk ID (Y/N)? $           ' ;@@XLAT
bdchar:	db	13,10,'Invalid character in Disk ID.              ',36 ;@@XLAT
prompt:	db	13,10,'Enter Disk ID  (11 character max or ENTER for none): $              ' ;@@XLAT
crlf:	db	13,10,36	; you guess!!!!
cur_dsk:	db	00h		; saves current disk

;******************************************************************************
;* 				Error Messages				      *
;******************************************************************************

no_hand:	db	'No file handles left!       ',13,10,24h ;@@XLAT
bad_drv:	db	'Invalid drive specified!      ',13,10,36 ;@@XLAT
no_room:	db	'No room in root directory!     ',0dh,0ah,36 ;@@XLAT
weird:	db	'System error!   ',13,10,'$' ;@@XLAT
yesmsg:	db	'Yes   ' ;@@XLAT
nomsg:	db	'No    ' ;@@XLAT

;******************************************************************************
findfile:
	mov	ah, [di]
	cmp	ah,'?'		; allow for globals
	je	no_err
	cmp	ah,'*'
	je	no_err
	cmp	ah,30h		; check for ascii numbers for filename
	jb	bump_di
	cmp	ah,39h		; '9'
	ja	chk_alphab
	jmp	no_err		; filename starts with a number
	nop

chk_alphab:
	cmp	ah,41h		; 'A'
	jb	bump_di
	cmp	ah,5ah		; 'Z'
	ja	chk_lcase
	jmp	no_err
	nop

chk_lcase:
	cmp	ah,5ch		; '\'	pathname. valid!
	je	no_err
	cmp	ah,61h		; 'a'
	jb	bump_di
	cmp	ah,7ah		; 'z'
	ja	err		; invalid file name
	jmp	no_err
	nop
bump_di:
	inc	di
	loop	findfile
err:
	stc
	jmp	dood
	nop
no_err:
	clc			; clear the carry, we found a non-blank

dood:
	ret

;******************************************************************************
;* ---invalid char table --- *

charstb:	db	'"','+',',','.','/',':',';','<','=','>','[','\',']','|'
tab_len:	db	$-charstb	; length of table

chk_char:

check_start:
	push	bx
	push	cx
	cmp	al,20h
	jle	no_good
	lea	bx,charstb	; begin loop to check table.
	mov	cl,[tab_len]	; cx is counter
	xor	ch,ch
chk_l:
	cmp	al,[bx]
	jz	no_good		; carry is set, return
	inc	bx		; get next char
	loop	chk_l
	clc			; just in case
	jmp	no_gud
	nop

no_good:
	stc
no_gud:
	pop	cx
	pop	bx
	ret

;******************************************************************************
begin:
	%include	"verschk.inc"

	mov	bx,OPS		; see if they entered anything.
	mov	cl, [bx]
	xor	ch,ch
	mov	[savecx],cx	; save it for later reference
	or	cx,cx		; see if cx=0
	jnz	som_drv		; if so, jump
	jmp	get_drv		; get  then set the drive
	nop
som_drv:
	mov	di,bx		; check for drive specifier on command line
	inc	di
	call	findfile	; locate 1st non-blank
	jnc	any_drv
	jmp	get_drv
	nop
any_drv:
	cmp	byte [di+1],':'	; check for drive spec
	jnz	get_drv
	mov	al, [di]

set_drv:
	push	ax
	cmp	al,40h		; see if it came from get_drv
	jl	set_10		; if < 40h assume no.
	and	al,1fh		; else strip off bits in high order nibble
set_10:
	mov	[drive1],al	; save in xfcb
	dec	al		; now check to see if desired drive is valid
	mov	bl,al		; save it for later comparison
	mov	dl,al		; select disk to see if its there
	mov	ah,19h		; get current disk
	int	21h		; in order to save it to reset later
	mov	[cur_dsk],al
	mov	ah,0eh		; select new disk to see if it is in system
	int	21h
	mov	ah,19h		; get current disk.
	int	21h
	cmp	al,bl		; if = disk is valid.
	je	proceed
	pop	ax		; discard ax
	mov	dl,[cur_dsk]
	mov	ah,0eh
	int	21h		; reset current disk
	mov	al,15		; indicate bad drive
	jmp	chk_15		; print error message and terminate

proceed:
	pop	ax		; 
	or	al,40h		; don't need to add 40h to it if from cmnd line
	and	al,0dfh		; make sure its upper case
	mov	[root],al	; set asciiz to chdir for del fcn
	mov	[drive],al	; set drive from command line
	
	mov	ah,al
	mov	al,'?'		; find drive char in message
	push	cx		; who knows if needed 
	push	di
	mov	cx,ax		; large number in CX
	mov	di, lbl_msg
	repnz scasb		; find ?
	mov	[di-1],ah	; replace ? with drive char
	pop	di
	pop	cx
	jmp	chk_4_vol	; check for existing label
	nop

get_drv:
	dec	[no_drv_spec]	; indicate no drive on command line
	mov	ah,19h		; call OS to return default drive
	int	21h
	inc	al		; bump it up one for the fun of it
	jmp	set_drv

chk_4_vol:
	mov	ah,1ah		; set dta
	lea	dx,dta
	int	21h
	push	cx
	mov	ah,4eh		; see if there is an existing label
	lea	dx,drive	; file name
	mov	cl,[vattri]	; volume attribute
	mov	ch,00h
	int	21h
	pop	cx
	jnc	get_dta		; no carry - file exists. get dta to find name
	lea	si,not_set
	push	di
	lea	di,lbl_name
	push	cx
	mov	cx,[ns_len]
	rep	movsb		; xfer "not set" to lbl_msg
	pop	cx
	pop	di
	test	[no_drv_spec],01h
	jz	ck_line

drv_adjust:
	inc	di
	inc	di
	dec	cx		; see if filename on command line

ck_line:
	call	findfile
	jnc	ck_lfil		; no carry means that there is a filename there
	jmp	do_prompt	; carry means we means we must ask for a name.
ck_lfil:
	lea	si,fname+1	; buffer for xfer
	xor	bl,bl		; use bl as a counter

l_xfer:
	mov	al, [di]	; di points to command line
	cmp	al,0dh		; end of filename on command line
	jz	l_xfered
	cmp	al,20h		; allow a space
	je	l_xffnc
	call	chk_char	; see if its a valid char
	jnc	l_xffnc
	jmp	bad_char	; nope. prompt for a new name
l_xffnc:
	cmp	bl,8		; see if we need to insert a period yet.
	je	bump_regs	; yup
	mov	[si],al
	inc	di
bump_regs:
	inc	si
	inc	bl
	jmp	l_xfer

l_xfered:
	mov	[si],00h	; make asciiz

flag_ck:
	cmp	byte [vol_flag],00h	; see if a label exists
	jnz	flag_ckt	; non-zero indicates a label is there
	jmp	make_file	; otherwise just create a new file
	nop
flag_ckt:
	jmp	want_del1	; see if they wish to change it

get_dta:
	lea	bx,dta
	add	bx,30
	inc	[vol_flag]	; indicate an existing label
	push	di
	lea	si,fname1	; buffer
	lea	di,lbl_name	; di points to lbl_msg so that we can put 
				; filename there also
xfer_oname:
	mov	al, [bx]
	cmp	al,2eh		; see if its a period
	je	no_dot		; yup
	cmp	al,00h		; see if end of name
	jz	o_xfered
	mov	[si],al
	mov	[di],al
	inc	di
	inc	si
	inc	bx
	jmp	xfer_oname

no_dot:
	inc	bx		; since filename has a period, skip it
	mov	si, fname1+8
	mov	di, lbl_name+8
	jmp	xfer_oname

o_xfered:
	mov	ax,0d0ah	; put cr/lf in lbl_msg
	mov	[di],ax
	pop	di
	test	[no_drv_spec],01h
	jnz	drv_adjust
	jmp	ck_line

ren_file:
	cmp	byte [vol_flag],01h	; see if a volume exists
	jz	ren_fdel	; if so, delete it
	jmp	no_vol		; otherwise, just exit
	nop
ren_fdel:
	mov	ah,13h		; delete existing file
	lea	dx,xfcb
	int	21h
	cmp	al,0ffh
	jz	file_err
	cmp	byte [fname+1],'?'	; see if a new name is there
	jnz	make_file

no_vol:
	mov	ax,4c00h
	jmp	fini		; exit with return code
	nop

make_file:
	mov	ah,3ch
	lea	dx,drive
	mov	cl,[vattri]
	xor	ch,ch
	int	21h
	jc	file_err
	mov	ax,4c00h

fini:
	push	ax
	mov	ah,0eh		; reset to default disk
	mov	dl,[cur_dsk]
	int	21h
	pop	ax
	int	21h		; exit with return code

file_err:
	mov	ah,59h		; get extended error code
	int	21h
	cmp	al,4		; out of handles
	jnz	chk_15
	lea	dx,no_hand
	mov	al,1		; errorlevel 1
	jmp	err_exit
	nop

chk_15:
	cmp	al,15		; invalid drive spec
	jnz	chk_18
	lea	dx,bad_drv
	mov	al,2		; error level 2
	jmp	err_exit
	nop

chk_18:
	cmp	al,18		; root dir full
	jnz	do_misc
	lea	dx,no_room
	mov	al,3		; errorlevel 3
	jmp	err_exit
	nop

do_misc:
	mov	ah,2		; for testing purposes only!!!
	mov	dl,al
	add	dl,30h		; make it a printable char
	int	21h
	sub	dl,30h
	lea	dx,weird

err_exit:
	mov	ah,9
	int	21h
	mov	ah,4ch
	jmp	fini

bad_char:
	lea	dx,bdchar
	mov	ah,9
	int	21h
	jmp	p1
	nop

do_prompt:
	mov	ah,9
	lea	dx,lbl_msg
	int	21h
	mov	ah,9
	lea	dx,lbl_name
	int	21h

p1:
	mov	ah,9
	lea	dx,prompt
	int	21h

get_name:
	lea	dx,dta0		; call OS to buffer input
	mov	ah,0ah
	int	21h

do_xfer:
	mov	bx,dx
	mov	cl,[bx+1]
	xor	ch,ch
	cmp	cx,LABEL_LEN	; see if # of chars enter <= LABEL_LEN
	jle	do_xfrle	; I'm picking up Rod's habits...
	mov	cx,LABEL_LEN	; xfer only 11 chars
do_xfrle:
	or	cx,cx		; see if any chars were entered
	jz	want_del	; no, ask for delete
	lea	di,fname+1	; filename
	inc	bx
	inc	bx
	xor	dl,dl

xfer1:
	cmp	dl,8
	je	do_dot

xfer_more:
	mov	al,[bx]
	cmp	al,0dh
	jz	xfer1_dun
	cmp	al,20h
	je	xfer_msp
	call	chk_char
	jc	bad_char
xfer_msp:
	mov	[di],al
	inc	bx
	inc	di
	inc	dl
	loop	xfer1

xfer1_dun:
	mov	ah,9
	lea	dx,crlf
	int	21h		; output cr/lf
	mov	[di],00h	; make asciiz
	jmp	flag_ck

do_dot:
	inc	di			; call
	jmp	xfer_more

want_del:
	cmp	byte [vol_flag],01h
	jl	no_del

want_del1:
	lea	dx,del_msg
	mov	ah,9
	int	21h
	mov	ah,07h		; input with no ^c check or echo
	int	21h
	mov	dl,al
	mov	ah,6
	int	21h
	and	al,5Fh
	cmp	al,[yesmsg]	; test answered affirmatively
	jnz	want_nrn
	jmp	ren_file
want_nrn:
	cmp	al,[nomsg]
	jnz	want_del

no_del:
	mov	ax,4c00h
	jmp	fini

dta0	db	50h,00h
dta	db	00h,50h dup(00h)	; disk transfer address	
