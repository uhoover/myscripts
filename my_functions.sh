#!/bin/bash
# function: allgemeine funktionen
# author: Uwe Sülzle
# cdate: 2017-02-07
#  
        declare -t OLD_VALUE=""
        declare -t FIELD="OLD_VALUE"
        declare -t EQUAL="EQUAL"
        declare -i STOP=99999;STOP=0
        declare -i FIRST=0;FIRST=0
        declare -i TRAPOFF=0
 #       declare -a SOURCELINE
        declare -t true=0
        declare -t false=1
        declare -t TMPF="/tmp/tmpfile.txt"
        [ ! -d "$HOME/log" ] && mkdir "$HOME/log"
        declare -t SYSLOG="$HOME/log/syslog.log"
        declare -t log_on=1
        declare -t echo_on=0
        declare -t debug_on=0
		declare -t verbose_on=0
		declare -t sqlerror="/tmp/sqlerror.txt"
		declare -t music="$HOME/my_databases/music.sqlite"
		export MYPATH="$HOME/my_scripts"
function func_tb_meta_info () {
	local db="$1";shift;local tb="$1";shift;local row=$1;shift;local parms=$(echo $* | tr '#|' ',,' )
	if [ "${parms:${#parms}-1:1}" = "," ];then parms="${parms}null"  ;fi          # letzter delimiter wird nicht als element erkannt
	local parmlist=$(echo $parms | quote)
	local del="";local del2="";local del3="";local line=""
	TNAME="" ;TTYPE="" ;TNOTN="" ;TDFLT="" ;TPKEY="";TMETA="";TSELECT="";TUPDATE="";TSORT="";local ip=-1;local pk="-"
	sql_execute "$db" ".headers off\nPRAGMA table_info($tb)"   > $tmpf
	if [ "$?" -gt "0" ];then log "$FUNCNAME error $?: $db" ".headers off\nPRAGMA table_info($tb)";return 1;fi
	while read -r line;do
		IFS=',';arr=($line);unset IFS;ip=$(($ip+1))
		TNAME=$TNAME$del"${arr[1]}";TTYPE=$TTYPE$del"${arr[2]}";TNOTN=$TNOTN$del"${arr[3]}"
		TDFLT=$TDFLT$del"${arr[4]}";TPKEY=$TPKEY$del"${arr[5]}"
		TMETA=$TMETA$del2"${arr[2]},${arr[3]},${arr[4]},${arr[5]}"
		if [ "${arr[2]}" = "INTEGER" ] || [ "${arr[2]}" = "REAL" ] ;then TSORT="${TSORT}${del2}1";else TSORT="${TSORT}${del2}0";fi
		if [ "${arr[5]}" = "1" ] ;then
			PRIMKEY="${arr[1]}";export ID=$ip;  
		else
			TSELECT=$TSELECT$del3$"${arr[1]}" 	
			TUPDATE=$TUPDATE$del3$"${arr[1]} = %s";del3=","	
		fi
		del=",";del2='|'
	done < $tmpf
	if [ "$PRIMKEY" = "" ];then 
		PRIMKEY="rowid";ID=0
		TNAME="rowid$del$TNAME";TTYPE="INTEGER$del$TTYPE";TNOTN="1$del$TNOTN";TSORT="1$del2$TSORT"
		TDFLT="' '$del$TDFLT";TPKEY="1$del$TPKEY";TMETA="rowid$del2$TMETA"
	fi 
	if [ "$parmlist" = "" ];then return;fi
	parmlist=${parmlist//'"null"'/null}
	TINSERT="insert into $tb ($TSELECT) values ($parmlist)"
	IFS=",";TUPDATE="update $tb set "$(printf "${TUPDATE}\n" $parmlist)" where $PRIMKEY = $row";unset IFS
}
function func_help () {
    [ $# -gt 1 ] && echo "         Wert unzulaessig: $2"
    echo "         $1 -- usage:"
    type -a "$1" | grep -e '\"\-\-' | func_translate -i '|,",)' -o " , , "
    echo "         func_test for a short demonstration"
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
#	text=$(echo $text | tr '"<>' '___')
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
	setmsg -e --width=400 "sql_execute\n$error\n$db\n$stmt" 
	return 1
}
function sql_execute () { func_sql_execute $* ; }
function trap_init () {
    script="$0";script=${script##*\\};
    exec 4< /dev/stdin
    export PS4='${script}+(${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
}
function trap_start() { 
#    IFS=$'\n' SOURCELINE=( $( cat -A "$0" ) )
    FIRST=1
}
function trap_help () {
    echo "debug ab Zeile       : trap 'set +x;trap_at $LINENO 174;set +x' DEBUG"
    echo "debug wenn field=$var: trap 'set -x;trap_when $LINENO $field value ;set +x' DEBUG"
    echo "debug wenn neuer Wert: trap 'set +x;trap_change $LINENO  $field;set +x' DEBUG"
}
function trap_stop() { STOP=0; }
function trap_off() { TRAPOFF=1; }
function trap_at() { trap_while "1" "stop at :$1" "$1" "$1" "$2"; }
function trap_when() { trap_while "1" "stop when $2 = $3:$1" "$1" "$2" "$3"; } 
function trap_change() { trap_while "0" "change $2 $OLD_VALUE $1" $1 $2 $2; } 
function trap_debug() { trap_while "1" "debug $1 " $1 $1 $1; } 
function trap_while() {
    if [ ${FIRST} -lt 1 ]; then  STOP=0; fi
    eq=$1;shift;msg="$1";shift
	if [ "${OLD_VALUE}" == "" ];   then  OLD_VALUE="$3"; fi
	if [ "$OLD_VALUE"   == "$2" ] && [ $eq -eq 1 ]; then  STOP=1; fi    
	if [ "$OLD_VALUE"   == "$2" ] && [ $eq -eq 0 ]; then  STOP=0; fi    
	if [ "$OLD_VALUE"   != "$2" ] && [ $eq -eq 0 ]; then  STOP=1; fi    
	if [ "$STOP"   	   -lt 1 ]; then  return; fi 
	if [ "$TRAPOFF"    -gt 0 ]; then  return; fi  
	OLD_VALUE="$3";
	LASTLINE=($1-1) 
	CMD="";            # argument 1: last line of error occurence
	if [ ${FIRST} -lt 1 ]; then  FIRST=1; trap_start; fi  
#	AKTLINE=${SOURCELINE[$LASTLINE]}    # $BASH_COMMAND moeglich?
#	msg="$msg:${AKTLINE%\^*}" 
	msg="$msg:${BASH_COMMAND}" 
	CMD=""
	while [[ $CMD != "ende" ]]; do
		read -u 4 -p "$msg " CMD
			if [ ${#CMD} -lt 1 ]; then
			   CMD="ende"
			fi
			if [ "$CMD" == "n" ] ||        [ "$CMD" == "n" ]; then cmd=$lastcmd;fi        
			case $CMD in
					vars ) ( set -o posix ; set );;
					ende ) ;;
					* ) eval $CMD;;
			esac
			lastcmd=$cmd
	done
}
function reverse () {
	if [ "$1" == "-d" ]; then  
		shift;delimiter="$1";shift
	else
		echo "$@" | grep -o . | tac | tr -d '\n' ; echo; return
	fi
	IFS="$delimiter";line=""
	for arg in ${*}; do line="$arg$del$line";del="$delimiter";done
    unset IFS 
    echo "$line"
}	
function func_is_digit () {
	if [ "$1" == "" ]; then echo 1;return;fi
    test -z "${@//[0-9]}" && echo 0 || echo 1
}
function isdigit () { func_is_digit "$@"; }
function func_print_script() {
    local
    end="##end"
    start="##start"
    file="$0"
    if [ $# -gt 0 ] && [ -f "$1" ];  then file="$1";shift;fi
    if [ $# -gt 0 ]; then start="$1";shift;fi
    if [ $# -gt 0 ]; then end="$1"; fi
    found=0
    while read -r line; do        
         if [ "${line:0:${#end}}" == "$end" ]; then        break; fi
         if [ "$found" -gt 0 ]; then log "$line";continue; fi
         if [ "${line:0:${#start}}" == "$start" ]; then found=1; fi  
    done < $file        
}
function func_log_logfile() {	
	logfile=$0
    file="${logfile##*/}"
    file="${file%\.*}"
    logfile="$HOME"'/log/'"$file"'.log' 
	echo "$logfile"
}
function log() {
	oldstate="$(set +o | grep xtrace)";set +x
	ohnevorschub=0
	if [ $# -lt 1 ];then func_log " ";return;fi  
	stopit=0;debug=0
	args="";
	for ((i=1;i<=$#;i++));do
	    if   [ "${!i}" == "file" ];        then    logfile=$(func_log_logfile);log_on=1;func_log " "
	    elif [ "${!i}" == "logfile" ];     then    shift;logfile="${!i}";log_on=1;func_log " "	
	    elif [ "${!i}" == "-n" ];          then    ohnevorschub="1"     
	    elif [ "${!i}" == "new" ];         then    log_on=1;[ -f "$logfile" ] && rm "$logfile"
	    elif [ "${!i}" == "log_on" ];      then    log_on=1 
	    elif [ "${!i}" == "log_off" ];     then    log_on=0 
	    elif [ "${!i}" == "echo_on" ];     then    echo_on=1
	    elif [ "${!i}" == "echo_off" ];    then    echo_on=0 
	    elif [ "${!i}" == "debug_on" ];    then    debug_on=1
	    elif [ "${!i}" == "debug_off" ];   then    debug_on=0 
	    elif [ "${!i}" == "debug" ];       then    debug=1
	    elif [ "${!i}" == "start" ];       then    func_start 
	    elif [ "${!i}" == "verbose" ];     then    verbose_on=1 
	    elif [ "${!i}" == "v_on" ];        then    verbose_on=1 
	    elif [ "${!i}" == "verbose_on" ];  then    verbose_on=1 
	    elif [ "${!i}" == "verbose_off" ]; then    verbose_on=0 
	    elif [ "${!i}" == "v_off" ];       then    verbose_on=0 
	    elif [ "${!i}" == "stop" ];        then    stopit=1 
	    elif [ "${!i}" == "ende" ];        then    stopit=1 
	    elif [ "${!i}" == "end" ];         then    stopit=1 
	    elif [ "${!i}" == "tlog" ];        then    tlog $logfile 
	    else                                       args="$args${!i} " 
	    fi
	done
	if [ ${#args} -gt 0 ];then func_log "$args";fi  
	if [ $stopit  -gt 0 ];then verbose_on=0;func_end;fi  
	eval "$oldstate"
}
function func_log() {                
    if [ "$debug"  -gt  0 ] && [ "$debug_on"  -lt  1 ]; then return;fi
    if [ "$verbose_on" -gt  0 ]; then 
        funcname="${FUNCNAME[2]}";if [ "$funcname" == "" ];then funcname="bash";fi
        funcname=$(left "${funcname}" 20 )
		set -- $(date "+%Y-%m-%d %H:%M:%S")" ${funcname}" "$@"
	fi 
    if [ "$log_on" -gt  0 ];     then
		if [ "$logfile" == "" ];  then logfile="$SYSLOG"   ;fi
		if [ "$ohnevorschub" -lt 1  ]; then
			echo -e      "$@" >> $logfile
		else		
			echo -e -n   "$@" >> $logfile
		fi
    fi  
    if [ "$echo_on" -gt  0 ];  then
		if [ "$ohnevorschub" -lt 1 ]; then
			echo -e      "$@"  
		else		
			echo -e -n   "$@"  
		fi
    fi  
}
function func_start() {        
    info="$(date "+%Y-%m-%d %H:%M:%S")  $(hostname) $0: START\n"
    if [ "$logfile" == "" ] ; then logfile="$SYSLOG";fi
    func_log $info
}
function func_end() {
	rc=$?; if [ "$retcode" != "" ]; then rc=$retcode;fi
    info=" \n$(date "+%Y-%m-%d %H:%M:%S")  $(hostname) $0: STOP - rc = $rc CPU-TIME $SECONDS \n"
    func_log $info
}
function func_date2stamp () {
    date --utc --date "$1" +%s
}
function func_stamp2date (){
    date --utc --date "$1 sec" "+%Y-%m-%d %T"
}
function func_dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}
function func_translate () {
    us=" ";mv=0;m=0;all="0";gap="";min=0;max=0;d=",";count=0;zi=0;x=0
    line="";
    while [ $# -gt 0 ] ;do
                if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
                        nparm=$(func_mygetopt $1)
                        shift; set -- $@ $nparm
                else
                        case "$1" in
                                "--mv-file"|"--mv")      mv="1";;
                                "--intab"|"-i")          shift;istr="$1";;
                                "--outtab"|"-o")         shift;ostr="$1";;
                                "--text"|"-t")           shift;line="$1";;
                                "--min-changes"|"--min") shift;min="$1";;
                                "--max-changes"|"--max") shift;max="$1";;
                                "--delimiter"|"-d")      shift;d="$1";;
                                "--recursive"|"--changeall"|"-r")   all="1";;
                                "--matched"|"-m")        m="1";;
                                "--count"|"--co"|"-c")   count="1";;
                                "--debug"|"-x")          set -x;x=1;;
                                "--help"|"-h")           func_help $FUNCNAME;return;;
                                [-]*)                    func_help $FUNCNAME "$1";return;;
                                *) line="$line$gap$1"
                                gap=" "
                        esac
                fi        
            shift;
    done
    file=$line        
    oifs=$IFS;li=0;lo=0;IFS="$d"
    for p in $istr;do ia[$li]="$p";ca[$li]="0";li=$(($li+1));done
    for p in $ostr;do oa[$lo]="$p";lo=$(($lo+1));done
    IFS=$oifs
    if [ -f "$line" ] && [ "$mv" -lt 1 ];then
         cat "$line"
    else
         if [ "$line" == "" ]; then
              cat < /dev/stdin
         else
              echo "$line"
         fi
    fi |        
    while IFS=: read -r line;do
		zi=$(($zi+1))
        while true;do    
            changed=0;string=""  
            for ((i=0;i<"${#line}";i++)); do
                u="${line:$i:1}"  
                found=0
                for ((i2=0;i2<$li;i2++)); do
                    e=${ia[$i2]}   # umlaute im array 2 bytes
                    le=${#e};
                    if [ "${line:$i:$le}" == "$e" ]; then
	                    if [ "$lo" -lt "$i2" ]; then
	                        z=""
	                    else
	                        z="${oa[$i2]}"
	                    fi  
	                    i=$(($i+$le-1))
	                    ca[$i2]=$((${ca[$i2]}+1))
	                    found=1;changed=$(($changed+1));i2=$li
                    fi          
                done                            
                if [ "$found" -gt 0 ]; then u="$z";fi  
                string="$string$u"  
            done
            line="$string"
            if [ "$changed" -lt  1 ]; then break;fi
            if [ "$all"     -lt  1 ]; then break;fi
            if [ "$changed" -gt 20 ]; then break;fi
       done
       [ "$min" -gt 0 ] && [ "$changed" -lt "$min" ] && echo "!min $min : $changed >> $string" > /dev/stderr
       [ "$max" -gt 0 ] && [ "$changed" -gt "$max" ] && echo "!max $max : $changed >> $string" > /dev/stderr  
       if [ "$m" -lt 1 ] || [ "$changed" -gt 0 ] ; then
           echo "$string"      
           if [ "$count" -gt 0 ]; then    
               echo "count: ${ca[*]}" > /dev/stderr
           fi
       fi
       if [ "$mv" -gt 0 ] && [  -f "$file" ]; then      
           mv -i "$file" "$string"
       fi
    done
    if [ "$x" -gt 0 ]; then set +x;fi        
}
function translate () { func_translate "$@" ; }
function umlaute () { func_translate --intab "ä,ö,ü,Ä,Ö,Ü,ß" --outtab "ae,oe,ue,Ae,Oe,Ue,ss"  "$@" ; }
function mv_umlaute () { func_translate --mv --intab "ä,ö,ü,Ä,Ö,Ü,ß, " --outtab "ae,oe,ue,Ae,Oe,Ue,ss,_"  "$@" ; }
function func_translate_all () { func_translate "--recursive" $@; }
function transall () { func_translate "--recursive" "$@"; }
function ows () { func_translate --recursive -i '  ' -o ' ' "$@" ; }
function change () { func_translate -i "$1" -o "$2" "$3"; }
function changeall () { func_translate -r -i "$1" -o "$2" "$3"; }
function file2csv () { func_cut $@; }
function func_csv2file () {  
	delimiter=",";oifs=$IFS;outdelimiter=" | ";file="";gap="" 
	while [ $# -gt 0 ] ;do
		if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
		    nparm=$(func_mygetopt $1)
			shift; set -- $@ $nparm
		else
			case "$1" in  
				"--file"|"-f")            shift;file="$1";;
				"--delimiter"|"-d")       shift;delimiter="$1";;
				"--out-delimiter"|"--od") shift;outdelimiter="$1";;        
				"--debug"|"-x")           set -x;;
				"--help"|"-h")            func_help $FUNCNAME;return;;
				[-]*)                     func_help $FUNCNAME "$1";return;;
				*) file="$file$gap$1"
				   gap=" "
			esac
			shift;
		fi        
	done
	if [ "$file" == "" ];then file="/dev/stdin";fi
	declare -a tcol tlen
    tmpf=/tmp/csv2file.csv;[ -f $tmpf ] && rm $tmpf
	while read -r line;do
	    IFS=$delimiter;tcol=($line);unset IFS 
	    for ((i=0;i<${#tcol[@]};i++));do
	        length=${#tcol[$i]} 
	        if [ "${#tlen[$i]}" -lt 1       ];then tlen[$i]=$length;fi
	        if [ "${tlen[$i]}"  -lt $length ];then tlen[$i]=$length;fi
	    done 
	    first=1   
	    echo $line >> $tmpf
	done < "$file"
	while read -r line;do
	    IFS=$delimiter;tcol=($line);unset IFS 
	    nline="";del=""
	    for ((i=0;i<${#tcol[@]};i++));do
	        nline="$nline$del$(left -t ${tcol[$i]} -l ${tlen[$i]})"
	        del=$outdelimiter
	    done   
	    echo "$nline"
	done < "$tmpf"
}
function csv2file () { func_csv2file "$@"; }
function func_substring () {
	start="";ende="";line="";gap="";x=0;isfile=0
	if [ $# -lt 6 ]; then func_help $FUNCNAME "$@";return;fi
	while [ $# -gt 0 ] ;do
		if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
			nparm=$(func_mygetopt $1)
			shift; set -- $@ $nparm
		else
			case "$1" in
				"--start"|"-s" )      shift;start="$1";;
				"--ende"|"-e")        shift;ende="$1";;
				"--von"|"-v" )        shift;start="$1";;
				"--bis"|"-b")         shift;ende="$1";;
				"--debug"|"-x")       set -x;x=1;;
				"--text"|"-t")        shift;line="$1";;
				"--file"|"-f")        isfile=1;;
				"--help"|"-h")        func_help $FUNCNAME;return;;
				[-]*)                 func_help $FUNCNAME "$1";return;;
				*) line="$line$gap$1"
						gap=" "
			esac
		fi        
		shift;
	done
	oifs=$IFS
	if [ -f "$line" ] &&  [ $isfile -gt 0 ];then
	   cat "$line"
	else
	   if [ "$line" == "" ]; then
		  cat < /dev/stdin
	   else
		  echo "$line"
	   fi
	fi |	
	while IFS=: read -r line;do 			  
		if [ "$(isdigit $start)" -gt 0 ]; then
            from=$(pos $start $line)
            if [ $from -lt 0 ]; then from=0;fi
        else
            from=$start    
        fi   	 
        if [ "$(isdigit $ende)" -gt 0 ]; then
            to=$(pos "$ende" "$line")
            if [ $to  -lt 0 ]; then to="${#line}";fi
            to=$(($to-$from)) 
        fi  
        if [ "$(isdigit $start)" -gt 0 ] && [ $from -gt 0 ]; then
            from=$(($from+1)) 
        fi     
		echo "${line:$from:$to}"  
	done        
	if [ "$x" -gt 0 ]; then set +x;fi
}
function substring () { func_substring -t "$1" -v "$2" -b "$3"; }
function trim_simple() { echo $@; }
function func_trim () {
    local
	lead="1";tail="1";char=" ";line="";text="";gap="";x=0
	while [ $# -gt 0 ] ;do
			if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
					nparm=$(func_mygetopt $1)
					shift; set -- $@ $nparm
			else
					case "$1" in
							"--left"|"-l")        tail="0";;
							"--right"|"-r")       lead="0";;
							"--debug"|"-x")       set -x;x=1;;
							"--char"|"-c")        shift;char=$1;;
							"--text"|"-t")        shift;line="$1";;
							"--help"|"-h")        func_help $FUNCNAME;return;;
							[-]*)                 func_help $FUNCNAME "$1";return 1;;
							*) line="$line$gap$1"
									gap=" "
					esac
			fi        
			shift;
	done
	[ "$char" == " " ] && test -z "${line// }" && echo "" && return
	if [ "$char" == " " ] && [ $lead -eq 1 ] && [ $tail -eq 1 ]; then
		line=$(echo "$line" | xargs) 
		echo "$line"
		return
	fi
	oifs=$IFS
	if [ -f "$line" ] ;then
	   cat "$line"
	else
	   if [ "$line" == "" ]; then
		  echo "cat stdin"
		  cat < /dev/stdin
	   else
		  echo "$line"
	   fi
	fi |      
	while IFS=: read line;do
		le=${#char};ls=${#line};end=$(($ls-$le))
		if [ "$lead" == "1" ]; then
			for ((i=0;i<end;i++)); do
				vgl=${line:$i:$le}
				if [ "$vgl" ==  "$char" ]; then
						i=$(($i+$le-1));
				else
						break;
				fi                  
			done
		    line=${line:$i}
		fi
		ls=${#line};end=$(($ls-$le))
		if [ "$tail" == "1" ]; then
			for ((i=end;i>-1;i--)); do
				vgl=${line:$i:$le}
				if [ "$vgl" ==  "$char" ]; then
						i=$(($i-$le+1));
				else        
						break;
				fi                  
			done
			i=$(($i+$le))
			line="${line:0:$i}"
		fi
		echo "$line"  
    done   
    IFS=$oifs     
    if [ "$x" -gt 0 ]; then set +x;fi
}
function trim () { func_trim "$@" ; }
function func_left () {
    right=0;pad=" ";line="";lng=0;plng="";gap="";x=0
    while [ $# -gt 0 ] ;do
        test -z "${1//[0-9]}" && num=1 || num=0
        if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
             nparm=$(func_mygetopt $1)
             shift; set -- $@ $nparm
        else
            case "$1" in
                 "--laenge"|"-l")          shift;lng=$1;;
                 "--text"|"-t")            shift;line=$1;;                        
                 "--right"|"-r")           right="1";;
                 "--padding"|"--pad"|"-p") shift;pad="$1";;
                 "--debug"|"-x")           set -x;x=1;;
                 "--help"|"-h")            func_help $FUNCNAME;return;;
                 [-]*)                     func_help $FUNCNAME "$1";return;;
                 *)  if [ "$plng" == "" ] && [ "$num" -gt 0 ]; then
                         plng="$1"
                     else  
                         line="$line$gap$1"
                         gap=" "
                     fi
            esac                
            shift;
        fi
    done
    if [ "$lng" -lt 1 ]; then
        lng=$plng
    else
        line="$plng$line"        
    fi
    if [ -f "$line" ] ;then
        cat "$line"
    else
        if [ "$line" == "" ]; then
            cat < /dev/stdin
        else
            echo "$line"
        fi
    fi |        
    while IFS=: read -r line;do
        rlng=$(($lng-${#line}))
        if [ "$rlng" -gt 0 ]; then
            COPIES=$(func_copies $rlng $pad)
        else
            COPIES=""
        fi    
        if [ "$right" -lt 1 ]; then
            ret="$line$COPIES"
            start=0
        else
            ret="$COPIES$line"
            start=$((${#ret}-$lng))
        fi
        echo "${ret:$start:$lng}"
    done
    if [ "$x" -gt 0 ]; then set +x;fi        
}
function left () { func_left "$@" ; }
function func_right () { func_left "--right" $@; }
function right () { func_right "$@" ; }
function func_copies () {
	line="";lng=0;plng="";gap="";x=0
	while [ $# -gt 0 ] ;do
		test -z "${1//[0-9]}" && num=1 || num=0
		if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
			nparm=$(func_mygetopt $1)
			shift; set -- $@ $nparm
		else
			case "$1" in
					"--occurs"|"-o") shift;lng="$1";;
					"--char"|"-c")   shift;line="$1";;
					"--debug"|"-x")  set -x;x=1;;
					"--help"|"-h")   func_help $FUNCNAME;return;;
					[-]*)            func_help $FUNCNAME "$1";return;;                
					*)         if [ "$plng" == "" ] && [ "$num" -gt 0 ]; then
									plng="$1"
							else  
									line="$line$gap$1"
									gap=" "
							fi
			esac                
			shift;
		fi        
	done

	if [ "$lng" -lt 1 ]; then
	   lng="$plng"
	else
    line="$plng$value"        
	fi  
	if [ "$line" == "" ]; then line=" ";fi
	str=""
	for ((i=0;i<$lng;i++)); do
	   str="$str$line"
	done
	echo "$str"
	if [ "$x" -gt 0 ]; then set +x;fi
}
function copies () { func_copies $@ ; }
function func_while_file () {
	cmd="";gap="";if="/dev/stdin";cmd="";parm="";ev=0 ;x=0
	while [ $# -gt 0 ] ;do
		if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
			nparm=$(func_mygetopt $1)
			shift; set -- $@ $nparm
		else
			case "$1" in
				"--infile"|"--if")           shift;if="$1";;
				"--command"|"--cmd"|"-c")    shift;cmd="$1";;
				"--eval"|"-e")               ev="1";;  
				"--parameter"|"--parm"|"-p") shift;parm="$1";;
				"--debug"|"-x")              set -x;x=1;;                  
				"--help"|"-h")               func_help $FUNCNAME;return;;
				*)
				if [ "$cmd" == "" ]; then
						cmd="$1"
				else    
						parm="$parm$gap$1"
						gap=" "
				fi    
			esac
			shift;
		fi        
    done
    eval "set -- $parm"  
    old_ifs=$IFS;IFS=$'\n'
	while read -r line; do      
		if [ "$ev" -gt 0 ]; then
		   eval '$cmd $@ "$line"'
		else
				   if [ "${#parm}" -gt 0 ]; then
					  $cmd $@ "$line"
				   else        
			  $cmd   "$line"
				   fi  
		fi
    done < $if
    IFS=$old_ifs
    if [ "$x" -gt 0 ]; then set +x;fi
}
function dofile () { func_while_file "$@"; }
function func_quote (){
    line="";ql='"';qr='"';i=0;gap="";file="";x=0;delimiter=",";remove=$false
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
function quote () { func_quote "$@"; }
function func_paste () {
    left="$t1";right="$t2";skipleft=0;skipright=0;delim=" | ";x=0
    if [ "$#" -eq 2 ]; then set -- "-l" "$1" "-r" "$2";fi  
    while [ "$#" -gt 0 ]; do
        case "$1" in
			"--left"|"-l")        shift; left=$1;;
			"--rigt"|"-r")        shift; right=$1;;
			"--delimiter"|"-d")   shift; delim=$1;;
			"--skip-left"|"-sl")  shift; skipleft=$1;;
			"--skip-right"|"-sr") shift; skipright=$1;;  
			"--debug"|"-x")       set -x;x=1;;                        
			"--help"|"-h")        func_help $FUNCNAME;return;;
			[-]*)                 func_help $FUNCNAME "$1";return;;
        esac
        shift
    done
	if [ ! -f "$left" ] || [ ! -f "$right" ]; then
			echo "keine Dateien: $left $right"
			return
	fi
	max=0;
	while read  line ; do
			if [ ${#line} -gt $max ]; then
					max=${#line}
			fi
	done < $left
    format='%-'$max's %s %s\n';next=0;ex=0;exec 3<  $left;exec 4<  $right
	while [ "$next" -lt 1 ] ; do
		for ((i=0;i<$skipleft;i++)); do read -u 3 lineleft;done
		for ((i=0;i<$skipright;i++)); do read -u 4 lineright;done
		ex=$((ex+1))
		read -u 3 lineleft
		read -u 4 lineright
		if [ "$lineleft" == "" ] && [ "$lineright" == "" ]; then
				break
		fi  
		printf "$format" "$lineleft" "$delim" "$lineright"
	done
	if [ "$x" -gt 0 ]; then set +x;fi
}
function paste () { func_paste $@ ; }
function func_getpath_unc () {
    set +x
    laufwerk="";path=$(translate -i '\' -o '/' "$@")
        [ "${path:0:4}" == '////' ] && path=$(translate -i '//' -o '/' $path)  
    if [ $(pos "$path" ":") -eq 1 ] ; then laufwerk="${path:0:2}";fi  
	if [ "${path:2:1}" == "/" ];      then laufwerk="${path:1:1}:";fi
	if [ "$laufwerk" != "" ]; then
			line=$(net use | grep -i ${1:0:2});  
			if [ "$line" == "" ]; then line="- - \\\\$COMPUTERNAME\\$SYSTEMDRIVE -"; fi
			read -r m1 m2 server m3 <<< $line
			path="$server${path:2}"
	fi        
	translate -i '/,:' -o '\,$' "$path"  
}
function func_getpath_linux () {
    path=$(translate -i '\' -o '/' "$@")
	if [ "${path:0:4}" == '////' ] ; then
	   path=$(translate -i '//' -o '/' $path)
	fi
	if [ $(pos "$path" ":") -ge 0 ] ; then
	   path=$(translate -i ':' -o '' "/"$path)
	fi
	if [ ${path:0:2} == '//' ] ; then
	   path=$(translate -i '/' -o '\' $path)
	fi        
    echo $path
}
function func_getpath_windows () {
    path=$(translate -i '/' -o '\' "$@")
        if [ $(pos $path ':') -eq 1 ];then echo $path;return;fi
    if [ "${path:0:4}" == '\\\\' ] ; then
	    path=$(translate -i '\\' -o '\' $path)
	fi        
	if [ "${path:0:2}" == '\\' ] ; then echo $path;return;fi
	echo "${path:1:1}:${path:2}"
}
function func_getpath_notes () {
    echo 'file:'$(func_getpath_unc "$@")
}
function getunc () { func_getpath_unc $@; }
function getlinux () { func_getpath_linux $@; }
function getwindows () { func_getpath_windows $@; }
function getnotes () { func_getpath_notes $@; }
function func_pos () {
	local
	if [ "${#1}" -gt "${#2}" ] ; then
	   str="$1";pos="$2"
	else  
	   str="$2";pos="$1"
	fi 
#	if [ "${#pos}" -eq 1 ];then return $(($(expr index "$str" "$pos") - 1)); fi  
    x="${str%%$pos*}"
    [[ "$x" = "$str" ]] && echo -1 || echo "${#x}"
}
function func_last_pos () {
	if [ "${#1}" -gt "${#2}" ] ; then
	   str="$1";pos="$2"
	else  
	   str="$2";pos="$1"
	fi    
    x="${str##*$pos}"
    [[ "$x" = "$str" ]] && echo -1 || echo "$((${#str}-${#pos}-${#x}))"
}
function pos () { func_pos "$@"; }
function lastpos () { func_last_pos "$@"; }

function func_uppercase() {
 echo $@ | tr [a-z] [A-Z]
}
function upper () { func_uppercase $@; }
function func_lowercase() {
 echo $@ | tr [A-Z] [a-z]
}
function lower () { func_lowercase $@; }
function func_mygetopt () {
    parms=$(echo $@ | tr -d "\:-");str=""
    for ((i=0;i<${#parms};i++)) ; do
       str="$str-${parms:$i:1} "
    done        
        echo $str
}
function func_cut () {
	local
	header="";dl="";delimiter=",";odel=$delimiter;reverse=0;il="";gap="";bl="";cl="-f1-";line="";trim=0;first=0
	declare -a tcl tdl til tbl tval tlen
	while [ $# -gt 0 ] ;do
	    if [ "$(echo $1 | grep -e '^-[a-eg-z].')" ]; then # zB -avcb
			nparm=$(func_mygetopt $1)
			shift; set -- $@ $nparm
	    else
		    case "$1" in
				"--header"|"--he")      shift;header="$1";;
				"--collist"|"--cl")     shift;cl="$1";;
				"-f"*)                  cl="$1";;
				"--dellist"|"--dl")     shift;dl="$1";;
				"--inslist"|"--il")     shift;il="$1";;
				"--delimiter"|"--char"|"-c")           shift;delimiter="$1";;
				"--output-delimiter"|"--ochar"|"--oc") shift;odel="$1";;
				"--trim")               trim=1;;
				"--reverse"|"-r")       reverse=1;;
				"--trace"|"--tr"|"-x")  set -x;;
				"--help"|"-h")          func_help $FUNCNAME;return;;
				[-]*)                   func_help $FUNCNAME "$1";return;;
				*) line="$line$gap$1"
				gap=" "
			esac
		fi        
		shift;
    done
