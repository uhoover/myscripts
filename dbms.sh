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
	getconfig_db 'parm_value' 'rc_field' '/home/uwe/my_databases/parm.sqlite_parm_parm_id'
	setconfig_db 'parm_id'    'rc_field' '/home/uwe/my_databases/parm.sqlite_parm_parm_id' 276276
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
	script=$(readlink -f $0)  
	x_configfile="$path/.configrc" 
	dbparm="$path/parm.sqlite" 
	parmtb="parm" 
	limit=150;term_hight=8
	tmpf="$path/tmp/dialogtmp.txt"   
	pparms=$*
	notable=$false;visible="true";myparm="";nowidgets="false";wtitle="Uwes sqlite dbms";X=400;Y=600
	source $x_configfile
	ctrl_config
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
function ctrl_config() {
	if [ ! -f "$x_configfile" ];then 
		echo "# defaultwerte etc:" 									>> "$x_configfile" 
		echo "tpath=\"$path/tmp\"						#	target temporary files" 	>> "$x_configfile" 
		echo "dbparm=\"$path/parm.sqlite\" 				#	parm database" 				>> "$x_configfile" 
		echo "parmtb=\"parm\" 							#	parm table" 				>> "$x_configfile" 
		echo "term_hight=\"8\"							#	anzahl zeilen terminal"		>> "$x_configfile" 
		echo "limit=150 								#	 " 							>> "$x_configfile" 
		echo "tmpf=\"$path/tmp/dialogtmp.txt\" 			#	 " 							>> "$x_configfile" 	  
	fi 
	if [ "$parmtb" = "" ]; then parmtb="parms";fi
	if [ -f $dbparm ];then 
		table=$(sql_execute $dbparm ".tables $parmtb") ;
		if [ "$table" = "$parmtb" ];then return  ;fi
	fi
	sqlite3 $dbparm << EOF
    create table if not exists $parmtb (
		parm_id		INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		parm_status	TEXT,
		parm_type	TEXT,
		parm_field	TEXT,
		parm_value	TEXT,
		parm_info	TEXT);
	insert into $parmtb values 	(null,0,"boolean","true","0		true",null),	(null,0,"boolean","false","1	false",null),
								(null,0,"status","aktiv","0	 	aktiv",null),	(null,0,"status","busy","1	busy",null),
								(null,0,"status","ready","2	 	ready",null),	(null,0,"status","done","3	done",null),
								(null,0,"status","inaktiv","9	  inaktiv",null);
EOF
}
function ctrl_tb () {
	dbliste=$(tb_get_labels $*)												# datenbanken und tabellen ermitteln
	IFS="|";arr=($dbliste);unset IFS
	if [ "${#arr[@]}" -lt "1" ];then setmsg -i "keine gueltigen Parameter";return 1 ;fi
	notebook="";for arg in ${arr[@]};do notebook="$notebook ${arg%%#*}";done 
    xmlfile="$tpath/xml_$(echo $notebook | tr ' ' '_').xml"
    geometryfile="$tpath/geometry_$(echo $notebook | tr ' ' '_').txt"
	echo "<window title=\"$wtitle\">" > $xmlfile
	echo "<notebook show-tabs=\"$visible\"  tab-labels=\""$(echo $notebook | tr '_ ' "-|")"\">" >> $xmlfile
	for arg in "${arr[@]}" ;do
		IFS='#';set -- $arg;unset IFS 
 		log "$FUNCNAME label $1 db $2 tb $3"  
  		tb_gui_get_xml "$1" "$2" "$3" >> $xmlfile 
	done
	echo "</notebook></window>" >> $xmlfile
	X=10;Y=10;HEIGHT=800;WIDTH=900
    [ -f "$geometryfile" ] && source "$geometryfile" 						# falls xwin informationen gespeichert sind
    geometry="$WIDTH""x""$HEIGHT""+""$X""+""$Y"
##
    gtkdialog -f "$xmlfile" --geometry="$geometry" > $tmpf					# start dialog
##    
    while read -r line;do
		echo $line															# defaultwerte speichern
       field="${line%%\=*}";value=$(echo "${line##*\=}" | tr -d '"')
       if [ "${line:0:6}" = "CBOXTB" ];then  labela+=( ${field:6} ) ;fi  	# label
       if [ "${line:0:6}" = "CBOXTB" ];then cboxtba+=( $value ) ;fi 		# tabelle
       if [ "${line:0:6}" = "CBOXWH" ];then cboxwha+=( $value ) ;fi 		# where
       if [ "${line:0:5}" = "ENTRY" ]; then  entrya+=( $value ) ;fi 		# database
       if [ "${line:0:4}" = "TREE" ];  then   treea+=( $value ) ;fi 		# last selected row
    done < $tmpf
    for ((ia=0;ia<${#cboxtba[@]};ia++)) ;do
		if [ "${entrya[$ia]}" != "" ];	then 
			setconfig_db "parm_id" "defaultdatabase" 	"${labela[$ia]}"  								"${entrya[$ia]}" 
		fi   
		if [ "${cboxtba[$ia]}" != "" ];	then
			setconfig_db "parm_id" "defaulttable"		"${labela[$ia]} ${entrya[$ia]}" 				"${cboxtba[$ia]}"  
		fi  
#			setconfig_db "parm_id" "defaultwhere"		"${labela[$ia]} ${entrya[$ia]} ${cboxtba[$ia]}" "${cboxwha[$ia]}"   
		if [ "${treea[$ia]}" != "" ];	then
			setconfig_db "parm_id" "defaultrow"			"${labela[$ia]} ${entrya[$ia]} ${cboxtba[$ia]}" "${treea[$ia]}"
		fi   
	done
}
function ctrl_tb_gui () {
#	func=$1;shift;label=$1;shift;db="$1";shift;tb="$1";shift;db_gui="$1";shift;tb_gui="$1";shift;where_gui="$*";row=$where_gui
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	func=$(trim_value ${parm[0]});label=$(trim_value ${parm[1]});db=$(trim_value ${parm[2]});tb=$(trim_value ${parm[3]})
	db_gui=$(trim_value ${parm[4]});tb_gui=$(trim_value ${parm[5]});where_gui=$(trim_value ${parm[6]});row=$(trim_value ${parm[7]})
	setmsg -i -d --width=600 "func $func\nlabel $label\ndb $db\ntb $tb\ndb_gui $db_gui\ntb_gui $tb_gui\nwhere_gui $where_gui\nrow $row"
	found=$true
	if [ "$func"    = "entry" ];	then db_gui="" ;fi
	if [ "$db_gui" != "" ];			then db=$db_gui ;fi
	if [ "$db" 		= "dfltdb" ];	then db=$(getconfig_db parm_value defaultdatabase $label);fi
	if [ "$db" 		= "" ];			then found=$false;db=$(get_fileselect parm_value searchpath database);fi
	is_database $db
	if [ "$?" -gt "0" ];			then setmsg -w "keine Datenbank ausgewaehlt";exit;fi
	if [ "$found"   = "$false" ];	then setconfig_db parm_id defaultdatabase "$label" "$db";return;fi
	if [ "$tb_gui" != "" ];			then tb=$tb_gui ;fi
	if [ "$tb" 		= "dflttb" ] || [ "$tb" 		= "" ];
									then	
									     tb=$(getconfig_db parm_value defaulttable "$label $db") 
										 if [ "$tb" 		= "" ];			then 
											tb=$(tb_get_tables "$db" "batch"| head -n1)
										 fi
		   								 setconfig_db parm_id defaulttable "$label $db" "$tb"
									fi
	if [ "$tb"      = "" ];			then setmsg -w "keine Tabelle gefunden";exit;fi
	if [ "$where_gui" != "" ]; 		then where="$where_gui" ;fi
	if [ "$where"   = "" ]; 		then where=$(getconfig_db parm_value defaultwhere $label $db $tb | remove_quotes);fi 
	setmsg -i -d "$FUNCNAME\nfunc $func\ndb $db\ntb $tb \nwhere $where"
	case "$func" in
#		"entry")   	getconfig_db parm_value defaultdatabase "$label" ;;
		"entry")   	echo $db ;;
		"fselect") 	db=$(get_fileselect parm_value searchpath database)
					is_database $db
					if [ "$?" = "0" ];then setconfig_db parm_id defaultdatabase "$label" "$db";fi
					return
					;;
		"cboxtb") 	if [ "$label" = "$tb" ];then echo $tb;return;fi
					if [ "$db" = "" ];	then setmsg -e "keine Datenbank gefunden";return;fi 
					tb=$(getconfig_db parm_value defaulttable "$label $db") 
		            if [ "$tb" != "" ];then echo $tb; else tb=" ";fi
		            tb_get_tables "$db" "batch" | grep -v "$tb" ;;
		"cboxwh") 	where=$(getconfig_db parm_value defaultwhere $label $db $tb) | remove_quotes
					if [ "$where" != "" ];then echo "$where" ; else where=" ";fi
					log debug  "$FUNCNAME\nlabel $label\ndb    $db\ntb    $tb\ndefaultwhere $where"
					sql_execute "$dbparm" "select parm_value from $parmtb where parm_field = \"$label $db $tb\" and parm_type = \"wherelist\"" | remove_quotes
					;;
		"tree") 	tb_read_table $label "$db" $tb "$where" ;;
		"b_delete") ctrl_rc_gui "button_delete | $db | $tb $PRIMKEY | $row";;
		*) 			setmsg -w "$func nicht bekannt"
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
	row=$(getconfig_db parm_value defaultrow "$label" "$db" "$tb" |  tr -d '"' )
	if [ "$row" != "" ];then selected_row="selected-row=\"$row\"" ;else selected_row=""  ;fi
	terminal="${tpath}/cmd_${label}.txt"
	terminal_cmd "$terminal" "$label" "$db" 
	echo '    <vbox>
		<tree headers_visible="true" hover_selection="false" hover_expand="true" exported_column="'$ID'" sort-column="'$ID'" '$selected_row'>
			<label>"'$lb'"</label>
			<variable>TREE'$label'</variable>
			<input>'$script' --func ctrl_tb_gui "tree | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</input>
			<action>'$script' '$nocmd' --func ctrl_rc $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>	
			<action type="refresh">CBOXWH'$label'</action>		
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true">  
				<variable>ENTRY'$label'</variable> 
				<sensitive>false</sensitive>  
				<input>'$script' --func ctrl_tb_gui "entry | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWHERE'$label'"</input>
				<action>'$script' --func terminal_cmd '$terminal' '$label' $ENTRY'$label'</action>
				<action type="refresh">TERMINAL'$label'</action>
			</entry> 
			<button space-fill="false">
            	<variable>BUTTONFSELECT'$label'</variable>
            	<sensitive>'$sensitiveFSELECT'</sensitive>
            	<input file stock="gtk-open"></input>
				<action>'$script' --func ctrl_tb_gui "fselect | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWHERE'$label'"</action>
            	<action type="clear">ENTRY'$label'</action>	
            	<action type="refresh">ENTRY'$label'</action>
            	<action type="refresh">CBOXTB'$label'</action>		
            </button> 
		  </hbox>
			<comboboxtext space-expand="true" space-fill="true" allow-empty="false">
				<variable>CBOXTB'$label'</variable>
				<sensitive>'$sensitiveCBOX'</sensitive>
				<input>'$script' --func ctrl_tb_gui "cboxtb | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWHERE'$label'"</input>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</comboboxtext>	
		</hbox>
		<hbox>
			<comboboxentry space-expand="true" space-fill="true" allow-empty="true">
				<variable>CBOXWH'$label'</variable>
				<input>'$script' --func ctrl_tb_gui "cboxwh | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWHERE'$label'"</input>
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
				<action>'$script' --func ctrl_tb_gui "b_delete | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWHERE'$label'| $TREE'$label'"</action>			
				<action type="refresh">TREE'$label'</action>
				<action type="refresh">CBOXWH'$label'</action>
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD'$label'</variable>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
				<action type="refresh">CBOXWH'$label'</action>	
			</button>
			<button>
				<label>ok</label>
				<action>'$script' --func save_geometry "'"${wtitle}#${geometryfile}"'"</action>	
				<action type="exit">CLOSE</action>
			</button>
		</hbox>
		<terminal space-expand="false" space-fill="false" text-background-color="#F2F89B" text-foreground-color="#000000" 
			autorefresh="true" argv0="/bin/bash" visible="false">
			<variable>TERMINAL'$label'</variable>
			<height>'$term_hight'</height>
			<input file>"'$terminal'"</input>
		</terminal>
	</vbox>'
} 
function tb_meta_info () {
	db="$1";tb="$2";local del="";local del2="";local del3="";local line=""
	TNAME="" ;TTYPE="" ;TNOTN="" ;TDFLT="" ;TPKEY="";TMETA="";TSELECT="";local ip=-1;local pk="-"
	sql_execute "$db" ".header off\nPRAGMA table_info($tb);"   > $tmpf
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
	done < $tmpf
	if [ "$PRIMKEY" = "" ];then 
		PRIMKEY="rowid";ID=0
		TNAME="rowid$del$TNAME";TTYPE="Integer$del$TTYPE";TNOTN="1$del$TNOTN";
		TDFLT="' '$del$TDFLT";TPKEY="1$del$TPKEY";TMETA="rowid$del2$TMETA"
	fi 
}
function tb_read_table() {
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$*  
	setmsg -i -d "$FUNCNAME\nlabel $label\ndb    $db\ntb    $tb\nwhere $where"
	tb_meta_info "$db" $tb
	if [ "$PRIMKEY" = "rowid" ];then srow="rowid," ;else srow="";fi
	if [ "$label" 	= "$tb" ];	then off="off" ;else off="on"  ;fi					# jeder select wird archiviert
	sql_execute $db ".separator |\n.header $off\nselect ${srow}* from $tb $where;"  | tee $epath/export_${tb}_$(date "+%Y%m%d%H%M").txt 
	if [ "$?"   	-gt "0" ];	then return ;fi 
	setconfig_db "parm_id"    "defaultwhere"  "$label $db $tb" "$where" 
	if [ "$where" 	= "" ]; 	then return ;fi 
	setconfig_db "parm_value" "wherelist"     "$label $db $tb" "$where" 		
}
function ctrl_rc () {
	log $FUNCNAME $*
	if [ "$#" -gt "3" ];then setmsg -w  " $#: zu viele Parameter\n tabelle ohne PRIMKEY?" ;return  ;fi
	row="$1";shift;db="$1";shift;tb="$@"
	tb_meta_info "$db" "$tb"
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME\nerror Meta-Info\n$db\n$tb";return ;fi
	if [ "$row" = "insert" ]; then
		echo "" > "$path/tmp/value_${tb}.txt" 
	else
		rc_sql_execute $db $tb eq $PRIMKEY $row 
	fi
    row_change_xml="$path/tmp/change_row_${tb}.xml"	
    rc_gui_get_xml $db $tb $row  > "$row_change_xml"	
 	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function ctrl_rc_gui () {
	log -d $FUNCNAME $@
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	func=$(trim_value ${parm[0]});db=$(trim_value ${parm[1]});tb=$(trim_value ${parm[2]});entry=$(trim_value ${parm[3]})
	field=$(trim_value ${parm[3]});key=$(trim_value ${parm[4]});entry=$(trim_value ${parm[4]});values=$(trim_value ${parm[@]:5})
	case $func in
		 "entry")   	    str=$(grep "$key" "$path/tmp/value_${tb}.txt");value="${str#*\= }" 
							if [ "$value" != ""  ];then echo $(trim_value $value | tr -d '"');return;fi
							IFS=',';meta=$(trim_value ${parm[6]});unset IFS
							if [ "$field" = "$key" ]; then 
								value=$(grep "$field" "$path/tmp/value_${tb}.txt.bak");echo "${value#*\= }";return 
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
		 "button_clear")   	if [ -f "$path/tmp/value_${tb}.txt" ];then echo "" > "$path/tmp/value_${tb}.txt";fi ;;
		 "button_refresh")  cp -f "$$path/tmp/value_${tb}.txt.bak" "$path/tmp/value_${tb}.txt" ;;
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
		FUNC=$func;LCMD=$tb2;ACTION=$db2;SDB=$db2;FILEPARM=$tb2;STB=$tb2;SCMD1=$cmd1;SCMD2=$cmd2;found=$true;LISTE=$db2
		break
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
	     done < "$path/tmp/value_${tb}.txt"
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
    echo -e "$erg" > "$path/tmp/value_${tb}.txt"
    cp -f "$path/tmp/value_${tb}.txt" "$path/tmp/value_${tb}.txt.bak"
    echo "delete from $parmtb where parm_field like \"$db $tb ${line%%\ *}%\" and parm_type = \"rc_field\";" > $tmpf
    while read -r line;do
		echo "insert into $parmtb (parm_type,parm_field,parm_value) values (\"rc_field\",\"${db}_${tb}_$(trim_value ${line%%\=*})\",\"$(trim_value ${line##*\=})\");"
	done < "$path/tmp/value_${tb}.txt" >> $tmpf
}
function setmsg () { func_setmsg $*; }
function get_field_name () { echo $(readlink -f "$*") | tr -d '/.'; }
function get_fileselect () {
	getfield="$1";shift;type="$1";shift;field="$*" 
	path=$(getconfig_db $getfield $type "$field")
	if [ "$path" = "" ];	then path=$HOME;fi
	mydb=$(zenity --file-selection --title "select $type" --filename=$path)
	if [ "$mydb" = "" ];	then echo "";return 1;fi
	setconfig_db "parm_id" "searchpath" "$field" "$mydb"  
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
	getfield="$1";shift;type="$1";shift;field="$1";shift;value=$*
#	log debug "$FUNCNAME getfield $getfield type #$type# field  $field  value $value id   $id" 
	if [ "$type" = "wherelist" ]; then
		id=$(sql_execute $dbparm ".header off\nselect $getfield from $parmtb where parm_field = '$field' and parm_value = '$value' and parm_type = '$type' limit 1")
	else
		id=$(sql_execute $dbparm ".header off\nselect $getfield from $parmtb where parm_field = \"$field\" and parm_type = \"$type\" limit 1")
	fi
#	log debug "$FUNCNAME $type $id"
	if [ "$type" = "wherelist" ] ;then
	    str1=$(echo $id    | tr -d '"')
	    str2=$(echo $value | tr -d '"')
	    if [ "$str1" = "$str2" ];then return 0;fi
	    setmsg -i -d "id $id\nvalue $value\nid_2 $str1\nvalue_2 $str2"
	fi
#	if [ "$id" != "" ] && [ "$type" != "wherelist" ]; then
	if [ "$id" != "" ] ; then
		sql_execute "$dbparm" "update $parmtb set parm_value = '$value' where parm_id = \"$id\""
 	else
 		sql_execute $dbparm "insert into $parmtb (parm_field,parm_value,parm_type) values ('$field','$value','$type')"
	fi
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME sql_error";return 1 ;else return 0 ;fi
}
function getconfig_db () {
	getfield="$1";type="$2";field="$3";shift;shift;shift;value=$*
	log debug "$FUNCNAME parmtb $parmtb\ngetfield $getfield\ntype $type\nfield $field\nvalue $value"
	sql_execute $dbparm ".header off\nselect $getfield from $parmtb where parm_field = \"$field\" and parm_type = \"$type\" limit 1" #>> $logfile
	log debug "$FUNCNAME getfield $getfield\ntype $type\nfield $field\nvalue $value"
	setmsg -i -d --width=400 "$FUNCNAME getfield $getfield\ntype $type\nfield $field\nvalue $value"
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME sql_error";return 1;else return 0 ;fi
}
function set_rc_value_extra   () {
	field=$1;shift;range="$1";shift;value=$(echo $* | tr  ',' ' ' | tr -d '"')
	if [ "$value" = "" ]; then return;fi
	if [ "${value:2:2}" = "--" ]; then return;fi
	IFS=",";range=($range);IFS=" ";value=($value);unset IFS;parm="";del=""
	for arg in ${range[@]}; do parm=$parm$del${value[$arg]};del=" ";done	
	setmsg -i -d "$FUNCNAME break\n$parm"
	set_rc_value $field "$parm"
}
function trim_value   () { echo $* ; }
function set_rc_value   () {
	field=$1;shift;value="$*"
	cp -f "$path/tmp/value_${tb}.txt" "$path/tmp/value_${tb}.txt.bak2"
	while read line;do
		name=$(trim_value "${line%%=*}") 
		if [ "$field" != "$name" ];then echo $line;continue;fi  
		echo "$name = ${value}"
	done  < "$path/tmp/value_${tb}.txt.bak2" > "$path/tmp/value_${tb}.txt"
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
function terminal_cmd () {
	termfile="$1" ;local db="$(getconfig_db parm_value defaultdatabase $2 - -)" #lb=$1;shift;db=$1;shift;tb=$1;shift
	echo ".exit" 		>  "$termfile" 
	echo "clear" 		>  "$termfile" 
	echo "sqlite3 $db" 	>> "$termfile"  
}
function remove_quotes () {
	while read -r line;do
		lng=${#line}
        if [ "$lng" -gt "3" ] && [ "${line:0:2}" = '""' ]; then lng=${#line};line="${line:2:$lng-3}";fi	
        if [ "$lng" -gt "2" ] && [ "${line:0:1}" = '"' ];  then lng=${#line};line="${line:1:$lng-2}";fi	
        echo $line | tr -s '"'
    done
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
