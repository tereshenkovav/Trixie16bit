SECTION .TEXT

BUFFER_WIDTH equ 10
BUFFER_HEIGHT equ 8
BUFFER_COLOR equ 6

global setUpBufferAsm
setUpBufferAsm:
	%include "pushregs.asm"

	mov	bx,[bp+14]
	mov 	di,[bx]
	mov 	bx,[bp+12]
	mov     es,[bx]

	cld

	mov	ax,[bp+BUFFER_WIDTH]
	shl	ax, 3
	stosw	
	mov	ax,[bp+BUFFER_HEIGHT]
	stosw

	mov 	bx,[bp+BUFFER_WIDTH]
	mul	bx
	mov	bx,2
	div	bx
	mov 	cx,ax
		
	mov	ax,[bp+BUFFER_COLOR]
	mov	ah,al
	
	rep	stosw

	%include "popregs.asm"
    retf 10

BUFFER_S_WIDTH equ 8
BUFFER_S_HEIGHT equ 6

global copyBufferAsm
copyBufferAsm:
	%include "pushregs.asm"

	mov	bx,[bp+12]
	mov 	di,[bx]
	mov 	bx,[bp+10]
	mov     es,[bx]

	mov	bx,[bp+16]
	mov	si,[bx]
	mov	bx,[bp+14]
	mov	ds,[bx]

	cld

	mov	ax,[bp+BUFFER_S_HEIGHT]
	mov 	bx,[bp+BUFFER_S_WIDTH]
	mul	bx
	mov	bx,2
	div	bx
	mov 	cx,ax
	add	cx,2

	rep	movsw

	%include "popregs.asm"
    retf 12

LINEHORZ_X1 equ 12
LINEHORZ_X2 equ 10
LINEHORZ_Y equ 8
LINEHORZ_COLOR equ 6

global drawLineHorzAsm
drawLineHorzAsm:
	%include "pushregs.asm"

	mov	bx,[bp+16]
	mov 	di,[bx]
	mov 	bx,[bp+14]
	mov     es,[bx]
	
	cld

	mov	ax, [es:di]
	shr	ax, 3 ; buf width in ax
        	
	mov	bx,[bp+LINEHORZ_Y] 
	mul	bx
	add	ax,[bp+LINEHORZ_X1] ; skip bytes in ax	
	add	di,ax
	add 	di,4
	
	mov 	cx,[bp+LINEHORZ_X2] ; x2
	sub	cx,[bp+LINEHORZ_X1] ; x2-x1
	inc 	cx
	mov	ax,[bp+LINEHORZ_COLOR] ; color

	rep	stosb	

	%include "popregs.asm"
    retf 12

LINEVERT_X equ 12
LINEVERT_Y1 equ 10
LINEVERT_Y2 equ 8
LINEVERT_COLOR equ 6

bufwidth dw 0

global drawLineVertAsm
drawLineVertAsm:
	%include "pushregs.asm"

	mov	bx,[bp+16]
	mov 	di,[bx]
	mov 	bx,[bp+14]
	mov     es,[bx]

	cld
        
	mov	ax, [es:di]
	shr	ax, 3
	mov 	[bufwidth], ax ; store buf width
	
	add	di, 4	

	mov	bx,[bp+LINEVERT_Y1] 
	mul	bx
	add 	di,ax

	mov	bx,[bp+LINEVERT_X]
	add	di,bx

	mov 	cx,[bp+LINEVERT_Y2] ; y2
	sub	cx,[bp+LINEVERT_Y1] ; y2-y1
	inc	cx

	mov 	dx, [bufwidth]
	dec 	dx

	mov	ax,[bp+LINEVERT_COLOR] ; color
cicle_vertline:
        stosb	
	add	di,dx
	loop cicle_vertline

	%include "popregs.asm"
    retf 12

DRAWSPRITE_X equ 10
DRAWSPRITE_Y equ 8
DRAWSPRITE_TRANSP equ 6
TRANSPCOLOR equ 127

spritewidth dw 0

