; serinfo - serial dump program

        ORG     0100h

segment	code

start:
	jmp	 EntryPnt


Intro:	db	'PC-MOS Serial Information Version 1.01 (920916)        ',13,10    ; @@XLAT@@
	db	'Copyright 1991,1992 The Software Link, Incorporated.',13,10
	db	'All Rights Reserved Worldwide',13,10,10
d_hdr:  db   ' PORT       AD      IB      OB    '
        db   'HS    IN  CN    IF   OF    UART TYPE'
        db   13,10,'$'

d_detail:  db  ' COM'
d_pnum_1:  db  '?'               ;port number first (or only) digit
d_pnum_2:  db  '?'               ; port number second digit (or colon)
d_pnum_3:  db  '?'               ; blank (or colon)
           db  '   $'

HSNone:	db	'*NONE*'	

d_bstart:
d_ad:   db  '????'            ; port address (in hex)
        db  '   '
d_ib:   db  '?????'           ; input buffer size
        db  '   '
d_ob:   db  '?????'           ; output buffer size
        db  '  '
d_hs:   db  '??????'             ; handshaking info
        db  '  '
d_inhi: db  ' '
d_in:   db  '?'               ; interrupt level
        db  '   '
d_cn:   db  '?'               ; connection type
        db  '    '
d_if:   db  '??'              ; receive fifo threshhold
        db  '   '
d_of:   db  '??'              ; transmit fifo burst size
        db  '    '

d_bend:                       ; end of area to be blanked out
        db  '$'

MaxFun:	  db	0
Port:	  dw	0
SerName:  dd	0

NoInfo:	  db	'- Information for port not available -$'
NonSpec:  db	'Non-Specific Serial Driver              '
NoVal:	  db	'no'	

Driver:	  db	'==== Driver: $'

SerialTab:
	 dw	None
	 dw	M8250B
	 dw	M16450
	 dw	M16550
	 dw	M16550A
	 dw	Special

None:	 db	'**NONE**$'
M8250B:  db	'8250B$'
M16450:	 db	'8250A/16450$'
M16550:	 db	'16550$'	
M16550A: db	'16550A$'
Special: db	'Inteligent$'

crlf:	db	13,10,'$'

struc	prstruc
.pirec_ad     resw	1
.pirec_ib     resw	1
.pirec_ob     resw	1
.pirec_in     resb	1
.pirec_cn     resb	1
.pirec_hs     resb	1
.pirec_xxon   resb	1
.pirec_rxon   resb	1
.pirec_xxoff  resb	1
.pirec_rxoff  resb	1
.pirec_if     resb	1
.pirec_of     resb	1
.pirec_uart   resb	1
endstruc

PR:	istruc	prstruc
	at	prstruc.pirec_ad, dw	0
	at	prstruc.pirec_ib, dw	0
	at	prstruc.pirec_ob, dw	0
	at	prstruc.pirec_in, db	0
	at	prstruc.pirec_cn, db	0
	at	prstruc.pirec_hs, db	0
	at	prstruc.pirec_xxon, db	0
	at	prstruc.pirec_rxon, db	0
	at	prstruc.pirec_xxoff, db	0
	at	prstruc.pirec_rxoff, db	0
	at	prstruc.pirec_if, db	0
	at	prstruc.pirec_of, db	0
	at	prstruc.pirec_uart, db	0
	iend

HSLetter: db	'xXdrDR'

EntryPnt:
	mov	dx, Intro
	mov	ah,9
	int	21h
PortLoop:
	mov	ah,6
	mov	dx,[cs:Port]
	int	14h
	cmp	ah,0ffh
	je	ExitPort
	and	ah,80h
	jz	ExitPort
	mov	[cs:MaxFun],al		 
	call	DumpPort		
NextPort:
	inc	word [cs:Port]	      		; bump to next port
	jmp	short PortLoop
ExitPort:	
	mov	ax,4c00h
	int	21h

DumpPort:
	mov	ax,cs
	mov	bx, NonSpec
	cmp	byte [cs:MaxFun],18
	jb	DP1
	mov	dx,[cs:Port]
	mov	ah,18
	int	14h
	mov	ax,ds
DP1:
	cmp	ax, [cs:SerName+2]
	je	DP2
	mov	[cs:SerName],bx
	mov	[cs:SerName+2],ax
	push	ax
	push	bx
	push	cs
	pop	ds
	mov	dx, Driver
	mov	ah,9
	int	21h
	pop	bx
	pop	ax
	cld
	mov	ds,ax
	mov	si,bx
	mov	cx,40
DP1Loop:
	lodsb
	mov	dl,al
	mov	ah,2
	int	21h
	loop	DP1Loop
	push	cs
	pop	ds
	mov	dx, crlf
	mov	ah,9
	int	21h
DP2:	
	mov	ax,[cs:Port]
	inc	al
	
	cmp	al,10
	jae	DP3
	mov	byte [cs:d_pnum_2],':'
	mov	byte [cs:d_pnum_3],' '
	add	al,'0'
	mov	[cs:d_pnum_1],al
	jmp	short DP4
DP3:
	mov	byte [cs:d_pnum_3],':'
	mov	ah,'0'
