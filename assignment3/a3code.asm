org 100h

jmp start 

;constants
win_top     equ 3
win_left    equ 8
win_bottom  equ 21
win_right   equ 72
win_width   equ win_right - win_left + 1        ; 65
inner_w     equ win_right - win_left - 1        ; 63  
text_col    equ win_left + 2                    
text_w      equ (win_right - 2) - text_col + 1  
search_col  equ win_left + 1                    
search_row0 equ win_top + 1                     
search_rown equ win_bottom - 1                  
nlines      equ 19
status_row  equ 23

%macro PUSHI 1                  
    mov ax, %1
    push ax
%endmacro

start:
    cld
    PUSHI 0720h
    call clear_screen

    PUSHI win_top
    PUSHI win_left
    PUSHI win_bottom
    PUSHI win_right
    PUSHI 0Bh                   ; border attribute
    call draw_box

    PUSHI win_top
    PUSHI title_col
    PUSHI title
    PUSHI 1Eh
    call print_string

    PUSHI 0                     ; first line index
    PUSHI 17                    ; number of lines
    PUSHI search_row0           ; first screen row
    call draw_text

    PUSHI win_top
    PUSHI win_left
    PUSHI win_bottom
    PUSHI win_right
    PUSHI 2
    call scroll_window_up

    PUSHI 17                    
    PUSHI 2
    PUSHI search_rown - 1      
    call draw_text

    ;find & highlight every occurrence of the keyword
    PUSHI keyword
    PUSHI 0CEh                  ; blinking yellow on red
    call find_and_highlight     
    mov [matches], ax

    PUSHI status_row
    PUSHI 10
    PUSHI msg1
    PUSHI 1Fh
    call print_string

    push word [matches]         ; number
    PUSHI status_row            ; row
    PUSHI 10 + msg1_len         ; column
    PUSHI 1Eh                   ; attribute
    call printNum               

    push ax                     
    pop bx                      
    PUSHI status_row
    push bx
    PUSHI msg2
    PUSHI 1Fh
    call print_string

    mov ah, 02h
    xor bh, bh
    mov dh, 24
    xor dl, dl
    int 10h

    xor ah, ah
    int 16h

    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

calc_offset:
    push bp
    mov bp, sp
    push dx
    mov ax, [bp+6]
    mov dx, 80
    mul dx
    add ax, [bp+4]
    shl ax, 1
    pop dx
    pop bp
    ret 4

clear_screen:
    push bp
    mov bp, sp
    push ax
    push cx
    push di
    push es
    mov ax, 0B800h
    mov es, ax
    xor di, di
    mov ax, [bp+4]
    mov cx, 2000
    cld
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    pop bp
    ret 2

draw_box:
    push bp
    mov bp, sp
    sub sp, 4
    push ax
    push bx
    push cx
    push di
    push es
    mov ax, 0B800h
    mov es, ax
    cld

    mov ax, [bp+6]              ; inner width = right-left-1
    sub ax, [bp+10]
    dec ax
    mov [bp-2], ax
    mov ax, [bp+8]              ; inner height = bottom-top-1
    sub ax, [bp+12]
    dec ax
    mov [bp-4], ax

    ; top edge
    push word [bp+12]
    push word [bp+10]
    call calc_offset
    mov di, ax
    mov ah, [bp+4]
    mov al, 0C9h
    stosw
    mov al, 0CDh
    mov cx, [bp-2]
    rep stosw
    mov al, 0BBh
    stosw

    ; middle rows
    mov bx, [bp+12]
    inc bx
.mid:
    cmp word [bp-4], 0
    je .bottom
    push bx
    push word [bp+10]
    call calc_offset
    mov di, ax
    mov ah, [bp+4]
    mov al, 0BAh
    stosw
    mov ax, 0720h               
    mov cx, [bp-2]
    rep stosw
    mov ah, [bp+4]
    mov al, 0BAh
    stosw
    inc bx
    dec word [bp-4]
    jmp .mid

