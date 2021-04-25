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
 source $x_configfile
	if [ "$limit" = "$" ];then limit=150  ;fi
	script=$(readlink -f $0)   
	tmpf="$path/tmp/dialogtmp.txt"
	tableinfo="$path/tmp/tableinfo.txt"  
	valuefile="$path/tmp/value.txt"
	dbparm="$path/parm.sqlite"
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
	        "--help"|-h)								func_help $FUNCNAME;echo -e "\n     usage dbname [table --all]]" ;return;;
	        "--all"|--tab-each-table)					myparm="$myparm $1";;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										myparm="$myparm $1";;
	    esac
	    shift
	done
    log start tlog
    log debug $pparms 
	ctrl_tb $myparm	
#	tb_create_dialog $myparm	
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
    gtkdialog -f "$xmlfile" --geometry="$geometry"
}
function ctrl_tb_gui () {
	func=$1;shift;label=$1;shift;db="$1";shift;tb="$1";shift;db_gui="$1";shift;tb_gui="$1";shift;where_gui="$*"
	setmsg -i -d --width=600 "func $func\nlabel $label\ndb $db\ntb $tb\ndb_gui $db_gui\ntb_gui $tb_gui\nwhere_gui $where_gui"
	set +x
	if [ "$func"    = "entry" ];	then db_gui="" ;fi
	if [ "$db_gui" != "" ];			then db=$db_gui ;fi
	if [ "$db" 		= "dfltdb" ];	then db=$(getconfig $label);fi
	if [ "$db" 		= "" ];			then db=$(get_fileselect);fi
	is_database $db
	if [ "$?" -gt "0" ];			then setmsg -w "keine Datenbnk ausgewaehlt";return;fi
	if [ "$tb_gui" != "" ];			then tb=$tb_gui ;fi
	if [ "$tb" 		= "dflttb" ];	then tb=$(getconfig $label $db);fi
	if [ "$tb" 		= "" ];			then tb=$(getconfig $label $db);fi
	if [ "$tb" 		= "" ];			then tb=$(x_get_tables "$db" "batch"| head -n1);fi
	if [ "$tb"      = "" ];			then setmsg -w "keine Tabelle gefunden";return;fi
	if [ "$where_gui" != "" ]; 		then where="$where_gui" ;fi
	if [ "$where"   = "" ]; 		then where=$(getconfig $label $db $tb);fi
	set +x; setmsg -i -d  "pause" 
	case "$func" in
		"entry") 	echo $(getconfig $label);return;;
		"fselect") 	db=$(get_fileselect);is_database $db;if [ "$?" = "0" ];then setconfig $label $db;fi;return;;
		"cboxtb") 	set +x;db=$(getconfig $label)
					if [ "$db" = "" ];	then setmsg -e "keine Datenbank gefunden";return;fi
					tb=$(getconfig $label $db)
		            if [ "$tb" != "" ];then echo $tb; else tb=" ";fi
		            x_get_tables "$db" "batch" | grep -v "$tb" ;;
		"cboxwh") 	where=$(getconfig $label $db $tb)
					if [ "$where" != "" ];then echo $where; else where=" ";fi
					tb_get_where_list $label $db $tb | grep -v "$where";;
		"tree") 	tb_read_table $label "$db" $tb "$where";;
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
			x_get_tables "$db" > $tmpf 
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
	terminal="${tpath}/cmd_${label}.txt"
	terminal_cmd "$terminal" "$label" "$db" 
	echo '    <vbox>
		<tree headers_visible="true" hover_selection="false" hover_expand="true" exported_column="'$ID'">
			<label>"'$lb'"</label>
			<variable>TREE'$label'</variable>
			<input>'$script' --func ctrl_tb_gui tree      '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
			<action>'$script' '$nocSmd' --func ctrl_rc $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>	
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
			<comboboxtext space-expand="true" space-fill="true" allow-empty="false">
				<variable>CBOXWH'$label'</variable>
				<input>'$script' --func ctrl_tb_gui cboxwh  '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</comboboxtext>	
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
				<action>'$script' --func sql_rc_ctrl insert $ENTRY'$label' $CBOXTB'$label'</action>
			</button>
			<button visible="true">
				<label>update</label>
				<variable>BUTTONAENDERN'$label'</variable>
				<sensitive>false</sensitive> 
				<action>'$script' --func sql_rc_ctrl $TREE'$V' $ENTRY'$label' $CBOXTB'$label'</action>
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD'$label'</variable>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</button>
			<button>
				<label>cancel</label>
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
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$(echo $* | tr -d '"')
	tb_meta_info "$db" $tb
	if [ "$PRIMKEY" = "rowid" ];then srow="rowid," ;else srow="";fi
	if [ "$label" = "$tb" ];then off="off" ;else off="on"  ;fi
	sql_execute $db ".separator |\n.header $off\nselect ${srow}* from $tb $where;"  | tee $epath/export_${tb}_$(date "+%Y%m%d%H%M").txt 
	if [ "$?" -gt "0" ];then return ;fi 
	setconfig "$label" "$db" "$tb" "$where" 
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
		sql_rc_sql_execute $db $tb eq $PRIMKEY $row > "$valuefile"
	fi
    row_change_xml="$path/tmp/change_row_${tb}.xml"	
    rc_gui_get_xml $db $tb $row  > "$row_change_xml"	
 	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function ctrl_rc_gui () {
	log $FUNCNAME $@
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	func=$(trim ${parm[0]});db=$(trim ${parm[1]});tb=$(trim ${parm[2]});field=$(trim ${parm[3]});key=$(trim ${parm[4]});values=$(trim ${parm[@]:5})
#	setmsg -i --width=400 "func #$func#\ndb #$db#\ntb #$tb#\nfield #$field#\nrvalues #${values}#"
	tb_meta_info "$db" "$tb"
	[ "$?" -gt "0" ] && setmsg -i "$FUNCNAME\nerror meta-info\n$db\$tb" && return
	IFS=',';name=($TNAME);notn=($TNOTN);ndflt=($TDFLT);unset IFS
	case $func in
		 "entry")   		str=$(grep "$field" "$valuefile");value="${str#*\= }" 
							if [ "$value" != ""  ];then echo $(trim $value | tr -d '"');return;fi
							if [ -f "$valuefile" ];then echo '';return;fi
							IFS=',';meta=$(trim ${parm[5]});unset IFS
							if [ "$field" = "$PRIMKEY" ]; then 
								value=$(grep "$field" "$valuefile.bak");echo "${value#*\= }";return 
							fi 	 
							if   [ "${meta[2]}" != "" ]; then  echo "${meta[2]}"  
							elif [ "${meta[1]}" != "0" ];then  echo "="  
							else                               echo "null"
							fi
							;;	 
		 "button_back")   	rc_sql_execute "$db" "$tb" "lt" 	"$field" "$key" ;;
		 "button_next")   	rc_sql_execute "$db" "$tb" "gt" 	"$field" "$key" ;;
		 "button_read")   	rc_sql_execute "$db" "$tb" "eq" 	"$field" "$key" ;;
		 "button_insert")   rc_sql_execute "$db" "$tb" "insert" "$field" "$key" "$values" ;;
		 "button_update")   rc_sql_execute "$db" "$tb" "update" "$field" "$key" "$values" ;;
		 "button_delete")   setmsg -q "$field=$key wirklich loeschen ?"
							if [ $? -gt 0 ];then setmsg "-w" "Vorgang abgebrochen";return  ;fi
							rc_sql_execute "$db" "$tb" "delete" "$field" "$key"  
							if [ $? -gt 0 ];then return  ;fi
							rc_sql_execute "$db" "$tb" "lt" "$field" "$key"  
							if [ $? -lt 1 ];then return  ;fi
							rc_sql_execute "$db" "$tb" "lt" "$field" "$key" 
							;;
		 "button_clear")   	if [ -f "$valuefile" ];then rm -f "$valuefile";fi ;;
		 "button_refresh")  cp -f "$valuefile.bak" "$valuefile" ;;
		*) setmsg -i -d --width=400 "func $func\ndb $db\ntb $tb\n$field\nrest $rest "
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
	echo '				<input>'$script' --func ctrl_rc_gui "entry | '$db '|' $tb '|' ${PRIMKEY} '|' ${meta[$ID]}'"</input>'
	echo '			</entry>'
	echo '			<text width-chars="46" justify="3"><label>'$PRIMKEY' (PK) (type,null,default,primkey)</label></text>'
	echo '		</hbox>'
	echo '	</vbox>'
