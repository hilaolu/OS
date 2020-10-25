org 0x7c00 ;bootloader start address
BaseOfStack equ 0x7c00 ;marco defination
BaseOfLoader equ 0x1000
OffsetOfLoader equ 0x00

RootDirSectors equ 14
SectorNumOfRootDirStart equ 19
SectorNumOfFAT1Start equ 1
SectorBalance equ 17

;FAT STRUCTURE
;(BOOT SECTOR->FILE ALLOCATE TABLE->ROOT DIRECTORY)(REVERSED)->DATA

    jmp short Start
    nop
    BS_OEMName db 'OSFORIOT'
    BPB_BytesPerSec dw 512
    BPB_SecPerClus db 1
    BPB_RsvdSecCnt dw 1
    BPB_NumFATs db 2
    BPB_RootEntCnt dw 224
    BPB_TotSec16 dw 2880
    BPB_Media db 0xf0
    BPB_FATSz16 dw 9
    BPB_SecPerTrk dw 18
    BPB_NumHeads dw 2
    BPB_HiddSec dd 0
    BPB_TotSec32 dd 0
    BS_DrvNum db 0
    BS_Reversed1 db 0
    BS_BootSig db 29h
    BS_VolID dd 0
    BS_VolLab db 'boot loader'
    BS_FileSysType db 'FAT12   '

Start:
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

;reset floppy

    xor	ah,	ah
    xor	dl,	dl
    int	13h

;search loader.bin

    mov word [SectorNo],SectorNumOfRootDirStart

Search_In_Root_Dir_Begin:
    cmp word [RootDirSizeForLoop],0
    je No_LoaderBin ;use je instead of jz
    dec word [RootDirSizeForLoop]
    mov ax,00h
    mov es,ax
    mov bx,8000h
    mov ax,[SectorNo]
    mov cl,1
    call Func_ReadOneSector
    mov si,LoaderFileName
    mov di,8000h
    cld ;clear direction flag
    mov dx,10h

Search_For_LoaderBin:
    cmp dx,0
    je Goto_Next_Sector_In_Root_Dir ;use je instead of jz
    dec dx
    mov cx,11

Cmp_FileName:
    cmp cx,0
    je FileName_Found
    dec cx
    lodsb
    cmp al,byte [es:di]
    je Go_On
    jmp Different

Go_On:
    inc di
    jmp Cmp_FileName

Different:
    and di,0ffe0h
    add di,20h
    mov si,LoaderFileName
    jmp Search_For_LoaderBin

Goto_Next_Sector_In_Root_Dir:
    add word [SectorNo],1
    jmp Search_In_Root_Dir_Begin

No_LoaderBin:
    mov ax,1301h
    mov bx,008ch
    mov dx,0100h
    mov cx,21
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,NoLoaderMessage
    int 10h
    jmp $

FileName_Found:
    mov ax,RootDirSectors
    and di,0ffe0h
    add di,01ah
    mov cx,word [es:di]
    push cx
    add cx,ax
    add cx,SectorBalance
    mov ax,BaseOfLoader
    mov es,ax
    mov bx,OffsetOfLoader
    mov ax,cx

Go_On_Loading_File:
    push ax
    push bx
    mov ah,0eh
    mov al,'.'
    mov bl,0fh
    int 10h
    pop bx
    pop ax

    mov cl,1
    call Func_ReadOneSector
    pop ax
    call Func_GetFATEntry
    cmp ax,0fffh
    je File_Loaded
    push ax
    mov dx,RootDirSectors
    add ax,dx
    add ax,SectorBalance
    add bx,[BPB_BytesPerSec]
    jmp Go_On_Loading_File

File_Loaded:
    jmp BaseOfLoader:OffsetOfLoader

Func_ReadOneSector:
    push bp
    mov bp,sp
    sub esp,2
    mov byte [bp-2],cl
    push bx
    mov bl,[BPB_SecPerTrk]
    div bl
    inc ah
    mov cl,ah
    mov dh,al
    shr al,1
    mov ch,al
    and dh,1
    pop bx
    mov dl,[BS_DrvNum]

Go_On_Reading:
    mov ah,2
    mov al,byte [bp-2]
    int 13h
    jc Go_On_Reading
    add esp,2
    pop bp
    ret

Func_GetFATEntry:
    push es
    push bx
    push ax
    mov ax,00
    mov es,ax
    pop ax
    mov byte [Odd],0
    mov bx,3
    mul bx
    mov bx,2
    div bx
    cmp dx,0
    je Even
    mov byte [Odd],1

Even:
    xor dx,dx
    mov bx,[BPB_BytesPerSec]
    div bx
    push dx
    mov bx,8000h
    add ax,SectorNumOfFAT1Start
    mov cl,2
    call Func_ReadOneSector

    pop dx
    add bx,dx
    mov ax,[es:bx]
    cmp byte [Odd],1
    jnz Even_2
    shr ax,4

Even_2:
    and ax,0fffh
    pop bx
    pop es
    ret

RootDirSizeForLoop dw RootDirSectors
SectorNo dw 0
Odd db 0

StartBootMessage: db "Start Boot"
NoLoaderMessage: db "Error:No Loader Found"
LoaderFileName: db "LOADER  BIN",0

    resb 510 - ($ - $$)
    dw	0xaa55
