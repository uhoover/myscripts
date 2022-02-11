#!/bin/bash
# function: allgemeine funktionen
# author: Uwe Sülzle
# cdate: 2017-02-07
#  
function fhelp () {
#	set -x 
#	vput "testtype|testfield|irgendwasanderes"
 	vget "parm_value" "testtype" "testfield"
}
function vgetp 	() { vget -p "$HOME/vparm.sqlite" "parm" $*; }
function vputp 	() { vput -p "$HOME/vparm.sqlite" "parm" $*; }
function vgetdb () {
	local db="$1" tb="$2"
	is_table "$db" "$tb"; [ $? -eq 0 ] && return
	cat <<EOF | sqlite3 "$db"
		create table $tb (
			parm_id 	integer primary key autoincrement not null,
			parm_status text 	default 0,
			parm_type 	text,
			parm_field 	text,
			parm_value 	text,
			parm_info 	text);
		create unique index ix1_field_type on ${tb}(parm_field,parm_type);
EOF
	return $?
}
function vget () {
	local db="/tmp/vparm.sqlite" tb="parm"
	[ "$1" = "-p" ] && [ db = "$2" ] && [ tb=$3 ] && shift && shift && shift
	vgetdb "$db" "$tb"
	[ $? -gt 0 ] && setmsg -e "sqlerror create tb" && return 1
	if [ "$1" = "stmt" ];then getstmt="$true";shift ;else getstmt="$false" ;fi
	local getfield="$1" type="$2" field=$(echo "$3" | tr ' ' '_') default="$4" where=${@:5}
	ix=$(pos '%' $field);if [ "$ix" -gt "-1" ];then eq1="like"  ;else eq1="=" ;fi
	ix=$(pos '%' $type); if [ "$ix" -gt "-1" ];then eq2="like"  ;else eq2="=" ;fi
	stmt=".header off\nselect $getfield from $tb where parm_field $eq1 \"$field\" and parm_type $eq2 \"$type\" $where" 
	if [ "$getstmt" = "$true" ];then echo "$stmt";return;fi
	value=$(sql_execute $db "$stmt") 
	if [ "$?" -gt "0" ];then return 1 ;fi
	if [ "$value" = "" ] &&  [ "$default" != "" ];then value="$default";setconfig   "$type|$field|$value" ;fi
	echo -e "$value";return 0
}
function vput () {
	local db="/tmp/vparm.sqlite" tb="parm"
	[ "$1" = "-p" ] && [ db = "$2" ] && [ tb=$3 ] && shift && shift && shift
	vgetdb "$db" "$tb"
	[ $? -gt 0 ] && setmsg -e "sqlerror create tb" && return 1
    local parm=$* field="" arr="" value="" type="" id=""
    IFS="|";arr=($parm);type="${arr[0]}";field=$(echo "${arr[1]}" | tr ' ' '_');value=$(remove_quotes ${arr[2]});unset IFS
	value=${value//\"/\"\"}
	if [ "$type" = "wherelist" ]; then
		id=$(sql_execute $db ".header off\nselect parm_id from $tb where parm_field = \"$field\" and parm_value = \"$value\" and parm_type = \"$type\" limit 1")
		if [ "$id" = "" ];then 
			id=$(sql_execute $db ".header off\nselect max(parm_id) +1 from $tb")
		fi 
		type="${type}_${id}"
	else
		id=$(sql_execute $db ".header off\nselect parm_id from $tb where parm_field = \"$field\" and parm_type = \"$type\"")
	fi
	if [ "$id" = "" ]; then 
		sql_execute "$db" "insert into $tb (parm_type,parm_field,parm_value) values (\"$type\",\"$field\",\"$value\")"
	else
		if [ "$type" != "wherelist" ]; then
			sql_execute "$db" "update $tb set parm_value = \"$value\" where parm_id = \"$id\""
		fi
	fi
	if [ "$?" -gt "0" ];then return 1 ;else return 0 ;fi
}
function is_database () { file -b "$*" | grep -q -i "sqlite"; }
function is_table () {	
	if [ "$#" -lt "2" ];then return 1;fi 
	is_database "$1"; if [ "$?" -gt "0" ];then return 1;fi
	local tb=$(sql_execute "$1" ".table $2")
	if [ "$tb" = "" ];then return 1;else return 0;fi
}
function sql_execute () {
	set -o noglob 
	if [ "$sqlerror" = "" ];then sqlerror="/tmp/sqlerror.txt";touch $sqlerror;fi
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db"  2> "$sqlerror"  | tr -d '\r'   
	error=$(<"$sqlerror")
	if [ "$error"  = "" ];then return 0;fi
	log "$FUNCNAME sql_error: $stmt"
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
    [ "$x" = "$str" ] && echo -1 || echo "${#x}"
}
function setmsg () {
	oldstate="$(set +o | grep xtrace)";set +x
	local parm="--notification";local text=""
	log debug $*
	while [ "$#" -gt "0" ];do
		case "$1" in
		"--width"*)				parm="$parm $1"				;;
		"-t"|"--timeout"*)		parm="$parm --timeout $2";shift;;
		"-w"|"--warning") 		parm="--warning"			;;
		"-e"|"--error")   		parm="--error"				;;
		"-i"|"--info")    		parm="--info" 		 		;;
		"-n"|"--notification")  parm="--notification"		;;
		"-q"|"--question")	    parm="--question"			;;
		"-d"|"--debug")	        if [  $debug -eq $false ];then  return  ;fi		;;
		"-*" )	   				parm="$parm ""$1"			;;
		*)						text="$text ""$1"			;;
		esac
		shift
	done
	text=$(echo $text | tr '"<>' '_' | tr "'" '_')
	if [ "$text" != "" ];then text="--text='$text'" ;fi
	eval "$oldstate"
	eval 'zenity' $parm $text 
	return $?
}
function remove_quotes () {
	[ "$*" = "" ] && return || local arg=$*
	[ "${arg:0:1}" != "$_quote" ] && echo $arg | tr -s $_quote && return
	$FUNCNAME ${arg:1:${#arg}-2}
}
function quote () {
	arg=$*
	IFS=$delimiter;local arr=($arg);unset IFS
	local del="" line=""
	for ((ia=0;ia<${#arr[@]};ia++)) ;do
		line="$line$del$_quote$(remove_quotes ${arr[$ia]})$_quote"
		del=$delimiter
	done
	echo "$line"
}
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
function log () { 
	[  $# 	-eq 0  			]   &&	 return;	
	[ ""	= "$logfile"  	]   && 	 log_getfilename $script 	 
	[ "$1"  = "log_disable" ]   && 	 logenable=$false			  && log ${@:2} 	&& return
	[ "$1"  = "log_enable" ]    && 	 logenable=$true			  && log ${@:2} 	&& return
	[ "$1"  = "echo_disable" ]  && 	 echoenable=$false			  && log ${@:2} 	&& return
	[ "$1"  = "echo_enable" ]   && 	 echoenable=$true			  && log ${@:2} 	&& return
	[ "$1"  = "logon"  ]        && 	 set -- "start " $script	  && rm "$logfile"  		
	[ "$1" 	= "logoff" ]       	&& 	 set -- "stop  " $script "\n" && logoff=$true	    				 
	[ "$1"  = "loglineno"  ]    && 	 lineno=$(printf "%03d\n" $2) && log ${@:3} 	&& return
	[ "$1" 	= "file" ]    	    && 	 logfile="$2" 				  && log ${@:3}		&& return
	[ "$1" 	= "tlog" ]    	    && 	 tlog 						  && log ${@:2}		&& return
	[ "$1" 	= "debug"  ]        && [ $debug -eq $false ]   	  	  && return
	[ "$1" 	= "debug_on" ] 	    &&   $debug=$true		 		  && log ${@:2}		&& return
	[ "$1" 	= "debug_off" ]     &&   $debug$false			 	  && log ${@:2}		&& return
	[ "$1" 	= "debug"  ] 	    && 	 shift;
	[  $logenable  -ne $false ] &&	 printf "%s %-20s %s" "$(date +"%y-%m-%d-%T:%N")" "${FUNCNAME[1]}" >> "$logfile";
	[  $logenable  -ne $false ] && 	 echo -e $lineno $* >> "$logfile"
	[  $echoenable -eq $true ]  && 	 echo -e $lineno $* 
	[  $logoff	   -eq $true ]	&& 	 log_histfile 
}
function log_getfilename () {
	local file=${@:-$0}
	[ ! -d "$HOME/log" ] && mkdir [ -d "$HOME/log" ]
	file=${file##*/}
	export logfile="$HOME/log/"${file%.*}".log"	
}
function log_histfile () {
	histfile="${logfile%\.*}_hist.${logfile##*\.}" 
	if [ ! -f "$histfile" ];then 
		cp    "$logfile" "$histfile"
	else  
		cat   "$logfile" "$histfile"  > "$tmpf"
		cp -f "$tmpf"    "$histfile"
	fi
}
function tlog () {
	local file=$@; if [ "$file" = "" ];then file=$logfile ;fi
	if [ "$(ps -F -C tail | grep "$file")" != "" ];then  return;fi # laeuft schon
	urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $file"  -e tail -f -n+1  $file &
}
function trap_help () {
    echo "debug at     LINENO         : trap 'set +x;trap_at     $LINENO  174;         set +x' DEBUG"
    echo "debug when   field eq  value: trap 'set -x;trap_when   $LINENO $field value ;set +x' DEBUG"
    echo "debug change field new value: trap 'set +x;trap_change $LINENO $field;       set +x' DEBUG"
}
function trap_off()    { set +x;trapoff=$true; }
function trap_at() 	   { lineno=$1;trap_while "$1:at lineno >= $2"   "$true"  "lineno" "$2" ; }
function trap_when()   { 		   trap_while "$1:when $2 = $3"      "$true"  "$2"     "$3"; } 
function trap_change() {   		   trap_while "$1:change $2 $compare_value to $(eval 'echo $'$2)" "$false" "$2" "$compare_value"; } 
function trap_while()  {
    local msg="$1" eq="$2" field="$3" value=""
    eval 'value=$'$field 
	[ $eq -eq $true  ] && [ "$value" != "$compare_value" ] && return
	[ $eq -eq $false ] && [ "$value"  = "$compare_value" ] && return
	if [ $trapoff -eq  $true ]; then  return; fi  
	compare_value="$value"
	msg="$msg:${BASH_COMMAND} --> " 
	while true ; do
		[ $trapoff -eq  $true ] && break  
		read -u 4 -p "$msg " cmd
		[ "$cmd" = "" ] && break      
		case $cmd in
				vars ) ( set -o posix ; set );;
				ende ) ;;
				* ) eval $cmd;;
		esac
	done
}
function trim_space () { echo $@; }
function fullpath () {
	[ -d $* ] && echo  $(cd -- $* && pwd) && return 0
	[ -f $* ] && echo "$(cd -- "$(dirname $*)" && pwd)/$(basename $*)" && return 0
	return 1
}
	declare _quote='"' true=0 false=1 debug=1 trapoff=1 logenable=0 echoenable=1 script=$(fullpath $0) logoff=1 func=1

#	fhelp
