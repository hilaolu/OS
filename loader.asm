;loader 1)get hardware info)2switch processor mode)3pass data to kernel
;real mode -> protect mode -> ia-32e mode

org	10000h
    jmp start

%include "fat12.inc"

BaseOfKernelFile equ 0x00
OffsetOfKernelFile equ 0x100000

BaseTmpOfKernelAddr equ 0x00
OffsetTmpOfKernelFile equ 0x7E00

MemoryStructBufferAddr equ 0x7E00

[section gdt]

LABEL_GDT: dd 0,0
LABEL_DESC_CODE32: dd 0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32: dd 0x0000FFFF,0x00CF9200

GdtLen equ $ - LABEL_GDT
GdtPtr dw GdtLen - 1
    dd LABEL_GDT

SelectorCode32 equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32 equ LABEL_DESC_DATA32 - LABEL_GDT

[section gdt64]

LABEL_GDT64: dq 0x0000000000000000
LABEL_DESC_CODE64: dq 0x0020980000000000
LABEL_DESC_DATA64: dq 0x0000920000000000

GdtLen64 equ $ - LABEL_GDT64
GdtPtr64 dw GdtLen64 - 1
    dd LABEL_GDT64

SelectorCode64 equ LABEL_DESC_CODE64 - LABEL_GDT64
SelectorData64 equ LABEL_DESC_DATA64 - LABEL_GDT64

[section .s16]
[bits 16]

start:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ax,0x00
    mov ss,ax
    mov sp,0x7c00

    ;display loader start imformation

    mov ax,1301h
    mov bx,000fh
    mov dx,0200h
    mov cx,12
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp, StartLoaderMessage
    int 10h

    ;open address a20

    push ax
    in al,92h
    or al,00000010b
    out 92h,al
    pop ax

    cli

    db 0x66
    lgdt [GdtPtr]

    mov eax,cr0
    or eax,1
    mov cr0,eax

    mov ax,SelectorData32
    mov fs,ax
    mov eax,cr0
    and al,11111110b
    mov cr0,eax

    sti

    ;reset floppy

    xor ah,ah
    xor dl,dl
    int 13h

    ;search kernel.bin

    mov word [SectorNo],SectorNumOfRootDirStart

search_in_root_dir_begin:
    cmp word [RootDirSizeForLoop],0
    je no_loader_bin
    dec word [RootDirSizeForLoop]
    mov ax,00h
    mov es,ax
    mov bx,8000h
    mov ax,[SectorNo]
    mov cl,1
    call read_one_sector
    mov si,KernelFileName
    mov di,8000h
    cld
    mov dx,10h

search_for_loader_bin:
    cmp dx,0
    je goto_next_sector_in_root_dir
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
    and di,0FFE0h
    add di,20h
    mov si,KernelFileName
    jmp search_for_loader_bin

goto_next_sector_in_root_dir:
    add word [SectorNo],1
    jmp search_in_root_dir_begin

;no kernel found

no_loader_bin:
    mov ax,1301h
    mov bx,008ch
    mov dx,0300h
    mov cx,21
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,NoLoaderMessage
    int 10h
    jmp $

;found loader.bin name in root director struct

filename_found:
    mov ax,RootDirSectors
    and di,0FFE0h
    add di,01Ah
    mov cx,word [es:di]
    push cx
    add cx,ax
    add cx,SectorBalance
    mov eax,BaseTmpOfKernelAddr ;baseofkernelfile
    mov es,eax
    mov bx,OffsetTmpOfKernelFile
    mov ax,cx

go_on_loading_file:
    push ax
    push bx
    mov ah,0eh
    mov al,'.'
    mov bl,0Fh
    int 10h
    pop bx
    pop ax

    mov cl,1
    call read_one_sector
    pop ax

    push cx
    push eax
    push fs
    push edi
    push ds
    push esi

    mov cx,200h
    mov ax,BaseOfKernelFile
    mov fs,ax
    mov edi,dword [OffsetOfKernelFileCount]

    mov ax,BaseTmpOfKernelAddr
    mov ds,ax
    mov esi,OffsetTmpOfKernelFile

