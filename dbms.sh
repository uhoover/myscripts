#!/bin/bash
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
function ftest () {
	dbmusic="/home/uwe/my_databases/music.sqlite"
	db="$1";tb="$2";field="$3";declare -a refarr
	cmdarr+=( "referenz|$dbmusic|track|ref_album_id|$dbmusic|album|select * from album|0|" )
	cmdarr+=( "referenz|$dbmusic|track|ref_composer_id|$dbmusic|composer|select * from composer|0|" )
    found=$false
    set -x
    IFS='|'
    for arg in "${refarr[@]}" ;do
		set $arg
		func="$1";db1="$2";tb1="$3";field1="$4";db2="$5";tb2="$6";cmd1="$7";cmd2="$8" 
		if [ "$db"    != "$db1" ];   then continue ;fi
		if [ "$tb"    != "$tb1" ];   then continue ;fi
		if [ "$field" != "$field1" ];then continue ;fi
		SDB=$db2;STB=$tb2;SCMD1=$cmd1;SCMD2=$cmd2;found=$true
	done
	if [ "$found" = "$true" ];then echo found $SCMD1; else echo not found  ;fi
	set +x
}
function ctrl () {
	log file 
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}"
	tpath="$path/tmp" 
	epath="/var/tmp/export_${folder%%\.*}" 
	[ ! -d "$path" ]     && mkdir "$path"  
	[ ! -d "$path/tmp" ] && mkdir "$path/tmp"  
	[ ! -d "$epath" ]    && mkdir "$epath" && ln -sf "$epath"    "$path"   
	[   -d "$HOME/log" ]                   && ln -sf "$HOME/log" "$path"   
	x_configfile="$path/.configrc" 
	if [ ! -f "$x_configfile" ];then echo "# defaultwerte etc:" > "$x_configfile" ;fi 
	dbparm="$path/parm.sqlite" 
 source $x_configfile
	if [ "$limit" = "" ];then limit=150  ;fi
	script=$(readlink -f $0)   
	tmpf="$path/tmp/dialogtmp.txt"
	tableinfo="$path/tmp/tableinfo.txt"  
	valuefile="$path/tmp/value.txt"
	please_choose="---- please choose "$(copies -c "-" 120);
	notable=$false;visible="true";parm="";nowidgets="false"  
	pparms=$*
	ctrl_load_parm
	notable=$false;visible="true";myparm="";nowidgets="false";wtitle="Uwes sqlite dbms";X=400;Y=600
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--tlog"|-t|--show-log-with-tail)  			log tlog ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--version"|-v)  				            echo "version 1.0.0" ;;
	        "--vb"|--verbose|--verbose-log)  			log verbose_on ;;
	        "--func"|-f|--execute-function)  			shift;cmd="nostop";log debug $pparms;$*;return ;;
	        "--notable"|--no-tab-with-db-selection)		notable=$true ;;
	        "--nolabel"|--no-notebook-label)			nolabel=$true ;;
	        "--nowidgets"|--no-extra-widgets)			nowidgets="true" ;;
	        "--window"|-w|--window-title)			    shift;wtitle="$1" ;;
	        "--help"|-h)								func_help $FUNCNAME;echo -e "\n     usage [ dbname [table ] --all  ]" ;return;;
	        "--all"|--tab-each-table)					myparm="$myparm $1";;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										myparm="$myparm $1";;
	    esac
	    shift
	done
    log start tlog debug $pparms 
	ctrl_tb $myparm	
}
function ctrl_load_parm() {
	if [ -f $dbparm ];then 
		table=$(sql_execute $dbparm ".tables parm") ;
		if [ "$table" = "parm" ];then return  ;fi
	fi
	sqlite3 $dbparm << EOF
    create table if not exists parm (
		parm_id		INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		parm_field	TEXT,
		parm_value	TEXT,
		parm_type	TEXT); 
		insert into parm values (null,0,"0	true","boolean"),(null,1,"1	false","boolean"),
								(null,0,"0	-","status"),(null,1,"1	in Bearneitung","status"),
								(null,2,"2	ready","status"),(null,9,"9	update-komplete","status"); 
EOF
}
function ctrl_tb () {
	erg=$(tb_get_labels $*)
	IFS="|";arr=($erg);unset IFS
	if [ "${#arr[@]}" -lt "1" ];then setmsg -i "keine gueltigen Parameter";return 1 ;fi
	notebook="";for arg in ${arr[@]};do notebook="$notebook ${arg%%#*}";done
    xmlfile="$tpath/xml_$(echo $notebook | tr ' ' '_').xml"
    geometryfile="$tpath/geometry_$(echo $notebook | tr ' ' '_').txt"
	echo "<window title=\"$wtitle\">" > $xmlfile
	echo "<notebook show-tabs=\"$visible\"  tab-labels=\""$(echo $notebook | tr '_ ' "-|")"\">" >> $xmlfile
	for arg in "${arr[@]}" ;do
		IFS='#';set -- $arg;unset IFS 
 		log "label $1 db $2 tb $3"  
  		tb_gui_get_xml "$1" "$2" "$3" >> $xmlfile 
	done
	unset IFS
	echo "</notebook></window>" >> $xmlfile
	X=10;Y=10;HEIGHT=800;WIDTH=900
    [ -f "$geometryfile" ] && source "$geometryfile" 
    geometry="$WIDTH""x""$HEIGHT""+""$X""+""$Y"
    declare -a cboxtba entrya treea cboxwh labela
    gtkdialog -f "$xmlfile" --geometry="$geometry" > $tmpf
    while read -r line;do
#       echo "${line:0:6} $line" 
       field="${line%%\=*}";value=$(echo "${line##*\=}" | tr -d '"')
       if [ "${line:0:6}" = "CBOXTB" ];then  labela+=( ${field:6} ) ;fi 
       if [ "${line:0:6}" = "CBOXTB" ];then cboxtba+=( $value ) ;fi 
       if [ "${line:0:6}" = "CBOXWH" ];then cboxwha+=( $value ) ;fi 
       if [ "${line:0:5}" = "ENTRY" ]; then  entrya+=( $value ) ;fi 
       if [ "${line:0:4}" = "TREE" ];  then   treea+=( $value ) ;fi 
    done < $tmpf
    for ((ia=0;ia<${#cboxtba[@]};ia++)) ;do
#		echo "${labela[$ia]}" "${cboxtba[$ia]}" "${entrya[$ia]}" "${treea[$ia]}" "${cboxwha[$ia]}"
#		label="${labela[$ia]}";tb="${cboxtba[$ia]}";db=$(echo "${entrya[$ia]}" | tr -d '/.');row="${treea[$ia]}";where="${cboxwha[$ia]}"
#		echo $label $tb $db $row $where
		setconfig_db "parm_id" "defaultdatabase" 	"${labela[$ia]}" "-" 			  "-" 				"${entrya[$ia]}"    
		setconfig_db "parm_id" "defaulttable"		"${labela[$ia]}" "${entrya[$ia]}" "-" 				"${cboxtba[$ia]}"    
		setconfig_db "parm_id" "defaultwhere"		"${labela[$ia]}" "${entrya[$ia]}" "${cboxtba[$ia]}" "${cboxwha[$ia]}"   
		setconfig_db "parm_id" "defaultrow"			"${labela[$ia]}" "${entrya[$ia]}" "${cboxtba[$ia]}" "${treea[$ia]}"   
	done
}
function ctrl_tb_gui () {
	func=$1;shift;label=$1;shift;db="$1";shift;tb="$1";shift;db_gui="$1";shift;tb_gui="$1";shift;where_gui="$*";row=$where_gui
	setmsg -i -d --width=600 "func $func\nlabel $label\ndb $db\ntb $tb\ndb_gui $db_gui\ntb_gui $tb_gui\nwhere_gui $where_gui"
	if [ "$func"    = "entry" ];	then db_gui="" ;fi
	if [ "$db_gui" != "" ];			then db=$db_gui ;fi
	if [ "$db" 		= "dfltdb" ];	then db=$(getconfig $label);fi
	if [ "$db" 		= "" ];			then db=$(get_fileselect);fi
	is_database $db
	if [ "$?" -gt "0" ];			then setmsg -w "keine Datenbnk ausgewaehlt";return;fi
	if [ "$tb_gui" != "" ];			then tb=$tb_gui ;fi
	if [ "$tb" 		= "dflttb" ];	then tb=$(getconfig $label $db);fi
	if [ "$tb" 		= "" ];			then tb=$(getconfig $label $db);fi
	if [ "$tb" 		= "" ];			then tb=$(tb_get_tables "$db" "batch"| head -n1);fi
	if [ "$tb"      = "" ];			then setmsg -w "keine Tabelle gefunden";return;fi
	if [ "$where_gui" != "" ]; 		then where="$where_gui" ;fi
	if [ "$where"   = "" ]; 		then where=$(getconfig $label $db $tb);fi 
	case "$func" in
		"entry")   	echo $(getconfig $label);return;;
		"fselect") 	db=$(get_fileselect);is_database $db;if [ "$?" = "0" ];then setconfig $label $db;fi;return;;
		"cboxtb") 	if [ "$label" = "$tb" ];then echo $tb;return;fi
		            db=$(getconfig $label)
					if [ "$db" = "" ];	then setmsg -e "keine Datenbank gefunden";return;fi
					tb=$(getconfig $label $db)
		            if [ "$tb" != "" ];then echo $tb; else tb=" ";fi
		            tb_get_tables "$db" "batch" | grep -v "$tb" ;;
		"cboxwh") 	#where=$(getconfig $label $db $tb)
		        	where=$(getconfig_db parm_value defaultwhere $label $db $tb)
					if [ "$where" != "" ];then echo $where; else where=" ";fi
					tb_get_where_list $label $db $tb | grep -v "$where"
					echo " " ;;
		"tree") 	setmsg -i -d "$FUNCNAME\nlabel $label\ndb    $db\ntb    $tb\nwhere $where"
					tb_read_table $label "$db" $tb "$where";;
		"crow_activated")  setmsg -i "label $label\ndb $db\ntb $tb\nrow $row";;
		*) setmsg -w "$func nicht bekannt"
	esac	
}
function tb_get_labels() {
	log debug $FUNCNAME $@  
	arr="";del="" 
	while [ "$#" -gt "0" ];do
		if   [ -f  "$1" ];then
			db=$1;sql_execute "$db" ".databases" > /dev/null
			if [ "$?" -gt "0" ];then setmsg -i "$db ist keine sqlite db";db="none";shift;continue;fi
			tb_get_tables "$db" > $tmpf 
			if [ "$2" = "" ] || [ -f  "$2" ]; then 
				dblabel=$(basename $db);tblabel=${dblabel%%\.*}
				arr="$arr$del$tblabel#$db#dflttb";del="|"
			fi	
		elif [ "$1" = "--all" ];then	
			if [ "$db" = "none" ];then continue  ;fi
			while read -r tb;do 
				arr="$arr$del$tb#$db#$tb";del="|"
			done < $tmpf
		else 
			if [ "$db" = "none" ];then continue  ;fi
			erg=$(grep -w "$1" $tmpf)
			if [ "$erg" = "" ];then setmsg -i "$1 ist keine sqlite tabelle";shift;continue;fi
			arr="$arr$del$1#$db#$1";del="|"
		fi
	    shift		
	done
	if [ "$notable" != "$true" ];then arr="$arr${del}selectDB#dfltdb#dflttb";fi
	echo $arr
}
function tb_gui_get_xml() {
	local label="$1";local db="$2";local tb="$3"
	if [ "$label" = "$tb" ]; then
		tb_meta_info "$db" "$tb"
		lb=$(echo $TNAME | tr '_,' '-|');sensitiveCBOX="false";sensitiveFSELECT="false" 
	else
		lb=$(copies 30 '|');sensitiveCBOX="true";ID=0;sensitiveFSELECT="true"
	fi
	row=$(getconfig_db parm_value defaultrow "$label" "$db" "$tb") #;row=$(echo $row | tr -d '"')
	if [ "$row" != "" ];then selected_row="selected-row=\"$row\"" ;else selected_row=""  ;fi
	terminal="${tpath}/cmd_${label}.txt"
	terminal_cmd "$terminal" "$label" "$db" 
	echo '    <vbox>
		<tree headers_visible="true" hover_selection="false" hover_expand="true" exported_column="'$ID'" sort-column="'$ID'" '$selected_row'>
			<label>"'$lb'"</label>
			<variable>TREE'$label'</variable>
			<input>'$script' --func ctrl_tb_gui tree      '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWH'$label'</input>
			<action>'$script' '$nocmd' --func ctrl_rc $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>	
			<action type="refresh">CBOXWH'$label'</action>		
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true">  
				<variable>ENTRY'$label'</variable> 
				<sensitive>false</sensitive>  
				<input>'$script' --func ctrl_tb_gui entry  '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
				<action>'$script' --func terminal_cmd '$terminal' '$label' $ENTRY'$label'</action>
				<action type="refresh">TERMINAL'$label'</action>
			</entry> 
			<button space-fill="false">
            	<variable>BUTTONFSELECT'$label'</variable>
            	<sensitive>'$sensitiveFSELECT'</sensitive>
            	<input file stock="gtk-open"></input>
				<action>'$script' --func ctrl_tb_gui fselect '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</action>
            	<action type="clear">ENTRY'$label'</action>	
            	<action type="refresh">ENTRY'$label'</action>
            	<action type="refresh">CBOXTB'$label'</action>		
            </button> 
		  </hbox>
			<comboboxtext space-expand="true" space-fill="true" allow-empty="false">
				<variable>CBOXTB'$label'</variable>
				<sensitive>'$sensitiveCBOX'</sensitive>
				<input>'$script' --func ctrl_tb_gui cboxtb  '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</comboboxtext>	
		</hbox>
		<hbox>
			<comboboxentry space-expand="true" space-fill="true" allow-empty="true">
				<variable>CBOXWH'$label'</variable>
				<input>'$script' --func ctrl_tb_gui cboxwh  '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
				<action signal="activate" type="clear">TREE'$tb'</action>
				<action signal="activate" type="refresh">TREE'$tb'</action>
			</comboboxentry>	
		</hbox>
		<hbox>
			<button>
				<label>show terminal</label>
				<variable>BUTTONSHOW'$label'</variable>
				<action type="show">TERMINAL'$label'</action>
				<action type="show">BUTTONHIDE'$label'</action>
				<action type="hide">BUTTONSHOW'$label'</action>
			</button>
			<button visible="false">
				<label>hide terminal</label>
				<variable>BUTTONHIDE'$label'</variable>
				<action type="hide">TERMINAL'$label'</action>
				<action type="show">BUTTONSHOW'$label'</action>
				<action type="hide">BUTTONHIDE'$label'</action>
			</button>
			<button>
				<label>clone</label>
				<variable>BUTTONCLONE'$label'</variable>
				<action>'$script' $ENTRY'$label' $CBOXTB'$label' --notable --window $CBOXTB'$label'_dbms &</action>
			</button>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$label'</variable>
				<sensitive>true</sensitive> 
				<action>'$script' --func ctrl_rc insert $ENTRY'$label' $CBOXTB'$label'</action>
			</button>
			<button visible="true">
				<label>update</label>
				<variable>BUTTONAENDERN'$label'</variable>
				<action>'$script' --func ctrl_rc $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>
			</button>
			<button visible="true">
				<label>delete</label>
				<variable>BUTTONDELETE'$label'</variable>
				<action>'$script' --func ctrl_rc_gui "button_delete  | $ENTRY'$label'| $CBOXTB'$label '| '$PRIMKEY' | $TREE'$label' | "</action>			
				<action type="refresh">TREE'$label'</action>
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD'$label'</variable>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</button>
			<button>
				<label>ok</label>
				<action>'$script' --func save_geometry '${wtitle}#${geometryfile}'</action>	
				<action type="exit">CLOSE</action>
			</button>
		</hbox>
		<terminal space-expand="false" space-fill="false" text-background-color="#F2F89B" text-foreground-color="#000000" 
			autorefresh="true" argv0="/bin/bash" visible="false">
			<variable>TERMINAL'$label'</variable>
			<height>10</height>
			<input file>"'$terminal'"</input>
		</terminal>
	</vbox>'
} 
function tb_meta_info () {
	db="$1";tb="$2";local del="";local del2="";local del3="";local line=""
	TNAME="" ;TTYPE="" ;TNOTN="" ;TDFLT="" ;TPKEY="";TMETA="";TSELECT="";local ip=-1;local pk="-"
	sql_execute "$db" ".header off\nPRAGMA table_info($tb);"   > $tableinfo
	if [ "$?" -gt "0" ];then return 1;fi
	while read -r line;do
		IFS=',';arr=($line);unset IFS;ip=$(($ip+1))
		TNAME=$TNAME$del"${arr[1]}";TTYPE=$TTYPE$del"${arr[2]}";TNOTN=$TNOTN$del"${arr[3]}"
		TDFLT=$TDFLT$del"${arr[4]}";TPKEY=$TPKEY$del"${arr[5]}"
		TMETA=$TMETA$del2"${arr[2]},${arr[3]},${arr[4]},${arr[5]}"
		if [ "${arr[5]}" = "1" ] ;then
			PRIMKEY="${arr[1]}";export ID=$ip;  
		else
			TSELECT=$TSELECT$del3$"${arr[1]}";del3=","	
		fi
		del=",";del2='|'
	done < $tableinfo
	if [ "$PRIMKEY" = "" ];then 
		PRIMKEY="rowid";ID=0
		TNAME="rowid$del$TNAME";TTYPE="Integer$del$TTYPE";TNOTN="1$del$TNOTN";
		TDFLT="' '$del$TDFLT";TPKEY="1$del$TPKEY";TMETA="rowid$del2$TMETA"
	fi 
}
function tb_read_table() {
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$* #; where=$(func_trim -c '"' -t $where)
	setmsg -i  "$FUNCNAME\nlabel $label\ndb    $db\ntb    $tb\nwhere $where"
	tb_meta_info "$db" $tb
	if [ "$PRIMKEY" = "rowid" ];then srow="rowid," ;else srow="";fi
	if [ "$label" = "$tb" ];then off="off" ;else off="on"  ;fi
	sql_execute $db ".separator |\n.header $off\nselect ${srow}* from $tb $where;"  | tee $epath/export_${tb}_$(date "+%Y%m%d%H%M").txt 
	if [ "$?" -gt "0" ];then return ;fi 
#	setconfig "$label" "$db" "$tb" "$where" 
	setconfig_db "parm_value" "wherelist" "$label" "$db" "$tb" "$where" 
}
function tb_get_where_list () {
	cmd="grep \"^dummy=\" $x_configfile | grep \"# $1 $2\" | cut -d '\"' -f2"
	bash -c "$cmd"
}
function ctrl_rc () {
	log $FUNCNAME $*
	if [ "$#" -gt "3" ];then setmsg -w  " $#: zu viele Parameter\n tabelle ohne PRIMKEY?" ;return  ;fi
	row="$1";shift;db="$1";shift;tb="$@"
	tb_meta_info "$db" "$tb"
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME\nerror Meta-Info\n$db\n$tb";return ;fi
	if [ "$row" = "insert" ]; then
		echo "" > "$valuefile" 
	else
		rc_sql_execute $db $tb eq $PRIMKEY $row 
	fi
    row_change_xml="$path/tmp/change_row_${tb}.xml"	
    rc_gui_get_xml $db $tb $row  > "$row_change_xml"	
 	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function ctrl_rc_gui () {
	log $FUNCNAME $@
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	func=$(trim_value ${parm[0]});db=$(trim_value ${parm[1]});tb=$(trim_value ${parm[2]});entry=$(trim_value ${parm[3]})
	field=$(trim_value ${parm[3]});key=$(trim_value ${parm[4]});entry=$(trim_value ${parm[4]});values=$(trim_value ${parm[@]:5})
	case $func in
		 "entry")   	    str=$(grep "$key" "$valuefile");value="${str#*\= }" 
							if [ "$value" != ""  ];then echo $(trim_value $value | tr -d '"');return;fi
							IFS=',';meta=$(trim_value ${parm[6]});unset IFS
							if [ "$field" = "$key" ]; then 
								value=$(grep "$field" "$valuefile.bak");echo "${value#*\= }";return 
							fi 	 
							if   [ "${meta[2]}" != "" ]; then  echo "${meta[2]}"  
							elif [ "${meta[1]}" != "0" ];then  echo "="  
							else                               echo "null"
							fi 	;; 
		 "button_back")   	rc_sql_execute "$db" "$tb" "lt" 	"$field" "$key" ;;
		 "button_next")   	rc_sql_execute "$db" "$tb" "gt" 	"$field" "$key" ;;
		 "button_read")   	rc_sql_execute "$db" "$tb" "eq" 	"$field" "$key" ;;
		 "button_insert")   rc_sql_execute "$db" "$tb" "insert" "$field" "$key" "$values"
							max=$(sql_execute "$db" ".header off\nselect max($key)")
		                    if [ "$max" != "" ];then rc_sql_execute "$db" "$tb" "eq" 	"$field" "$max";fi ;;
		 "button_update")   rc_sql_execute "$db" "$tb" "update" "$field" "$key" "$values" ;;
		 "button_delete")   setmsg -q "$field=$key wirklich loeschen ?"
							if [ $? -gt 0 ];then setmsg "-w" "Vorgang abgebrochen";return  ;fi
							rc_sql_execute "$db" "$tb" "delete" "$field" "$key"  
							if [ $? -gt 0 ];then setmsg "-n" "sql_error";return  ;fi
							if [ "$values" = "" ];then return;fi
							nkey=$(rc_sql_execute "$db" "$tb" "gt" "$field" "$key")  
							if [ "$nkey" = "" ];then nkey=$(rc_sql_execute "$db" "$tb" "lt" "$field" "$key");fi
							if [ "$nkey" = "" ];then return;fi
							rc_sql_execute "$db" "$tb" "eq" "$field" "$nkey"  ;;
		 "button_clear")   	if [ -f "$valuefile" ];then echo "" > "$valuefile";fi ;;
		 "button_refresh")  cp -f "$valuefile.bak" "$valuefile" ;;
		 "cbox_i")          rc_gui_get_cmd "$db" "$tb" "$key";									# regel ermitteln
							entry=$($FUNCNAME "entry | $db | $tb | $field | $key" )				# entry ermitteln recursiv funktioniert!
							if [ "$FUNC" = "reference" ]; then
								sql_execute "$SDB" "$SCMD1  = \"$entry\"";						# aktuellen wert als erstes anzeigen
								sql_execute "$SDB" "$SCMD1 != \"$entry\"";						# dann die anderen
							else
								IFS='#';liste=($LISTE);unset IFS
								lng=${#entry}
								for arg in "${liste[@]}" ;do if [ "$entry"  = "${arg:0:$lng}" ];then echo $arg;break ;fi;done
								for arg in "${liste[@]}" ;do if [ "$entry" != "${arg:0:$lng}" ];then echo $arg		 ;fi;done
							fi						
							;;
		 "cbox_a")          rc_gui_get_cmd "$db" "$tb" "$key"
							if [ "$FUNC" = "liste" ];then SCMD2="$LCMD"  ;fi
							set_rc_value_extra "$key" "$SCMD2" "$values"
		                    ;;
		 "fselect") 	    sfile=$(get_fileselect "selectfile" "$entry" "letzter Pfad Fileselect")
							if [ "$?" -gt "0" ];then log "$FUNCNAME Suche abgebrochen"  ;fi
							set_rc_value "$field" "$sfile"
							;;
		 "action") 		    rc_gui_get_cmd "$db" "$tb" "$field"
							$ACTION "$entry"
							;;
		 *) 				setmsg -i   --width=400 "func $func nicht bekannt\ndb $db\ntb $tb\n$field\nentry $entry"
	esac
}
function rc_gui_get_xml () {
	log debug "$FUNCNAME ID $ID $@"
	db="$1";shift;tb="$1";shift;key="$1"
	sizetlabel=20;sizemeta=36;ref_entry=""
	eval 'cmd_ref=$'$(get_field_name $db$tb"_ref")
    eval 'cmd_fsl=$'$(get_field_name $db$tb"_fsl")
    eval 'cmd_bln=$'$(get_field_name $db$tb"_bln")
    IFS=",";name=($TNAME);unset IFS;IFS="|";meta=($TMETA);unset IFS
	echo '<vbox>'
	echo '	<vbox>'
	echo '		<hbox>'
	echo '			<entry width_chars="'$sizemeta'" space-expand="false">'
	echo '				<variable>entryp</variable>'
	echo '				<input>'$script' --func ctrl_rc_gui "entry | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]} '|' ${meta[$ID]}'"</input>'
	echo '			</entry>'
	echo '			<text width-chars="46" justify="3"><label>'$PRIMKEY' (PK) (type,null,default,primkey)</label></text>'
	echo '		</hbox>'
	echo '	</vbox>'
	echo '  <vbox hscrollbar-policy="0">'
    entrys="";del=""
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		rc_gui_get_cmd "$db" "$tb" "${name[$ia]}"
		if [ "$?" = "$true" ];then func=$FUNC;visible="false" ;else func="";visible="true";fi
		echo    '	<hbox>' 
		IFS='#';set -- $cmd;unset IFS
		if  [ "$func" = "" ] || [ "$func" = "fileselect" ]; then 
			echo    ' 			<entry width_chars="'$sizemeta'"  space-fill="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>true</sensitive>' 
			echo    ' 				<input>'$script' --func ctrl_rc_gui "entry  | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]} '|' ${meta[$ia]}'"</input>' 
			echo    ' 			</entry>' 
		fi
		entrys="${entrys}${del}"'$entry'"$ia";del="#"
		if [ "$func" = "fileselect" ]; then 
		    ref_entry="$ref_entry $ia"'_'"$ia" 
		    if [ "$ACTION" != "" ]; then
		    echo	'	        <button>'
			echo	'				<variable>entry'$ia'_'$ia'_'$ia'</variable>'
			echo	'				<input file stock="gtk-media-play"></input>'
    		echo	' 				<action>'$script' --func ctrl_rc_gui "action  | '$db '|' $tb '|' ${name[$ia]} '| $entry'$ia'"</action>'
			echo	'			</button>'
		    fi
			echo 	'			<button>'
            echo	'				<variable>entry'$ia'_'$ia'</variable>'
            echo	'				<input file stock="gtk-open"></input>'
            echo    '    			<action>'$script' --func ctrl_rc_gui "fselect | '$db '|' $tb '|' ${name[$ia]} '| $entry'$ia'"</action>'
            echo	'    			<action type="refresh">entry'$ia'</action>'	
            echo	'			</button>' 	
		fi
		if 	[ "$func" = "reference" ] || [ "$func" = "liste" ] ;then 
		    ref_entry="$ref_entry $ia""_""$ia"
			echo    ' 			<entry width_chars="5"  space-fill="true"  visible="false">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>false</sensitive>' 
			echo    ' 				<input>'$script' --func ctrl_rc_gui   "entry   | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]}'"</input>' 
			echo    ' 			</entry>' 
            echo  	' 			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false" visible="true">'
			echo 	' 				<variable>entry'$ia'_'$ia'</variable>'
			echo  	' 				<sensitive>true</sensitive>'
			echo  	' 		    	<input>'$script'  --func ctrl_rc_gui  "cbox_i  | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]}' | $entry'$ia'"</input>'
			echo  	'               <action>'$script' --func ctrl_rc_gui  "cbox_a  | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]}' | $entry'$ia'_'$ia'"</action>'
			echo  	'               <action type="refresh">entry'$ia'</action>'
			echo  	'       	</comboboxtext>'
		fi
		if 	[ "$func" = "cmd" ] ;then echo ${@:2};fi 
		echo  	' 			<text width-chars="'$sizemeta'" justify="2"><label>'${name[$ia]}' ('${meta[$ia]}')</label></text>'   
		echo    '	</hbox>' 
	done
	echo '	</vbox>'
	echo '	<hbox>'
	for label in back next read insert update delete clear refresh;do
		echo '		<button><label>'$label'</label>'
		echo '			<action>'$script' --func ctrl_rc_gui "button_'$label'  | '$db '|' $tb '|' $PRIMKEY '| $entryp | '$entrys'"</action>'
        if [ "$label" != "update" ] && [ "$label" != "insert" ];then rc_entrys_refresh;fi  
		echo '		</button>'
	done
	echo '		<button ok></button><button cancel></button>'
	echo '	</hbox>'
	echo '</vbox>'  
}
function rc_entrys_refresh () {
	log debug $FUNCNAME $@
	IFS=",";name=($TNAME);unset IFS;shift;IFS="|";meta=($TMETA);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" = "$PRIMKEY" ];then continue ;fi
		if [ ""${name[$ia ]}"" = "rowid" ];then continue ;fi
		echo '			<action type="refresh">entry'$ia'</action>'  
	done
	for entry in $ref_entry; do 
		echo '			<action type="refresh">entry'$entry'</action>' 
	done
	echo '			<action type="refresh">entryp</action>'
}
function get_ref_parms () { ref="$*";ref2=${ref#*\#};echo ${ref2%%\|*}; }
function rc_gui_get_cmd() {
	if [ "$nowidgets" = "true" ];then echo "";return 1;fi
	local db=$1;local tb=$2;local field="$3"
    found=$false
    IFS='|'
    for arg in "${cmdarr[@]}" ;do
		set $arg
		func="$1";db1="$2";tb1="$3";field1="$4";db2="$5";tb2="$6";cmd1="$7";cmd2="$8" 
		if [ "$db"    != "$db1" ];   then continue ;fi
		if [ "$tb"    != "$tb1" ];   then continue ;fi
		if [ "$field" != "$field1" ];then continue ;fi
		FUNC=$func;LCMD=$tb2;ACTION=$db2;SDB=$db2;FILEPARM=$tb2;STB=$tb2;SCMD1=$cmd1;SCMD2=$cmd2;found=$true;LISTE=$db2;break
	done
	unset IFS
	return $found
}
function rc_sql_execute () {
	log debug $FUNCNAME $@
	db=$1;shift;tb=$1;shift;local mode=$1;shift;PRIMKEY=$1;shift;row=$1;shift	
	if [ "$mode" = "update" ] || [ "$mode" = "insert" ];		then 
	     parm=$*;IFS='#';values=($parm);unset IFS
	     ia=-1;uline="";iline="";vline="";del=""
	     while read -r line;do
			field=$(trim_value "${line%%\ *}");value=$(trim_value "${line##*\ }" | tr -d '"')
			if [ "$field" = "$PRIMKEY" ];then continue ;fi
			ia=$((ia+1))
			uline="$uline$del$field"' = "'"${values[$ia]}"'"'
			iline="$iline$del$field"
			vline="$vline$del"'"'"${values[$ia]}"'"'
			del=","
	     done < "$valuefile"
	fi
	if [ "$mode" = "eq" ];		then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" = "delete" ];	then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" = "update" ];	then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" = "lt" ];		then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" = "gt" ];		then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	if [ "$PRIMKEY" = "rowid" ];then srow="rowid," ;else srow="";fi
	case "$mode" in
		 "delete")	erg=$(sql_execute "$db" "delete from $tb $where") ;;
		 "update")	erg=$(sql_execute "$db" "update $tb set "$uline "$where") ;;
		 "insert")	erg=$(sql_execute "$db" "insert into $tb (${iline}) values (${vline})") ;;
		  *)  		erg=$(sql_execute "$db" ".mode line\n.header off\nselect ${srow}* from $tb $where")
	esac
	if [ "$?" -gt "0" ];		then return 1;fi
	if [ "$mode" = "delete" ];	then setmsg -n "success delete";return  ;fi
	if [ "$mode" = "insert" ];	then setmsg -n "success insert";return  ;fi
	if [ "$mode" = "update" ];	then setmsg -n "success update";return  ;fi
	if [ "$erg"  = ""  ];then setmsg -i "keine id $mode $row gefunden"  ;return 1;fi
    echo -e "$erg" > "$valuefile"
    cp -f "$valuefile" "$valuefile.bak"
}
function rc_get_parm () {
	field="$1";shift;nr="$1";shift;type="$1" 
	val=$(tb_get_meta_val $nr)
	stmt=".mode csv\nselect parm_value from parm where parm_field   = \"$val\" and parm_type = \"$type\""
	sql_execute $dbparm $stmt | tr -d '"'
	stmt=".mode csv\nselect parm_value from parm where parm_field  != \"$val\" and parm_type = \"$type\""
	sql_execute $dbparm $stmt | tr -d '"'
	echo "$please_choose"
}
function setmsg () { func_setmsg $*; }
function get_field_name () { echo $(readlink -f "$*") | tr -d '/.'; }
function get_fileselect () {
	label="$1";path="$2";comment="$3"
	if [ "$label" = "" ];then label="searchpath"  ;fi
	if [ "$comment" = "" ];then comment="letzter pfad fuer file-select"  ;fi
	if [ "$path" = "" ];then path=$searchpath  ;fi
	if [ "$path" = "" ];then path=$HOME;fi
	mydb=$(zenity --file-selection --title "select sqlite db" --filename=$path)
	if [ "$mydb" = "" ];then echo "";return 1;fi
	setconfig_file "$label" "$mydb" "-" "$comment"
	echo $mydb 
}
function is_database () {
	if [ "$*" = "" ];then return 1;fi
	sql_execute "$*" ".databases" > /dev/null
	if [ "$?" -gt "0" ];then return 1;else return 0;fi
}
function is_table () {	
	if [ "$2" = "" ];then return 1;fi 
	tb=$(sql_execute "$1" ".table $2")
	if [ "$tb" = "" ];then return 1;else return 0;fi
}
function setconfig_db () {
	set +x
	getfield="$1";shift;type=$1;field="$2 $3 $4";value=${@:5}  
#	setmsg -i "$getfield\n$type\n$field\n$value";return
#	if [ "$type" = "wherelist" ];then getfield="parm_value" ;else getfield="parm_id" ;fi
 	id=$(sql_execute $dbparm ".header off\nselect $getfield from parm where parm_field = \"$field\" and parm_type = \"$type\"")
#	setmsg -i "$getfield\n$type\n$field\n$value\nid $id" ;return
	if [ "$type" = "wherelist" ] && [ "$id" = "$value" ];then return 0 ;fi
	if [ "$id" != "" ] && [ "$type" != "wherelist" ]; then
		 sql_execute "$dbparm" "update parm set parm_value = \"$value\" where parm_id = \"$id\""
 	else
 		sql_execute $dbparm "insert into parm (parm_field,parm_value,parm_type) values ('$field','$value','$type')"
	fi
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME sql_error";return 1 ;else return 0 ;fi
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
#	sort -u "$path/tmp/configrc" > "$x_configfile"
	cp -f "$path/tmp/configrc"   "$x_configfile"
	return
	cp -f "$x_configfile" "$path/tmp/configrc"  
	grep -v "# $comment" "$path/tmp/configrc" > "$x_configfile"
	echo "$line" >> "$x_configfile"
}
function getconfig_db () {
	getfield="$1";type="$2";field="$3"" ""$4"" ""$5";value=${@:5}
	sql_execute $dbparm ".header off\nselect $getfield from parm where parm_field = \"$field\" and parm_type = \"$type\"" | tr -d '"'
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME sql_error";return 1;else return 0 ;fi
}
function getconfig () {
	lb=$1;shift;db=$1;shift;tb=$1;shift
	if [ "$tb" != "" ];then eval 'echo $'"$(get_field_name $db)"'dfltwhere'"$lb$tb";return  ;fi
	if [ "$db" != "" ];then eval 'echo $'"$(get_field_name $db)"'dflttb'"$lb";return;fi
	if [ "$lb" != "" ];then eval 'echo $dfltdb'"$lb";return;fi
	setmsg -w ---width=300 "getconfig parameter nicht erkannt\n$lb $db $tb";return 1
}
function setconfig () {
	label=$1;shift;db=$1;shift;tb=$1;shift;where="$*"
	if 		[ "$label" !=  "tb" ]; then
			setconfig_file "dfltdb$label" "$db" "-" "default-datenbank fuer label=$label"
			field=$(get_field_name $db)
	fi
	if 		[ "$tb" = "" ];then return;fi
	if 		[ "$label" != "$tb" ]; then
			setconfig_file "$(get_field_name $db)dflttb$label"    "$tb"    "-" "default-tabelle fuer tbselect (label=$label)"
	fi
	if 		[ "$where" = "" ];then return;fi
	setconfig_file "$(get_field_name $db)dfltwhere$label$tb" "$where" "-" "default-where fuer $tb (label=$label)"
	setconfig_file "dummy" "$where" "+" "$db $tb"
}
function set_rc_value_extra   () {
	set -x
	field=$1;shift;range="$1";shift;value=$(echo $* | tr  ',' ' ' | tr -d '"')
	if [ "$value" = "" ]; then return;fi
	if [ "${value:2:2}" = "--" ]; then return;fi
	IFS=",";range=($range);IFS=" ";value=($value);unset IFS;parm="";del=""
	for arg in ${range[@]}; do parm=$parm$del${value[$arg]};del=" ";done	
	setmsg -i -d "$FUNCNAME break\n$parm"
	set_rc_value $field "$parm"
}
function trim_value   () { 
#	setmsg -i break $*
#	echo trim $*
	echo $* ; 
}
function set_rc_value   () {
	field=$1;shift;value="$*"
	cp -f "$valuefile" "$valuefile"".bak2"
	while read line;do
		name=$(trim_value "${line%%=*}") 
		if [ "$field" != "$name" ];then echo $line;continue;fi  
		echo "$name = ${value}"
	done  < "$valuefile"".bak2" > "$valuefile"
	setmsg -i -d "$FUNCNAME break\n$parm"
}
function tb_get_tables () {
	log debug $FUNCNAME $* 
 	if [ "$1" = "" ];then  return ;fi
	if [ -d "$1" ];then setmsg "$1 ist ein Ordner\nBitte sqlite_db ausaehlen" ;return ;fi
	sql_execute "$1" '.tables' | fmt -w 2 | grep -v -e '^$'  
	if [ "$?" -gt "0" ];then return 1;fi
}
function sql_execute () { func_sql_execute $*; }
function tb_get_meta_val   () {
	nr=$1  
	str=$(head -n $(($nr+1)) "$valuefile" | tail -n 1)
	str="${str#*\= }"
	IFS="|";arrmeta=($TMETA);IFS=",";meta=(${arrmeta[$nr]});unset IFS
	if [ "$str" != "" ] && [ "$1" ==  "$ID" ];then  echo "$str" > "$idfile";fi
	if [ "$str" == "" ] && [ "${meta[3]}" == "1" ]; then  str=$(cat "$idfile");fi 
	if [ "$str" == "" ];then
	   if   [ "${meta[2]}" != "" ]; then  str="${meta[2]}"  
	   elif [ "${meta[1]}" != "0" ];then  str="="  
	   else                               str="NULL"
	   fi
	fi   
    echo $str | tr -d '\r'
} 
function terminal_cmd () {
	termfile="$1" ;local db="$(getconfig $2 $3)"
	echo ".exit" 		>  "$termfile" 
	echo "sqlite3 $db" 	>> "$termfile"  
}
function x_read_csv () {
	file=$*;[ ! -f "$file" ] && setmsg -w --width=400 "kein file $file" && return
	sql_execute $dbparm "drop table if exists tmpcsv;"
	sql_execute $dbparm ".import $file tmpcsv"
	notable="$true";ctrl_tb $dbparm tmpcsv 
	gtkdialog  -f "$dfile"
	setmsg -q "speichern ?"
	if [ "$?" -gt "0" ];then return;fi
	sql_execute $dbparm "select * from tmpcsv" > "$file"
}
function zz () { return; } 
	ctrl $*
