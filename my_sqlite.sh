#!/bin/bash
# function: sqlite unterstuetzung
# author: Uwe Sülzle
# cdate: 2020-01-31

export PATHDB="/root/my_databases"
export DBMUSIC="$PATHDB/mymusic.sqlite"
export DBFILE="$PATHDB/myfiles.sqlite"
export DBBLOB="$PATHDB/myblobs.sqlite"
export DBAKT="$DBMUSIC"
export RSFILE="/root/my_databases/result/rsfile.csv"
export RSMAX=0 result="" RSNODATA=100
export RSLAST=0
       declare -a RS
export RS
function sql      () {
    local;set -o noglob;all=$true #;set -x
    if [ "$1" == "-" ];then shift;all=$false;fi
    if [ -f "$1" ];then   db="$1";shift;else db=$DBAKT;fi
#   if [ -f "$1" ];then file="$1";shift;else file=$RSFILE;fi
    if [ -f "$1" ];then file="$1";shift;else file="${RSFILE/.csv/$(date +"_%Y_%m_%d_%H_%M").csv}";fi
    local parm="$@"  #;echo file $file parm $parm
    [ "$1" == ".import" ] && parm='.nullvalue NULL'"\n"'.mode csv '"\n"'.separator ","'"\n$parm"
    if [ "${parm:0:1}" != "." ] && [ $(pos ";" "$parm") -lt 0 ];then parm="$parm"";";fi
    if [ "${parm:0:6}" == "insert" ]; then parm="$parm""select last_insert_rowid();";fi
    if [ "$all" == "$false" ]; then  echo -e "$parm" | sqlite3 "$db" ;return;fi
 #   set +x
    echo -e "$parm" | sqlite3 "$db"  | egrep -vi "(^\-\-\-|^run|^   )" | tee "$file"
    ix=-1;RS=()
	while read -r line; do ix=$((ix+1));RS[$ix]=$(echo $line | tr -d '\r');done < "$file"
	if [ $ix -lt 0 ];then RS[0]="$RSNODATA";fi
	RSMAX=${#RS[*]}
	RSLAST=$(($RSMAX-1)) 
	result=$(echo ${RS[$RSLAST]} | tr -d '\r')
	result=$(trim $result) 
	cp -f $file $RSFILE  
	set +o noglob
}
function sql_set_parm () {
	local file=~/.sqliterc;reset=$false
    if [ "$1" == "list" ]; then less $file;return;fi 
    if [ "$1" == "reset" ];then reset=$true;shift;set -- $@;fi 
    grep -ve "^$1" $file  > /tmp/.sqlrc
    cp -f /tmp/.sqlrc $file
    if [ "$reset" == "$false" ]; then echo "$@" >> $file;fi
}
sql_insert_blob () {
	fpath="$1";shift;if [ ! -f "$fpath" ];then echo "$fpath ist keine datei";return;fi
	refid=$1
	if [ "$(isdigit $refid)" == "$true" ];then shift; else refid="";fi
	fname=$(basename "$fpath");ftype="${fname##*\.}";finfo="$@" 
    str='insert into blobs    
        (blob_id_ref,blob_name,blob_path,blob_type,blob_info,blob_file)  
         values   
        ("'$refid'","'$fname'","'$fpath'","'$ftype'","'$finfo'",readfile("'$fpath'"))'
    sql $DBBLOB "$str;" > /dev/null
}
function sql_select_blob () {
	if   [ $# -eq 1 ];then str="where blob_id=$1" 
	elif [ $# -gt 1 ];then str="$@"
	else                   str=""
	fi 
    sqlstr="select blob_id,blob_id_ref,blob_name,quote(blob_path),blob_type,blob_info from blobs $str;" 
    sql $DBBLOB ".mode csv\n$sqlstr" > /dev/null 
    declare -a myrs;myrsmax=$RSMAX
    for ((i=1;i<$RSMAX;i++));do myrs[$i]=${RS[$i]};done
    for ((i=1;i<$myrsmax;i++));do
        IFS=',';arr=(${myrs[$i]});unset IFS 
        str="select writefile('/root/test/${arr[2]}',blob_file) from blobs where blob_id = ${arr[0]}"
        sql $DBBLOB "$str" # > /dev/null 
    done 
} 
sql_reload () {
#	file-verarbeitung:versuche automatisch import/replace mit und ohne header zu regeln
	local
	rfile="$1";shift;if [ ! -f $rfile ];then log "$file ist keine datei";return;fi
##1 parameter verarbeiten und tabellennamen ermitteln
	db="$1";if [ -f "$db" ];then shift; else db=$DBAKT;fi
	table=$@;nfile="/tmp/header.txt"
	line=$(head -n 1 "$rfile");#line=$(echo "$line" | tr -d '\r')
	IFS=",";declare -a header=($line) ;unset IFS
	zh=${#header[*]}
	#for arg in ${header[*]} ;do echo $zh header $arg;done
	#IFS=",";declare -a header=($(head -n 1 "$rfile"));unset IFS
	#zh=0;for arg in ${header[@]} ;do zh=$((zh+1));done;  ### !!!! funktioniert nicht: "${#header[$@]}"	
	#for ((ia=0;ia<${zh};ia++)) ;do echo "header >"${header[$ia]}"<";done;return
	if [ "$table" == "" ];then table=${header[0]%%\_*};fi
	if [ "$table" == "" ] || [ "$table" == "${header[0]}" ] || [ "-" == "${header[0]:0:1}" ];then 
		header=()
		table=${file[0]#*\_}
		table=${table%%\.*}
	fi
	if [ "$table" == "" ];then log kann keine tabelle ermitteln;return;fi
##2 import benotigt zwingend spalte mit id; beim insert wird vorhandener spaltenwert ersetzt 
	sql "select max(${table}_id) from $table" > /dev/null
	if [ "$(isdigit $result)" == "$false" ];then max=0;else max=$result;fi
	set +x
##3 tabellennamen emitteln.um header zu identifizieren, eventuell auch metadaten verarbeiten
##3 Zwischendatei erforderlich, da pipe subshell erzwingt und variablen nicht zurueckgegeben werden koennen	
	[ -f "$nfile" ] && rm "$nfile"	
	sql "-" $db ".mode csv\n.schema $table" |
    while read -r line; do
        log debug "schema " $line
        if [ $(pos '"' $line) -lt 0 ];then continue;fi
        if [ ${#line} -lt 1 ];        then continue;fi
        echo "${line%%\ *}" | tr -d '"' >> $nfile
    done 
    zs=0;while read -r line; do schema+=($line);zs=$(($zs+1));done < "$nfile";
##4 falls keine header-zeile vorhanden
    if [ "${#header[@]}" -lt 1 ];then 
        for arg in "${schema[$@]}";do header+=$arg;done
        zh=$zs
    fi
    set +x
##5 ohne id spalte wird eine mit incrementellem maxwert hinzugefuegt und nach import fertig    
    found=$false;for arg in ${header[@]}; do if [ "$arg" == "${table}_id" ]; then found=$true;break;fi;done
	if [ $found = $false ] && [ "$(($zh+1))" -eq "$zs" ]; then
	    func_cut -c ","   --il "1 ++${max}#${table}_id" "$rfile"  > $nfile
	    echo -e "delete from $table;" | sqlite3 "$db" # > /dev/null
	    sql ".mode csv\n.import $nfile $table"
		return
	fi  
##6 insert oder update. replace loescht und fuegt dann ein, was bei oreign_key unerwuenscht sein kann 
	for arg in ${#header[@]} ;do log debug "header >"$arg"<";done
	
    found=$false;declare -a cols;
    found=$false;for arg in ${schema[@]}; do if [ "$arg" == "${header[0]}" ]; then found=$true;fi;done
	unset IFS
	while read -r line;do
	#	trap 'set +x;trap_debug $LINENO;set +x' debug
	#   echo ">$line<"
	    line=$(echo $line | tr -d '\r') ## carriage return entfernen
	    log debug ">$line<"
	    if [ "$found" == "$true" ];     then found=$false;continue;fi
	    if [ "${line:0:5}" == "     " ];then continue;fi
	    if [ "${line:0:1}" == "-" ];    then continue;fi
	    if [ "$found"      == "$true" ];then found=$false;continue;fi  ### falls header vorhanden
	    uline="update $table set "
	    lline="insert into $table ("
	    value="";del="";key=""
	    IFS=",";cols=($line) ;unset IFS
	    for arg in ${cols[@]} ;do log debug "cols >"$arg"<";done
	  # for ((ia=0;ia<${#cols[$@]};ia++)) ;do log debug "cols2 >"${cols[$ia]}"<";done ## ?? geht nicht
        set +x
	    for ((ix1=0;ix1<$zh;ix1++));do
	        val="$(trim_simple ${cols[$ix1]})"
	        if [ "${header[$ix1]}" == "${table}_id" ]; then
	           key="${cols[$ix1]}" ## ; echo key $key
	           if [ "$(isdigit $key)" == "$false" ];then max=$(($max+1)) ;key=$max  ;fi
	           sql "select ${table}_id from $table where ${table}_id = $key;" > /dev/null
	           if [ "$result" == "$RSNODATA" ]; then insert=$true;else insert=$false;fi
	           log debug key $key result $result insert $insert
	        else
	           uline="$uline$del${header[$ix1]}='$val'"
	           lline="$lline$del${header[$ix1]}"
	           value="$value$del'${val}'"
	           del=","
	        fi   
	    done
	    if [ "$insert" == "$false" ]; then
	        log  debug "$uline where ${table}_id = $key;" 
	        sql "$uline where ${table}_id = $key;" 
	    else    
	        log  debug "${lline}) values (${value}) ;"
	        sql "${lline}) values (${value}) ;"
	    fi
	done  < "$rfile"
	unset IFS  
}