mov_kernel:
    mov al,byte [ds:esi]
    mov byte [fs:edi],al

    inc esi
    inc edi

    loop mov_kernel

    mov eax,0x1000
    mov ds,eax

    mov dword [OffsetOfKernelFileCount],edi

    pop esi
    pop ds
    pop edi
    pop fs
    pop eax
    pop cx

    call get_fat_entry
    cmp ax,0fffh
    je file_loaded
    push ax
    mov dx,RootDirSectors
    add ax,dx
    add ax,SectorBalance

    jmp go_on_loading_file

file_loaded:
    mov ax,0b800h
    mov gs,ax
    mov ah,0fh
    mov al,'G'
    mov [gs:((80*0+39)*2)],ax

kill_motor:
    push dx
    mov dx,03f2h
    mov al,0
    out dx,al
    pop dx

;get memory address size type

    mov ax,1301h
    mov bx,000fh
    mov dx,0400h
    mov cx,24
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,StartGetMemStructMessage
    int 10h

    mov ebx,0
    mov ax,0x00
    mov es,ax
    mov di,MemoryStructBufferAddr

get_mem_struct:
    mov eax,0x0e820
    mov ecx,20
    mov edx,0x534d4150
    int 15h
    jc get_mem_fail
    add di,20

    cmp ebx,0
    jne get_mem_struct
    jmp get_mem_ok

get_mem_fail:
    mov ax,1301h
    mov bx,008ch
    mov dx,0500h
    mov cx,23
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,GetMemStructErrMessage
    int 10h
    jmp $

get_mem_ok:
    mov ax,1301h
    mov bx,000fh
    mov dx,0600h
    mov cx,29
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,GetMemStructOKMessage
    int 10h

    ;get svga information

    mov ax,1301h
    mov bx,000fh
    mov dx,0800h
    mov cx,23
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,StartGetSVGAVBEInfoMessage
    int 10h

    mov ax,0x00
    mov es,ax
    mov di,0x8000
    mov ax,4f00h

    int 10h

    cmp ax,004fh

    je .ko

;fail

    mov ax,1301h
    mov bx,008ch
    mov dx,0900h
    mov cx,32
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,GetSVGAVBEInfoErrMessage
    int 10h

    jmp $

.ko:
    mov ax,1301h
    mov bx,000fh
    mov dx,0a00h
    mov cx,29
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,GetSVGAVBEInfoOKMessage
    int 10h

;get svga mode info

    mov ax,1301h
    mov bx,000fh
    mov dx,0c00h
    mov cx,24
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,StartGetSVGAModeInfoMessage
    int 10h

    mov ax,0x00
    mov es,ax
    mov si,0x800e

    mov esi,dword [es:si]
    mov edi,0x8200

svga_mode_info_get:
    mov cx,word [es:esi]

;display svga mode information

    push ax
    mov ax,00h
    mov al,ch
    call disp_al

    mov ax,00h
    mov al,cl
    call disp_al

    pop ax

    cmp cx,0ffffh
    je svga_mode_info_finish

    mov ax,4f01h
    int 10h

    cmp ax,004fh
    jnz svga_mode_info_fail

    add esi,2
    add edi,0x100

    jmp svga_mode_info_get

svga_mode_info_fail:
    mov ax,1301h
    mov bx,008ch
    mov dx,0d00h
    mov cx,24
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,GetSVGAModeInfoErrMessage
    int 10h

set_svga_mode_vesa_vbe_fail:
    jmp $

svga_mode_info_finish:
    mov ax,1301h
    mov bx,000fh
    mov dx,0e00h
    mov cx,30
    push ax
    mov ax,ds
    mov es,ax
    pop ax
    mov bp,GetSVGAModeInfoOKMessage
    int 10h

;set the svga mode (vesa vbe)

    mov ax,4f02h
    mov bx,4180h
    int 10h

    cmp ax,004fh
    jnz set_svga_mode_vesa_vbe_fail

    ;init idt gdt goto protect mode

    cli

    db 0x66
    lgdt [GdtPtr]

    mov eax,cr0
    or eax,1
    mov cr0,eax

    jmp dword SelectorCode32:go_to_tmp_protect

