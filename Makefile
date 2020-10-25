all:img

img:compile
	dd if=/dev/zero of=./bootloader.img bs=1440k count=1 conv=notrunc
	dd if=boot.bin of=./bootloader.img bs=512 count=1 conv=notrunc
	bash script/build/copy.sh

run:img
	qemu-system-x86_64 -fda bootloader.img

compile:loader bootloader

loader:loader.asm
	nasm loader.asm -o loader.bin

bootloader:boot.asm
	nasm boot.asm -o boot.bin

clean:
	rm *.bin *.img
