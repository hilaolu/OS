all:system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R ".comment" -O binary $^ kernel.bin

system:head.o main.o
	ld -b elf64-x86-64 -o $@ $^ -T kernel.lds

main.o:main.c
	gcc -mcmodel=large -fno-builtin -m64 -c $^

head.o:head.S
	gcc -E  head.S > head.s
	as --64 -o head.o head.s

clean:
	rm -rf *.o *.s~ *.s *.S~ *.c~ *.h~ system  Makefile~ kernel.lds~ kernel.bin -f
