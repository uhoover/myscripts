#/bin/bash
  source /home/uwe/my_scripts/my_functions.sh
#
	if [ "$#" -lt "1" ]; then 
		file="$SYSLOG" 
	else 
		file=$*
	fi
	if [ ! -f  "$file" ]; then echo "error: kein file $file";exit;fi
#	if [ "$(ps | grep tail | grep "$file")" != "" ];then  exit;fi # laeuft schon
	if [ "$(ps -F -C tail | grep "$file")" != "" ];then  exit;fi # laeuft schon
#	urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $lfile" -e tail -f -n 10 $lfile &
	urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $file"  -e tail -f -n+1  $file &
exit
	

[ "$1" == "start" ] && [ -f "$2" ] && lfile="$2" && set -- start
if [ "$lfile" == "" ]; then lfile="/root/log/gtkdialog.txt";fi
echo $@ >> $lfile
if [ "$*" != "start" ];then  exit;fi
#if [ "$(ps | grep tail | grep gtkdialog)" != "" ];then  exit;fi # laeuft schon
if [ "$(ps | grep tail | grep "$lfile")" != "" ];then  exit;fi # laeuft schon
urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $lfile" -e tail -f -n 10 $lfile &
#rxvt  --background "#F4FAB4" --foreground black --title $logfile -e tail -f -n 10 $logfile &
