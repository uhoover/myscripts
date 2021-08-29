#!/bin/sh
dev="sda3"
if [ "`grep $dev /etc/mtab`" == "" ]; then
   echo "$dev not mounted"
   mounted="$dev"
   mount -t ext4 /dev/$dev /mnt/$dev ### rw,relatime,barrier=1,data=ordered
else 
   echo "$dev     mounted"
   mounted=""
fi

#openroot.sh "/mnt/$dev"  

openroot.sh "/mnt/$dev"  ~/oroot.sh  

if [ "$mounted" == "" ]; then
	exit 0
else
	umount -f "/mnt/$dev" 
fi
exit 1