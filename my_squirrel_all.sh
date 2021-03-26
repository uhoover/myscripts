#!/bin/bash
#!/bin/bash -e
#!/usr/local/bin/gtkdialog -e
# author uwe suelzle
# created 2021-03-16
# version 1.0.0
# function: dbms for sqlite
#
 source /home/uwe/my_scripts/my_functions.sh
 trap axit EXIT
 set -o noglob
function axit() {
	retcode=0 
  	if [ "$cmd" = "" ]; then log stop;fi
}
function amain () {
	log file   
#	log file tlog verbose_on debug_on  
	pparms=$*
	refresh=$false;notable=$false;visible="true";parm=""
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--tlog"|-t|--show-log-with-tail)  			log tlog ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--version"|-v)  				            echo "version 1.0.0" ;;
	        "--vb"|--verbose|--verbose-log)  			log verbose_on ;;
	        "--func"|-f|--execute-function)  			shift;cmd="nostop";log debug $pparms;$*;return ;;
	        "--notable"|--no-tab-with-db-selection)		notable=$true ;;
	        "--nolabel"|--no-notebook-label)			nolabel=$true ;;
	        "--help"|-h)								func_help $FUNCNAME;echo -e "\n     usage dbname [table --all]]" ;return;;
	        "--all"|--tab-each-table)					parm="$parm $1";;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										parm="$parm $1";;
	    esac
	    shift
	done
    log start
    log debug $pparms
	tb_create_dialog   $parm	
	gtkdialog  -f "$dfile"

} 
 	folder="$(basename $0)";path="$HOME/.${folder%%\.*}"
	tpath="$path/tmp"  
	[ ! -d "$path" ]  && mkdir "$path"  
	[ ! -d "$path/tmp" ] && mkdir "$path/tmp"  
	x_configfile="$path/.configrc" 
	if [ ! -f "$x_configfile" ];then echo "# defaultwerte etc:" > "$x_configfile" ;fi  
 source $x_configfile
	lfile="/home/uwe/log/gtkdialog.txt" 
	script=$(readlink -f $0)   
	changexml="$path/tmp/change.xml" 
	idfile="$path/tmp/id.txt" 
	efile="$path/tmp/error.txt" 
	tmpf="$path/tmp/dialogtmp.txt"
	tableinfo="$path/tmp/tableinfo.txt"  
	valuefile="$path/tmp/value.txt"
	dfile="$path/tmp/table.xml"; 
function gui_rc_entrys_hbox_extra () {
	db="$1";shift;tb="$1";shift;field="$1";shift;nr="$1";shift;meta="$1";shift;cmd=$*
#	setmsg -i -d --width=600 "extra befehl field $field nr $nr\n cmd $cmd"
	echo  ' 			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false" visible="true">'
	echo  ' 				<variable>entry'$nr$nr'</variable>'
	echo  ' 				<sensitive>true</sensitive>'
    echo  ' 			    <input>/home/uwe/my_scripts/my_squirrel_all.sh --func sql_execute '$db '"'$cmd'"</input>'
    echo  '                 <action>'$script' --func tb_set_meta_val '$nr' $entry'$nr$nr'</action>'
    echo  '                 <action type="refresh">entry'$nr'</action>'
    echo  '             </comboboxtext>'
#	echo  ' 			<text width-chars="25" justify="3"><label>'${meta[$ia]}'</label></text>'   
}
function gui_rc_entrys_hbox () {
	log debug $@
	db=$1;shift;tb=$1;shift;PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		eval 'cmdextra=$'$(getdbname $db)$tb${name[$ia]}
		if [ "$cmdextra" = "" ]; then length="20"; else length="19";fi
		echo    '	<hbox>'   
		echo    ' 			<text width-chars="'$length'" justify="3"><label>'" "${name[$ia]}'</label></text>' 
		echo    ' 			<entry width_chars="30">'  
		echo    ' 				<variable>entry'$ia'</variable>' 
		echo    ' 				<input>'$script' --func tb_get_meta_val '$ia'</input>'  
		echo    ' 			</entry>' 
		if [ "$cmdextra" = "" ]; then
		   echo  ' 			<text width-chars="25" justify="3"><label>'${meta[$ia]}'</label></text>'   
		else
		   gui_rc_entrys_hbox_extra "$db" "$tb" "${name[$ia]}" "$ia" "${meta[$ia]}" "$cmdextra"	
		fi
        echo    '	</hbox>' 
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
	db="$1";shift;tb="$1";shift;row="$1";shift;PRIMKEY="$1";shift;ID="$1";shift
	TNAMES="$1";shift;TLINE="$1";shift;TNOTN="$1";shift;TSELECT="$1"
	echo '<vbox>'
	echo '	<vbox>'
	echo '		<hbox>'
	echo '			<text width-chars="20" justify="3"><label>'"$PRIMKEY"' (PK)</label></text>'
	echo '			<entry width_chars="30">'
	echo '				<variable>entryp</variable>'
	echo '				<input>'$script' --func tb_get_meta_val '"$ID"'</input>'
	echo '			</entry>'
	echo '			<text width-chars="25" justify="3"><label>type,null,default,primkey</label></text>'
	echo '		</hbox>'
	echo '	</vbox>'
	echo '  <frame>'
	echo '  <vbox>'
			   gui_rc_entrys_hbox $db $tb $PRIMKEY $ID $TNAMES $TLINE
	echo '	</vbox>'
	echo '  </frame>'
	echo '	<hbox>'
	echo '		<button><label>back</label>'
	echo '			<action>'$script' --func sql_rc_read '$db' '$tb' lt '$PRIMKEY' $entryp</action>'
			        gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE
	echo '		</button>'
	echo '		<button><label>next</label>'
	echo '			<action>'$script' --func sql_rc_read '$db' '$tb' gt '$PRIMKEY' $entryp</action>'
			        gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE
    echo '		</button>'
	echo '		<button><label>read</label>'
	echo '			<action>'$script' --func sql_rc_read '$db' '$tb' eq '$PRIMKEY' $entryp</action>'
	echo '			<action type="enable">BUTTONAENDERN</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE 
	echo '		</button>'
	echo '		<button><label>insert</label>'
	echo '			<action>'$script' --func sql_rc_update_insert '$db' '$tb' insert $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE 
	echo '		</button>'
	echo '		<button><label>update</label><variable>BUTTONUPDATE</variable>'
	echo '			<action>'$script' --func sql_rc_update_insert '$db' '$tb' update $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>'
	echo '		</button>'
	echo '		<button><label>delete</label>'
	echo '			<action>'$script' --func sql_rc_delete '$db' '$tb' '$PRIMKEY' $entryp</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE 
	echo '		</button>'
	echo '		<button><label>clear</label>'
	echo '			<action type="enable">BUTTONUPDATE</action>'
	echo '			<action>'$script' --func sql_rc_clear '"$(gui_rc_entrys_variable_list $PRIMKEY $ID $TNAMES $TLINE)"'</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE 
	echo '		</button>'
	echo '		<button><label>refresh</label>'
	echo '			<variable>BUTTONREFRESH</variable>'
	echo '			<action type="enable">BUTTONAENDERN</action>'
	echo '			<action>cp -f '"$valuefile.bak" "$valuefile"'</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE 
	echo '		</button>'
	echo '		<button ok></button><button cancel></button>'
	echo '	</hbox>'
	echo '</vbox>' 
}
function gui_tb_get_default () {
	log debug "$*";str=$(echo "$*" | tr -d ' "-') 
	if [ "$str" = "" ] ;then echo "";return  ;fi
	echo "<default>\"$*\"</default>"
}
function gui_tb_get_dialog () {
	log debug $@
	tb="$1";shift;dfltdb="$1";shift;dflttb=$1;shift;visibleDB=$1;shift;visibleTB="$1";shift;dfltwhere="$*"   
	if [ "$tb" = "$dflttb" ]; then
		IFS="@";marray=($(tb_meta_info "$dfltdb" "$dflttb"));unset IFS
		pk="${marray[0]}"
		label=$(echo "${marray[2]}"| tr ',_' '|-')
		visibleHD="true";off="on"
	else
	    if [ "$dfltlabel" == "" ]; then
		    str="_____";del="";dfltlabel=""
		    for ((ia=1;ia<17;ia++)) ;do dfltlabel=$dfltlabel$del$str$ia$str;del="|";done
		fi 
		label=$dfltlabel
		visibleHD="false";off="off"
	fi
	echo  '
	<vbox>
		<tree headers_visible="'$visibleHD'" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="0">
			<label>'"$label"'</label>
			<height>500</height><width>600</width> 
			<variable>TREE'$tb'</variable>
			<input>'$script' --func sql_read_table '$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb' "$CBOXWHERE'$tb'"</input>
			<action>'$script' --func sql_rc_ctrl $TREE'$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</action>
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
					<input>'$script' --func x_get_tables $CBOXDBSEL'$tb' '$tb'</input>
					<action type="clear">TREE'$tb'</action>
					<action type="refresh">CBOXWHERE'$tb'</action>
					<action type="refresh">TREE'$tb'</action>
				</comboboxtext>
			</hbox>
			<comboboxentry auto-refresh="true">
				<variable>CBOXWHERE'$tb'</variable>
				'$(gui_tb_get_default  "$dfltwhere ")'
				<input>'$script' --func sql_get_where $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</input>
				<action signal="activate" type="refresh">TREE'$tb'</action>
				<action signal="activate" type="refresh">CBOXWHERE'$tb'</action>
			</comboboxentry>
		</frame>
		<hbox>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$tb'</variable>
				<sensitive>true</sensitive> 
				<action>'$script' --func sql_rc_ctrl insert $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</action>
			</button>
			<button visible="false">
				<label>aendern</label>
				<variable>BUTTONAENDERN'$tb'</variable>
				<sensitive>false</sensitive> 
				<action>'$script' --func sql_rc_ctrl $TREE'$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</action>
			</button>
			<button>
				<label>read</label>
				<variable>BUTTONREAD'$tb'</variable>
				<action type="clear">TREE'$tb'</action>
				<action type="refresh">TREE'$tb'</action>
			</button>
			<button cancel></button>
		</hbox>
	 </vbox>
	 '
}
function setmsg () { func_setmsg $*; }
function setmsg_old () {
	parm="--notification";text=""
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
	if [ "$text" != "" ];then text="--text='$text'" ;fi
	eval 'zenity' $parm $text 
	return $?
}
function getdbname () { echo $(readlink -f "$*") | tr -d '/.'; }
function get_fileselect () {
	set +x
	if [ "$searchpath" = "" ]; then searchpath=$HOME;fi
	mydb=$(zenity --file-selection --filename=$searchpath)
	if [ "$mydb" = "" ];then echo "";return;fi
	sql_execute $mydb ".tables"
	if [ "$?" -gt "0" ];then return ;fi
	#~ error=$(<$efile)
	#~ if [ "$error" != "" ];then echo "";return;fi
	setconfig_file "searchpath" "$mydb" "-" "letzter pfad fuer file-select"
	echo $mydb 
	set +x
}
function setconfig_file () {
	field="$1";shift;value="$1";shift;append="$1";shift;comment="$*"
	line=$(printf "%-80s $s" "$field=\"$value\"" "# $comment")
	grep "$line" $x_configfile > /dev/null;
	status=$?
	if [ "$status" = "0" ];then return  ;fi
	if [ "$append" = "+" ];then echo "$line" >> "$x_configfile"  ;return  ;fi
	cp -f "$x_configfile" "$path/tmp/configrc"  
	grep -v "# $comment" "$x_configfile" > "$path/tmp/configrc" 
	echo "$line" >> "$path/tmp/configrc" 
	sort -u "$path/tmp/configrc" > "$x_configfile"
	return
	cp -f "$x_configfile" "$path/tmp/configrc"  
	grep -v "# $comment" "$path/tmp/configrc" > "$x_configfile"
	echo "$line" >> "$x_configfile"
}
function setconfig () {
	label=$1;shift;db=$1;shift;tb=$1;shift;where="$*"
	if 		[ "$label" =  "selectDB" ]; then
			setconfig_file "dfltdb" "$db" "-" "default-datenbank fuer dbselect (label=selectDB)"
			field=$(getdbname $db)
	fi
	if 		[ "$label" != "$tb" ]; then
			setconfig_file "$(getdbname $db)dflttb$label"    "$tb"    "-" "default-tabelle fuer tbselect (label=$label)"
	fi
	if 		[ "$where" = "" ];then return;fi
	setconfig_file "$(getdbname $db)dfltwhere$label$tb" "$where" "-" "default-where fuer $tb (label=$label)"
	setconfig_file "dummy" "$where" "+" "$db $tb"
}
function sql_get_where () {
	cmd="grep \"^dummy=\" $x_configfile | grep \"# $1 $2\" | cut -d '\"' -f2"
	bash -c "$cmd"
}
function sql_rc_read () {
	log debug $@
	db=$1;shift;tb=$1;shift;local mode=$1;shift;PRIMKEY=$1;shift;row=$1;
	if [ "$row" == "NULL" ] || [ "$row" == "" ] || [ "$row" == "=" ];then row=$(cat $idfile);fi
	if [ "$mode" == "eq" ];then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" == "lt" ];then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" == "gt" ];then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	erg=$(sql_execute "$db" ".mode line\n.header off\nselect * from $tb $where")
	if [ "$?" -gt "0" ];then return ;fi
	log debug $mode $row "erg = $erg"
	if [ "$erg" == "" ];then setmsg "keine id $mode $row gefunden"  ;return  ;fi
    echo -e "$erg" > "$valuefile"
    echo $row  > $idfile
    cp -f "$valuefile" "$valuefile.bak"
}
function x_get_tables () {
	log debug $*
	setmsg -i -d "x_get_tables #$*#"  
 	if [ "$1" = "-" ];then  return ;fi
	if [ -d "$1" ];then setmsg "$1 ist ein Ordner\nBitte sqlite_db ausaehlen" ;return ;fi
	sql_execute "$1" '.tables' | fmt -w 2
	if [ "$?" -gt "0" ];then return ;fi
	#~ if [ "$(<$efile)" != "" ];then return;fi  
}
function sql_rc_ctrl () {
	log debug $*
	if [ "$#" -gt "3" ];then setmsg -w  " $#: zu viele Parameter\n tabelle ohne PRIMKEY?" ;return  ;fi
	row="$1";shift;db="$1";shift;tb="$@"
	IFS="@";marray=($(tb_meta_info "$db" "$tb"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}

	if [ "$TNAME" == "" ];then return  ;fi
	if [ "$row" == "insert" ]; then
		echo "" > "$valuefile" 
	else
		sql_rc_read $db $tb eq $PRIMKEY $row > "$valuefile"
	fi
    row_change_xml="$path/tmp/change_row_${tb}.xml"
    gui_rc_get_dialog $db $tb $row $PRIMKEY $ID $TNAME $TLINE $TNOTN $TSELECT > "$row_change_xml"	
	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function sql_rc_back () { sql_rc_read lt $@; }
function sql_rc_next () { sql_rc_read gt $@; }
function sql_rc_clear () { echo "" > "$valuefile" ; }
function sql_rc_update_insert () {
	log debug "$@"
	db=$1;shift;tb=$1;shift;mode=$1;shift;ID="$1";shift;PRIMKEY="$1";shift;TSELECT="$1";shift;TNOTN="$1";shift;value=$*
	z=${#value};if [ "${value:(($z-1)):1}" == "|" ];then value=$value" ";fi
	IFS=",";names=($TSELECT);nulls=($TNOTN)
	IFS="|";values=($value)
	unset IFS
	if [ "${#names[@]}" -ne "${#values[@]}" ];then  
	    setmsg "-e" "abbruch! fields: ${#names[@]} values ${#values[@]}"
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
	#~ erg=$error
	#~ log erg $erg
	#~ if [ "$erg" != "" ];then
	if [ "$?" -gt "0" ];then 
		setmsg "-e" "abbruch rc = $erg : $stmt $db"
		return
	else
	    setmsg "$mode erfolgreich"
	fi
	if [ "$mode" == "insert" ];then
		row=$(sql_execute "$db" ".header off\nselect max($PRIMKEY) from $tb;" );
		if [ "$?" -gt "0" ];then return ;fi
		sql_rc_read $db $tb eq $PRIMKEY $row
	fi
}
function sql_rc_delete () {
	log debug $@
	db=$1;shift;tb=$1;shift;PRIMKEY=$1;shift;ID=$1
	setmsg -z "$PRIMKEY=$id wirklich loeschen ?"
	if [ $? -gt 0 ];then setmsg "-w" "Vorgang abgebrochen";return  ;fi
	erg=$(sql_execute $"$db" "delete from $tb where $PRIMKEY = $ID;")  
	[ "$erg" == "" ] && erg="delete erfolgreich" && setmsg $erg
	erg=$(sql_execute $"$db" "select min($PRIMKEY) from $tb;")
	if [ "$?" -gt "0" ];then return ;fi
	if [ "$erg" -lt "$ID" ]; then
	    sql_rc_read "$db" "$tb" "lt" "$PRIMKEY" "$ID"
	else
		sql_rc_read "$db" "$tb" "gt" "$PRIMKEY" "$ID"
	fi
}
function sql_execute () { func_sql_execute $*; }
function sql_execute_old () {
	set -o noglob
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db" 2> "$efile" | tr -d '\r' 
	error=$(<$efile)
	if [ "$error" != "" ];then setmsg -e --width=400 "sql_execute $error" $db "\n" $stmt;echo "";return 1;fi
}
function sql_read_table ()  {
	log $@
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$(echo $* | tr -d '"')
	if [ "$label" = "$tb" ];then off="off" ;else off="on"  ;fi
	if [ "$db" = "" ];then setmsg -w --width=400 " sql_read_table\n label $label\n bitte datenbank selektieren\n $*" ;return  ;fi
	if [ "$tb" = "" ];then setmsg -w --width=400 " sql_read_table\n label $label\n keine tabelle uebergeben\n $*" ;return  ;fi
	sql_execute $db ".separator |\n.header $off\nselect * from $tb $where;" | tee $path/tmp/export_${tb}.txt 
	if [ "$?" -gt "0" ];then return ;fi 
	setconfig "$label" "$db" "$tb" "$where" 
}
function tb_create_dialog_nb () {
	tb=$3;where=""
	if [ "$tb"      = "" ]; then tb=$(x_get_tables "$2" "batch"| head -n1) ;fi
	if [ "$tb"     != "" ]; then eval 'where=$'$(getdbname "$2")'dfltwhere'$1$tb ;fi
	if [ "$2"      != "" ]; then eval 'export CBOXDBSEL'$1'='$2 ;fi
	if [ "$tb"     != "" ]; then eval 'export CBOXENTRY'$1'='$tb ;fi 
	if [ "$where"  != "" ]; then eval 'export CBOXWHERE'$1'="'$where'"';fi
	log debug $(export -p | grep "CBOX")
	erg="$1 $2 $tb $4 $5 $where"
	notebook=$notebook" $1" 
}
function tb_create_dialog () {
	log debug $@ 
	notebook="" 
	[ -f "$dfile" ] && rm "$dfile"	 
	if [ "$dfltdb" != "" ]; then eval 'dflttb=$'$(getdbname $dfltdb)'dflttbselectDB' ;fi
	if [ "$dfltdb"  = "" ]; then dfltdb=$(get_fileselect);fi
	if [ "$dfltdb"  = "" ]; then return;fi
	if [ "$dflttb"  = "" ]; then dflttb="-";fi
 	cfile="$path/tmp/labelliste.txt";[ -f "$cfile" ] && rm "$cfile";db=""
	notebook="";zn=-1 
	while [ "$#" -gt "0" ];do
		if   [ -f  "$1" ];then
			db=$1
			if [ "$2" = "" ] || [ -f  "$2" ]; then 
				dblabel=$(basename $db);tblabel=${dblabel%%\.*}
				eval 'tb=$'$(getdbname $db)'dflttb'
				if [ "$tb" = "" ];then tb="-" ;fi
				tb_create_dialog_nb "$tblabel" $db $tb "false" "true";zn=$((zn+1));anb[$zn]="$erg"
			fi	
		elif [ "$1" = "--all" ];then
			x_get_tables "$db" > $tmpf 
			while read -r line;do 
				tb_create_dialog_nb $line $db $line "false" "false";zn=$((zn+1));anb[$zn]="$erg"
			done < $tmpf
		else 
			tb_create_dialog_nb "$1" "$db" "$1" "false" "false";zn=$((zn+1));anb[$zn]="$erg"
		fi
	    shift		
	done
 	if [ "$notable" != "$true" ];then 
 		tb_create_dialog_nb "selectDB" "$dfltdb" "$dflttb" "true" "true";zn=$((zn+1));anb[$zn]="$erg" 
	fi
	echo "<window title=\"Uwes sqlite dbms\">" > $dfile
	echo "<notebook show-tabs=\"$visible\" space-expands=\"true\" tab-labels=\""$(echo $notebook | tr ' ' "|")"\">" >> $dfile
	for arg in "${anb[@]}" ;do
		set -- $arg 
		log debug $(printf "labels %-10s %-40s %-15s %-5s %-5s %s\n" $1 $2 $3 $4 $5 "$(echo ${@:6})")
		gui_tb_get_dialog $1 $2 $3 $4 $5 "$(echo ${@:6})" >> $dfile
	done
	echo "</notebook></window>" >> $dfile 
}
function tb_set_meta_val   () {
	set -x
	nr=$1;shift;value=$*
	cp -f "$valuefile" "$valuefile"".bak2"
	i=-1
	while read line;do
		i=$((i+1))
		if [ "$i" != "$nr" ];then echo $line;continue;fi  
		echo "${line%=*} = ${value% *}"
	done  < "$valuefile"".bak2" > "$valuefile"
	set +x
	setmsg -i --width=400 "$FUNCTION\nnr= $nr\nvalue=$value"
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
	local db="$1";shift;local tb=$@;local del="";local del2="";local del3="";local line=""
	TNAME="" ;TTYPE="" ;TNOTN="" ;TDFLT="" ;TPKEY="";TLINE="";TSELECT="";local ip=-1;local pk="-"
	sql_execute "$db" ".header off\nPRAGMA table_info($tb);"   > $tableinfo
	if [ "$?" -gt "0" ];then return ;fi
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
function zz () { return; } 
	amain $*
