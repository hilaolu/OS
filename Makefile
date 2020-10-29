SOURCE_DIR=.
SOURCE_FILE = $(wildcard $(SOURCE_DIR)/*.asm)
OBJS = $(patsubst %.asm, %.bin, $(SOURCE_FILE))
KERNEL = kernel.bin
all:bootloader.img

bootloader.img:$(OBJS) $(KERNEL)
	dd if=/dev/zero of=./bootloader.img bs=1440k count=1 conv=notrunc
	dd if=boot.bin of=./bootloader.img bs=512 count=1 conv=notrunc
	bash script/build/copy.sh

$(KERNEL):
	bash script/build/build_kernel.sh

run:bootloader.img
	qemu-system-x86_64 -fda bootloader.img

$(OBJS):%.bin:%.asm
	nasm $< -o $@

clean:
	rm *.bin *.img -f

clean_all:
	make clean
	cd kernel
	make clean

azure:$(OBJS) $(KERNEL)
