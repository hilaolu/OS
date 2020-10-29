.section .text

.globl start

start:
    mov $0x10,%ax
    mov %ax,%ds
    mov %ax,%es
    mov %ax,%fs
    mov %ax,%ss
    mov $0x7e00,%esp

    lgdt gdt_pointer(%rip)

    lidt idt_pointer(%rip)

    mov $0x10,%ax
    mov %ax,%ds
    mov %ax,%es
    mov %ax,%fs
    mov %ax,%gs
    mov %ax,%ss

    movq $0x7e00,%rsp

    movq $0x101000,%rax
    movq %rax,%cr3
    movq switch_seg(%rip), %rax
    pushq $0x08
    pushq %rax
    lretq

switch_seg:
    .quad entry64

entry64:
    movq $0x10,%rax
    movq %rax,%ds
    movq %rax,%es
    movq %rax,%gs
    movq %rax,%ss
    movq $0xffff800000007e00,%rsp

    movq go_to_kernel(%rip),%rax
    pushq $0x08
    pushq %rax
    lretq

go_to_kernel:
    .quad start_kernel

.align 8

.org 0x1000

pml4e:
    .quad 0x102007
    .fill 255,8,0
    .quad 0x102007
    .fill 255,8,0

.org 0x2000

pdpte:
    .quad 0x103003
    .fill 511,8,0

.org 0x3000

pde:
    .quad 0x000083
    .quad 0x200083
    .quad 0x400083
    .quad 0x600083
    .quad 0x800083
    .quad 0xe0000083
    .quad 0xe0200083
    .quad 0xe0400083
    .quad 0xe0600083
    .quad 0xe0800083
    .quad 0xe0a00083
    .quad 0xe0c00083
    .quad 0xe0e00083
    .fill 499,8,0

.section .data

.globl gdt_table

gdt_table:
    .quad 0x0000000000000000
    .quad 0x0020980000000000
    .quad 0x0000920000000000
    .quad 0x0020f80000000000
    .quad 0x0000f20000000000
    .quad 0x00cf9a000000ffff
    .quad 0x00cf92000000ffff
    .fill 10,8,0

gdt_end:

gdt_pointer:

gdt_limit:
    .word gdt_end - gdt_table - 1

gdt_base:
    .quad gdt_table

.globl idt_table

idt_table:
    .fill 512,8,0

idt_end:

idt_pointer:

idt_limit:
    .word idt_end - idt_table - 1

idt_base:
    .quad idt_table

.globl tss64_table

tss64_table:
    .fill 13,8,0

tss64_end:

tss64_pointer:

tss64_limit:
    .word tss64_end - tss64_table - 1

tss64_base: .quad tss64_table
