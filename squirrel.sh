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
	script=$(readlink -f $0) 
	tableinfo="$mypath/tableinfo.txt"
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
#		show_table "$mydb" "$tb" "$where"  
		$script func show_table "$mydb" "$tb" "$where" &
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
	sql_execute $db ".separator |\n.header off\nselect * from $tb $where;"
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
	log gui_rc_entrys_hbox $@
	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		echo '		<hbox>'  
		echo '			<text width-chars="20" justify="3"><label>'" "${name[$ia]}'</label></text>'  
		echo '			<entry width_chars="30"><variable>entry'$ia'</variable><input>'"$script"' func tb_get_meta_val '$ia'</input></entry>' 
		echo '			<text width-chars="25" justify="3"><label>'${meta[$ia]}'</label></text>'  
		echo '		</hbox>' 
	done
}
function tb_get_meta_val () {
	log debug tb_get_meta_val $*
	nr=$1  
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
	log debug gui_rc_entrys_action_refresh $@
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
	local line="";del=" "
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
#		line=$line'"'$del'""$entry'"$ia"'"';del="|"
		line=$line$del'$entry'$ia;del="|"
	done
	echo "\"$line\""
}
function gui_rc_entrys_variable_list_save () {
	log debug gui_rc_entrys_variable_list $@
	PRIMKEY="$1";shift;ID="$1";shift;IFS=",";name=($1);unset IFS;shift 
	local line="";del=""
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
		line=$line"$del"' "$entry'"$ia"'"'
#		del="|"
		log vlist "$line"
	done
	echo "$line"
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
			<entry width_chars="30"><variable>entryp</variable><input>'"$script"' func tb_get_meta_val '"$ID"'</input></entry>
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
			<action>'"$script"' func sql_rc_read lt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>next</label>
			<action>'"$script"' func sql_rc_read gt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>read</label>
			<action>'"$script"' func sql_rc_read eq '$PRIMKEY' $entryp</action>
			<action type="enable">BUTTONAENDERN</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>insert</label>
			<action>'"$script"' func sql_rc_update_insert insert $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>update</label><variable>BUTTONUPDATE</variable>
			<action>'"$script"' func sql_rc_update_insert update $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
		</button>
		<button><label>delete</label>
			<action>'"$script"' func sql_rc_delete '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>clear</label>
			<action type="enable">BUTTONUPDATE</action>
			<action>'"$script"' func sql_rc_clear '"$(gui_rc_entrys_variable_list $PRIMKEY $ID $TNAMES $TLINE)"'</action>
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
	log row_ctrl $*	 
	export db=$1;shift;export tb=$1;shift;export row=$1
	export idfile="$mypath/id_$tb.txt"
	efile="$mypath/sqlerror_$tb.txt"
	tableinfo="$mypath/tableinfo_$tb.txt"
	export valuefile="$mypath/value_$tb.txt"
	valuefilebak="$mypath/value_${tb}.txt.bak"
	row_change_xml="$mypath/change_row_${tb}.xml"
	IFS="@";marray=($(tb_meta_info "$db" "$tb"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}
	log debug "primkey 	$PRIMKEY"
	log debug "id		 	$ID"
	log debug "tname	 	$TNAME"
	log debug "ttype	 	$TTYPE"
	log debug "tnotn	 	$TNOTN"
	log debug "tdflt	 	$TDFLT"
	log debug "tline	 	$TLINE"
	log debug "tselect	$TSELECT"
	if [ "$TNAME" == "" ];then return  ;fi
		if [ "$row" == "insert" ]; then
		echo "" > "$valuefile" 
	else
		sql_rc_read eq $PRIMKEY $row > "$valuefile"
	fi
	gui_rc_get_dialog $row $tb $db $PRIMKEY $ID $TNAME $TLINE $TNOTN $TSELECT > "$row_change_xml"
	gtkdialog -f "$row_change_xml" & 
}
function show_table () {
	log show_table $@
 	mydb=$1;shift;tb=$1;shift;where="$*" 
 	IFS="@";marray=($(tb_meta_info "$mydb" "$tb"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}
    label=$(echo $TNAME | tr '_,' '-|')
    log   "tb: $tb label: $label key: $PRIMKEY keycol: $ID where: $where"
	export MAIN_DIALOG='
	    <window title="'"$mydb $tb $PRIMKEY $ID"'"> 
	    <vbox>
		<tree headers_visible="true" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="0">
			<label>'"$label"'</label>
			<height>500</height><width>600</width> 
			<variable>TREE'$tb'</variable>
			<input>'"$script"' func read_table '"$mydb"' '"$tb"' "'"$where"'"</input>
			<action>'"$script"' func row_ctrl '"$mydb"' '"$tb"' $TREE'"$tb"'</action>
		</tree>
		</vbox>
		</window>'
#   log $MAIN_DIALOG
#	gtkdialog --program=MAIN_DIALOG;return	
	tb_xml="$mypath/tb_${tb}.xml"
	echo -e $MAIN_DIALOG > "$tb_xml"
	gtkdialog -f "$tb_xml"	
	return
	IFS="|";for tb in $*;do echo $tb;done;unset IFS
}
function show_table_del () {
	log show_table $@
 	mydb=$1;shift;tb=$1;shift;where="$*" 
 	IFS="@";marray=($(tb_meta_info "$mydb" "$tb"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}
    label=$(echo "PRAGMA table_info($tb)" | sqlite3 $mydb | cut -d ',' -f2 | fmt | tr ' _' '|-')
    key=$(echo "PRAGMA table_info($tb)" | sqlite3 $mydb  |  sort -t ','  -k 4 | tail -n 1 | cut -d',' -f2)
    keycol=$(echo "PRAGMA table_info($tb)" | sqlite3 $mydb  |  sort -t ','  -k 4 | tail -n 1 | cut -d',' -f1)
    log   "tb: $tb label: $label key: $key keycol: $keycol where: $where"
	export MAIN_DIALOG='
	    <window title="'"$mydb $tb $key $keycol"'"> 
	    <vbox>
		<tree headers_visible="true" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="0">
			<label>'"$label"'</label>
			<height>500</height><width>600</width> 
			<variable>TREE'$tb'</variable>
			<input>'"$script"' func read_table '"$mydb"' '"$tb"' "'"$where"'"</input>
			<action>'"$script"' func row_ctrl '"$mydb"' '"$tb"' $TREE'"$tb"'</action>
		</tree>
		</vbox>
		</window>'
    log $MAIN_DIALOG
#	gtkdialog --program=MAIN_DIALOG;return	
	tb_xml="$mypath/tb_${tb}.xml"
	echo -e $MAIN_DIALOG > "$tb_xml"
	gtkdialog -f "$tb_xml"	
	return
	IFS="|";for tb in $*;do echo $tb;done;unset IFS
}
function sql_rc_read () {
	log sql_rc_read $@ "db=$db tb=$tb"
	local mode=$1;shift;PRIMKEY=$1;shift;row=$1;
	if [ "$row" == "NULL" ] || [ "$row" == "" ] || [ "$row" == "=" ];then row=$(cat $idfile);fi
	if [ "$mode" == "eq" ];then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" == "lt" ];then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" == "gt" ];then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	erg=$(sql_execute "$db" ".mode line\n.header off\nselect * from $tb $where")
	log debug $mode $row "erg = $erg"
	if [ "$erg" == "" ];then setmsg "keine id $mode $row gefunden"  ;return  ;fi
    echo -e "$erg" > "$valuefile"
    echo $row  > $idfile
    cp -f "$valuefile" "$valuefile.bak"
}
function sql_rc_update_insert () {
	log sql_rc_update_insert_neu "$@"
	mode=$1;shift;ID="$1";shift;PRIMKEY="$1";shift;TSELECT="$1";shift;TNOTN="$1";shift;value=$*
	z=${#value};if [ "${value:(($z-1)):1}" == "|" ];then value=$value" ";fi
	IFS=",";names=($TSELECT);nulls=($TNOTN)
	IFS="|";values=($value)
	unset IFS
	if [ "${#names[@]}" -ne "${#values[@]}" ];then  
	    setmsg "abbruch! fields: ${#names[@]} values ${#values[@]}"
	    log "$(declare -p names values)"
	    return  
	fi
	local ia=0;local iline="";local uline="";local del="";local val=""
	for ((ia=0;ia<${#names[@]};ia++)) ;do
		log debug field "${names[$ia]}" value "${values[$ia]}"
        val="${values[$ia]}" 
	    if [ "$val" == "" ] && [ "$nulls[$ia]" != "1" ];    then  val='null';fi
		uline="$uline$del${names[$ia]} = '$val'"
		iline="$iline$del'$val'";
		del=","
	done
	if [ "$mode" == "insert" ];then
		stmt="insert into $tb ($TSELECT) values ($iline);"
	else
		stmt="update $tb  set $uline where $PRIMKEY = $ID ;"
	fi
	log debug uline $uline;log debug iline $iline;log debug stmt  $stmt
	erg=$(sql_execute "$db" "$stmt" )
	if [ "$erg" != "" ];then
		setmsg  "abbruch rc = $erg : $stmt $db"
		return
	else
	    setmsg "$mode erfolgreich"
	fi
	if [ "$mode" == "insert" ];then
		row=$(sql_execute "$db" ".header off\nselect max($PRIMKEY) from $tb;" );
		sql_rc_read eq $PRIMKEY $row
	fi
}
function sql_execute () {
	set -o noglob
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db" 2> $efile | tr -d '\r' 
	error=$(<$efile)
	if [ "$error" != "" ];then log - "sql_execute $error" $db $stmt;fi
	echo $error | tr -d '\r' 
}
function setmsg () {
	log setmsg $*
	zenity --notification --text="$*"_
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
		"func") shift;cmd="$*" ;;
		"read_table") cmd="$*" ;;
		"row_ctrl") cmd="$*" ;;
		"log") cmd="$*" ;;
	esac
	if [ "$cmd" != "" ];then log file;$cmd;exit;fi
	log file start tlog
	_amain "$@"

