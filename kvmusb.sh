for dev in $(ls /dev/bus/usb); do chown -R root:$(whoami) $dev;done