global drawSpriteAsm
drawSpriteAsm:
	%include "pushregs.asm"

	mov	bx,[bp+18]
	mov 	di,[bx]
	mov 	bx,[bp+16]
	mov     es,[bx]
	mov	bx,[bp+14]
	mov 	si,[bx]
	mov 	bx,[bp+12]
	mov     ds,[bx]

	cld
        
	mov	ax, [es:di]
	shr	ax, 3
	mov 	[bufwidth], ax ; store buf width
	            
	add	di, 4

	; set at X;Y point
	mov	bx,[bp+DRAWSPRITE_Y] 
	mul	bx
	add 	di,ax
	mov	bx,[bp+DRAWSPRITE_X]
	add	di,bx

	lodsw
	shr	ax, 3
	mov	dx, ax ; dx - sprite width
	lodsw
	mov	bx, ax ; bx - sprite height
                 
cicle_sprite_y:

	mov	cx, dx
	mov	ax,[bp+DRAWSPRITE_TRANSP]
        cmp	ax, 0
        jne     do_transp_alg

	; std alg
	rep	movsb
	jmp	draw_sprite_fin

do_transp_alg:
        lodsb
	cmp 	al, 0FFh
	je	sprite_skip_pixel
	stosb	
	jmp sprite_fin_transp
sprite_skip_pixel:
	inc	di
sprite_fin_transp:
        loop do_transp_alg

draw_sprite_fin:

	mov	ax, [bufwidth]
        add	di, ax
	sub	di, dx

	dec	bx
	cmp	bx,0
	jne	cicle_sprite_y		

	%include "popregs.asm"
    retf 14

global drawSpriteMirrorAsm
drawSpriteMirrorAsm:
	%include "pushregs.asm"

	mov	bx,[bp+18]
	mov 	di,[bx]
	mov 	bx,[bp+16]
	mov     es,[bx]
	mov	bx,[bp+14]
	mov 	si,[bx]
	mov 	bx,[bp+12]
	mov     ds,[bx]

	cld
        
	mov	ax, [es:di]
	shr	ax, 3
	mov 	[bufwidth], ax ; store buf width
	            
	add	di, 4

	; set at X;Y point
	mov	bx,[bp+DRAWSPRITE_Y] 
	mul	bx
	add 	di,ax
	mov	bx,[bp+DRAWSPRITE_X]
	add	di,bx

	lodsw
	shr	ax, 3
	mov	dx, ax ; dx - sprite width
	lodsw
	mov	bx, ax ; bx - sprite height

	add 	si,dx
	dec	si                 
cicle_sprite_y1:

	mov	cx, dx
	mov	ax,[bp+DRAWSPRITE_TRANSP]
	cmp	ax,0
	jne	do_transp_alg1

	; std alg
do_std_alg1:
	mov	al,[ds:si]
	dec	si
	stosb
	loop 	do_std_alg1

	jmp 	draw_sprite_fin1

do_transp_alg1:
        mov	al,[ds:si]
	dec	si
	cmp 	al, 0FFh
	je	sprite_skip_pixel1
	stosb	
	jmp sprite_fin_transp1
sprite_skip_pixel1:
	inc	di
sprite_fin_transp1:
        loop do_transp_alg1

draw_sprite_fin1:

	mov	ax, [bufwidth]
        add	di, ax
	sub	di, dx
	add	si, dx
	add	si, dx

	dec	bx
	cmp	bx,0
	jne	cicle_sprite_y1

	%include "popregs.asm"
    retf 14

global getMouseAsm
getMouseAsm:
	%include "pushregs.asm"

	mov	bx,[bp+8]
	mov 	di,[bx]
	mov 	bx,[bp+6]
	mov     es,[bx]

	mov 	ax, 3
	int 	33h

	cld
        
	mov ax,cx
	stosw	
	mov ax,dx
	stosw	
	mov ax,bx
	stosw	
	
	%include "popregs.asm"	
	retf 4

MOUSEWINDOW_X1 equ 12
MOUSEWINDOW_Y1 equ 10
MOUSEWINDOW_X2 equ 8
MOUSEWINDOW_Y2 equ 6

