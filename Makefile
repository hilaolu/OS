all:img

bootloader:boot.asm
	nasm boot.asm -o boot.bin

img:bootloader loader
	dd if=/dev/zero of=./bootloader.img bs=1440k count=1 conv=notrunc
	dd if=boot.bin of=./bootloader.img bs=512 count=1 conv=notrunc
	bash script/build/copy.sh

run:img
	qemu-system-x86_64 -fda bootloader.img

loader:loader.asm
	nasm loader.asm -o loader.bin

clean:
	rm *.bin *.img
