l=$(sed 's:^[^/]*::;s/ .*//' <<< $(udisksctl loop-setup -f bootloader.img))
sleep 0.1
loop=${l::-1}
echo $loop
mount=`udisksctl mount -b $loop`
sleep 0.1
mountpoint=${mount##* }
echo $mountpoint
cp loader.bin $mountpoint/.
sleep 0.5
udisksctl unmount -b $loop
udisksctl loop-delete -b $loop