#	echo '  <frame>'
	echo '  <vbox hscrollbar-policy="0">'
    entrys="";del=""
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		cmd=$(rc_gui_get_cmd "$db" "$tb" "${name[$ia]}")
		echo    '	<hbox>' 
		IFS='#';set -- $cmd;unset IFS
		if  [ "$1" = "" ] || [ "$1" = "fileselect" ]; then 
			echo    ' 			<entry width_chars="'$sizemeta'"  space-fill="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>true</sensitive>' 
			echo    ' 				<input>'$script' --func ctrl_rc_gui "entry  | '$db '|' $tb '|' ${name[$ia]} '|' ${meta[$ia]}'"</input>' 
			echo    ' 			</entry>' 
		fi
		entrys="${entrys}${del}"'$entry'"$ia";del="#"
		if [ "$1" = "fileselect" ]; then 
		    ref_entry="$ref_entry $ia"'_'"$ia" 
		    if [ "$3" = "play" ]; then
		    echo	'	        <button>'
			echo	'				<variable>entry'$ia'_'$ia'_'$ia'</variable>'
			echo	'				<input file stock="gtk-media-play"></input>'
    		echo	' 				<action>'$script' --func ctrl_rc_gui "play   | '$db '|' $tb '|' ${name[$ia]} '|' $cmd'"</action>'
			echo	'			</button>'
		    fi
			echo 	'			<button>'
            echo	'				<variable>entry'$ia'_'$ia'</variable>'
            echo	'				<input file stock="gtk-open"></input>'
            echo    '    			<action>'$script' --func ctrl_rc_gui "fselect | '$db '|' $tb '|' ${name[$ia]} '|' $cmd'"</action>'
            echo	'    			<action type="refresh">entry'$ia'</action>'	
            echo	'			</button>' 	
		fi
		if 	[ "$1" = "reference" ] || [ "$1" = "parm" ] ;then 
		    ref_entry="$ref_entry $ia""_""$ia"
		    if [ "$2" = "-" ];then mydb=$db ;else mydb=$2 ;fi 
		    if [ "$3" = "-" ];then mytb=$tb ;else mytb=$3 ;fi 
			echo    ' 			<entry width_chars="5"  space-fill="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>false</sensitive>' 
			echo    ' 				<input>'$script' --func ctrl_rc_gui   "entry   | '$db '|' $tb '|' ${name[$ia]}'"</input>' 
			echo    ' 			</entry>' 
            echo  	' 			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false" visible="true">'
			echo 	' 				<variable>entry'$ia'_'$ia'</variable>'
			echo  	' 				<sensitive>true</sensitive>'
			echo  	' 		    	<input>'$script'  --func ctrl_rc_gui  "cbox_i  | '$db '|' $tb '|' ${name[$ia]} '|' $cmd'"</input>'
			echo  	'               <action>'$script' --func ctrl_rc_gui  "vbox_a  | '$db '|' $tb '|' ${name[$ia]} '|' $cmd' | $entry'$ia'_'$ia'"</action>'
			echo  	'               <action type="refresh">entry'$ia'</action>'
			echo  	'       	</comboboxtext>'
		fi
		if 	[ "$1" = "cmd" ] ;then echo ${@:2};fi 
		echo  	' 			<text width-chars="'$sizemeta'" justify="2"><label>'${name[$ia]}' ('${meta[$ia]}')</label></text>'   
		echo    '	</hbox>' 
	done
	echo '	</vbox>'