DP3Loop:
	cmp	al,10
	jb	DP3Low
	sub	al,10
	inc	ah
	jmp	short DP3Loop
DP3Low:
        mov	[cs:d_pnum_1],ah
	add	al,'0'
	mov	[cs:d_pnum_2],al	
DP4:
	push	cs
	pop	ds
	mov	dx, d_detail
	mov	ah,9
	int	21h

	cmp	byte [cs:MaxFun],24
	jae	DP5
	mov	dx, NoInfo
	mov	ah,9
	int	21h
	jmp	DPExit
DP5:
	mov	dx,[cs:Port]
	mov	ah,24
	mov	cx,prstruc_size
	mov	bx, PR
	push	cs
	pop	es
	int	14h
	mov	ax,[cs:PR + prstruc.pirec_ad]
	and	ax,07fffh			; mask out high bit
	lea	bx,d_ad+3
	call	bintohex
	mov	ax, [cs:NoVal]
	mov	[cs:d_inhi],ax
	mov	al,[cs:PR + prstruc.pirec_in]
	cmp	al,0ffh
	je	DP6a
	mov	byte [cs:d_inhi],' '
	cmp	al,10	
	jb	DP6
	mov	byte [cs:d_inhi],'1'
	sub	al,10
DP6:
	add	al,'0'
	mov	[cs:d_in],al
DP6a:
	mov	al,[cs:PR + prstruc.pirec_cn]
	mov	[cs:d_cn],al
	mov	al,[cs:PR + prstruc.pirec_hs]
	call	DecodeHS
	mov	al,[cs:PR + prstruc.pirec_if]
	or	al,al
	jnz	DP7
	mov	ax, [cs:NoVal]
	mov	[cs:d_if],ax
	jmp	short DP8
DP7:
	call	Format2
	mov	[cs:d_if],ax
DP8:
	mov	al,[cs:PR + prstruc.pirec_of]
	cmp	al,1
	ja	DP9
	mov	ax, [cs:NoVal]
	mov	[cs:d_of],ax
	jmp	short DP10
DP9:
	call	Format2
	mov	[cs:d_of],ax
DP10:
        mov     di, d_ob+4         ;Point at last digit
        mov     ax,[cs:PR + prstruc.pirec_ob]
        call    format_dec               ;Make it printable

        mov     di, d_ib+4         ;Point at last digit
        mov     ax,[cs:PR + prstruc.pirec_ib]
        call    format_dec               ;Make it printable


	mov	dx, d_bstart
	mov	ah,9
	int	21h	

	xor	bx,bx
	mov	bl,[cs:PR + prstruc.pirec_uart]
	cmp	bl,4
	jbe	DPUart
	mov	bl,5
DPUart:
	shl	bx,1
	mov	dx, [cs:bx+SerialTab]
	mov	ah,9
	int	21h

DPExit:
	mov	dx, crlf
	mov	ah,9
	int	21h
	ret

Format2:
	mov	ah,' '
	cmp	al,10
	jb	F2
	mov	ah,'1'
	sub	al,10
F2:
	add	al,'0'
	xchg	al,ah
	ret

format_dec:
	 push	di
	 push	cx
	 mov	cx,6
fdeclp:
	 mov	byte [di],' '
	 dec	di
	 loop	fdeclp	 
	 pop	cx
	 pop	di
         push dx                ; save work regs
         push bx
         mov  bx,10             ; divisor

format_dec1:
         xor  dx,dx             ; zap the high half
         div  bx                ; extract lowest digit into dx
         add  dl,'0'            ; ascii-ize
         mov  [di],dl           ; store it
         dec  di                ; point to prior char
         cmp  ax,0              ; any more digits?
         jnz  format_dec1          ; yes: process them

         pop  bx                ; restore regs
         pop  dx
         ret

DecodeHS:
	or	al,al
	jnz	DHS1
	mov	ax, [cs:HSNone]
	mov	[cs:d_hs],ax
	mov	ax, [cs:HSNone+2]
	mov	[cs:d_hs+2],ax
	mov	ax, [cs:HSNone+4]
	mov	[cs:d_hs+4],ax
	ret	 
	 
DHS1:
	mov	word [cs:d_hs],2020h
	mov	word [cs:d_hs+2],2020h
	mov	word [cs:d_hs+4],2020h
	mov	cx,6
	xor	si,si
	mov	di, d_hs
	mov	bx,1
DHSLoop:
	push	cx
	mov	cx,bx
	test	cl,al
	jz	DHSSkip
	mov	ah, [cs:si+HSLetter]
	mov	[di],ah
	inc	di
DHSSkip:
	inc	si
	shl	bx,1
	pop	cx
	loop	DHSLoop
	ret

;------------------- binary-to-hexadecimal routine ------------------;
hextable: db    '0123456789ABCDEF'

bintohex:
	push  si
	mov   dl,4
bthloop1:
	mov   si,ax
	and   si,000fh
	mov   cl,[cs:hextable+si]
	mov   [bx],cl
	mov   cl,4
	shr   ax,cl
	dec   bx
	dec   dl
	jg    bthloop1
	pop   si
	ret

EndOfProg:
