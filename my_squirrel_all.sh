#!/bin/bash
#!/bin/bash -e
#!/usr/local/bin/gtkdialog -e
# author uwe suelzle
# created 202?-??-??
# function: 
#
 source /home/uwe/my_scripts/my_functions.sh
 trap axit EXIT
function axit() {
	retcode=0 
  	if [ "$cmd" = "" ]; then log stop;fi
} 
#
 	folder="$(basename $0)";path="$HOME/.${folder%%\.*}"
	tpath="$path/tmp"  
	[ ! -d "$path" ]  && mkdir "$path"  
	[ ! -d "$path/tmp" ] && mkdir "$path/tmp"  
	x_configfile="$path/.configrc" 
	if [ ! -f "$x_configfile" ];then echo "# defaultwerte etc:" > "$x_configfile" ;fi  
 source $x_configfile
	parmtb="parmneu" true=0 false=1
	lfile="/home/uwe/log/gtkdialog.txt" 
    tmpmodus=$false;master="/home/uwe/my_databases/parmtb.sqlite"	
    if [ "$tmpmodus" == "$true" ];then	  
	    [ ! -f "$path/tmp/$(basename $master)" ] && cp "$master" "$path/tmp"
	    master="$path/tmp/parmtb.sqlite" 
	fi
	script=$(readlink -f $0)   
	parmdb="$master" 
	changexml="$path/tmp/change.xml" 
	idfile="$path/tmp/id.txt" 
	efile="$path/tmp/error.txt" 
	tmpf="$path/tmp/dialogtmp.txt"
	tableinfo="$path/tmp/tableinfo.txt"  
	valuefile="$path/tmp/value.txt"
#
function gui_rc_entrys_hbox () {
	log $@
	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		echo '		<hbox>'  
		echo '			<text width-chars="20" justify="3"><label>'" "${name[$ia]}'</label></text>'  
		echo '			<entry width_chars="30"><variable>entry'$ia'</variable><input>'$script' func tb_get_meta_val '$ia'</input></entry>' 
		echo '			<text width-chars="25" justify="3"><label>'${meta[$ia]}'</label></text>'  
		echo '		</hbox>' 
	done
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
	local line="";del=" "
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
		line=$line$del'$entry'$ia;del="|"
	done
	echo "\"$line\""
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
			<entry width_chars="30"><variable>entryp</variable><input>'$script' func tb_get_meta_val '"$ID"'</input></entry>
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
			<action>'$script' func sql_rc_read lt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>next</label>
			<action>'$script' func sql_rc_read gt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>read</label>
			<action>'$script' func sql_rc_read eq '$PRIMKEY' $entryp</action>
			<action type="enable">BUTTONAENDERN</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>insert</label>
			<action>'$script' func sql_rc_update_insert insert $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>update</label><variable>BUTTONUPDATE</variable>
			<action>'$script' func sql_rc_update_insert update $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
		</button>
		<button><label>delete</label>
			<action>'$script' func sql_rc_delete '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>clear</label>
			<action type="enable">BUTTONUPDATE</action>
			<action>'$script' func sql_rc_clear '"$(gui_rc_entrys_variable_list $PRIMKEY $ID $TNAMES $TLINE)"'</action>
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
</vbox>' > "$row_change_xml"	
}
function gui_tb_get_default () {
#	log $* #;read -p weiter
	if [ "$*" = "" ] || [ "$*" = "-" ] || [ "$*" = '""' ];then echo "";return  ;fi
	echo "<default>$*</default>"
}
function gui_tb_get_dialog () {
	log debug $@
	tb="$1";shift;dfltdb="$1";shift;dflttb=$1;shift;visibleDB=$1;shift;visibleTB="$1";shift;dfltwhere="$*" 
	if [ "$dfltdb" = "-" ];then str="";else str="$dfltdb";fi;eval 'export CBOXDBSEL'$tb'='$str 
	if [ "$dflttb" = "-" ];then dflttb=$(x_get_tables $dfltdb "batch"| head -n1) ;fi; 
	if [ "$dflttb" = "-" ];then str="";else str="$dflttb";fi;eval 'export CBOXENTRY'$tb'='$str 
	if [ "$dfltwhere" = "-" ];then str="";else str="$dfltwhere";fi;eval 'export CBOXWHERE'$tb'="'$str'"' 
#	errmsg "gui_tb_get_dialog 1 dfltwhere $dfltwhere string $str export" $(eval 'echo $CBOXWHERE'$tb);
	if [ "$tb" = "$dflttb" ]; then
		IFS="@";marray=($(tb_meta_info "$dflttb" "$dfltdb"));unset IFS
		pk="${marray[0]}"
		label=$(echo "${marray[2]}"| tr ',' '|')
		visibleHD="true";off="on"
	else
	    if [ "$dfltlabel" == "" ]; then
		    str="_____";del="";dfltlabel=""
		    for ((ia=1;ia<11;ia++)) ;do dfltlabel=$dfltlabel$del$str$ia$str;del="|";done
		fi 
		label=$dfltlabel
		visibleHD="false";off="off"
	fi
	set +x
	if [ "$dflttb" != "-" ];
		then off="off" #;visibleTB="true" ;visibleDB="false"
		else off="on"  #;visibleTB="false";visibleDB="true"
	fi  
	echo  '
	<vbox>
		<tree headers_visible="'$visibleHD'" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="0">
			<label>'"$label"'</label>
			<height>500</height><width>600</width> 
			<variable>TREE'$tb'</variable>
			<input>'$script' func sql_read_table '$off' '$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb' "$CBOXWHERE'$tb'"</input>
			<action>'$script' func sql_rc_ctrl $TREE'$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</action>
			<action type="enable">BUTTONAENDERN'$tb'</action>
		</tree>
		<frame click = selection >
			<hbox homogenoues="true">
			    <hbox visible="'$visibleDB'">
					<entry width-chars="30" accept="file">
						'$(gui_tb_get_default $dfltdb)'
						<variable>CBOXDBSEL'$tb'</variable>
					</entry>
					<button>
						<input file stock="gtk-open"></input>
						<variable>FILESEL'$tb'</variable>
						<action type="fileselect">CBOXDBSEL'$tb'</action>
						<action type="refresh">CBOXENTRY'$tb'</action>
					</button>
				</hbox>
				<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false" visible="'$visibleTB'">
					<variable>CBOXENTRY'$tb'</variable>
					'$(gui_tb_get_default $dflttb)'
					<sensitive>true</sensitive>
					<input>'$script' func x_get_tables $CBOXDBSEL'$tb' '$tb'</input>
					<action type="clear">TREE'$tb'</action>
					<action type="refresh">CBOXWHERE'$tb'</action>
					<action type="refresh">TREE'$tb'</action>
				</comboboxtext>
			</hbox>
			<comboboxentry auto-refresh="true">
				<variable>CBOXWHERE'$tb'</variable>
				'$(gui_tb_get_default $dfltwhere)'
				<input>'$script' func sql_get_where $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</input>
				<action signal="activate" type="refresh">TREE'$tb'</action>
			</comboboxentry>
		</frame>
		<hbox>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$tb'</variable>
				<sensitive>true</sensitive> 
				<action>'$script' func sql_rc_ctrl insert $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</action>
			</button>
			<button visible="false">
				<label>aendern</label>
				<variable>BUTTONAENDERN'$tb'</variable>
				<sensitive>false</sensitive> 
				<action>$(which rowchange) $TREE'$tb' $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</action>
			</button>
			<button>
				<label>read</label>
				<variable>BUTTONREAD'$tb'</variable>
				<action type="clear">TREE'$tb'</action>
				<action type="refresh">TREE'$tb'</action>
			</button>
			<button cancel></button>
		</hbox>
	</vbox>'
}
function yesno () {
	if [ "$#" -lt "1" ];then set -- "are you sure ?" ;fi
	export YESNO='
	<vbox>
		<text><label>'"$@"'</label></text>
		<hbox><button ok></button><button cancel></button></hbox>
	</vbox>'    
	gtkdialog -p YESNO > "$tmpf"
	while read -r line;do
		log yesno  $line
		if [ "$line" == 'EXIT="OK"' ];then return 0 ;fi
	done < "$tmpf"
	return 1
}
function setmsg () {
	log setmsg $*
	case "$1" in
		"-w"|"--warning") 			type="--warnig"			;;
		"-e"|"--error")   			type="--error"			;;
		"-i"|"--info")    			type="--info"  			;;
		"-n"|"--notificatio")    	type="--notification"	;;
		*)							type="--notification"
	esac
	zenity $type --text="$*" 
}
function getdbname () { echo "$*" | tr -d '/.'; }
function setconfig () {
	label=$1;shift;db=$1;shift;tb=$1;shift;where=$*
	log $label $db $tb $where
	return
	field="$1";shift;value="$1";shift;append="$1";shift;comment="$*"
	if [ "$field" = "dflttable" ]; then
#		setmsg $homeuwemy_databasesmymusicsqlite
		eval 'dflttb=$'$(getdbname $value)
		comment="defaulttable $value";field=$(getdbname $value);value=$append;append="-"
	fi
	line="$field=\"$value\" # $comment"
	if [ "$append" = "+" ];then echo "$line" >> "$x_configfile"  ;return  ;fi
	grep "$comment" $x_configfile > /dev/null;
	status=$?
	if [ "$status" -gt "0" ];then echo "$line" >> "$x_configfile"  ;return  ;fi
	grep "$line" $x_configfile > /dev/null;
	status=$?
	if [ "$status" = "0" ];then return  ;fi
	cp -f "$x_configfile" "$path/tmp/configrc"  
	grep -v "$comment" "$path/tmp/configrc" > "$x_configfile"
	echo "$field=\"$value\" # $comment" >> "$x_configfile"
}
function errmsg () {
	log errmsg $*
	zenity --error --text="$*" 
}
function warnmsg () {
	log warnmsg $*
	zenity --warning --text="$*" 
}
function sql_get_where () {
	local tb="$1";shift;local db=$@
	stmt=".header off\nselect distinct value from $parmtb where typ in (5,6) and active = 0 and db = \"$db\" and tb = \"$tb\";"
	sql_execute "$parmdb" "$stmt" | tr -d '"'  
}
function sql_get_stmt () {
	local typ=$1;shift;local active=$1;shift;local db="$1";shift;local tb="$1";shift;local lb=$1;shift;local val=$1;shift;local info=$@
	str=${active%%\)*};str=${str##*\(};active=${str%%\,*}
	str=$(echo $typ,"$db",$tb | tr -d '"');  
	erg=$(grep "$str" $path/tmp/default.txt)
	if [ "$erg" == "" ];then
		echo "insert into $parmtb (typ,active,db,tb,label,value,info) values ($typ,$active,\"$db\",\"$tb\",\"$lb\",\"$val\",\"$info\");"
	else
		echo "update $parmtb set typ=$typ,active=$active,db=\"$db\",tb=\"$tb\",label=\"$lb\",value=\"$val\",info=\"$info\" where id = $erg;"
	fi
}
function sql_read_table_parmtb () {
	echo -e $@ | sqlite3 $parmdb 2> "$efile" | tr -d '\r'
	err=$(<$efile)
	if [ "$err" != "" ];then log "- $@ $err";fi
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
	if [ "$erg" == "" ];then setmsg "keine id $mode $row gefunden"  ;return  ;fi
    echo -e "$erg" > "$valuefile"
    echo $row  > $idfile
    cp -f "$valuefile" "$valuefile.bak"
}
function x_get_tables () {
	log $*
	if [ "$#" -lt "2" ];then setmsg "Reiter $1\nBitte eine sqlite Datenbank auswaehlen" ;return ;fi
	if [ -d "$1" ];then setmsg "$1 ist ein Ordner\nBitte sqlite_db ausaehlen" ;return ;fi
	sql_execute "$1" '.tables' | fmt -w 2
	if [ "$(<$efile)" != "" ];then return;fi  
}
function sql_rc_ctrl () {
	log debug $@
	row="$1";shift;db="$1";shift;tb="$@"
	IFS="@";marray=($(tb_meta_info "$tb" "$db"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}
	if [ "$TNAME" == "" ];then return  ;fi
	if [ "$row" == "insert" ]; then
		echo "" > "$valuefile" 
	else
		sql_rc_read eq $PRIMKEY $row > "$valuefile"
	fi
    row_change_xml="$path/tmp/change_row_${tb}.xml"
    gui_rc_get_dialog $row $tb $db $PRIMKEY $ID $TNAME $TLINE $TNOTN $TSELECT 
	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function sql_rc_back () { sql_rc_read lt $@; }
function sql_rc_next () { sql_rc_read gt $@; }
function sql_rc_clear () { echo "" > "$valuefile" ; }
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
	sql_execute "$db" "$stmt" 
	erg=$error
	log erg $erg
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
function sql_rc_update_insert_save () {
    set +x
    log $@
	mode=$1;shift;ID="$1";shift;PRIMKEY="$1";shift;TSELECT="$1";shift;TNOTN="$1";shift
	local ia=0;local iline="";local uline="";local del="";local val=""
	IFS=",";names=($TSELECT);nulls=($TNOTN);unset IFS
	for ((ia=0;ia<${#names[@]};ia++)) ;do
        val=$(echo "$1" | tr -d '"');shift
	    if [ "$val" == "" ] && [ "$nulls[$ia]" != "1" ];    then  val='null';fi
		uline="$uline$del${names[$ia]} = \"$val\""
		iline="$iline$del\"$val\"";
		del=","
	done
	if [ "$mode" == "insert" ];then
		stmt="insert into $tb ($TSELECT) values ($iline);"
	else
		stmt="update $tb  set $uline where $PRIMKEY = $ID ;"
	fi
	erg=$(sql_execute "$db" "$stmt" )
	log debug "rc = $erg : $stmt $db"
	[ "$erg" == "" ] && erg="$mode erfolgreich" && setmsg $erg
	if [ "$mode" == "insert" ];then
		row=$(sql_execute "$db" ".header off\nselect max($PRIMKEY) from $tb;" );
		sql_rc_read eq $PRIMKEY $row
	fi
}
function sql_rc_delete () {
	log $@
	PRIMKEY=$1;shift;ID=$1
	yesno "$PRIMKEY=$id wirklich loeschen ?"
	if [ $? -gt 0 ];then setmsg "Vorgang abgebrochen";return  ;fi
	erg=$(sql_execute $"$db" "delete from $tb where $PRIMKEY = $ID;")  
	[ "$erg" == "" ] && erg="delete erfolgreich" && setmsg $erg
	erg=$(sql_execute $"$db" "select min($PRIMKEY) from $tb;")
	if [ "$erg" -lt "$ID" ]; then
	    sql_rc_read "lt" "$PRIMKEY" "$ID"
	else
		sql_rc_read "gt" "$PRIMKEY" "$ID"
	fi
}
function sql_execute () {
	set -o noglob
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db" 2> $efile | tr -d '\r' 
	error=$(<$efile)
	if [ "$error" != "" ];then errmsg "sql_execute $error" $db $stmt;echo "";return 1;fi
}
function sql_read_table ()  {
	log $@
	off=$1;shift;view="$1";shift;local db="$1";shift;local tb="$1";shift;where=$(echo $* | tr -d '"')
	if [ "$db" = "" ];then setmsg -w "sql_read_table: keine datenbank uebergeben - $*" ;return  ;fi
	if [ "$tb" = "" ];then setmsg -w "sql_read_table: keine tabelle uebergeben - $*" ;return  ;fi
	sql_execute $db ".separator |\n.header $off\nselect * from $tb $where;" | tee $path/tmp/export_${tb}.txt  
	setconfig "$view" "$db" "$tb" "$where" 
	return
	error=$(<$efile);if [ "$error" != "" ];then return;fi
	if [ "$where" == "" ];then return;fi
	stmt="update $parmtb set value = \"$where\" where typ = 5 and tb =\"$tb\" and db = \"$db\";"
	erg=$(sql_execute $parmdb $stmt); if [ "$erg" != "" ];then return;fi
	stmt="select 1 from $parmtb where typ = 6 and tb =\"$tb\" and db = \"$db\" and value = \"$where\" limit 1;"
	erg=$(sql_execute $parmdb $stmt); if [ "$erg" != "" ];then return;fi
	stmt="insert into $parmtb (typ,active,db,tb,value) values (6,0,\"$db\",\"$tb\",\"$where\");"
	erg=$(sql_execute $parmdb $stmt);
}
function tb_create_dialog () {
	log debug $@ 
	local dfile="$path/tmp/table.xml"; [ -f "$dfile" ] && rm "$dfile"	 
	if [ "$dfltdb" != "" ]; then eval 'dflttb=$'$(getdbname $dfltdb) ;fi
	if [ "$dfltdb"  = "" ]; then dfltdb="-" ;fi
	log debug "db" $dfltdb "tb" $dflttb 
 	local cfile="$path/tmp/cliste.txt";[ -f "$cfile" ] && rm "$cfile";db=""
 	notebook="" 
	while [ "$#" -gt "0" ];do
		if   [ -f  "$1" ];then
			db=$1
			if [ "$2" = "" ] || [ -f  "$2" ]; then 
				dblabel=$(basename $db);tblabel=${dblabel%%\.*}
				eval 'tb=$'$(getdbname $db)
				if [ "$tb" = "" ];then tb="-" ;fi
				echo $tblabel $db $tb "false" "true" >> $cfile # gui without db selection
				notebook="$notebook $tblabel";
			fi	
		elif [ "$1" = "--all" ];then
			x_get_tables "$db" > $tmpf 
			while read -r line;do 
				echo $line $db $line "false" "false" >> $cfile # gui without db,tb selection
				notebook="$notebook $line"
			done < $tmpf	 
		else 
			echo "$1 $db $1 false false"  >> "$cfile"
			notebook="$notebook $1"; 
		fi
	    shift		
	done
	if [ "$notable" != "$true" ];then 
		echo "tabel $dfltdb $dflttb true true" >> "$cfile"
		if [ "$notebook" != "" ];then notebook="$notebook tabel";fi
	fi
	if [ "$notebook" != "" ];then 
		echo "<notebook space-expands=\"true\" tab-labels=\""$(echo $notebook | tr ' ' "|")"\">" > $dfile
	fi
 	[ -f $tmpf ] && rm $tmpf;where="-"
	while read -r line;do 
		set -- $line
		if [ "$3" != "-" ]; then
			eval 'where=$'$(getdbname $2)$1
		else
			where="-"
		fi
#		warnmsg 
	    if [ "$where" = "" ];then where="-" ;fi	
		printf "%-10s %-40s %-15s %s %s %s\n" $1 $2 $3 $4 $5 "$where" >> $tmpf
		gui_tb_get_dialog $1 $2 $3 $4 $5 "$where" >> $dfile
	done < $cfile
	if [ "$notebook" != "" ];then echo "</notebook>" >> $dfile;fi
#	cat $tmpf
#  	cat $dfile
	gtkdialog  -f "$dfile"
}
function tb_db_names_user () {
	log debug $@ 
	local db="";local refresh=$1;shift;local dbsave=""
	if [ "$#" -lt "1" ]; then  where=";"; else where="and db = \"$@\";";fi
	sql_read_table_parmtb ".headers off\nselect distinct db from $parmtb where typ = 1 and active = 0 $where" > $path/tmp/dblist.txt
    export defaultdbsel=$(head -1 $path/tmp/dblist.txt)
	[ -f $path/tmp/nameslist.txt ] && rm $path/tmp/nameslist.txt
	[ -f $path/tmp/stmtlist.txt ] && rm $path/tmp/stmtlist.txt
	while read -r db; do
		tables=$(echo -e ".table" | sqlite3 $db) 
		for tb in $tables;do
			if [ "$tb" == "" ];then continue  ;fi
			echo $db $tb >> $path/tmp/nameslist.txt
		done
		if [ "$refresh" == "$true" ];then
			echo -e "delete from $parmtb where typ in (2) and db = \"$db\";" | sqlite3 $parmdb
		fi 	
	done < $path/tmp/dblist.txt
	log debug $@ 
	sql_read_table_parmtb "select typ,db,tb from $parmtb where typ in (2,3,4,5);" | tr -d '"' > $path/tmp/default.txt
	sql_read_table_parmtb ".headers off\n.separator ' '\nselect db,tb from $parmtb where typ = 2;" > $path/tmp/nameslist2.txt
	diff $path/tmp/nameslist.txt $path/tmp/nameslist2.txt |
	while read -r line;do
	    set -- $line;mode=$1;shift;db=$1;shift;tb=$1;shift
	    if [ "$mode" != "<" ] && [ "$1" != ">" ] ;then continue ;fi
	    IFS="@";marray=($(tb_meta_info "$tb" "$db"));unset IFS;pk="${marray[0]}"
	    if [ "$pk" == "-" ]; 
	        then log $db $tb hat keinen primarykey;where="limit 150"
	        else where="where $pk >= 0 limit 150"
	    fi
	    if [ "$db" != "$dbsave" ]; then
			dblabel=$(basename $db);dblabel=${dblabel%%\.*}
			dbsave=$db
			sql_get_stmt 3 "(0)"    "$db" "$db" "$dblabel" "defaultdb"    "batch"   >> $path/tmp/stmtlist.txt
			sql_get_stmt 4 "(0)"    "$db" "$tb" "$dblabel" "defaulttable" "batch"	>> $path/tmp/stmtlist.txt
			sql_get_stmt 5 "(0)"    "$db" "$tb" "$dblabel" "$where" 	  "batch"	>> $path/tmp/stmtlist.txt
		fi
	    sql_get_stmt 2 "(0,1)"  "$db"  "$tb" ""     ""            "batch" 			>> $path/tmp/stmtlist.txt
	    sql_get_stmt 3 "(0)"    "$db"  "$db" "$tb" "defaultdb"    "batch" 			>> $path/tmp/stmtlist.txt
	    sql_get_stmt 4 "(0)"    "$db"  "$tb" "$tb" "defaulttable" "batch" 			>> $path/tmp/stmtlist.txt
	    sql_get_stmt 5 "(0)"    "$db"  "$tb" "$tb" "$where" 	  "batch"  			>> $path/tmp/stmtlist.txt
	done
	log debug $@ 
	sql_get_stmt 3 "(0)" "$parmdb" "$parmdb"  "tabel" "defaultdb"    "batch" 		>> $path/tmp/stmtlist.txt
	sql_get_stmt 4 "(0)" "$parmdb" "$parmtb"  "tabel" "defaulttable" "batch" 		>> $path/tmp/stmtlist.txt
	sql_get_stmt 5 "(0)" "$parmdb" "$parmtb"  "tabel" "where id >= 0 limit 150" "batch" >> $path/tmp/stmtlist.txt
	if [ ! -f $path/tmp/stmtlist.txt  ];then return ;fi
	grep "insert" $path/tmp/stmtlist.txt > $path/tmp/sqlread.txt
	err=$(sql_read_table_parmtb ".read \"$path/tmp/sqlread.txt\"")
	if [ "$err" != "" ];then log "-" tb_db_names_user $err ;fi
}
function tb_get_meta_val   () {
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
function tb_meta_info () {
	local tb=$1;shift;local db=$@;local del="";local del2="";local del3="";local line=""
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
function zz () {
	return
}
	if [ "$1" = "func" ];then shift;log file tlog debug;cmd="--";$*;exit ;fi 
	log file tlog verbose_on debug_on
	if [ "$1" = "sql_rc_ctrl" ];then shift;sql_rc_ctrl $@;cmd="--";exit ;fi 
	log start 
	refresh=$false;notable=$false;parm=""
	while [ "$#" -gt 0 ];do
        if   [ "$1" == "--refresh" ]; then refresh=$true 
        elif [ "$1" == "--notable" ]; then notable=$true 
		else parm="$parm $1"
		fi
		shift
	done
	if [ ! -f "$path/tmp/refreshed.txt" ];then refresh=$true;touch "$path/tmp/refreshed.txt" ;fi
    tb_db_names_user $refresh #;exit
	tb_create_dialog $parm