[section .s32]
[bits 32]

go_to_tmp_protect:

;go to tmp long mode

    mov ax,0x10
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov ss,ax
    mov esp,7e00h

    call support_long_mode
    test eax,eax

    jz no_support

    ;init temporary page table 0x90000

    mov dword [0x90000],0x91007
    mov dword [0x90004],0x00000
    mov dword [0x90800],0x91007
    mov dword [0x90804],0x00000

    mov dword [0x91000],0x92007
    mov dword [0x91004],0x00000

    mov dword [0x92000],0x000083
    mov dword [0x92004],0x000000

    mov dword [0x92008],0x200083
    mov dword [0x9200c],0x000000

    mov dword [0x92010],0x400083
    mov dword [0x92014],0x000000

    mov dword [0x92018],0x600083
    mov dword [0x9201c],0x000000

    mov dword [0x92020],0x800083
    mov dword [0x92024],0x000000

    mov dword [0x92028],0xa00083
    mov dword [0x9202c],0x000000

    ;load gdtr

    db 0x66
    lgdt [GdtPtr64]
    mov ax,0x10
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax

    mov esp,7e00h

    ;open pae

    mov eax,cr4
    bts eax,5
    mov cr4,eax

    ;load cr3

    mov eax,0x90000
    mov cr3,eax

    ;enable long-mode

    mov ecx,0c0000080h
    rdmsr

    bts eax,8
    wrmsr

    ;open pe and paging

    mov eax,cr0
    bts eax,0
    bts eax,31
    mov cr0,eax

    jmp SelectorCode64:OffsetOfKernelFile

    ;test support long mode or not

support_long_mode:
    mov eax,0x80000000
    cpuid
    cmp eax,0x80000001
    setnb al
    jb support_long_mode_done
    mov eax,0x80000001
    cpuid
    bt edx,29
    setc al

support_long_mode_done:
    movzx eax,al
    ret

    ;no support

no_support:
    jmp $

    ;read one sector from floppy

[section .s16lib]
[bits 16]

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

    ;get fat entry

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

    ;display num in al

disp_al:
    push ecx
    push edx
    push edi

    mov edi,[DisplayPosition]
    mov ah,0Fh
    mov dl,al
    shr al,4
    mov ecx,2

.begin:
    and al,0fh
    cmp al,9
    ja .1
    add al,'0'
    jmp .2

.1:
    sub al,0Ah
    add al,'A'

.2:
    mov [gs:edi],ax
    add edi,2

    mov al,dl
    loop .begin

    mov [DisplayPosition],edi

    pop edi
    pop edx
    pop ecx

    ret

    ;tmnp idt

idt:
    times 0x50 db 0

idt_end:

idt_pointer:
    dw idt_end - idt -1
    dd idt

;tmp variable

RootDirSizeForLoop dw RootDirSectors
SectorNo dw 0
Odd db 0
OffsetOfKernelFileCount dd OffsetOfKernelFile

DisplayPosition dd 0

;display messages

StartLoaderMessage: db "Start Loader"
NoLoaderMessage: db "Error:No Kernel Found"
KernelFileName: db "KERNEL  BIN",0
StartGetMemStructMessage: db "Start Get Memory Struct."
GetMemStructErrMessage: db "Get Memory Struct Error"
GetMemStructOKMessage: db "Get Memory Struct Success"

StartGetSVGAVBEInfoMessage: db "Start Get SVGA VBE Info"
GetSVGAVBEInfoErrMessage: db "Get SVGA VBE Info Error"
GetSVGAVBEInfoOKMessage: db "Get SVGA VBE Info Success"

StartGetSVGAModeInfoMessage: db "Start Get SVGA Mode Info"
GetSVGAModeInfoErrMessage: db "Get SVGA Mode Info Error"
GetSVGAModeInfoOKMessage: db "Get SVGA Mode Info Success"
