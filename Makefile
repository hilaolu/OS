all:img

img:
	nasm boot.asm -o bootloader.img

run:
	qemu-system-x86_64 -fda bootloader.img
