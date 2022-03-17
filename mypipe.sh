#!/bin/bash

function xineplaylist () {
	file="$1"
	echo "# toxine playlist"
	grep 'location\|title' "$file" |
	while read -r line;do
		strf="${line#*<location>}"
#		echo $strf $line
		if [ "${#strf}" -ne "${#line}" ]; then
		   location="${strf%%</location>*}"
		   continue
		fi
		strf="${line#*<title>}"
		if [ "$strf" != "$line" ]; then
		   strl="${strf%%</title>*}"
		   echo "entry {"
		   echo "	identifier = $strl;"
		   echo "	mrl = $location;"
		   echo "};"
		   continue
		fi
	done
	echo "# END"
}
	declare -g GVAR="uwe" GVAR2="dani"
	xineplaylist "/home/uwe/.config/vlc/radio_channels_list.xspf" > "/home/uwe/.xine/radio.tox"
exit
export MAIN_DIALOG='
<window title="refresh with dummy">
 <vbox>
 <entry auto-refresh="true" visible="false">
	<input file>/tmp/socket</input> 
	<action type="refresh">entry</action> 
 </entry>
 <entry>
	<variable>entry</variable>
	<input>echo $(date "+%Y_%m_%d_%H_%M_%S")</input> 
 </entry>
 <button ok></button>
 <button cancel></button>
 </vbox>
</window>
'

 gtkdialog --program=MAIN_DIALOG 

exit

 source /home/uwe/my_scripts/my_functions.sh

	db=/home/uwe/my_databases/parm.sqlite
	tb=rules
    ixline=""
	sql_execute "$db" "pragma index_list($tb)" |  tr '[:upper:]' '[:lower:]' |
    while read iline; do
		IFS=",";arr=($iline);ixline="${arr[1]},${arr[2]},${arr[3]},"
		sql_execute "$db" "pragma index_info(${arr[1]})" |  tr '[:upper:]' '[:lower:]' | 
		while read line; do
			echo ">1 $ixline" 
			echo ">2 $line" 
			IFS=",";arr=(${ixline}${line});unset IFS;del=","
			stmt="set"  
			if [ "${arr[0]:0:16}" != "sqlite_autoindex" ];then  stmt="set ixname=\"${arr[0]}\"";else stmt="set";del=" ";fi
			if [ "${arr[2]}" = "u" ];then  stmt="${stmt}${del}isunique=\"unique\"";del=",";fi
			echo "update $crtb $stmt where field=\"${arr[5]}\";" # >> $readcrtb
		done 
	done  
  
exit 

set -x
rm -f /tmp/foo
rm -f /tmp/bar
rm -f /tmp/dbin
touch /tmp/foo
touch /tmp/bar
mkfifo /tmp/dbin

exec 5>/tmp/dbin       # open /tmp/foo for writing, on fd 5
exec 6</tmp/bar       # open /tmp/bar for reading, on fd 6

while true; do
    read  -p "cmd " line
    case "$line" in
		exit) 	rm -f '/tmp/db_in' && rm -f '/tmp/db_out' && break;;
        *) 		echo "$line" >&5 
#				cat '/tmp/db_out'
    esac
done


cat <&6 |             # call cat, with its standard input connected to
                      # what is currently fd 6, i.e., /tmp/bar
while read a; do      # 
  echo $a >&5         # write to fd 5, i.e., /tmp/foo
done                  #

exit
#set -x
(
rm -f fifo
mkfifo fifo
exec 3<fifo   # open fifo for reading
trap "exit" 1 2 3 15
exec cat fifo | nl
) &
bpid=$!

(
exec 3>fifo  # open fifo for writing
trap "exit" 1 2 3 15
while true;
do
    echo "blah" > fifo
done
)
kill -TERM $bpid

exit
 
set -x
rm -f '/tmp/db_in' && rm -f '/tmp/db_out'  
mkfifo '/tmp/db_in'
mkfifo '/tmp/db_out'
exec 5< /tmp/db_in

# Create the sqlite process in the background (assume database setup already)
sqlite3 '/home/uwe/my_database/test.sqlite' </tmp/db_in >/tmp/db_out &
#sqlite3 '/home/uwe/my_database/test.sqlite' </tmp/db_in &

while true; do
    read -u 5 -p "cmd " line
    case "$line" in
		exit) 	rm -f '/tmp/db_in' && rm -f '/tmp/db_out' && break;;
        *) 		echo "$line" >/tmp/db_in 
#				cat '/tmp/db_out'
    esac
done

exit

# Set connection parameters
echo '.timeout 1000' >/tmp/db_in

# Perform a query with count in first result
echo 'SELECT COUNT(*) FROM foo WHERE bar=1;SELECT * FROM bar WHERE bar=1;' >/tmp/db_in
read results </tmp/db_out
while [ $results -gt 0 ]; do
    IFS='|'; read key value </tmp/db_out
    echo "$key=$value"

    results=$(($results - 1))
done


PIPE=/tmp/catpipe
trap "rm -f $PIPE" exit 1
[[ ! -p $PIPE ]] && mkfifo $PIPE

while true; do
     while read line; do
          case "$line" in
               @exit) rm -f $PIPE && exit 0;;
               @*) eval "${line#@}" ;;
               * ) echo "$line" ;;
          esac
     done <$PIPE
done

exit 
