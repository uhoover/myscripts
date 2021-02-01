#/bin/bash
[ "$1" == "start" ] && [ -f "$2" ] && lfile="$2" && set -- start
if [ "$lfile" == "" ]; then lfile="/root/log/gtkdialog.txt";fi
echo $@ >> $lfile
if [ "$*" != "start" ];then  exit;fi
#if [ "$(ps | grep tail | grep gtkdialog)" != "" ];then  exit;fi # laeuft schon
if [ "$(ps | grep tail | grep "$lfile")" != "" ];then  exit;fi # laeuft schon
urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $lfile" -e tail -f -n 10 $lfile &
#rxvt  --background "#F4FAB4" --foreground black --title $logfile -e tail -f -n 10 $logfile &