#---------- stdout kann nichtgut verarbeitet werden
    if [ "$line"   == "" ] && [ "$header"   == "" ];then
         line="/tmp/cut_"$(date "+%Y-%m-%d_%H:%M:%S")
         cat > "$line"
         zeilen=$(wc -l "$line")
         if [ "${zeilen:0:2}" == " " ]; then log "keine eingaben";return;fi
    fi         
#---------- bl enthaelt die bytelist  fuer die /bin/cut notation, falls kein delimiter gefunden wird
	if [ "$line"   == "" ];then line="$header";fi
    if [ "$header" == "" ];then 
         if [ -f "$line" ];then header=$(head -n 1 "$line");first=1;else header="$line";fi
    fi
    dpos=$(pos "$delimiter" "$header");bl=""
    if [ $dpos -lt 0 ];then
		del="";start=1;vor="#";bis=0
		for ((i=0;i<${#header};i++));do
			if [ "${header:$i:1}" != " " ] && [ "$vor" == " " ];then 
			    if [ $bis -eq 0 ];then bis=$i;else bis=$(($i));fi 
				bl="$bl"$del$(($start))"-""$bis" 
				start=$(($bis+1)) 
				del=","
			fi 
			vor="${header:$i:1}"    
		done
		bl=$bl$del$(($start))"-";del=","
	fi 
    log debug bl $bl
#---------- cl enthaelt die fieldlist fuer die /bin/cut notation und wird spaltenweise aufbereitet
    [ "$header" != "" ] && IFS=$delimiter && x=$(wc -w <<< $header) && unset IFS
    [ "${cl:$((${#cl}-1)):1}" == "-" ] && cl=$cl$(($x))
	end=${#cl}
	cols="";start=1;del="";zi=-1;declare -a tcol
	if [ "${cl:0:2}" == "-f" ]; then cl="${cl:2}";fi
	log debug cl $cl
	if [ "${cl:0:1}" == "-"  ]; then cl=1"$cl";fi
	log debug start  bl $bl
	log debug start  cl $cl
#---------  revers-regel einarbeiten
	if [ "$reverse" -eq 1 ]; then 
	    unset IFS
		cl=$(reverse -d $delimiter "$cl")
		bl=$(reverse -d $delimiter "$bl")
	fi
#---------  delete-list und insert-list einfuegen
    log debug revers  bl $bl
	log debug revers cl $cl
	IFS=$delimiter;tbl=(${bl});tcl=($cl);tdl=($dl);til=($il)  
    nline=$cl;obl=$bl;bl="";cl="";nbl="";ncl="";start=1;length=${#delimiter}
	for i in $nline;do
	    von=${i%%\-*} 
	    bis=${i#*\-}; # if [ "$bis"  ]
		for ((i2=$von;i2<=$bis;i2++));do 
		    found=0
		    for i3 in ${til[*]};do 
				nr=${i3%%\ *};val="="${i3#*\ }  
				byte=${tbl[$(($i2))]}
				nbis=${byte#*\-}
				if [ "$i2" == "$nr" ]; then 
					if [ "$ncl" == "" ];then 
						ncl="$val";nbl="$val";
					else 
						ncl="$ncl$delimiter$val";nbl=$nbl$delimiter$val
					fi
			    fi		
			done
		    for i3 in ${tdl[*]};do if [ "$i2" == "$i3" ]; then found=1;break;fi;done
			if [ $found -eq 0 ]; then 
				byte=${tbl[$(($i2-1))]}
				nvon=${byte%%\-*}
				nbis=${byte#*\-}
				if [ "$ncl" == "" ];then 
					ncl="$i2";nbl=$von"-"$nbis
				else 
				    if [ "$nbis" != "" ];then nbis=$(($nbis));fi
					ncl="$ncl$delimiter$i2";nbl=$nbl$delimiter$(($nvon))"-"$nbis
				fi
				if [ "$cl" == "" ];then 
					cl="$i2";bl=$nvon"-"$nbis
				else 
					cl="$cl$delimiter$i2";bl=$bl$delimiter$nvon"-"$nbis
				fi
				start=$(($start+$nbis+${#delimiter}))
	        fi 	
    	done
	done
	IFS=$delimiter;tbl=($bl);tnbl=($nbl);tncl=($ncl);tcl=($cl)
	lowest=1;end=${#tncl[*]};sorted=1
	while true;do
	    found=0;min=0 
	    for ((i=0;i<$end;i++));do 
	        if [ ${tncl[$i]:0:1} == "="  ] ; then sorted=0 ;continue ;fi
	        if [ ${tncl[$i]} -eq $lowest ] ; then found=1  ;fi
	        if [ ${tncl[$i]} -lt $min ]    ; then sorted=0 ;fi
	        min=${tncl[$i]}
	    done     
	    if [ $found -eq 1 ]; then lowest=$(($lowest+1));continue;fi    
	    for ((i=0;i<$end;i++));do 
			if [ ${tncl[$i]:0:1} == "="  ] ; then continue ;fi
	        if [ ${tncl[$i]} -gt $lowest ] ; then tncl[$i]=$((${tncl[$i]}-1));found=1  ;fi
	    done  
	    if [ $found -eq 0 ];then break;fi      
	done
	unset IFS
	if [ "$obl" != "" ];then liste="-b""$bl";else liste="--delimiter $delimiter -f"$cl;fi
    outdel=$odel
    if [ -f "$line" ] ;		then cmd='cut --output-delimiter "$outdel" $liste "$line"'
	elif 
		[ ${#line} -gt 0 ] ;then cmd='cut --output-delimiter "$outdel" $liste <<< "$line"'
	else
								 cmd='cat < /dev/stdin | cut --output-delimiter "$outdel"'
	fi 
#-------- wenn keine besonderheiten vorliegen, loesung mit cut	
	if [ $sorted -eq 1 ] && [ $trim -eq 0 ];then
		echo direkt nach cut $(eval echo $cmd)
	    eval "$cmd"
	    return
	fi 
	end=${#tncl[*]}; 
#	if [ "$odel"   == "" ];then delim=",";else delim=$odel;fi
	if [ "$outdel" == "" ];then outdel=$delimter;fi
	if [ -f "$line" ]; then maxz=$(wc -l $line);maxz=${maxz%% *};else maxz=2000;fi;#echo "maxz = $maxz"
	delimiter=$outdel;zeile=0
	eval $cmd |
	while read -r line;do
	    zeile=$(($zeile+1)); if [ "$zeile" -gt "$maxz" ];then log debug "break bei $maxz";break;fi 
	    if [ "$line" == "" ];then continue;fi
	    IFS=$delimiter;tval=($line);unset IFS
	    if [ ${#tval[*]} -lt 1 ];then trap 'set +x;trap_debug $LINENO;set +x' DEBUG;fi
		nline="";del=""
		for ((itncl=0;itncl<$end;itncl++));do
		    arg="${tncl[$itncl]}" 
		    #log debug $itncl $end $arg  
		    if [ ${arg:0:1} == "=" ]; then
		        val="${arg:1}" 
		        title="${val#*\#}"
		        if [ "$title" != "$val" ];then
		            tncl[$itncl]="=""${val%%\#*}"
		            tlen[$itncl]=${#title}
		            val="$title"
		        fi
		        if [ "${val:0:2}" == "++" ]; then
					val="${val:2}"
					if [ "$incr" = "" ];then incr=$val;fi
					incr=$(($incr+1))
					val=$incr
				fi
				len=${tlen[$itncl]} 
				if [ "$len" == "" ];then len=0;fi
				if [ $trim -gt 0  ];then len=0;fi
			 	while [ "${#val}" -lt $len ];do val="$val"" ";done 
			 	if [ $trim -gt 0  ];then val=$(trim_simple "$val") ;fi 
			 #	if [ $trim -gt 0  ];then val=$(echo "$val" | xargs) ;fi 
		        nline="$nline$del$val" # ;echo  ">$nline<"  
				del=$odel				  
		    else
				val="${tval[$(($arg-1))]}"
				if [ "${val:0:1}" == " " ] || [ "${val:$((${#val}-1)):1}" == " " ]; then	
					if [ $trim -gt 0  ];then val=$(trim_simple "$val") ;fi  
				fi	 
			#	if [ $trim -gt 0  ];then val=$(echo "$val" | xargs) ;fi  	 
				nline="$nline$del$val"	 	 
				del=$odel
			fi
		done
	#	echo $end $line;declare -p tval;continue
		echo "$nline"         
	done
}
function func_test () {
    i=-1
    a[$((++i))]='string=$(echo "    verßchiedöne   Öprationen ")'
    a[$((++i))]='string=$(umlaute "$string")'
    a[$((++i))]='string=$(change "prat"  "perat"  "$string")'
    a[$((++i))]='string=$(translate -i "  ,ss,oe,Oe" -o " ,s,e,O"  "$string")'
    a[$((++i))]='string=$(transall --intab "  ,op" --outtab " ,ope" -t "$string")'
    a[$((++i))]='string=$(quote --ql "  ___" --qr "___     " "$string")'
    a[$((++i))]='string=$(trim -l "$string")'
    a[$((++i))]='string=$(trim -r "$string")'
    a[$((++i))]='string=$(trim -c "_"  "$string")'
    a[$((++i))]='string2="$string"'
    a[$((++i))]='string=$(left  12  "$string2")'
    a[$((++i))]='string=$(right 12  "$string2")'
    a[$((++i))]='string=$(left  40  "$string2")'
    a[$((++i))]='string=$(right 40 -p "_" "$string2")'
    z1=$(($i+1))
    a[$((++i))]='less "/root/test/ft.txt"'
    a[$((++i))]='translate -r -i "  " -o " " "/root/test/ft.txt"'
    a[$((++i))]='ows "/root/test/ft.txt"'
    a[$((++i))]='file2csv "/root/test/ft.txt" > /root/test/ftcsv.txt'
    a[$((++i))]='less "/root/test/ftcsv.txt"'
    a[$((++i))]='csv2file -d " | " "/root/test/ftcsv.txt"'
    a[$((++i))]='csv2file -d " | " "/root/test/ftcsv.txt" | dofile quote'
    a[$((++i))]=''
    echo -e "\nString-Verabeitung\n"
    for ((n=0;n<=$z1;n++));do
        eval "${a[$n]}"; printf "%-64s  >%s<\n" "${a[$n]}"  "$string"
    done  
    echo " zeile1 mit mehreren spalten" > /root/test/ft.txt
    echo "zeile2   mit mehreren  spalten     " >> /root/test/ft.txt
    echo -e "\n    userdefined function with find command: "
    echo "export -f func_quote "
    echo "find $PWD -maxdepth 1 -exec bash -c 'func_quote "$@"' bash {}  \; "
    echo -e "\nFile-Verabeitung"
    i=$(($i+1))
    for ((n=$z1;n<=$i;n++));do
        printf "\n--> %-63s  \n" "${a[$n]}"; eval "${a[$n]}";
    done
    set +x
    printf "\n--> %-63s  \n" "csv2file -d \" | \" \"/root/test/ftcsv.txt\" | quote '-c \"@\"' "
    csv2file -d " | " "/root/test/ftcsv.txt" | quote -c "@"    
}
function func_init () {
	mylog="/c/tmp/mylog.txt"
	alias ddiff="func_dateDiff"
	alias s2d="func_stamp2date"
	alias d2s="func_date2stamp"
	alias w2linux="func_translate -i ':\,\' -o '/,/' /"
	export ddiff="func_dateDiff"
	export s2d="func_stamp2date"
	export d2s="func_date2stamp"
	export w2linux="func_translate -i ':\,\' -o '/,/' /"
}
save_geometry (){
#	str=$*;window=${str%\#*};gfile=${str#*\#}
	str=$*;IFS='#';local arr=( $str );unset IFS; window=${arr[0]};gfile=${arr[1]};glabel=${arr[2]}
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
	echo "HEIGHT=$HEIGHT"  >  "$gfile"
	echo "WIDTH=$WIDTH"    >> "$gfile"
	echo "X=$X"            >> "$gfile"
	echo "Y=$Y"            >> "$gfile"
	setconfig_db "config" "$glabel" ${WIDTH}x${HEIGHT}+${X}+${Y}
	chmod 700 "$gfile"
}
trap_init
	if [ -d "$MYPATH" ]; then
		log debug "oldpath $PATH" 
		export PATH="$PATH:$MYPATH"
		log debug "newpath $PATH" 
	fi
	alias mclear='printf "\033c"'
