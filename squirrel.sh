#!/bin/bash -e
#!/usr/local/bin/gtkdialog -e
# author uwe suelzle
# created 202?-??-??
# function: 
#
 source /home/uwe/my_scripts/my_functions.sh
 trap xexit EXIT
# set -e  # bei fehler sprung nach xexit
	folder="$(basename $0)";mypath="$HOME/.${folder%%\.*}"; [ ! -d $mypath ] && mkdir -p $mypath
	cfile="$mypath/configrc"
	efile="$mypath/sqlerror.txt"
	tableinfo="$mypath/tableinfo.txt"
	valuefile="$mypath/value.txt"
	if [ ! -f "$cfile" ]; then
	    echo "searchpath='/home/uwe/my_databases/'" > $cfile
	fi
	source $cfile
#
function _amain () {
	if [ "$#" -gt "0" ] && [ -f "$1" ];then 
		mydb=$1;shift
	else 
		mydb=$(zenity --file-selection --filename=$searchpath)
	fi	
	if [ "$mydb" = "" ];then log "bye bye"  ;exit  ;fi
	zargs=$#
	while true;do 
		if [ "$#" -lt "1" ];then 
			tb=$(zenity  --width=200 --height=400 --list --multiple --column="table" $(echo .tables | sqlite3 $mydb))
			where=""
		else
			tb=$1;shift
			where="$*"
		fi
		if [ "$tb" = "" ]; then break;fi
		show_table "$tb" "$where"
		if [ "$zargs" -gt "0" ]; then break;fi
	done
}
function _amainsave () {
	if [ "$#" -gt "0" ] && [ -f "$1" ];then 
		mydb=$1;shift
	else 
		mydb=$(zenity --file-selection --filename=$searchpath)
	fi	
	if [ "$mydb" = "" ];then log "bye bye"  ;exit  ;fi
	while true;do 
		if [ "$#" -gt "0" ];then erg=$1;shift;else erg="";fi
		if [ "$#" -gt "0" ];then where="$1";set --;else where="";erg="";fi
		if [ "$erg" = "" ]; then
			erg=$(zenity  --width=200 --height=400 --list --multiple --column="table" $(echo .tables | sqlite3 $mydb))
		fi
		if [ "$erg" = "" ]; then break;fi
		show_table $erg "$where"
	done
}
function read_table () {
	log "read-table $*"
	db=$1;shift;tb=$1;shift;where="$*"
	log "db >$db $tb< where >$where< "
	sql_execute $db ".separator |\n.header off\nselect * from $tb $where;"
#	sql_execute $db ".separator |\n.header off\nselect genre_id,genre_name  from genre;"
#	echo -e ".separator |\n.header off\nselect genre_id,genre_name  from genre;" | sqlite3 $db	
}
function tb_meta_info () {
	local db=$1;shift;local tb=$@;local del="";local del2="";local del3="";local line=""
	TNAME="" ;TTYPE="" ;TNOTN="" ;TDFLT="" ;TPKEY="";TLINE="";TSELECT="";local ip=-1;local pk="-"
	sql_execute "$db" ".header off\nPRAGMA table_info($tb);"   > $tableinfo
	while read -r line;do
		IFS=',';arr=($line);unset IFS;ip=$(($ip+1))
		TNAME=$TNAME$del"${arr[1]}"	
		TTYPE=$TTYPE$del"${arr[2]}"	
		TNOTN=$TNOTN$del"${arr[3]}"	
		TDFLT=$TDFLT$del"${arr[4]}"	
		TPKEY=$TPKEY$del"${arr[5]}"
		TLINE=$TLINE$del2"${arr[2]},${arr[3]},${arr[4]},${arr[5]}"
		if [ "${arr[5]}" == "1" ];then
			PRIMKEY="${arr[1]}";export ID=$ip;  
		else
			TSELECT=$TSELECT$del3$"${arr[1]}";del3=","	
		fi
		del=",";del2='|'
	done < $tableinfo
	echo "$PRIMKEY@ID@$TNAME@$TTYPE@$TNOTN@$TDFLT@$TPKEY@$TLINE@$TSELECT"  
}
function gui_rc_entrys_hbox () {
	log $@
	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		echo '		<hbox>'  
		echo '			<text width-chars="20" justify="3"><label>'" "${name[$ia]}'</label></text>'  
		echo '			<entry width_chars="30"><variable>entry'$ia'</variable><input>tb_get_meta_val '$ia'</input></entry>' 
		echo '			<text width-chars="25" justify="3"><label>'${meta[$ia]}'</label></text>'  
		echo '		</hbox>' 
	done
}
function tb_get_meta_val   () {
	nr=$1 #;nr2=$(($nr+1))
	str=$(head -n $(($nr+1)) "$valuefile" | tail -n 1)
	str="${str#*\= }"
	IFS="|";arrmeta=($TLINE);IFS=",";meta=(${arrmeta[$nr]});unset IFS
	if [ "$str" != "" ] && [ "$1" ==  "$ID" ];then  echo "$str" > "$idfile";fi
	if [ "$str" == "" ] && [ "${meta[3]}" == "1" ]; then  str=$(cat "$idfile");fi 
	if [ "$str" == "" ];then
	   if   [ "${meta[2]}" != "" ]; then  str="${meta[2]}"  
	   elif [ "${meta[1]}" != "0" ];then  str="="  
	   else                               str="NULL"
	   fi
	fi   
    echo "$str" | tr -d '\r'
} 
function gui_rc_entrys_action_refresh () {
	log $@
	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		echo '				<action type="refresh">entry'$ia'</action>'  
	done
	echo '				<action type="refresh">entryp</action>'
}
function gui_rc_entrys_variable_list () {
	log $@
	PRIMKEY="$1";shift;ID="$1";shift;IFS=",";name=($1);unset IFS;shift 
	local line=""
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
		line=$line' "$entry'"$ia"'"'
	done
	echo $line
}
function gui_rc_get_dialog () {
	log debug $@
	row="$1";shift;tb="$1";shift;db="$1";shift;PRIMKEY="$1";shift;ID="$1";shift
	TNAMES="$1";shift;TLINE="$1";shift;TNOTN="$1";shift;TSELECT="$1"
	echo '
<vbox>
	<vbox>
		<hbox>
			<text width-chars="20" justify="3"><label>'"$PRIMKEY"' (PK)</label></text>
			<entry width_chars="30"><variable>entryp</variable><input>tb_get_meta_val '"$ID"'</input></entry>
			<text width-chars="25" justify="3"><label>type,null,default,primkey</label></text>
		</hbox>
	</vbox>
	<frame>
		<vbox>
			'$(gui_rc_entrys_hbox $PRIMKEY $ID $TNAMES $TLINE)'
		</vbox>
	</frame>
	<hbox>
		<button><label>back</label>
			<action>$0 sql_rc_read lt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>next</label>
			<action>$0 sql_rc_read gt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>read</label>
			<action>$0 sql_rc_read eq '$PRIMKEY' $entryp</action>
			<action type="enable">BUTTONAENDERN</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>insert</label>
			<action>$0 sql_rc_update_insert insert $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>update</label><variable>BUTTONUPDATE</variable>
			<action>$0 sql_rc_update_insert update $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
		</button>
		<button><label>delete</label>
			<action>$0 sql_rc_delete '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>clear</label>
			<action type="enable">BUTTONUPDATE</action>
			<action>$0 sql_rc_clear '"$(gui_rc_entrys_variable_list $PRIMKEY $ID $TNAMES $TLINE)"'</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>refresh</label>
			<variable>BUTTONREFRESH</variable>
			<action type="enable">BUTTONAENDERN</action>
			<action>cp -f '"$valuefile.bak" "$valuefile"'</action>
			 '"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button ok></button><button cancel></button>
	</hbox>
</vbox>' 	
}
function row_ctrl () {
	if [ "$1" = "log" ]; then
	    shift;logfile="$1";shift 
	    log logfile $logfile $*
	fi
	db=$1;shift;tb=$1;shift;row=$1
	idfile="$mypath/id_$tb.txt"
	efile="$mypath/sqlerror_$tb.txt"
	tableinfo="$mypath/tableinfo_$tb.txt"
	valuefile="$mypath/value_$tb.txt"
	row_change_xml="$mypath/change_row_${tb}.xml"
	IFS="@";marray=($(tb_meta_info "$db" "$tb"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}
	log "primkey 	$PRIMKEY"
	log "id		 	$ID"
	log "tname	 	$TNAME"
	log "ttype	 	$TTYPE"
	log "tnotn	 	$TNOTN"
	log "tdflt	 	$TDFLT"
	log "tline	 	$TLINE"
	log "tselect	$TSELECT"
	if [ "$TNAME" == "" ];then return  ;fi
		if [ "$row" == "insert" ]; then
		echo "" > "$valuefile" 
	else
		sql_rc_read eq $PRIMKEY $row > "$valuefile"
	fi
	gui_rc_get_dialog $row $tb $db $PRIMKEY $ID $TNAME $TLINE $TNOTN $TSELECT > "$row_change_xml"
#	gtkdialog -f "$row_change_xml" & 
}
function show_table () {
 	tb=$1;shift;where="$*" 
    label=$(echo "PRAGMA table_info($tb)" | sqlite3 $mydb | cut -d ',' -f2 | fmt | tr ' ' '|')
    key=$(echo "PRAGMA table_info($tb)" | sqlite3 $mydb  |  sort -t ','  -k 4 | tail -n 1 | cut -d',' -f2)
    keycol=$(echo "PRAGMA table_info($tb)" | sqlite3 $mydb  |  sort -t ','  -k 4 | tail -n 1 | cut -d',' -f1)
    log "tb: $tb label: $label key: $key keycol: $keycol where: $where"
	export MAIN_DIALOG='
	    <window title="'"$mydb $tb $key $keycol"'"> 
	    <vbox>
		<tree headers_visible="true" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="0">
			<label>'"$label"'</label>
			<height>500</height><width>600</width> 
			<variable>TREE'$tb'</variable>
			<input>'"$0"' read_table '"$mydb"' '"$tb"' "'"$where"'"</input>
			<action>'"$0"' row_ctrl log '"$logfile $mydb"' '"$tb"' $TREE'"$tb"'</action>
		</tree>
		</vbox>
		</window>'
    echo $MAIN_DIALOG
	gtkdialog --program=MAIN_DIALOG	
	return
	IFS="|";for tb in $*;do echo $tb;done;unset IFS
}
function sql_rc_read () {
	log debug $@
	local mode=$1;shift;PRIMKEY=$1;shift;row=$1;
	if [ "$row" == "NULL" ] || [ "$row" == "" ] || [ "$row" == "=" ];then row=$(cat $idfile);fi
	if [ "$mode" == "eq" ];then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" == "lt" ];then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" == "gt" ];then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	erg=$(sql_execute "$db" ".mode line\n.header off\nselect * from $tb $where")
	log debug $mode $row "erg = $erg"
	if [ "$erg" == "" ];then gxmessage -timeout 4 "keine id $mode $row gefunden"  ;return  ;fi
    echo -e "$erg" > "$valuefile"
    echo $row  > $idfile
    cp -f "$valuefile" "$valuefile.bak"
}
function sql_execute () {
	set -o noglob
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db" 2> $efile | tr -d '\r' 
	error=$(<$efile)
	if [ "$error" != "" ];then log - "sql_execute $error" $db $stmt;fi
}
function xexit() {
	retcode=0 
  	if [ "$cmd" = "" ]; then log stop;fi
}
#	if [ "$#" -lt  "1" ];then set -- "$DBMUSIC" "komponist" "where komponist_id = 17" ;fi
#	if [ "$#" -lt  "1" ];then set -- "$DBMUSIC" "genre"   ;fi
 	if [ "$#" -lt  "1" ];then set -- "$DBMUSIC"    ;fi
    cmd=""
	case "$1" in
		"read_table") cmd="$*" ;;
		"row_ctrl") cmd="$*" ;;
		"log") cmd="$*" ;;
	esac
	if [ "$cmd" != "" ];then log file;$cmd;exit;fi
	log file start tlog
	_amain "$@"

