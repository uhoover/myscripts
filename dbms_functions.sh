#!/bin/bash
	declare true=0 false=1 debug=1
function ftest () {
	path="$HOME/.dbms";false=1;true=0 
	log logon tlog
	log debug test no
	log debug_on
	log debug test yes
	log logoff	 
}
function log () { 
	[  $# 	-eq 0  ]    	&&	return;	
	[ ""	= "$logfile"  ] && 	logfile="${path}/log.txt" && touch $logfile
	[ "$1"  = "logon"  ]    && 	log $(date +"%y-%m-%d-%T:%N") "---- start" $0  	&& log ${@:2} 	&& return
	[ "$1" 	= "logoff" ]    && 	log $(date +"%y-%m-%d-%T:%N") "---- stop"  $0  	  				&& return
	[ "$1" 	= "file" ]    	&& 	logfile="$2" 									&& log ${@:3}	&& return
	[ "$1" 	= "new" ]    	&& 	rm $logfile 									&& log ${@:2}	&& return
	[ "$1" 	= "tlog" ]    	&& 	tlog 											&& log ${@:2}	&& return
	[ "$1" 	= "debug"  ]    && [ "$debug" != "$true" ]   					     				&& return
	[ "$1" 	= "debug_on" ] 	&& [ "$debug"  = "$true" ] 						    && log ${@:2}	&& return
	[ "$1" 	= "debug_off" ] && [ "$debug"  = "$false" ] 					    && log ${@:2}	&& return
	[ "$1" 	= "debug"  ] 	&& shift;
	[ "$1"  = "-" 	   ]    && setmsg  ${@:2}													&& return
	echo $(date +"%y-%m-%d-%T:%N") ${FUNCNAME[1]:0:20} "$@" >> "$logfile";
}
function tlog () {
	local file=$@; if [ "$file" = "" ];then file=$logfile ;fi
	if [ "$(ps -F -C tail | grep "$file")" != "" ];then  return;fi # laeuft schon
	urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $file"  -e tail -f -n+1  $file &
}
function sql_execute () {
	set -o noglob 
	if [ "$sqlerror" = "" ];then sqlerror="/tmp/sqlerror.txt";touch $sqlerror;fi
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db"  2> "$sqlerror"  | tr -d '\r'   
	error=$(<"$sqlerror")
	if [ "$error"  = "" ];then return 0;fi
	log $FUNCNAME $stmt
	setmsg -e --width=400 "sql_execute\n$error\ndb $db\nstmt $stmt" 
	return 1
}
function pos () {
	local str pos x
	if [ "${#1}" -gt "${#2}" ] ; then
	   str="$1";pos="$2"
	else  
	   str="$2";pos="$1"
	fi 
    x="${str%%$pos*}"
    [[ "$x" = "$str" ]] && echo -1 || echo "${#x}"
}
function setmsg () {
	oldstate="$(set +o | grep xtrace)";set +x
	local parm="--notification";local text=""
	log debug $*
	while [ "$#" -gt "0" ];do
		case "$1" in
		"--width"*)				parm="$parm ""$1"		;;
		"-w"|"--warning") 		parm="--warning"		;;
		"-e"|"--error")   		parm="--error"			;;
		"-i"|"--info")    		parm="--info" 		 	;;
		"-n"|"--notification")  parm="--notification"	;;
		"-q"|"--question")	    parm="--question"		;;
		"-d"|"--debug")	        if [  $debug -eq $false ];then  return  ;fi		;;
		"-*" )	   				parm="$parm ""$1"		;;
		*)						text="$text ""$1"		;;
		esac
		shift
	done
	text=$(echo $text | tr '"<>' '_' | tr "'" '_')
	if [ "$text" != "" ];then text="--text='$text'" ;fi
	eval "$oldstate"
	eval 'zenity' $parm $text 
	return $?
}
function quote (){
    local line="" ql='"' qr='"' i=0 gap="" file="" x=0 delimiter="," remove=$false
    while [ $# -gt 0 ] ;do
		if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
			nparm=$(func_mygetopt $1)
			shift; set -- $@ $nparm
		else
			case "$1" in
				"--quote-left"|"--ql"|"-l")    shift;ql="$1";;
				"--quote-right"|"--qr"|"-r")   shift;qr="$1";;
				"--quote-char"|"--qc"|"-c")    shift;ql="$1";qr="$1";;
				"--delimiter"|"--dl"|"-d")     shift;delimiter="$1";;
				"--remove"|"-r")    		   remove="$true";;
				"--text"|"-t")                 shift;line="$line$ql$1$qr";;
				"--help"|"-h")                 func_help $FUNCNAME;return;;
				"--debug"|"-x")                set -x;x=1;;
			#	[-]*)                          func_help $FUNCNAME "$1";return;;
				*)  if [ "$file" == "" ]; then file=$1; fi
					line="$line$gap$1"
					gap=" "
			esac
			shift
		fi
    done
    lql=${#ql};lqr=${#qr}
    if [ "$line" != "" ]  ; then 
		echo "$line" 
    elif [ -f "$file" ] ;then
        cat "$file"
    else
        cat < /dev/stdin
    fi |
    while read -r line;do
		IFS="$delimiter";arr=($line);unset IFS;del="";erg="" 
		for arg in "${arr[@]}"; do
			while true;do		#	remove quotes
				lng=${#arg}
				if [ "$lng" -gt "$lql" ] && [ "${arg:0:$lql}" = "$ql" ]; then 
					arg="${arg:$lql}" 
					lng="${#arg}"
	                if [ "${arg:$lng-$lqr:$lqr}" = "$qr" ];  then arg="${arg:0:$lng-$lqr}";fi
	            else    	
					break;
			    fi
			done	  
			if [ "$remove" = "$true" ];then 
				erg=$erg$del$arg 
			else
				erg=$erg$del$ql$arg$qr
			fi
			del=$delimiter
		done
        echo $erg
    done      
}
function tb_meta_info () {
	local db="$1" tb="$2" row="$3" parms=${@:4}
	is_table "$db" "$tb";if [ "$?" -gt 0 ];then return 1 ;fi
	if [ "${parms:${#parms}-1:1}" = "," ];then parms="${parms}null"  ;fi  # last nullstring not count 
	local parmlist=$(echo $parms | quote -l '"' -r '"' -d "#")
	IFS="#";local parmarray=($parmlist);unset IFS 
	local del="" del2="" del3="" line="" nparmlist="" 
	GTBNAME="" ;GTBTYPE="" ;GTBNOTN="" ;GTBDFLT="" ;GTBPKEY="";GTBMETA="" 
	GTBSELECT="";GTBINSERT="";GTBUPDATE="";GTBUPSTMT="";GTBSORT="";GTBMAXCOLS=-1
	meta_info_file=$(getfilename "$tpath/meta_info" "${tb}" "${db}" ".txt")
	local ip=-1 ia=-1  pk="-"
	sql_execute "$db" ".headers off\nPRAGMA table_info($tb)"   > "$meta_info_file"
	if [ "$?" -gt "0" ];then log "error $?: $db" ".headers off\nPRAGMA table_info($tb)";return 1;fi
	while read -r line;do
		GTBMAXCOLS=$(($GTBMAXCOLS+1))
		IFS=',';arr=($line);unset IFS;ip=$(($ip+1))
		GTBNAME=$GTBNAME$del"${arr[1]}";GTBTYPE=$GTBTYPE$del"${arr[2]}";GTBNOTN=$GTBNOTN$del"${arr[3]}"
		GTBDFLT=$GTBDFLT$del"${arr[4]}";GTBPKEY=$GTBPKEY$del"${arr[5]}"
		GTBMETA=$GTBMETA$del2"${arr[2]},${arr[3]},${arr[4]},${arr[5]}"
		if [ "${arr[2]}" = "INTEGER" ] || [ "${arr[2]}" = "REAL" ] ;then GTBSORT="${GTBSORT}${del2}1";else GTBSORT="${GTBSORT}${del2}0";fi
		if [ "${arr[5]}" = "1" ] ;then
			PRIMKEY="${arr[1]}";export ID=$ip;  
		else
			ia=$(($ia+1));value="${parmarray[$ia]}"
			if [ "$value" = "" ] && [ "${arr[3]}" = "0" ];then value="null";fi
			nparmlist=$nparmlist$del${parmarray[$ip]}
			GTBSELECT=$GTBSELECT$del3$"${arr[1]}" 	
			GTBUPSTMT=$GTBUPSTMT$del3$"${arr[1]} = %s" 
			GTBINSERT=$GTBINSERT$del3$"$value"	
			GTBUPDATE=$GTBUPDATE$del3$"${arr[1]} = $value";del3=","	
		fi
		del=",";del2='|'
	done < "$meta_info_file"
	if [ "$PRIMKEY" = "" ];then 
		PRIMKEY="rowid";ID=0
		GTBNAME="rowid$del$GTBNAME";GTBTYPE="INTEGER$del$GTBTYPE";GTBNOTN="1$del$GTBNOTN";GTBSORT="1$del2$GTBSORT"
		GTBDFLT="' '$del$GTBDFLT";GTBPKEY="1$del$GTBPKEY";GTBMETA="rowid$del2$GTBMETA"
	fi 
	if [ "$parmlist" = "" ];then return;fi
	nparmlist=${nparmlist//'"null"'/null}
	nparmlist=${nparmlist//\'null\'/null}
	GTBINSERT="insert into $tb (${GTBSELECT}) values (${GTBINSERT})"
	GTBUPDATE="update $tb set ${GTBUPDATE}\n where $PRIMKEY = $row";unset IFS
}
function func_setmsg () {
	oldstate="$(set +o | grep xtrace)";set +x
	local parm="--notification";local text=""
	log debug $*
	while [ "$#" -gt "0" ];do
		case "$1" in
		"--width"*)				parm="$parm ""$1"		;;
		"-w"|"--warning") 		parm="--warning"		;;
		"-e"|"--error")   		parm="--error"			;;
		"-i"|"--info")    		parm="--info" 		 	;;
		"-n"|"--notification")  parm="--notification"	;;
		"-q"|"--question")	    parm="--question"		;;
		"-d"|"--debug")	        if [ "$debug_on" = "0" ];then  return  ;fi		;;
		"-*" )	   				parm="$parm ""$1"		;;
		*)						text="$text ""$1"		;;
		esac
		shift
	done
	text=$(echo $text | tr '"<>' '_' | tr "'" '_')
	if [ "$text" != "" ];then text="--text='$text'" ;fi
	eval "$oldstate"
	eval 'zenity' $parm $text 
	return $?
}
function setmsg () { func_setmsg $* ; }
function func_sql_execute () {
	set -o noglob 
	if [ "$sqlerror" = "" ];then sqlerror="/tmp/sqlerror.txt";touch $sqlerror;fi
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db"  2> "$sqlerror"  | tr -d '\r'   
	error=$(<"$sqlerror")
	if [ "$error"  = "" ];then return 0;fi
	log $FUNCNAME $stmt
	setmsg -e --width=400 "sql_execute\n$error\ndb $db\nstmt $stmt" 
	return 1
}
function sql_execute () { func_sql_execute $*; } 
function save_geometry (){
	str=$*;IFS='#';local arr=( $str );unset IFS; local window=${arr[0]} gfile=${arr[1]} glabel=${arr[2]}
	XWININFO=$(xwininfo -stats -name "$window")
	if [ "$?" -ne "0" ];then func_setmsg -i "error XWINFO";return  ;fi
	HEIGHT=$(echo "$XWININFO" | grep 'Height:' | awk '{print $2}')
	WIDTH=$(echo "$XWININFO" | grep 'Width:' | awk '{print $2}')
	X1=$(echo "$XWININFO" | grep 'Absolute upper-left X' | awk '{print $4}')
	Y1=$(echo "$XWININFO" | grep 'Absolute upper-left Y' | awk '{print $4}')
	X2=$(echo "$XWININFO" | grep 'Relative upper-left X' | awk '{print $4}')
	Y2=$(echo "$XWININFO" | grep 'Relative upper-left Y' | awk '{print $4}')
	X=$(($X1-$X2))
	Y=$(($Y1-$Y2))
	setconfig "geometry|$glabel|${WIDTH}x${HEIGHT}+${X}+${Y}"
}
function fullpath () {
	[ -d $* ] && echo dir  $(cd -- $* && pwd) && return 0
	[ -f $* ] && echo file "$(cd -- "$(dirname $*)" && pwd)/$(basename $*)" && return 0
	return 1
}
