all:img

bootloader:boot.asm
	nasm boot.asm -o boot.bin

img:bootloader
	dd if=boot.bin of=./bootloader.img bs=512 count=1 conv=notrunc

run:img
	qemu-system-x86_64 -fda bootloader.img