#	echo '  </frame>'
	echo '	<hbox>'
	echo '		<button><label>back</label>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_back    | '$db '|' $tb '|' $PRIMKEY '| $entryp"</action>'
			        rc_entrys_refresh  
	echo '		</button>'
	echo '		<button><label>next</label>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_next    | '$db '|' $tb '|' $PRIMKEY '| $entryp"</action>'
			        rc_entrys_refresh  
    echo '		</button>'
	echo '		<button><label>read</label>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_read    | '$db '|' $tb '|' $PRIMKEY '| $entryp"</action>'
	echo '			<action type="enable">BUTTONAENDERN</action>'
					rc_entrys_refresh  
	echo '		</button>'
	echo '		<button><label>insert</label>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_insert  | '$db '|' $tb '|' $PRIMKEY '| $entryp | '$entrys'"</action>'
					rc_entrys_refresh  
	echo '		</button>'
	echo '		<button><label>update</label><variable>BUTTONUPDATE</variable>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_update  | '$db '|' $tb '|' $PRIMKEY '| $entryp | '$entrys'"</action>'
					rc_entrys_refresh  
	echo '		</button>'
	echo '		<button><label>delete</label>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_delete  | '$db '|' $tb '|' $PRIMKEY '| $entryp | '$entrys'"</action>'
					rc_entrys_refresh 
	echo '		</button>'
	echo '		<button><label>clear</label>'
	echo '			<action type="enable">BUTTONUPDATE</action>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_clear   | '$db '|' $tb '|' $PRIMKEY '| $entryp | '$entrys'"</action>'
					rc_entrys_refresh  
	echo '		</button>'
	echo '		<button><label>refresh</label>'
	echo '			<variable>BUTTONREFRESH</variable>'
	echo '			<action type="enable">BUTTONAENDERN</action>'
	echo '			<action>'$script' --func ctrl_rc_gui "button_refresh | '$db '|' $tb '|' $PRIMKEY '| $entryp | '$entrys'"</action>'
					rc_entrys_refresh  
	echo '		</button>'
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
		echo '				<action type="refresh">entry'$ia'</action>'  
	done
	for entry in $ref_entry; do 
		echo '				<action type="refresh">entry'$entry'</action>' 
	done
	echo '				<action type="refresh">entryp</action>'
}
function get_ref_parms () { ref="$*";ref2=${ref#*\#};echo ${ref2%%\|*}; }
function rc_gui_get_cmd () {
	if [ "$nowidgets" = "true" ];then echo "";return  ;fi
	db=$1;tb=$2;field="$3"
	eval 'cmd=$'$(get_field_name $db)$tb$field;if [ "$cmd" != "" ];then echo "cmd $cmd";return ;fi
	if [ "$parm_ref" != "" ]; then
		ix=$(pos $field $parm_ref)
		if [ "$ix" -gt "-1" ]; then echo "parm#$(get_ref_parms ${parm_ref:$ix})";return;fi
	fi
	cmd_ref=$homeuwemy_databasesmusicsqlitetrack_ref
	if [ "$cmd_ref" != "" ]; then
		ix=$(pos $field $cmd_ref)
		if [ "$ix" -gt "-1" ]; then echo "reference#$(get_ref_parms ${cmd_ref:$ix})";return;fi
	fi
	cmd_fsl=$homeuwemy_databasesmusicsqlitetrack_fsl
	if [ "$cmd_fsl" != "" ]; then
		ix=$(pos $field $cmd_fsl)
		if [ "$ix" -gt "-1" ]; then echo "fileselect#$(get_ref_parms ${cmd_fsl:$ix})";return;fi
	fi
	case "$field" in
		fls_*|fsl_*|fsf_*) 	echo "fileselect#$field#play" ;return	;;
		fsld_*|fsd_*) 		echo "fileselect#$field#--directory";return		;;
		ref_*|reference_*) 	field=${field#*_};tb=${field%%_*};echo "reference#$db#$tb#$field#0";return		;;
	esac
}
function rc_sql_execute () {
	log debug $FUNCNAME $@
	db=$1;shift;tb=$1;shift;local mode=$1;shift;PRIMKEY=$1;shift;row=$1;shift	
	if [ "$mode" = "update" ] || [ "$mode" = "insert" ];		then 
	     parm=$*;IFS='#';values=($parm);unset IFS
	     ia=-1;uline="";iline="";vline="";del=""
	     while read -r line;do
			field=$(trim "${line%%\ *}");value=$(trim "${line##*\ }" | tr -d '"')
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
		 "delete")	erg=$(sql_execute "$db" "delete from $tb $where");;
		 "update")	erg=$(sql_execute "$db" "update $tb set "$uline "$where");;
		 "insert")	erg=$(sql_execute "$db" "insert into $tb (${iline}) values (${vline}))";;
		  *)  		erg=$(sql_execute "$db" ".mode line\n.header off\nselect ${srow}* from $tb $where")
	esac
	if [ "$?" -gt "0" ];		then return 1;fi
	if [ "$mode" = "delete" ];	then setmsg -n "success delete";return  ;fi
	if [ "$mode" = "insert" ];	then setmsg -n "success insert";return  ;fi
	if [ "$mode" = "update" ];	then setmsg -n "success update";return  ;fi
	if [ "$erg" = ""  ];then setmsg "keine id $mode $row gefunden"  ;return 1;fi
    echo -e "$erg" > "$valuefile"
    cp -f "$valuefile" "$valuefile.bak"
}
function del_gui_rc_entrys_hbox () {
#	db=$1;shift;tb=$1;shift;PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
 	db=$1;shift;tb=$1;shift;IFS=",";name=($TNAME);unset IFS;shift;IFS="|";meta=($TMETA);unset IFS
    eval 'cmd_ref=$'$(get_field_name $db$tb"_ref")
    eval 'cmd_fsl=$'$(get_field_name $db$tb"_fsl")
    eval 'cmd_bln=$'$(get_field_name $db$tb"_bln")
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		cmd=$(rc_gui_get_cmd "$db" "$tb" "${name[$ia]}")
		echo    '	<hbox>' 
		IFS='#';set -- $cmd;unset IFS
		if  [ "$1" = "" ] || [ "$1" = "fileselect" ]; then 
			echo    ' 			<entry width_chars="'$sizemeta'"  space-fill="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>true</sensitive>' 
			echo    ' 				<input>'$script' --func tb_get_meta_val '$ia'</input>' 
			echo    ' 			</entry>' 
		fi
		if [ "$1" = "fileselect" ]; then 
		    ref_entry="$ref_entry $ia"'_'"$ia" 
		    file=$(tb_get_meta_val $ia)
		    if [ "$3" = "play" ]; then
		    echo	'	        <button>'
			echo	'				<variable>entry17_17_17</variable>'
			echo	'				<input file stock="gtk-media-play"></input>'
    		echo	' 				<action>ffplay "'$file'" &</action>'
			echo	'			</button>'
					dir=""
			else 	dir="$3"
		    fi
		    stmt="zenity --file-selection $dir --filename=\"$file\""
			echo 	'			<button>'
            echo	'				<variable>entry'$ia'_'$ia'</variable>'
            echo	'				<input file stock="gtk-open"></input>'
            echo    '    			<action>/home/uwe/my_scripts/my_squirrel_all.sh --func tb_set_meta_val '$ia' 0 $('$stmt')</action>'
            echo	'    			<action type="refresh">entry'$ia'</action>'	
            echo	'			</button>' 	
		fi
		if 	[ "$1" = "reference" ] || [ "$1" = "parm" ] ;then 
		    ref_entry="$ref_entry $ia""_""$ia"
		    if [ "$2" = "-" ];then mydb=$db ;else mydb=$2 ;fi 
		    if [ "$3" = "-" ];then mytb=$tb ;else mytb=$3 ;fi 
		    setmsg -i -d --width="400" "$cmd\n 1 $1\n db $mydb\n tb $mytb\n field $4\n range $5"
		    if [ "$1" = "reference" ]; then
				stmt='/home/uwe/my_scripts/my_squirrel_all.sh --func gui_rc_get_cmd "'$mydb'" "'$mytb'" "'$4'" "'$ia'"' 
				range=$5        
			else
				stmt='/home/uwe/my_scripts/my_squirrel_all.sh --func gui_rc_get_parm "'${name[$ia]}'" "'$ia'" "'$2'"' 
				range=0        
			fi
			echo    ' 			<entry width_chars="5"  space-fill="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>false</sensitive>' 
			echo    ' 				<input>'$script' --func tb_get_meta_val '$ia'</input>' 
			echo    ' 			</entry>' 
            echo  	' 			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false" visible="true">'
			echo 	' 				<variable>entry'$ia'_'$ia'</variable>'
			echo  	' 				<sensitive>true</sensitive>'
			echo  	' 		    	<input>'$stmt'</input>'
			echo  	'               <action>'$script' --func tb_set_meta_val_cmd '$type' '$ia'  '$range' "$entry'$ia'_'$ia'"</action>'
			echo  	'               <action type="refresh">entry'$ia'</action>'
			echo  	'       	</comboboxtext>'
		fi
		if 	[ "$1" = "cmd" ] ;then echo ${@:2};fi 
		echo  	' 			<text width-chars="'$sizemeta'" justify="2"><label>'${name[$ia]}' (' ${meta[$ia]}')</label></text>'   
		echo    '	</hbox>' 
	done
}
function del_gui_rc_entrys_action_refresh () {
	log debug $FUNCNAME $@
#	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	IFS=",";name=($TNAME);unset IFS;shift;IFS="|";meta=($TMETA);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		if [ ""${name[$ia ]}"" == "rowid" ];then continue ;fi
		echo '				<action type="refresh">entry'$ia'</action>'  
	done
	for entry in $ref_entry; do 
		echo '				<action type="refresh">entry'$entry'</action>' 
	done
	echo '				<action type="refresh">entryp</action>'
}
function del_gui_rc_entrys_variable_list () {
	log   $FUNCNAME $@
#	PRIMKEY="$1";shift;ID="$1";shift;IFS=",";name=($1);unset IFS;shift 
	IFS=",";name=($TNAME);unset IFS 
	log $(declare -p name);setmsg -i "break"
	local line="";del=" "
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
		line=$line$del'$entry'$ia;del="|"
	done
	echo "\"$line\""
}
function del_gui_rc_get_cmd () {
	db="$1";shift;tb="$1";shift;field="$1";shift;nr="$1" 
	val=$(tb_get_meta_val $nr)
	stmt=".mode column\nselect * from $tb where $field  = \"$val\""
	sql_execute $db $stmt #| left $cmdleft
	stmt=".mode column\nselect * from $tb where $field != \"$val\""
	sql_execute $db $stmt #| left $cmdleft
	echo "$please_choose"
}
function gui_rc_get_parm () {
	field="$1";shift;nr="$1";shift;type="$1" 
	val=$(tb_get_meta_val $nr)
	stmt=".mode csv\nselect parm_value from parm where parm_field   = \"$val\" and parm_type = \"$type\""
	sql_execute $dbparm $stmt | tr -d '"'
	stmt=".mode csv\nselect parm_value from parm where parm_field  != \"$val\" and parm_type = \"$type\""
	sql_execute $dbparm $stmt | tr -d '"'
	echo "$please_choose"
}
function del_gui_rc_get_ref () {
	db=$1;shift;stmt=$*
	sql_execute $db $stmt | left 50
	echo "\"---- bitte waehlen --------------------------------------------------------------------------------\""
}
function del_gui_rc_get_dialog () {
	log debug $FUNCNAME $@
	db="$1";shift;tb="$1";shift;row="$1"
	sizetlabel=20;sizemeta=36;ref_entry=""
	echo '<vbox>'
	echo '	<vbox>'
	echo '		<hbox>'
	echo '			<entry width_chars="30" space-expand="false">'
	echo '				<variable>entryp</variable>'
	echo '				<input>'$script' --func tb_get_meta_val '"$ID"'</input>'
	echo '			</entry>'
	echo '			<text width-chars="46" justify="3"><label>'"$PRIMKEY"' (PK) (type,null,default,primkey)</label></text>'
	echo '		</hbox>'
	echo '	</vbox>'
	echo '  <frame>'
	echo '  <vbox height="600" hscrollbar-policy="0">'
			   gui_rc_entrys_hbox $db $tb $PRIMKEY $ID $TNAMES $TMETA
	echo '	</vbox>'
	echo '  </frame>'
	echo '	<hbox>'
	echo '		<button><label>back</label>'
	echo '			<action>'$script' --func sql_rc_sql_execute '$db' '$tb' lt '$PRIMKEY' $entryp</action>'
			        gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA
	echo '		</button>'
	echo '		<button><label>next</label>'
	echo '			<action>'$script' --func sql_rc_sql_execute '$db' '$tb' gt '$PRIMKEY' $entryp</action>'
			        gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA
    echo '		</button>'
	echo '		<button><label>read</label>'
	echo '			<action>'$script' --func sql_rc_sql_execute '$db' '$tb' eq '$PRIMKEY' $entryp</action>'
	echo '			<action type="enable">BUTTONAENDERN</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA 
	echo '		</button>'
	echo '		<button><label>insert</label>'
	echo '			<action>'$script' --func sql_rc_update_insert '$db' '$tb' insert $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA 
	echo '		</button>'
	echo '		<button><label>update</label><variable>BUTTONUPDATE</variable>'
	echo '			<action>'$script' --func sql_rc_update_insert '$db' '$tb' update $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>'
	echo '		</button>'
	echo '		<button><label>delete</label>'
	echo '			<action>'$script' --func sql_rc_delete '$db' '$tb' '$PRIMKEY' $entryp</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA 
	echo '		</button>'
	echo '		<button><label>clear</label>'
	echo '			<action type="enable">BUTTONUPDATE</action>'
	echo '			<action>'$script' --func sql_rc_clear '"$(gui_rc_entrys_variable_list $PRIMKEY $ID $TNAMES $TMETA)"'</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA 
	echo '		</button>'
	echo '		<button><label>refresh</label>'
	echo '			<variable>BUTTONREFRESH</variable>'
	echo '			<action type="enable">BUTTONAENDERN</action>'
	echo '			<action>cp -f '"$valuefile.bak" "$valuefile"'</action>'
					gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TMETA 
	echo '		</button>'
	echo '		<button ok></button><button cancel></button>'
	echo '	</hbox>'
	echo '</vbox>' 
}
function setmsg () { func_setmsg $*; }
function get_field_name () { echo $(readlink -f "$*") | tr -d '/.'; }
function get_fileselect () {
	if [ "$searchpath" = "" ]; then searchpath=$HOME;fi
	mydb=$(zenity --file-selection --title "select sqlite db" --filename=$searchpath)
	if [ "$mydb" = "" ];then echo "";return 1;fi
	setconfig_file "searchpath" "$mydb" "-" "letzter pfad fuer file-select"
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
function sql_get_where () {
	cmd="grep \"^dummy=\" $x_configfile | grep \"# $1 $2\" | cut -d '\"' -f2"
	bash -c "$cmd"
}
function sql_rc_sql_execute () {
	log debug $FUNCNAME $@
	db=$1;shift;tb=$1;shift;local mode=$1;shift;PRIMKEY=$1;shift;row=$1;
	if [ "$row" == "NULL" ] || [ "$row" == "" ] || [ "$row" == "=" ];then row=$(cat $idfile);fi
	if [ "$mode" == "eq" ];then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" == "lt" ];then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" == "gt" ];then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	if [ "$PRIMKEY" == "rowid" ];then srow="rowid," ;else srow="";fi
	erg=$(sql_execute "$db" ".mode line\n.header off\nselect ${srow}* from $tb $where")
	if [ "$?" -gt "0" ];then return ;fi
	if [ "$erg" == "" ];then setmsg "keine id $mode $row gefunden"  ;return  ;fi
    echo -e "$erg" > "$valuefile"
#    echo $row  > $

    cp -f "$valuefile" "$valuefile.bak"
}
function x_get_tables () {
	log debug $FUNCNAME $* 
 	if [ "$1" = "" ];then  return ;fi
	if [ -d "$1" ];then setmsg "$1 ist ein Ordner\nBitte sqlite_db ausaehlen" ;return ;fi
	sql_execute "$1" '.tables' | fmt -w 2 | grep -v -e '^$'  
	if [ "$?" -gt "0" ];then return 1;fi
}
function sql_rc_ctrl () {
	log $FUNCNAME $*
	if [ "$#" -gt "3" ];then setmsg -w  " $#: zu viele Parameter\n tabelle ohne PRIMKEY?" ;return  ;fi
	row="$1";shift;db="$1";shift;tb="$@"
	tb_meta_info "$db" "$tb"
#	PRIMKEY=${marray[0]};ID=${marray[1]}
#	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TMETA=${marray[7]};TSELECT=${marray[8]}
	if [ "$TNAME" == "" ];then return  ;fi
	if [ "$row" == "insert" ]; then
		echo "" > "$valuefile" 
	else
		sql_rc_sql_execute $db $tb eq $PRIMKEY $row > "$valuefile"
	fi

    row_change_xml="$path/tmp/change_row_${tb}.xml"
#    gui_rc_get_dialog $db $tb $row $PRIMKEY $ID $TNAME $TMETA $TNOTN $TSELECT > "$row_change_xml"	
    gui_rc_get_dialog $db $tb $row  > "$row_change_xml"	
	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function sql_rc_back () { sql_rc_sql_execute lt $@; }
function sql_rc_next () { sql_rc_sql_execute gt $@; }
function sql_rc_clear () { echo "" > "$valuefile" ; }
function sql_rc_update_insert () {
	log $FUNCNAME "$@"
	trap 'set +x;trap_at $LINENO 598;set +x' DEBUG
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
#		log debug field "${names[$ia]}" value "${values[$ia]}"
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
	sql_execute "$db" "$stmt" 
	if [ "$?" -gt "0" ];then 
		setmsg "-e" "abbruch rc = $erg : $stmt $db"
		return
	else
	    setmsg "$mode erfolgreich"
	fi
	if [ "$mode" == "insert" ];then
		row=$(sql_execute "$db" ".header off\nselect max($PRIMKEY) from $tb;" );
		if [ "$?" -gt "0" ];then return ;fi
		sql_rc_sql_execute $db $tb eq $PRIMKEY $row
	fi
}
function sql_rc_delete () {
	log debug $FUNCNAME $@
	db=$1;shift;tb=$1;shift;PRIMKEY=$1;shift;ID=$1
	setmsg -z "$PRIMKEY=$id wirklich loeschen ?"
	if [ $? -gt 0 ];then setmsg "-w" "Vorgang abgebrochen";return  ;fi
	erg=$(sql_execute $"$db" "delete from $tb where $PRIMKEY = $ID;")  
	[ "$erg" = "" ] && erg="delete erfolgreich" && setmsg $erg
	erg=$(sql_execute $"$db" "select min($PRIMKEY) from $tb;")
	if [ "$?" -gt "0" ];then return ;fi
	if [ "$erg" -lt "$ID" ]; then
	    sql_rc_sql_execute "$db" "$tb" "lt" "$PRIMKEY" "$ID"
	else
		sql_rc_sql_execute "$db" "$tb" "gt" "$PRIMKEY" "$ID"
	fi
}
function sql_execute () { func_sql_execute $*; }
function sql_read_table ()  {
	log debug $FUNCNAME $@
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$(echo $* | tr -d '"')
	if [ "$label" = "$tb" ];then off="off" ;else off="on"  ;fi
	if [ "$db" = "" ];then db=$(get_fileselect);fi
	if [ "$db" = "" ];then setmsg -n --width=400 " sql_read_table\n label $label\n bitte datenbank selektieren\n $*" ;return  ;fi
	if [ "$tb" = "" ];then tb=$(x_get_tables "$db" "batch"| head -n1);fi
	if [ "$tb" = "" ];then setmsg -n --width=400 " sql_read_table\n label $label\n keine tabelle uebergeben\n $*" ;return  ;fi
	erg=$(tb_meta_info $db $tb);row=${erg%%@*};if [ "$row" == "rowid" ];then srow="rowid," ;else srow="";fi
	sql_execute $db ".separator |\n.header $off\nselect ${srow}* from $tb $where;" # | tee $path/tmp/export_${tb}_$(date "+%Y%m%d%H%M").txt 
	if [ "$?" -gt "0" ];then return ;fi 
	setconfig "$label" "$db" "$tb" "$where" 
}
function tb_set_meta_val_cmd   () {
	nr=$1;shift;range="$1";shift;value="$*"
	if [ "$value" = "" ]; then return;fi
	if [ "${value:2:2}" = "--" ]; then return;fi
	IFS=",";range=($range);IFS=" ";value=($value);unset IFS;parm="";del=""
	for arg in ${range[@]}; do parm=$parm$del${value[$arg]};del=" ";done	
	tb_set_meta_val $nr "$parm"
}
function tb_set_meta_val   () {
	nr=$1;shift;value="$*"
	cp -f "$valuefile" "$valuefile"".bak2"
	i=-1
	while read line;do
		i=$((i+1))
		if [ "$i" != "$nr" ];then echo $line;continue;fi  
		echo "${line%%=*} = ${value}"
	done  < "$valuefile"".bak2" > "$valuefile"
}
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