global setMouseWindowAsm
setMouseWindowAsm:
	%include "pushregs.asm"

	mov	ax,07h
	mov	cx,[bp+MOUSEWINDOW_X1]
	mov	dx,[bp+MOUSEWINDOW_X2]
	int 	33h

	mov	ax,08h
	mov	cx,[bp+MOUSEWINDOW_Y1]
	mov	dx,[bp+MOUSEWINDOW_Y2]
	int 	33h

	%include "popregs.asm"	
	retf 8

DRAWCHAR_X equ 12
DRAWCHAR_Y equ 10
DRAWCHAR_CHAR equ 8
DRAWCHAR_COLOR equ 6

CHAR_SIZE equ 8

global drawCharAsm
drawCharAsm:
	%include "pushregs.asm"

	mov	bx,[bp+20]
	mov 	di,[bx]
	mov 	bx,[bp+18]
	mov     es,[bx]
	mov	bx,[bp+16]
	mov 	si,[bx]
	mov 	bx,[bp+14]
	mov     ds,[bx]

	cld
        
	mov	ax, [es:di]
	shr	ax, 3
	mov 	[bufwidth], ax ; store buf width
	            
	add	di, 4

	; set at X;Y point
	mov	bx,[bp+DRAWCHAR_Y] 
	mul	bx
	add 	di,ax
	mov	bx,[bp+DRAWCHAR_X]
	add	di,bx

	; go to printed char in font table
	mov	ax,[bp+DRAWCHAR_CHAR]
	mov	bx,CHAR_SIZE
	mul	bx
	add	si,ax

	mov	cx, CHAR_SIZE
cicle_char_y:

        lodsb
	mov	dl,al
        mov	ax,[bp+DRAWCHAR_COLOR]
        mov	bx,0
cicle_char_x:        
        bt	dx,bx
	jnc	skip_marker	
	stosb
	jmp 	cicle_char_fin
skip_marker:
	inc	di	
cicle_char_fin:
	inc	bx
	cmp 	bx,8
	jne 	cicle_char_x
        
        mov	ax, [bufwidth]
        add	di, ax
	sub	di, CHAR_SIZE

	loop	cicle_char_y		

	%include "popregs.asm"
    retf 14

FILLRECT_X1 equ 14
FILLRECT_Y1 equ 12
FILLRECT_W equ 10
FILLRECT_H equ 8
FILLRECT_C equ 6

global fillRectAsm
fillRectAsm:
	%include "pushregs.asm"

	mov	bx,[bp+18]
	mov 	di,[bx]
	mov 	bx,[bp+16]
	mov     es,[bx]

	cld

	mov	ax, [es:di]
	shr	ax, 3
	mov 	[bufwidth], ax ; store buf width

	add	di, 4

	; set at X;Y point
	mov	bx,[bp+FILLRECT_Y1]
	mul	bx
	add 	di,ax
	mov	bx,[bp+FILLRECT_X1]
	add	di,bx

	mov	dx, [bp+FILLRECT_W] ; dx - rect width	
	mov	bx, [bp+FILLRECT_H] ; bx - rect height

cicle_rect_y:

	mov	cx, dx
	mov	ax,[bp+FILLRECT_C]
	rep	stosb

	mov	ax, [bufwidth]
        add	di, ax
	sub	di, dx

	dec	bx
	cmp	bx,0
	jne	cicle_rect_y

	%include "popregs.asm"
    retf 14

PALETTE_START equ 8
PALETTE_COUNT equ 6

global setPaletteAsm
setPaletteAsm:
	%include "pushregs.asm"

	mov	bx,[bp+12]
	mov 	dx,[bx]
	mov 	bx,[bp+10]
	mov     es,[bx]

	mov 	ah,10h
	mov	al,12h
	mov	bx,[bp+PALETTE_START]
	mov	cx,[bp+PALETTE_COUNT]
	int	10h

	%include "popregs.asm"
    retf 8
