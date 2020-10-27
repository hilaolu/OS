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

    jmp short start
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

start:
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

search_in_root_dir_begin:
    cmp word [RootDirSizeForLoop],0
    je no_loader_bin ;use je instead of jz
    dec word [RootDirSizeForLoop]
    mov ax,00h
    mov es,ax
    mov bx,8000h
    mov ax,[SectorNo]
    mov cl,1
    call read_one_sector
    mov si,LoaderFileName
    mov di,8000h
    cld ;clear direction flag
    mov dx,10h

search_for_loader_bin:
    cmp dx,0
    je goto_next_sector_in_root_dir ;use je instead of jz
    dec dx
    mov cx,11

cmp_filename:
    cmp cx,0
    je filename_found
    dec cx
    lodsb
    cmp al,byte [es:di]
    je go_on
    jmp different

go_on:
    inc di
    jmp cmp_filename

different:
    and di,0ffe0h
    add di,20h
    mov si,LoaderFileName
    jmp search_for_loader_bin

goto_next_sector_in_root_dir:
    add word [SectorNo],1
    jmp search_in_root_dir_begin

no_loader_bin:
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

filename_found:
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

go_on_loading_file:
    push ax
    push bx
    mov ah,0eh
    mov al,'.'
    mov bl,0fh
    int 10h
    pop bx
    pop ax

    mov cl,1
    call read_one_sector
    pop ax
    call get_fat_entry
    cmp ax,0fffh
    je file_loaded
    push ax
    mov dx,RootDirSectors
    add ax,dx
    add ax,SectorBalance
    add bx,[BPB_BytesPerSec]
    jmp go_on_loading_file

file_loaded:
    jmp BaseOfLoader:OffsetOfLoader

read_one_sector:
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

go_on_reading:
    mov ah,2
    mov al,byte [bp-2]
    int 13h
    jc go_on_reading
    add esp,2
    pop bp
    ret

get_fat_entry:
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
    je even
    mov byte [Odd],1

even:
    xor dx,dx
    mov bx,[BPB_BytesPerSec]
    div bx
    push dx
    mov bx,8000h
    add ax,SectorNumOfFAT1Start
    mov cl,2
    call read_one_sector

    pop dx
    add bx,dx
    mov ax,[es:bx]
    cmp byte [Odd],1
    jnz even_2
    shr ax,4

even_2:
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
