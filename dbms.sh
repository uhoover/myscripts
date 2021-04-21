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
	tb_create_dialog $myparm	
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
 		log debug "label $1 db $2 tb $3"  
 		tb_gui_get_xml "$1" "$2" "$3" >> $xmlfile 
	done
	unset IFS
	echo "</notebook></window>" >> $xmlfile
return
	X=10;Y=10;HEIGHT=800;WIDTH=900
    [ -f "$geometryfile" ] && source "$geometryfile" 
    geometry="$WIDTH""x""$HEIGHT""+""$X""+""$Y"
    gtkdialog -f "$xmlfile" --geometry="$geometry"
}
function ctrl_tb_gui () {
	func=$1;shift;label=$1;shift;db="$1";shift;tb="$1";shift;db_gui="$1";shift;tb_gui="$1";shift;where_gui="$*"
	if [ "$func" = "fselect" ];		then db_gui=$(get_fileselect);func="entry";fi
	if [ "$db_gui" != "" ]; 		then db="$db_gui" ;fi
	if [ "$db" = "dfltdb" ];		then db=$(tb_get_dflt_db $label);fi
	is_database $db
	if [ "$?" -gt "0" ];			then setmsg -i "keine datenbank: $db";echo $db;return;fi
	if [ "$func" = "entry" ];		then echo $db;return  ;fi
	set +x
	if [ "$tb_gui" != "" ]; 		then tb="$tb_gui" ;fi
	if [ "$tb" = "dflttb" ];		then tb=$(tb_get_dflt_tb $label "$db");fi
	if [ "$tb" = "" ];				then tb=$(x_get_tables "$db" "batch"| head -n1);fi
	is_table "$db" "$tb"
	if [ "$?" -gt "0" ];			then setmsg -i "keine tabelle: $tb";echo $tb;return;fi
	if [ "$func" = "cboxtb" ];		then 
		echo $tb
		if [ "$table" != "$label" ];then x_get_tables "$db" "batch" | grep -v $tb  ;fi
		return
	fi
	if [ "$where_gui" != "" ]; 		then where="$where_gui" ;fi
	if [ "$where" = "" ] && [ "$db_gui" = "" ];then where=$(tb_get_dflt_where $label $db $tb);fi	
	if [ "$func" = "cboxwh" ];		then 
		echo $where
		tb_get_where_list $label $db $tb | grep -v "$where"
		return
	fi 
	if [ "$func" = "tree" ];		then tb_read_table $label "$db" $tb "$where";return;fi	
	setmsg -w "$FUNCNAME Regel nicht erkannt\n$func $db $tb $where"
	set +x
}
function tb_get_labels() {
	log debug $FUNCNAME $@  
	set -x
	arr="";del="" 
	while [ "$#" -gt "0" ];do
		if   [ -f  "$1" ];then
			db=$1;sql_execute "$db" ".databases" > /dev/null
			if [ "$?" -gt "0" ];then setmsg -i "$db ist keine sqlite db";db="none";shift;continue;fi
			x_get_tables "$db" > $tmpf 
			if [ "$2" = "" ] || [ -f  "$2" ]; then 
				dblabel=$(basename $db);tblabel=${dblabel%%\.*}
				arr="$arr$del$tblabel#$db#$(ftest_get_dflt_tb $tblabel $db)";del="|"
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
	log debug $FUNCNAME
	label="$1";db="$2";tb="$3"
	if [ "$label" = "$tb" ]; then
		tb_meta_info "$db" "$tb"
		lb=$(echo $TNAME | tr '_,' '-|');sensitiveCBOX="false"
	else
		lb=$(copies 30 '|');sensitiveCBOX="true";ID=0
	fi
	if [ "$label" = "selectDB" ]; then
	    sensitiveFSELECT="true" 
	else
	    sensitiveFSELECT="false" 
	fi
	echo '    <vbox>
		<tree headers_visible="true" hover_selection="false" hover_expand="true" exported_column="'$ID'">
			<label>"'$lb'"</label>
			<variable>TREE'$label'</variable>
			<input>'$script' --func ctrl_tb_gui tree      '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true">  
				<variable>ENTRY'$label'</variable> 
				<sensitive>false</sensitive>  
				<input>'$script' --func ctrl_tb_gui entry  '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
				<action type="refresh">CBOXTB'$label'</action>	
			</entry> 
			<button space-fill="false">
            	<variable>BUTTONFSELECT'$label'</variable>
            	<sensitive>'$sensitiveFSELECT'</sensitive>
            	<input file stock="gtk-open"></input>
				<input>'$script' --func ctrl_tb_gui fselect '$label' '$db' '$tb' $ENTRY'$label' $CBOXTB'$label' $CBOXWHERE'$label'</input>
            	<action type="refresh">ENTRY'$label'</action>	
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
			<button ok></button>
			<button cancel></button>
		</hbox>
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
	if [ "$PRIMKEY" = "" ];then PRIMKEY="rowid";ID=0;TNAME="rowid$del$TNAME";TMETA="rowid$del2$TMETA"  ;fi 
}
function tb_read_table() {
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$(echo $* | tr -d '"')
	tb_meta_info "$db" $tb
	if [ "$row" = "rowid" ];then srow="rowid," ;else srow="";fi
	sql_execute $db ".separator |\n.header $off\nselect ${srow}* from $tb $where;" # | tee $path/tmp/export_${tb}_$(date "+%Y%m%d%H%M").txt 
	if [ "$?" -gt "0" ];then return ;fi 
	setconfig "$label" "$db" "$tb" "$where" 
}
function tb_get_dflt_db() {
	label=$1;
	eval 'db=$dfltdb'$label
	if [ "$db" != "" ];then echo $db;return;fi 
	db=$(get_fileselect)
	if [ "$?" -gt "0" ];then return 1;fi
	echo $db
}
function tb_get_dflt_tb() {
	label=$1;db="$2" 
	eval 'tb=$'$(get_field_name "${db}dflttb${label}")
	echo $tb
}
function tb_get_dflt_where() {
	label=$1;shift;db="$1";shift;tb=$1;shift;where=$*
	if [ "$where" != "" ];then echo $where;return;fi
	eval 'where=$'$(get_field_name "${db}dfltwhere${label}${tb}")
	echo $where
}
function tb_get_where_list () {
	cmd="grep \"^dummy=\" $x_configfile | grep \"# $1 $2\" | cut -d '\"' -f2"
	bash -c "$cmd"
}
function get_ref_parms () { ref="$*";ref2=${ref#*\#};echo ${ref2%%\|*}; }
function gui_rc_entrys_hbox_cmd () {
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
function gui_rc_entrys_hbox () {
	db=$1;shift;tb=$1;shift;PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
    eval 'cmd_ref=$'$(get_field_name $db$tb"_ref")
    eval 'cmd_fsl=$'$(get_field_name $db$tb"_fsl")
    eval 'cmd_bln=$'$(get_field_name $db$tb"_bln")
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		cmd=$(gui_rc_entrys_hbox_cmd "$db" "$tb" "${name[$ia]}")
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
function gui_rc_entrys_action_refresh () {
	log debug $FUNCNAME $@
	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		echo '				<action type="refresh">entry'$ia'</action>'  
	done
	for entry in $ref_entry; do 
		echo '				<action type="refresh">entry'$entry'</action>' 
	done
	echo '				<action type="refresh">entryp</action>'
}
function gui_rc_entrys_variable_list () {
	log debug $FUNCNAME $@
	PRIMKEY="$1";shift;ID="$1";shift;IFS=",";name=($1);unset IFS;shift 
	local line="";del=" "
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
		line=$line$del'$entry'$ia;del="|"
	done
	echo "\"$line\""
}
function gui_rc_get_cmd () {
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
function gui_rc_get_ref () {
	db=$1;shift;stmt=$*
	sql_execute $db $stmt | left 50
	echo "\"---- bitte waehlen --------------------------------------------------------------------------------\""
}
function gui_rc_get_dialog () {
	log $FUNCNAME $@
	db="$1";shift;tb="$1";shift;row="$1";shift;PRIMKEY="$1";shift;ID="$1";shift
	TNAMES="$1";shift;TLINE="$1";shift;TNOTN="$1";shift;TSELECT="$1"
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
	log debug $FUNCNAME $@
	tb="$1";shift;dfltdb="$1";shift;dflttb=$1;shift;visibleDB=$1;shift;visibleTB="$1";shift;dfltwhere="$*"   
	if [ "$tb" = "$dflttb" ]; then
		IFS="@";marray=($(tb_meta_info "$dfltdb" "$dflttb"));unset IFS
		pk="${marray[0]}";ID=${marray[1]}
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
	terminal="${tpath}/cmd_${tb}.txt"
	terminal_cmd "$terminal" "$dfltdb" 
	if [ "$nowidgets" == "true" ];then nocmd="--nowidgets";else nocmd="" ;fi
	echo  '
	<vbox>
		<tree headers_visible="'$visibleHD'" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="'$ID'">
			<label>'"$label"'</label>
			<variable>TREE'$tb'</variable>
			<input>'$script' --func sql_read_table '$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb' "$CBOXWHERE'$tb'"</input>
			<action>'$script' '$nocmd' --func sql_rc_ctrl $TREE'$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</action>
			<action signal="changed" type="enable">BUTTONAENDERN'$tb'</action>
		</tree>
		<vbox space-expand="false" space-fill="true">
		<frame click = selection >
			<hbox homogenoues="true">
			    <hbox>
					<entry width-chars="30" accept="file">
						'$(gui_tb_get_default $dfltdb)'
						<variable>CBOXDBSEL'$tb'</variable>
						<sensitive>"false"</sensitive>
						<action>'$script' --func terminal_cmd '$terminal' $CBOXDBSEL'$tb'</action>
						<action type="refresh">TERMINAL'$tb'</action>
					</entry>
					<button>
						<input file stock="gtk-open"></input>
						<variable>FILESEL'$tb'</variable>
						<action type="fileselect">CBOXDBSEL'$tb'</action>
						<action type="refresh">CBOXDBSEL'$tb'</action>
						<action type="refresh">CBOXENTRY'$tb'</action>
						<sensitive>"'$visibleDB'"</sensitive>
					</button>
				</hbox>
				<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false">
					<variable>CBOXENTRY'$tb'</variable>
					'$(gui_tb_get_default $dflttb)'
					<input>'$script' --func x_get_tables $CBOXDBSEL'$tb' '$tb'</input>
					<action type="clear">TREE'$tb'</action>
					<action type="refresh">CBOXWHERE'$tb'</action>
					<action type="refresh">TREE'$tb'</action>
					<sensitive>"'$visibleTB'"</sensitive>
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
				<label>show terminal</label>
				<variable>BUTTONSHOW'$tb'</variable>
				<action type="show">TERMINAL'$tb'</action>
				<action type="show">BUTTONHIDE'$tb'</action>
				<action type="hide">BUTTONSHOW'$tb'</action>
			</button>
			<button visible="false">
				<label>hide terminal</label>
				<variable>BUTTONHIDE'$tb'</variable>
				<action type="hide">TERMINAL'$tb'</action>
				<action type="show">BUTTONSHOW'$tb'</action>
				<action type="hide">BUTTONHIDE'$tb'</action>
			</button>
			<button>
				<label>clone</label>
				<variable>BUTTONCLONE'$tb'</variable>
				<action>'$script' $CBOXDBSEL'$tb' $CBOXENTRY'$tb' --notable &</action>
			</button>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$tb'</variable>
				<sensitive>true</sensitive> 
				<action>'$script' --func sql_rc_ctrl insert $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</action>
			</button>
			<button visible="true">
				<label>update</label>
				<variable>BUTTONAENDERN'$tb'</variable>
				<sensitive>false</sensitive> 
				<action>'$script' --func sql_rc_ctrl $TREE'$tb' $CBOXDBSEL'$tb' $CBOXENTRY'$tb'</action>
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD'$tb'</variable>
				<action type="clear">TREE'$tb'</action>
				<action type="refresh">TREE'$tb'</action>
			</button>
			<button>
				<label>cancel</label>
				<action>'$0' --func save_geometry '${wtitle}#${tbgeometry}'</action>	
				<action type="exit">CLOSE</action>
			</button>
		</hbox>
		<terminal space-expand="false" space-fill="false" text-background-color="#F2F89B" text-foreground-color="#000000" 
			autorefresh="true" argv0="/bin/bash" visible="false">
			<variable>TERMINAL'$tb'</variable>
			<height>10</height>
			<input file>"'$terminal'"</input>
		</terminal>
		</vbox>
	 </vbox>
	 '
}
function setmsg () { func_setmsg $*; }
function get_field_name () { echo $(readlink -f "$*") | tr -d '/.'; }
function get_fileselect () {
	if [ "$searchpath" = "" ]; then searchpath=$HOME;fi
	mydb=$(zenity --file-selection --filename=$searchpath)
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
function setconfig () {
	label=$1;shift;db=$1;shift;tb=$1;shift;where="$*"
#	setmsg -i "$label\n$db"
	if 		[ "$label" =  "selectDB" ]; then
			setconfig_file "dfltdb" "$db" "-" "default-datenbank fuer dbselect (label=selectDB)"
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
function sql_rc_read () {
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
    echo $row  > $idfile
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
	log debug $FUNCNAME "$@"
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
		sql_rc_read $db $tb eq $PRIMKEY $row
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
	    sql_rc_read "$db" "$tb" "lt" "$PRIMKEY" "$ID"
	else
		sql_rc_read "$db" "$tb" "gt" "$PRIMKEY" "$ID"
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
function tb_create_dialog_nb () {
 	log debug $FUNCNAME $LINENO $(printf "labels %-10s %-40s %-15s %-5s %-5s %s\n" $1 $2 $3 $4 $5 "$(echo ${@:6})") 
	label="$1";db="$2";tb="$3";where=""
	if [ "$db"      = ""  ]; then db=$dfltdb;fi
	if [ "$db"      = ""  ]; then db=$(get_fileselect);fi
	if [ "$?"     -gt "0" ]; then return 1;fi
	if [ "$tb"      = ""  ]; then eval 'tb=$'$(get_field_name "$db")'dflttb'$label;fi
	if [ "$tb"      = ""  ]; then tb=$(x_get_tables "$db" "batch"| head -n1);fi
	if [ "$?"     -gt "0" ]; then setmsg -i "no tb selected\n $db";return 1;fi
	if [ "$tb"     != ""  ]; then eval 'where=$'$(get_field_name "$db")'dfltwhere'$label$tb ;fi
	if [ "$db"     != ""  ]; then eval 'export CBOXDBSEL'$label'='$db ;fi
	if [ "$tb"     != ""  ]; then eval 'export CBOXENTRY'$label'='$tb ;fi 
	if [ "$where"  != ""  ]; then eval 'export CBOXWHERE'$label'="'$where'"';fi
	erg="$label $db $tb $4 $5 $where"
	notebook=$notebook" $1" 
}
function tb_create_dialog () {
	log debug $FUNCNAME $@ 
	notebook="" 
	[ -f "$dfile" ] && rm "$dfile"	 
	notebook="";zn=-1 
	while [ "$#" -gt "0" ];do
		if   [ -f  "$1" ];then
			db=$1
			if [ "$2" = "" ] || [ -f  "$2" ]; then 
				dblabel=$(basename $db);tblabel=${dblabel%%\.*}
				tb_create_dialog_nb "$tblabel" $db "" "false" "true";if [ "$?" = "0" ];then zn=$((zn+1));anb[$zn]="$erg";fi
			fi	
		elif [ "$1" = "--all" ];then
			x_get_tables "$db" > $tmpf 
			while read -r line;do 
				tb_create_dialog_nb $line $db $line "false" "false";if [ "$?" = "0" ];then zn=$((zn+1));anb[$zn]="$erg";fi
			done < $tmpf
		else 
			tb_create_dialog_nb "$1" "$db" "$1" "false" "false";if [ "$?" = "0" ];then zn=$((zn+1));anb[$zn]="$erg";fi
		fi
	    shift		
	done
 	if [ "$notable" != "$true" ];then 
		log debug $FUNCNAME $LINENO db $dfltdb tb $dflttb
 		tb_create_dialog_nb "selectDB" "$dfltdb" "$dflttb" "true" "true";if [ "$?" = "0" ];then zn=$((zn+1));anb[$zn]="$erg";fi
	fi
	if [ "$zn" -lt "0" ];then return 1 ;fi
	echo "<window title=\"$wtitle\"  default_height=\"$HEIGHT\" default_width=\"$WIDTH\">" > $dfile
	echo "<notebook show-tabs=\"$visible\" space-expands=\"true\" tab-labels=\""$(echo $notebook | tr ' ' "|")"\">" >> $dfile
	for arg in "${anb[@]}" ;do
		set -- $arg 
 		log debug  $FUNCNAME $LINENO $(printf "labels %-10s %-40s %-15s %-5s %-5s %s\n" $1 $2 $3 $4 $5 "$(echo ${@:6})")
		gui_tb_get_dialog $1 $2 $3 $4 $5 "$(echo ${@:6})" >> $dfile
	done
	echo "</notebook></window>" >> $dfile 
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
	IFS="|";arrmeta=($TLINE);IFS=",";meta=(${arrmeta[$nr]});unset IFS
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
	termfile="$1";db="$2"
	echo ".exit" 		>  "$termfile" 
	echo "sqlite3 $db" 	>> "$termfile"  
}
function x_read_csv () {
	file=$*;[ ! -f "$file" ] && setmsg -w --width=400 "kein file $file" && return
	sql_execute $dbparm "drop table if exists tmpcsv;"
	sql_execute $dbparm ".import $file tmpcsv"
	notable="$true";tb_create_dialog $dbparm tmpcsv 
	gtkdialog  -f "$dfile"
	setmsg -q "speichern ?"
	if [ "$?" -gt "0" ];then return;fi
	sql_execute $dbparm "select * from tmpcsv" > "$file"
}
function zz () { return; } 
	ctrl $*