.bottom:                        
    push word [bp+8]
    push word [bp+10]
    call calc_offset
    mov di, ax
    mov ah, [bp+4]
    mov al, 0C8h
    stosw
    mov al, 0CDh
    mov cx, [bp-2]
    rep stosw
    mov al, 0BCh
    stosw

    pop es
    pop di
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret 10

print_string:
    push bp
    mov bp, sp
    push ax
    push si
    push di
    push es
    mov ax, 0B800h
    mov es, ax
    push word [bp+10]
    push word [bp+8]
    call calc_offset
    mov di, ax
    mov si, [bp+6]
    mov ah, [bp+4]
    cld
.l: lodsb
    or al, al
    jz .done
    stosw
    jmp .l
.done:
    pop es
    pop di
    pop si
    pop ax
    pop bp
    ret 8

draw_line:
    push bp
    mov bp, sp
    push ax
    push cx
    push si
    push di
    push es
    mov ax, 0B800h
    mov es, ax
    push word [bp+6]
    mov ax, text_col
    push ax
    call calc_offset
    mov di, ax
    mov si, [bp+4]
    mov cx, text_w
    mov ah, 07h
    cld
.l: lodsb
    or al, al
    jz .pad
    stosw
    loop .l
.pad:
    mov al, ' '
    rep stosw                  
    pop es
    pop di
    pop si
    pop cx
    pop ax
    pop bp
    ret 4

draw_text:
    push bp
    mov bp, sp
    sub sp, 2
    push ax
    push bx
    push cx
    mov ax, [bp+4]
    mov [bp-2], ax
    mov bx, [bp+8]
    shl bx, 1                 
    mov cx, [bp+6]
.l: jcxz .done
    push word [bp-2]
    push word [lines+bx]
    call draw_line
    add bx, 2
    inc word [bp-2]
    loop .l
.done:
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret 6

scroll_window_up:
    push bp
    mov bp, sp
    sub sp, 6
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    mov ax, 0B800h
    mov ds, ax                  
    mov es, ax
    cld

    mov ax, [bp+6]             
    sub ax, [bp+10]
    dec ax
    mov [bp-2], ax

    mov ax, [bp+8]            
    sub ax, [bp+12]
    dec ax
    mov dx, [bp+4]             
    cmp dx, ax
    jbe .ok
    mov dx, ax
.ok:
    mov [bp-6], dx
    sub ax, dx                  
    mov [bp-4], ax

    mov bx, [bp+12]             
    inc bx
.mv:
    cmp word [bp-4], 0
    je .blank
	
    ; destination offset
    push bx
    mov ax, [bp+10]
    inc ax
    push ax
    call calc_offset
    mov di, ax
	
    ; source offset  (row + n)
    mov ax, bx
    add ax, [bp-6]
    push ax
    mov ax, [bp+10]
    inc ax
    push ax
    call calc_offset
    mov si, ax
    mov cx, [bp-2]
    rep movsw                   ; move one row inside the window only
    inc bx
    dec word [bp-4]
    jmp .mv

.blank:                         
    cmp word [bp-6], 0
    je .done
    push bx
    mov ax, [bp+10]
    inc ax
    push ax
    call calc_offset
    mov di, ax
    mov cx, [bp-2]
    mov ax, 0720h
    rep stosw
    inc bx
    dec word [bp-6]
    jmp .blank

.done:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret 10

find_and_highlight:
    push bp
    mov bp, sp
    sub sp, 74
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    cld

    mov word [bp-2], 0

    ; key length
    mov si, [bp+6]
    xor cx, cx
.len:
    lodsb
    or al, al
    jz .gotlen
    inc cx
    jmp .len
	
.gotlen:
    cmp cx, 0
    je .exit
    cmp cx, inner_w
    ja .exit
    mov [bp-6], cx
    mov ax, inner_w
    sub ax, cx
    mov [bp-10], ax

    mov word [bp-4], search_row0
