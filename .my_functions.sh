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
        declare -a SOURCELINE
#        echo "trapoff = TRAPOFF"
function func_help () {
    [ $# -gt 1 ] && echo "         Wert unzulaessig: $2"
    echo "         $1 -- usage:"
    type -a "$1" | grep -e '\"\-\-' | func_translate -i '|,",)' -o " , , "
    echo "         func_test for a short demonstration"
}
function trap_start() {
    IFS=" " # declare -a array
    IFS=$'\n' SOURCELINE=( $( cat -A "$0" ) )
    FIRST=1
}
function trap_stop() { 
	if [ $FIRST -lt 1 ]; then
	    FIRST=1
	fi    
	STOP=0;
}
function trap_off() { 
	TRAPOFF=1;
}
function trap_while() {
        if [ "$TRAPOFF" -gt 0 ]; then  return; fi 
        CMD=""
        while [[ $CMD != "ende" ]]; do
            read -u 4 -p "$@ " CMD
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
function trap_exit_script() {
        echo $(date "+%Y-%m-%d %H:%M:%S") " $(hostname) $0: EXIT on line $1 (exit status $2)"
}
function trap_field_change() { 
	    if [ $TRAPOFF -gt 0 ]; then  return; fi  
        value=$(eval echo \${$FIELD})
        if [ $# > 1 ] ; then value=$2 ; fi
        if [ "$OLD_VALUE" == "$value" ] ; then return ; fi
        num=$1;LASTLINE=$((num-1))
        trap_while  "Zeile $LASTLINE $FIELD alt >$OLD_VALUE< neu >$value< "
        OLD_VALUE=$value
}
function trap_at() {  
        if [ ${FIRST} -lt 1 ]; then  STOP=$2; fi
        if [ $STOP -lt 1 ];  then  return; fi    
        if [ $1 -lt $STOP ]; then  return; fi
        if [ $TRAPOFF -gt 0 ]; then  return; fi  
        trap_debug_short $1
}
function trap_equal() {
#	    echo "trap_equal TRAPOFF >$TRAPOFF<" 
	    if [ "$TRAPOFF" -gt 0 ]; then  return; fi 
        if [ "$STOP" -gt 0 ]; then  trap_debug_short $1;return; fi    
        if [ "$2" != "$3" ] ; then  return;        fi
        STOP=1  
        trap_debug_short $1
}
function trap_debug_short() {      
    if [ "$TRAPOFF" -gt 0 ]; then  return; fi 
    CMD="";LASTLINE=($1-1)            # argument 1: last line of error occurence
    if [ ${FIRST} -lt 1 ]; then  FIRST=1; trap_start; fi  
#   echo ">> LASTLINE -$LASTLINE-"  
#     echo ">> SOURCELINE -$SOURCELINE-"  
    AKTLINE=${SOURCELINE[$LASTLINE]}
#    echo $AKTLINE
    trap_while "debug:$1:${AKTLINE%\^*} "
}
function trap_help () {
    echo "usage: start trap_init first"
    echo "trap 'trap_exit_script ${LINENO} $?' EXIT"
    echo "trap 'set +x;trap_debug_long;set -x' DEBUG"
    echo "trap 'set +x;trap_debug_short ${LINENO} ;set +x' DEBUG"
    echo "trap 'set +x;trap_field_change ${LINENO} $name;set +x' DEBUG"
    echo "trap 'set +x;trap_at ${LINENO} 20;set +x' DEBUG"
    echo "trap_short"
    echo "trap_long"
    echo "trap_change \"name\""
}
function trap_init () {
        #declare -t OLD_VALUE=""
        #declare -t FIELD="OLD_VALUE"
        #declare -t EQUAL="EQUAL"
        #declare -i STOP=99999;STOP=99999
        #declare -i FIRST=0;FIRST=0
        #echo "trap_init $STOP $FIRST"
        script=$0;script=${script##*\\};
        exec 4< /dev/stdin
        export PS4='${script}+(${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
}
function trap_debug_long() { trap_while "cmd/enter"; }
function trap_debug_at() { trap_while "cmd/enter"; }
function trap_change() { FIELD=$1;trap  - debug;trap 'set +x;trap_field_change ${LINENO} ;set +x' DEBUG; }
function trap_long() { trap  - debug;trap 'set +x;trap_debug_long;set -x' DEBUG; }
function trap_short() {        trap  - debug; trap 'set +x;trap_debug_short ${LINENO};set +x' DEBUG; }
function func_is_digit () {
    test -z "${@//[0-9]}" && echo 0 || echo 1
}
function isdigit () { func_is_digit "$@"; }
function func_print_script() {
        end="never"
        start=""
        if [ $# -gt 2 ]; then end=$3; fi
        if [ $# -gt 1 ]; then end=$2; fi
        if [ $# -gt 0 ]; then start=$1; fi
        found=0
    while read line; do        
                if [ "${line:0:${#end}}" == "#end" ]; then        break; fi
                if [ "$found" -gt 0 ]; then echo "$line";continue; fi
                if [ "$start" == "" ]; then
                echo "start gefunden"  
                        found=1
                        continue;
                fi
                if [ "${line:0:${#start}}" == "${start}" ]; then found=1; fi  
        done < $0        
}
function log() {
	if [ $# -lt 1 ];then func_log " ";return;fi  
	stopit=0
	args=""
	for ((i=1;i<=$#;i++));do
	    if   [ "${!i}" == "logfile" ];  then    shift;logfile="${!i}";log_on=1;func_log " "
	    elif [ "${!i}" == "newfile" ];  then    shift;logfile="${!i}";log_on=1;[ -f "$logfile" ] && rm "$logfile"	     
	    elif [ "${!i}" == "new" ];      then    log_on=1;[ -f "$logfile" ] && rm "$logfile"
	    elif [ "${!i}" == "log_on" ];   then    log_on=1 
	    elif [ "${!i}" == "log_off" ];  then    log_on=0 
	    elif [ "${!i}" == "echo_on" ];  then    echo_on=1
	    elif [ "${!i}" == "echo_off" ]; then    echo_on=0 
	    elif [ "${!i}" == "start" ];    then    func_start 
	    elif [ "${!i}" == "stop" ];     then    stopit=1 
	    elif [ "${!i}" == "ende" ];     then    stopit=1 
	    elif [ "${!i}" == "end" ];      then    stopit=1 
	    else                                    args="$args${!i} " 
	    fi
	done
	if [ ${#args} -gt 0 ];then func_log "$args";fi  
	if [ $stopit  -gt 0 ];then func_end;        fi  
}
function func_log() {                
    if [ "$1" == "logfile" ];   then shift; logfile=$@; return;  fi
    if [ "$log_on" -gt  0 ];    then
       if [ "$logfile" == "" ]; then logfile="/root/uwelog.txt";fi
       echo -e "$@" >> $logfile
    fi  
    if [ "$echo_on" -gt  0 ];  then
       echo -e "$@"  
    fi    
#    if [ "$logfile" == "" ];  then
#       echo -e "$@"
#    else
#       echo -e "$@" >> $logfile
#    fi          
}
function func_start() {        
    info="$(date "+%Y-%m-%d %H:%M:%S")  $(hostname) $0: START\n"
    if [ "$logfile" == "" ] ; then logfile="/root/uwelog.txt";fi
    func_log $info
}
function func_end() {
    info=" \n$(date "+%Y-%m-%d %H:%M:%S")  $(hostname) $0: STOP\n"
    func_log $info
}
function func_date2stamp () {
    date --utc --date "$1" +%s
}

function func_stamp2date (){
    date --utc --date "1970-01-01 $1 sec" "+%Y-%m-%d %T"
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
#        set -x
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
function func_file2csv () {
        file="";d=",";d2=";";max="0";min="0";gap="";x=0
        while [ $# -gt 0 ] ;do
                if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
                        nparm=$(func_mygetopt $1)
                        shift; set -- $@ $nparm
                else
                        case "$1" in  
                                "--file"|"-f")           shift;file="$1";;
                                "--delimiter"|"-d")      shift;d="$1";;
                                "--min-changes"|"--min") shift;min="$1";;
                                "--max-changes"|"--max") shift;max="$1";;        
                                "--debug"|"-x")          set -x;x=1;;                        
                                "--help"|"-h")           func_help $FUNCNAME;return;;
                                [-]*)                      func_help $FUNCNAME "$1";return;;
                                *) file="$file$gap$1"
                                        gap=" "
                        esac
                        shift;
                fi        
        done
        if [ "$d" == "$d2" ] ; then d2=",";fi
        if [ $min -lt 1 ] && [ $max -lt 1 ] ; then
            cat "$file"   |
        tr -s " "     |
        trim          |
        tr " " "$d"            

    else
                ows  $file    |
                trim          |
                func_translate  -i " " -o "$d" -d "$d2" --max "$max" --min "$min"
        fi
        if [ "$x" -gt 0 ]; then set +x;fi
}
function file2csv () { func_file2csv "$@"; }
function func_csv2file () {  
  i=-1;d=",";oifs=$IFS;IFS=$d;od=" | ";dynamic=1;file="";h="";gap="";x=0
  while [ $# -gt 0 ] ;do
                if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
                        nparm=$(func_mygetopt $1)
                        shift; set -- $@ $nparm
                else
                        case "$1" in  
                                "--file"|"-f")            shift;file="$1";;
                                "--delimiter"|"-d")       shift;d="$1";;
                                "--title"|"-t")           shift;header="$1";;
                                "--dynamic"|"--dy")       shift;dynamic="$1";;
                                "--out-delimiter"|"--od") shift;od="$1";;        
                                "--debug"|"-x")           set -x;x=1;;
                                "--help"|"-h")            func_help $FUNCNAME;return;;
                                [-]*)                       func_help $FUNCNAME "$1";return;;
                                *) file="$file$gap$1"
                                        gap=" "
                        esac
                        shift;
                fi        
  done
  while read -r line;do                 # spaltenbreite ermitteln
     i=$(($i+1))
         if [ $i -eq 0 ]; then
            if [ "$header" == "" ]; then
                   header=$line
                else
                   dynamic=0
                fi
                occ=-1
                for col in $header; do
                  occ=$(($occ+1))
                  if [ $(isdigit "$col") -lt 1 ]; then
                     length=$col
                  else
             length="${#col}"
          fi                        
                  p[$occ]="$length"          
        done
                cols=$occ
         fi        
         occ=-1
         
         for col in $line; do
            if [ "$dynamic " -lt 1 ]; then break;fi
            occ=$(($occ+1))
                if [ "$cols" -lt "$occ" ]; then p[$occ]=0;fi
                if [ "${#col}" -gt "${p[$occ]}" ] ; then
                   p[$occ]="${#col}"          
        fi
         done        
  done         < $file
  while read -r line; do
     occ=-1;nline="";t="" #;set -x
         for col in $line; do
            occ=$(($occ+1))
                if [ $occ -gt $cols ]; then
                   length="${#col}"
                else
                   length="${p[$occ]}"
                fi  
        nline="$nline$t $(left "$length" $col)"
                t=$od
         done        
     echo "$nline"
  done        < $file
  IFS=$oifs
  if [ "$x" -gt 0 ]; then set +x;fi
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
function func_trim () {
        lead="1";tail="1";char=" ";line="";gap="";x=0
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
                                [-]*)                 func_help $FUNCNAME "$1";return;;
                                *) line="$line$gap$1"
                                        gap=" "
                        esac
                fi        
                shift;
        done
        oifs=$IFS
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
        line="";ql='"';qr='"';i=0;gap="";file="";x=0
    while [ $# -gt 0 ] ;do
                if [ "$(echo $1 | grep -e '^-[a-z].')" ]; then # zB -avcb
                        nparm=$(func_mygetopt $1)
                        shift; set -- $@ $nparm
                else
                        case "$1" in
                                "--quote-left"|"--ql"|"-l")    shift;ql="$1";;
                                "--quote-right"|"--qr"|"-r")   shift;qr="$1";;
                                "--quote-char"|"--qc"|"-c")    shift;ql="$1";qr="$1";;
                                "--text"|"-t")                 shift;line="$line$ql$1$qr";;
                                "--help"|"-h")                 func_help $FUNCNAME;return;;
                                "--debug"|"-x")                set -x;x=1;;
                                [-]*)                          func_help $FUNCNAME "$1";return;;
                                *)  if [ "$file" == "" ]; then file=$1; fi
                                        line="$line$gap$ql$1$qr"
                                        gap=" "
                        esac
                        shift
                fi
    done
        if [ "$line" != "" ] && [ ! -f "$file" ] ; then echo "$line";return;fi
        if [ -f "$file" ] ;then
           cat "$file"
    else
           cat < /dev/stdin
    fi |
        while IFS=: read -r line;do
           echo $ql$line$qr
    done
        if [ "$x" -gt 0 ]; then set +x;fi        
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
#        set +x
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
	if [ "${#1}" -gt "${#2}" ] ; then
	   str="$1";pos="$2"
	else  
	   str="$2";pos="$1"
	fi    
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
trap_init
func_init
export -f log
export -f trap_long
export -f trap_at
export -f trap_change
export -f trap_equal
log_on=0
echo_on=0
#export logfile="/root/uwelog.txt"
export MYPATH="/home/uwe/my_scripts"
if [ -d "$MYPATH" ] && [ "" = "$(echo $PATH | grep $MYPATH)" ] ; then
   log "oldpath $PATH" 
   export PATH="$PATH:$MYPATH"
   log "newpath $PATH" 
fi
export PATHGIT="/media/uwe/fritzbox/USBDISK2-0-01/gitrepros"

alias mclear='printf "\033c"'
alias pfritz='cd "/media/uwe/fritzbox/USBDISK2-0-01"'
alias pscript='cd "/home/uwe/my_scripts"'

