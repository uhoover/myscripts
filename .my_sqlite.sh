#!/bin/bash
# function: sqlite unterstuetzung
# author: Uwe Sülzle
# cdate: 2020-01-31

export PATHDB="/root/my_databases"
export DBMUSIC="$PATHDB/mymusic.sqlite"
#alias  sql='sqlite3 "$DBMUSIC'

function sqlmusic () {
     local
     set -o noglob
     sql "$DBMUSIC" $@
}
function sql () {
    local
    set -o noglob
    db="$1";shift
    parm="$@"
    if [ "$1" == ".import" ];then
       parm='.nullvalue "info"'"\n"'.mode csv '"\n"'.separator ","'"\n$parm"
    fi       
#   echo -e "$parm" 
    echo -e "$parm" | sqlite3 "$db"  
}

function sql_read_all() {
#	
    set -o noglob 
	db="$@"; if [ "$db" == "" ];then db="$DBMUSIC";fi            
    tabs=$(sqlite3 $db '.tables') 
    for tab in $tabs;do          
        sqlmusic "select * from  $tab ;" 
    done  
}
function sql_id3tool_to_file() {
     file=$@
     if [ ${#file} -lt 1 ]; then file="load_genre.csv";fi
#### tail +2 eliminiert 1 zeile mit header
     id3tool -l | grep -v '\-\-' | cut -d "|" -f1 | trim | tail +2 > $file
}
function sql_add_key() {
#	 set -x
     log log_on echo_off  # filename wird mit echo zurueckgegeben, andere meldungen ins log
     if [ -f "$1" ]; then 
        file="$1"
        shift
     else
        log "Parameter unstimmig: $1 ist kein file \nusage file.csv [db] [tablename] "
        echo ""
        return
     fi  
     if [ $# -gt 1 ]; then 
        db="$1"
        shift
     else
        db="$DBMUSIC"    
     fi
     if [ $# -gt 0 ]; then 
        table="$1"
        shift
     fi
     if [ $# -gt 0 ]; then 
         log "Parameter unstimmig: $@\nusage file.csv [db] [tablename] "
         echo ""
         return
     fi
     log "add key $file $db $table"
     max=0
#    uebwepruefung auf spalte mit autoincrement und ermittlung max-wert, falls tabelle bekannt  
     if [ ${#table} -gt 0 ];then
	     line=$(eval "sqlite3 $db '.schema $table'" | grep -i "auto" | grep -i "${table}_id")
		 if [ ${#line} -lt 1 ];then echo "$table with ${table}_id in $table not found";return;fi
		 max=$(eval "sqlite3 $db 'select max(${table}_id) from $table;'")
		 set -- $max 
         max=${!#} ## letztes argument	
#        tail -n 1 letzter satz der ausgabe; mit while read -r hat es nicht funktioniert
#        erg=$(eval "sqlite3 $db 'select * from $table where ${table}_id = $max;'" | tail -n 1)
#        log "max(${table}_id)=$max record=$erg"
     fi	
     ix=$max 
     basename="${file%%\.*}" 
     extension="${file##*\.}" 
     if [ "${#extension}" -gt 0 ];then extension=".""$extension";fi
     newfile="${basename}_add_key$extension"
     log "newfile $newfile"
     [ -f "$newfile" ] && rm "$newfile" 
	 while read -r line;do
	     if [ "${#line}"   -lt  1 ]  ;then continue;fi
	     if [ "${line:0:1}" ==  "-" ];then continue;fi
         ix=$(($ix+1))
         echo "$ix,$line" >> "$newfile"
     done  < "$file"
     echo "$newfile"
}
export -f sqlmusic
export -f sql