.row:
    push word [bp-4]
    mov ax, search_col
    push ax
    call calc_offset
    mov si, ax
    mov ax, 0B800h
    mov ds, ax                 
    mov ax, ss
    mov es, ax                  
    lea di, [bp-74]
    mov cx, inner_w
.cp:
    lodsw                      
    stosb
    loop .cp

    mov ax, ss
    mov ds, ax
    mov es, ax
    mov word [bp-8], 0
.scan:
    mov ax, [bp-8]
    cmp ax, [bp-10]
    ja .rowdone
    lea di, [bp-74]
    add di, ax
    mov si, [bp+6]
    mov cx, [bp-6]
    repe cmpsb
    jne .nomatch

    inc word [bp-2]
    push word [bp-4]
    mov ax, [bp-8]
    add ax, search_col
    push ax
    call calc_offset
    mov di, ax
    inc di                      ; point at the attribute byte
    mov ax, 0B800h
    mov es, ax
    mov cx, [bp-6]
    mov al, [bp+4]
.at:
    stosb                       ; write attribute
    inc di                      ; skip the ASCII byte
    loop .at
    mov ax, ss
    mov es, ax
    mov ax, [bp-8]              ; continue after the matched text
    add ax, [bp-6]
    mov [bp-8], ax
    jmp .scan
.nomatch:
    inc word [bp-8]
    jmp .scan

.rowdone:
    inc word [bp-4]
    cmp word [bp-4], search_rown
    jbe .row

.exit:
    mov ax, [bp-2]              ; return value
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    mov sp, bp
    pop bp
    ret 4

printNum:
    push bp
    mov bp, sp
    sub sp, 2
    push bx
    push cx
    push dx
    push di
    push es
    mov ax, 0B800h
    mov es, ax
    cld

    mov word [bp-2], 0
    mov ax, [bp+10]
    mov bx, 10
	
.div:
    xor dx, dx
    div bx
    push dx                   
    inc word [bp-2]
    or ax, ax
    jnz .div

    push word [bp+8]
    push word [bp+6]
    call calc_offset
    mov di, ax
    mov cx, [bp-2]
	
.out:
    pop ax
    add al, '0'
    mov ah, [bp+4]
    stosw
    loop .out

    mov ax, [bp+6]              ; return next free column
    add ax, [bp-2]
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    mov sp, bp
    pop bp
    ret 8

; data
title       db ' TEXT VIEWPORT MANAGER ', 0
title_len   equ $ - title - 1
title_col   equ win_left + (win_width - title_len) / 2
 
keyword     db 'stack', 0
msg1        db 'total matches found: ', 0
msg1_len    equ $ - msg1 - 1
msg2        db ' | viewport status: ACTIVE', 0
matches     dw 0
 
l0  db 'The Intel 8088 Processor - A Short History', 0
l1  db '==========================================', 0
l2  db 'The Intel 8088 was released in 1979 as a cost reduced', 0
l3  db 'version of the 8086 processor. Inside, it is a full', 0
l4  db 'sixteen bit CPU, but its external data bus is only', 0
l5  db 'eight bits wide, so every word moves in two bus cycles.', 0
l6  db 'IBM chose this chip for the original Personal Computer', 0
l7  db 'in 1981, and that single decision shaped the industry.', 0
l8  db 'The processor has fourteen registers, including four', 0
l9  db 'general purpose registers named AX, BX, CX and DX.', 0
l10 db 'Memory is reached through segment and offset pairs,', 0
l11 db 'which together form a twenty bit physical address', 0
l12 db 'and allow the CPU to reach one megabyte of memory.', 0
l13 db 'Programs keep return addresses and local data on the', 0
l14 db 'stack, which grows downward and is managed by SP.', 0
l15 db 'Calling a procedure pushes the return address on the', 0
l16 db 'stack, and the ret instruction pops it back again.', 0
l17 db 'Remember: the stack is last in, first out. stack stack.', 0
l18 db 'hope it was informative.', 0
 
lines dw l0, l1, l2, l3, l4, l5, l6, l7, l8, l9
      dw l10, l11, l12, l13, l14, l15, l16, l17, l18

