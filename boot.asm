org 0x7c00 ;bootloader start address
BaseOfStack equ 0x7c00 ;marco defination

Label_Start:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,BaseOfStack ;stack pointer

;clear screen

    mov ax,0600h
    mov bx,0700h
    mov cx,0
    mov dx,0184fh
    int 10h ;bios interrupt

;set focus

    mov ax,0200h
    mov bx,0000h
    mov dx,0000h
    int 10h

;display message on screen

    mov ax,1301h
    mov bx,000fh
    mov dx,0000h
    mov cx,10
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,StartBootMessage
    int 10h

    xor	ah,	ah
    xor	dl,	dl
    int	13h

    jmp	$

    StartBootMessage: db "Start Boot"

    resb 510 - ($ - $$)
    dw	0xaa55
