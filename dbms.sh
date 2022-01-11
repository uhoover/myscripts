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
  	if [ "$cmd" = "" ]; then log stop;fi
  	if [ "$rxtitle" != "" ]; then
		wmctrl -a "$rxtitle" -b toggle,shaded 
	fi	
}
function ftest () {
	set -x
    local db="$1" tb="$2";local file=$(getfilename "$sqlpath/create_systable" "$tb" "$db" ".sql")
	is_table "$db" "$tb"; if [ $? -lt 1 ]; then return;fi 
	cat << EOF > "$file"
create table $tb(
	"${tb}_id" integer primary key autoincrement not null unique,
	"${tb}_status" integer not null default '0',
	"${tb}_name" text,
	"${tb}_type" text not null default 'liste',
	"${tb}_db" text not null,
	"${tb}_tb" text not null,
	"${tb}_field" text not null,
	"${tb}_db_ref" text,
	"${tb}_tb_ref" text,
	"${tb}_action" text,
	"${tb}_parms" text,
	"${tb}_receive_list" text,
	"${tb}_info" text
);
insert into $tb values(1,0,'${tb}_type_liste','liste','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_type','','','liste@reference@table@fileselect@command','null','0','liste from string, separator must be @');
insert into $tb values(2,0,'${tb}_db_fileselect','fileselect','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_db',null,null,'action@/home/uwe/my_scripts/dbms.sh --func rules_command rules',NULL,'0','fileselect');
insert into $tb values(3,0,'${tb}_db_reference','reference','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_status','/home/uwe/my_databases/parm.sqlite','parms','select parm_value from parms where parm_type = ''status'' and substr(parm_value,1,instr(parm_value,'' '' )-1)','','0','complex sql possible - script completes with operator and field');
insert into $tb values(4,0,'${tb}_tb_command','command','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_tb','','','input@action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','call rules_action with tag  db  tb  pid  fieldname  fieldvalue  parmlist - delimited by pipe');
insert into $tb values(5,0,'${tb}_db_fileselect','fileselect','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_db_ref','','','action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','fileselect');
insert into $tb values(6,0,'${tb}_tb_command','command','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_tb_ref','','','input@action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of table names');
insert into $tb values(7,0,'${tb}_tb_command','command','/home/uwe/.dbms/parm.sqlite','$tb','${tb}_field','','','input@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of field names');
insert into $tb values(8,0,'modify_tb_command','command','/home/uwe/.dbms/parm.sqlite','modify','foreign_table','','','input@action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of table names');
insert into $tb values(9,0,'modify_field_command','command','/home/uwe/.dbms/parm.sqlite','modify','foreign_field','','','input@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of field names');
insert into $tb values(10,0,'modify_boolean','liste','/home/uwe/.dbms/parm.sqlite','modify','type','','','integer@real@text@blob','','0',NULL);
insert into $tb values(11,0,'modify_boolean','liste','/home/uwe/.dbms/parm.sqlite','modify','auto_increment','','','true@false','','0',NULL);
insert into $tb values(12,0,'modify_boolean','liste','/home/uwe/.dbms/parm.sqlite','modify','isunique','','','true@false','','0',NULL);
insert into $tb values(13,0,'modify_boolean','liste','/home/uwe/.dbms/parm.sqlite','modify','nullable','','','true@false','','0',NULL);
insert into $tb values(14,0,'modify_boolean','liste','/home/uwe/.dbms/parm.sqlite','modify','primary_key','','','true@false','','0',NULL);
create unique index ix_${tb}_dbtbfield on ${tb}(${tb}_db,${tb}_tb,${tb}_field);
EOF
    setmsg -i pause
    sql_execute "$db" ".read" "$file"
}
function ctrl () {
	log file tlog verbose  
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}"
	tpath="/tmp/.${folder%%\.*}";xpath="$path/xml" 
	dbpath="$HOME/db";sqlpath="$dbpath/sql";ipath="$dbpath/import";rpath="$dbpath/read" 
	epath="/var/tmp/export_${folder%%\.*}" 
	dpath="/var/tmp/dump_${folder%%\.*}" 
	[ ! -d "$path" ]     && mkdir 	 "$path"  
	[ ! -d "$tpath" ]    && mkdir 	 "$tpath"  
	[ ! -s "$path/tmpdbms" ] && ln -s "$tpath"	  "$path/tmpdbms"  
	filesocket="${tpath}/socket"  
	[ ! -f "$filesocket" ]                    && echo $(date "+%Y_%m_%d_%H_%M_%S_%N") > "$filesocket" 
	[ ! -d "$path/tmp" ] && mkdir 	 "$path/tmp"  
	[ ! -d "$xpath" ]	 && mkdir 	 "$xpath"  
	[ ! -d "$epath" ]    && mkdir 	 "$epath"   && ln -sf "$epath"    "$path"   
	[ ! -d "$dpath" ]    && mkdir 	 "$dpath"   && ln -sf "$dpath"    "$path"   
	[ ! -d "$ipath" ]    && mkdir -p "$ipath"   && ln -sf "$ipath"    "$path"   
	[ ! -d "$rpath" ]    && mkdir -p "$rpath"   && ln -sf "$rpath"    "$path"   
	[ ! -d "$sqlpath" ]  && mkdir -p "$sqlpath" && ln -sf "$sqlpath"  "$path"   
	[   -d "$HOME/log" ]                        && ln -sf "$HOME/log" "$path"   
	script=$(readlink -f $0)  
	x_configfile="$path/.configrc" 
	dbparm="$path/sysmaster.sqlite" 
	dbrules="$dbparm" 
	dbrules2="/home/uwe/my_databases/parm.sqlite" 
	dbcreate="$dbparm" 
	tbparm="sysparms"
	tbrules="rules"
	tbcreate="modify"
	pid=$$
	ctrl_systb_master "$dbparm"   "$tbparm" 
	limit=$(getconfig "parm_value" "config" "limit" 500)
	maxcols=$(getconfig "parm_value" "config" "maxcols" 30)
	term_heigth=$(getconfig "parm_value" "config" "term_heigth" 8)
	wtitle=$(getconfig "parm_value" "config" "wtitle" "dbms")
	export=$(getconfig "parm_value" "config" "export" "$false")
	separator=$(getconfig "parm_value" "config" "separator" "|")
	tmpf="$tpath/tmpfile.txt"   
	tmpf2="$tpath/tmpfile2.txt"   
	pparms=$*
	noselectDB=$false;myparm="";norules="$false";X=400;Y=600
	ctrl_fileconfig
	source $x_configfile
	declare -g	GTBNAME="" 	 GTBTYPE=""   GTBNOTN="" GTBDFLT="" GTBPKEY="" GTBMETA="" GTBSELECT="" GTBINSERT="" 
	declare -g  GTBUPDATE="" GTBUPSTMT="" GTBSORT="" GTBMAXCOLS=-1
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--tlog"|-t|--show-log-with-tail)  			log tlog ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--version"|-v)  				            echo "version 0.9.1" ;;
	        "--vb"|--verbose|--verbose-log)  			log verbose_on ;;
	        "--func"|-f|--execute-function)  			shift;cmd="nostop";log debug $pparms;$@;return ;;
	        "--noselectDB"|--no-tab-with-db-selection)	noselectDB=$true ;;
	        "--nolabel"|--no-notebook-label)			nolabel=$true ;;
	        "--norules"|--no-extra-widgets)				norules="true" ;;
	        "--window"|-w|--window-title)			    shift;wtitle="$1" ;;
	        "--geometry_tb"|--gtb|--HEIGHTxWIDTH+X+Y)	shift;geometry_tb="$1" ;;
	        "--geometry_rc"|--grc|--HEIGHTxWIDTH+X+Y)	shift;geometry_rc="$1" ;;
	        "--help"|-h)								func_help $FUNCNAME;echo -e "\n     usage [ dbname [table ] --all  ]" ;return;;
	        "--all"|--tab-each-table)					myparm="$myparm $1";;
	        "--trap_at"|--trap_at_line)					shift;trap 'set +x;trap_at $LINENO $1;set -x' DEBUG;shift;;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										myparm="$myparm $1";;
	    esac
	    shift
	done
	log start
	tb_ctrl $myparm	
}
function ctrl_systb_rules() {
	local db="$1" tb="$2";local file=$(getfilename "$sqlpath/create_systable" "$tb" "$db" ".sql")
	is_table "$db" "$tb"; if [ $? -lt 1 ]; then return;fi 
	cat << EOF > "$file"
create table $tb (
	"rules_id" integer primary key autoincrement not null unique,
	"rules_status" integer not null default '0',
	"rules_name" text,
	"rules_type" text not null default 'liste',
	"rules_db" text not null,
	"rules_tb" text not null,
	"rules_field" text not null,
	"rules_db_ref" text,
	"rules_tb_ref" text,
	"rules_action" text,
	"rules_parms" text,
	"rules_receive_list" text,
	"rules_info" text
);
insert into $tb values(1,0,'rules_type_liste','liste',"$db","$tb",'rules_type','','','liste@reference@table@fileselect@command','null','0','liste from string, separator must be @');
insert into $tb values(2,0,'rules_db_fileselect','fileselect',"$db","$tb",'rules_db',null,null,'action@/home/uwe/my_scripts/dbms.sh --func rules_command rules',NULL,'0','fileselect');
insert into $tb values(3,0,'rules_db_reference','reference',"$db","$tb",'rules_status','/home/uwe/my_databases/parm.sqlite','parms','select parm_value from parms where parm_type = ''status'' and substr(parm_value,1,instr(parm_value,'' '' )-1)','','0','complex sql possible - script completes with operator and field');
insert into $tb values(4,0,'rules_tb_command','command',"$db","$tb",'rules_tb','','','input@action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','call rules_action with tag  db  tb  pid  fieldname  fieldvalue  parmlist - delimited by pipe');
insert into $tb values(5,0,'rules_db_fileselect','fileselect',"$db","$tb",'rules_db_ref','','','action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','fileselect');
insert into $tb values(6,0,'rules_tb_command','command',"$db","$tb",'rules_tb_ref','','','input@action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of table names');
insert into $tb values(7,0,'rules_tb_command','command',"$db","$tb",'rules_field','','','input@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of field names');
insert into $tb values(8,0,'modify_tb_command','command',"$dbcreate","$tbcreate",'foreign_table','','','input@action@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of table names');
insert into $tb values(9,0,'modify_field_command','command',"$dbcreate","$tbcreate",'foreign_field','','','input@/home/uwe/my_scripts/dbms.sh --func rules_command rules','','0','get list of field names');
insert into $tb values(10,0,'modify_boolean','liste',"$dbcreate","$tbcreate",'type','','','integer@real@text@blob','','0',NULL);
insert into $tb values(11,0,'modify_boolean','liste',"$dbcreate","$tbcreate",'auto_increment','','','true@false','','0',NULL);
insert into $tb values(12,0,'modify_boolean','liste',"$dbcreate","$tbcreate",'isunique','','','true@false','','0',NULL);
insert into $tb values(13,0,'modify_boolean','liste',"$dbcreate","$tbcreate",'nullable','','','true@false','','0',NULL);
insert into $tb values(14,0,'modify_boolean','liste',"$dbcreate","$tbcreate",'primary_key','','','true@false','','0',NULL);
create unique index ix_${tb}_dbtbfield on ${tb}(rules_db,rules_tb,rules_field);
EOF
    sql_execute "$db" ".read" "$file"
}
function ctrl_systb_master() {
	local db="$1" tb="$2";local file=$(getfilename "$sqlpath/create_systable" "$tb" "$db" ".sql")
	is_table "$db" "$tb"; if [ $? -lt 1 ]; then return;fi 
	cat << EOF >> "$file"
create table $tb (
	parm_id 	integer primary key autoincrement not null,
	parm_status text 	default 0,
	parm_type 	text,
	parm_field 	text,
	parm_value 	text,
	parm_info 	text);
insert into ${tb} values(0,'0','status','activ','0 active',NULL);
insert into ${tb} values(1,'0','status','dirty','1 dirty',NULL);
insert into ${tb} values(2,'0','status','ready','2 ready',NULL);
insert into ${tb} values(4,'0','status','done','3 done',NULL);
insert into ${tb} values(5,'0','status','inactiv','9 inactive',NULL);
create unique index ix1_field_type on ${tb}(parm_field,parm_type);
EOF
	sql_execute "$db" ".read" "$file"
}
function ctrl_systb_modify() {
	local db="$1" tb="$2";local file=$(getfilename "$sqlpath/create_systable" "$tb" "$db" ".sql")
#	is_table "$db" "$tb"; if [ $? -lt 1 ]; then return;fi 	
##### create system table to store and manipulate table-schema	
	cat << EOF >> "$file"
	drop table if exists $tb; 
 	create table   $tb (  
	     crtb_id        integer primary key autoincrement not null unique, 
	     pos            integer not null,  
	     field          text    not null unique,  
	     type           text    not null default 'text',  
	     primary_key    text	default 'false',  
	     auto_increment text	default 'false',  
	     isunique		text	default 'false',  
	     nullable       text	default 'false',  
	     default_value  text,  
	     ixname		    text,  
	     foreign_table	text,  
	     foreign_field  text,  
	     on_delete  	text,  
	     on_update  	text,  
	     check_const  	text,
	     field_old  	text	default 'null'
	);  	
EOF
#sql_execute "$db" ".read $file"
echo "$file"
}
function ctrl_fileconfig() {
	if [ -f "$x_configfile" ];then return;fi 
	echo "# defaultwerte etc:" 															>> "$x_configfile" 
	echo "# tpath=\"$tpath\"							#	target temporary files" 	>> "$x_configfile" 
	echo "# dbparm=\"$path/parm.sqlite\" 				#	parm database" 				>> "$x_configfile" 
	echo "# tbparm=\"parm\" 							#	parm table" 				>> "$x_configfile" 
	echo "# term_heigth=\"8\"							#	anzahl zeilen terminal"		>> "$x_configfile" 
	echo "# limit=150 									#	 " 							>> "$x_configfile" 
	echo "# tmpf=\"$tpath/dialogtmp.txt\" 				#	 " 							>> "$x_configfile" 	  
	echo "# export=\"$false\" 							#	always read to file " 		>> "$x_configfile" 	  
	echo "# geometry_tb=\"800x600+100+100\" 			#	set tb height,width,x,y " 	>> "$x_configfile" 	  
	echo "# geometry_rc=\"600x400+100+150\" 			#	set rc height,width,x,y " 	>> "$x_configfile" 	  
}
function ctrl_rollback () {
	ps -ax | grep -v grep | grep "gtkdialog -f" | grep "$tpath" > "$tmpf"
	while read -r line;do
		log $FUNCNAME $line
		return
	done < "$tmpf"
	find "${tpath}" -name "dump*" |
	while read -r file;do
		if [ "$found" = "$false" ]; then 	
			setmsg -q "data chanded\ncommit ?"
			if [ "$?" -eq 0 ];then find "${tpath}" -name "dump*" -delete ;return  ;fi
			found="$true"
		fi
		line=$(head -n 1 "$file")
		set -- $line;tb=$2;db=${@:3}
        utils_ctrl "$db" "$tb" "restore" "$file"
        rm "$file"
	done	
}
function tb_ctrl () {
	log $*
	dbliste=$(tb_get_labels $*)												# datenbanken und tabellen ermitteln
	IFS="|";arr=($dbliste);unset IFS
	if [ "${#arr[@]}" -lt "1" ];then setmsg -i "keine gueltigen Parameter";return 1 ;fi
	notebook="";for arg in ${arr[@]};do notebook="$notebook ${arg%%#*}";done 
    geometrylabel="geometry_$(echo $notebook | tr ' ' '_')"
    geometryfile="$tpath/${geometrylabel}.txt"
    xfile="$(echo $notebook | tr ' ' '_').xml"
    if [ -f "${xpath}/${xfile}" ]; then
		xmlfile="${xpath}/${xfile}"
	else
	    xmlfile="${tpath}/${xfile}"
	    wtitle=$(echo $wtitle $notebook | tr ' ' '-')
		echo "<window title=\"$wtitle\" allow-shrink=\"true\">" > $xmlfile
		if [ "${#arr[@]}" -lt "2" ];then visible="false" ;else visible="true" ;fi
		echo "<notebook show-tabs=\"$visible\"  tab-labels=\""$(echo $notebook | tr '_ ' "-|")"\">" >> $xmlfile
		for arg in "${arr[@]}" ;do
			IFS='#';set -- $arg;unset IFS 
	  		tb_gui_get_xml "$1" "$2" "$3" "$pid" >> $xmlfile 
		done
		echo "</notebook></window>" >> $xmlfile
	fi
    if [ "$geometry_tb" = "" ];then geometry_tb=$(getconfig "parm_value" "geometry" "$geometrylabel" '800x800+100+100');fi
##
    log before main dialog
    gtkdialog -f "$xmlfile" --geometry="$geometry_tb" > $tmpf				# start dialog
##   
    while read -r line;do
		echo $line															# save defaults
		field="${line%%\=*}";value=$(echo "${line##*\=}" | tr -d '"')
		if [ "${line:0:6}" = "CBOXTB" ];then  labela+=( ${field:6} ) ;fi  	# label
		if [ "${line:0:6}" = "CBOXTB" ];then cboxtba+=( $value ) ;fi 		# tabelle
		if [ "${line:0:5}" = "ENTRY" ]; then  entrya+=( $value ) ;fi 		# database
		if [ "${line:0:4}" = "TREE" ];  then   treea+=( $value ) ;fi 		# last selected row
    done < $tmpf
    for ((ia=0;ia<${#cboxtba[@]};ia++)) ;do
		if [ "${cboxtba[$ia]}" != "" ];	then
#			setconfig   "defaulttable|${labela[$ia]}_${entrya[$ia]}|${cboxtba[$ia]}"  
			setconfig   "defaulttable|${entrya[$ia]}|${cboxtba[$ia]}"  
		fi     
		if [ "${treea[$ia]}" != "" ];	then
			setconfig   "defaultrow|${labela[$ia]}_${entrya[$ia]} ${cboxtba[$ia]}|${treea[$ia]}" 
		fi   
	done
	ctrl_rollback 
}
function tb_ctrl_gui () {
	log debug $*
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	local func=$(trim_value ${parm[0]}) pid=$(trim_value ${parm[1]}) label=$(trim_value ${parm[2]}) 
	local db=$(trim_value ${parm[3]})   tb=$(trim_value ${parm[4]})  value=$(trim_value ${parm[@]:5})
	rxtitle=""
	setmsg -i -d --width=600 "func $func\nlabel $label\ndb $db\ntb $tb\nvalue $value"
	dbfile="${tpath}/input_${pid}_${label}_db.txt"
	tbfile="${tpath}/input_${pid}_${label}_tb.txt"
	whfile="${tpath}/input_${pid}_${label}_wh.txt"
	xxfile="${tpath}/input_${pid}_${label}_xx.txt"
	terminal="${tpath}/input_${pid}_${label}_cmd.txt"
	if [ "$db" = "" ];then 
		db=$(getconfig parm_value defaultdatabase $label)
		if [ "$db" = "" ];then 
			db=$(getfileselect database)
			if [ "$db" = "" ];then
				echo "" > "$dbfile";echo "" > "$tbfile";echo "" > "$whfile" 
				log no db;return
			fi
		fi
	fi
	if [ "$tb" = "" ];then 
#		tb=$(getconfig parm_value defaulttable ${label}_${db})
		tb=$(getconfig parm_value defaulttable $db)
		if [ "$tb" = "" ];then 
			tb_get_tables "$db" |
			while read -r tb;do 
				setconfig "defaulttable|$db|$tb"
				break
			done
#			tb=$(getconfig parm_value defaulttable ${label}_${db})
			tb=$(getconfig parm_value defaulttable $db)
		fi
		if [ "$tb" = "" ];then 
			echo "" > "$tbfile";echo "" > "$whfile"; return
		fi
	fi
	case "$func" in
		"input")   	echo "$db" > "$dbfile" 
					echo "$db $tb" > "$xxfile"
		            tb_get_tables "$db" "$tb" > "$tbfile"
		            tb_get_where "$label" "$db" "$tb" > "$whfile"
		            terminal_cmd "$terminal" "$label" "$db" 
#		            if [ "$value" = "defaultwhere" ];then wh="$(getconfig parm_value defaultwhere "${label}_${db}_${tb}" | remove_quotes)"  ;fi
		            if [ "$value" = "defaultwhere" ];then wh="$(getconfig parm_value defaultwhere "${db} ${tb}" | remove_quotes)"  ;fi
					tb_read_table "$pid" "$label" "$db" "$tb" "$wh";;
		"fselect") 	db=$(getfileselect database)
					is_database $db
					if [ "$?" -gt 0 ];then setmsg -i "$db\nno db";return;fi
					setconfig   "defaultdatabase|$label|$db"
					$FUNCNAME "input | $pid | $label | $db | | ";;
#		"table") 	wh="$(getconfig parm_value defaultwhere "${label}_${db}_${tb}" | remove_quotes)"
		"table") 	wh="$(getconfig parm_value defaultwhere "${db} ${tb}" | remove_quotes)"
					tb_get_where $label "$db" "$tb" "$wh" > "$whfile"
					tb_read_table "$pid" "$label" "$db" "$tb" "$wh"
#					setconfig   "defaulttable|$label $db|$tb";;
					setconfig   "defaulttable|$db|$tb";;
	    "b_utiltb") utils_ctrl "$db" "$tb";;
		"b_utils")  if [ "$label" = "selectDB" ];then mydb="" ;else mydb="$db"  ;fi
					utils_ctrl "$mydb" "";;
		"where") 	tb_read_table "$pid" "$label" "$db" "$tb" "$value";;
		"b_wh_del")	nwhere=${value//\"/\"\"}
					stmt="delete from $tbparm where parm_field = '${label}_${db}_${tb}' and parm_value = \"$nwhere\""
					sql_execute "$dbparm" "$stmt"
		            tb_get_where "$pid" "$label" "$db" "$tb" > "$whfile";;
		"b_wh_new") nwhere=$(zenity --width=600 --entry --entry-text="$value" --text="use double qoute if necessary")
					if [ "$nwhere" = "" ];then return;fi 
					sql_execute "$db" "explain select * from $tb $nwhere"
					if [ "$?" -gt "0" ];then return ;fi
#					setconfig   "defaultwhere|$label $db $tb|$nwhere" 		
					setconfig   "defaultwhere|$db $tb|$nwhere" 		
#					setconfig   "wherelist|$label $db $tb|$nwhere"  
					setconfig   "wherelist|$db $tb|$nwhere"  
		            tb_get_where "$label" "$db" "$tb" "$nwhere" > "$whfile" 
					tb_read_table "$pid" "$label" "$db" "$tb" "$nwhere";;
		"b_delete") uid_ctrl_gui "button_delete | $db | $tb | unknown | $value ||||";;
		"b_update") uid_ctrl "$value" "$db" "$tb";;
		"b_config")	setconfig   "defaultwhere|$dbparm $tbparm|where parm_field like \"%${db}_${tb}\" or parm_type = \"config\"" 
					ctrl_start_new_instance "rx_settings" "$dbparm $tbparm --noselectDB";;
		"b_clone")	ctrl_start_new_instance "rx_clone_$tb" "$db $tb --noselectDB";;
		"b_insert")	uid_ctrl "insert" "$db" "$tb" ;;
		"b_refresh") "$FUNCNAME" "input | $pid | $label | $db | $tb | defaultwhere" ;;
		"b_exit")	find $tpath -name "*$pid*" -delete
					save_geometry "$value" ;;
		*) 			setmsg -w "$func nicht bekannt"
	esac
}
function ctrl_start_new_instance () {
#	rxvt="urxvt -depth 32 -bg [65]#000000 -geometry 40x20"
	rxvt="urxvt -bg [100]#FFFFDA -geometry 40x20"
	$rxvt -title "$1" -e $script ${@:2}
	wmctrl -l | grep "$1" | while read -r window;do wmctrl -a "$window" -b toggle,shaded;done 
}
function tb_get_where () {
	local label="$1" db="$2" tb="$3" wh="${@:4}"
#	if [ "$wh" = "" ];then wh=$(getconfig parm_value defaultwhere "${label}_${db}_${tb}" | remove_quotes);fi 
	if [ "$wh" = "" ];then wh=$(getconfig parm_value defaultwhere "${db} ${tb}" | remove_quotes);fi 
	if [ "$wh" = "" ];then wh=" ";else echo "$wh";fi
	echo "" 
	getconfig parm_value "%wherelist%" "${label}_${db}_${tb}" | remove_quotes | grep -vw "$wh"
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
	if [ "$noselectDB" != "$true" ];then arr="$arr${del}selectDB##";fi
	echo $arr
}
function tb_gui_get_xml() {
	local label="$1" db="$2" tb="$3" pid="$4"
	if [ "$label" = "$tb" ]; then
		tb_meta_info "$db" "$tb"
		lb=$(echo $GTBNAME | tr '_,' '-|');sensitiveCBOX="false";sensitiveFSELECT="false";sorGTBTYPE=$GTBSORT 
	else
		lb=$(copies 30 '|');lb="c1"
		for ((ia=2;ia<=$maxcols;ia++)) ;do
			lb=$lb"|c"$ia
		done
		sensitiveCBOX="true";ID=0;sensitiveFSELECT="true";sorGTBTYPE="1$(copies 29 '|0')"
	fi
    if [ "$label" = "selectDB" ];then 
		visibleFSELECT="true";utils="utils"
	else 
		visibleFSELECT="false";utils="db_utils"
	fi
	if [ "$row" != "" ];   		 then row="$(sql_execute $cdb '.header off\nselect count(*) from '$ctb' where rowid < '$row)"  ;fi
	if [ "$row" != "" ];   		 then selected_row="selected-row=\"$row\"" ;else selected_row=""  ;fi
	terminal="${tpath}/input_${pid}_${label}_cmd.txt"
	exportfile="$epath/export_${pid}_${label}.csv"
	dbfile="${tpath}/input_${pid}_${label}_db.txt"
	tbfile="${tpath}/input_${pid}_${label}_tb.txt"
	whfile="${tpath}/input_${pid}_${label}_wh.txt"
	echo '    <vbox>
		<entry visible="false">
            <variable>DUMMY'$label'</variable>
			<input>'$script' --func tb_ctrl_gui "input | '$pid' | '$label' | '$db' | '$tb' | defaultwhere"</input>
        </entry>
        <entry auto-refresh="true" visible="false">
            <variable>DUMMY2'$label'</variable>
			<input file>"'$filesocket'"</input> 
			<action type="refresh">DUMMY'$label'</action>
		</entry>
		<tree headers_visible="true" hover-selection="false" hover-expand="true" auto-refresh="true" 
		 exported_column="'$ID'" sort-column="'$ID'" column-sort-function="'$sorGTBTYPE'" '$selected_row'>
			<label>"'$lb'"</label>
			<variable>TREE'$label'</variable>
			<input file>"'$exportfile'"</input>			
			<action>'$script' '$nocmd' --func uid_ctrl $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>				
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true" auto-refresh="true">  
				<variable>ENTRY'$label'</variable> 
				<sensitive>false</sensitive>  
				<input file>"'$dbfile'"</input>
			</entry> 
			<button space-fill="false" visible="'$visibleFSELECT'">
            	<variable>BUTTONFSELECT'$label'</variable>
            	<input file stock="gtk-open"></input>
				<action>'$script' --func tb_ctrl_gui "fselect | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
				<action type="refresh">TERMINAL'$label'</action>
            </button> 
		  </hbox>
			<comboboxtext space-expand="true" space-fill="true"  auto-refresh="true">
				<variable>CBOXTB'$label'</variable>
				<sensitive>'$sensitiveCBOX'</sensitive>
				<input file>"'$tbfile'"</input>			
				<action>'$script' --func tb_ctrl_gui "table | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
			</comboboxtext>	
			<button>
				<label>tb_utils</label>
				<action>'$script' --func tb_ctrl_gui "b_utiltb | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
			</button>
		</hbox>
		<hbox>
			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true">
				<variable>CBOXWH'$label'</variable>
				<input file>"'$whfile'"</input>
				<action>'$script' --func tb_ctrl_gui "where     | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>
			</comboboxtext>
			<button visible="true">
				<label>delete</label>
				<variable>BUTTONWHEREDELETE'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_wh_del  | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>
			</button>
			<button visible="true">
				<label>edit</label>
				<variable>BUTTONWHEREEDIT'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_wh_new  | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>
			</button>
			<button>
				<label>settings</label>
				<variable>BUTTONCONFIG'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_config  | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
			</button>	
		</hbox>
		<hbox>
			<button>
				<label>workdir</label>
				<action>xdg-open '$path' &</action>
			</button>
			<button>
				<label>'$utils'</label>
				<action>'$script' --func tb_ctrl_gui "b_utils	 | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
			</button>
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
				<action>'$script' --func tb_ctrl_gui "b_clone   | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
			</button>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_insert  | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label'"</action>
			</button>
			<button>
				<label>update</label>
				<variable>BUTTONAENDERN'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_update  | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label' | $TREE'$label'"</action>
			</button>
			<button>
				<label>delete</label>
				<variable>BUTTONDELETE'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_delete  | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label' | $TREE'$label'"</action>			
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD'$label'</variable>
				<action>'$script' --func tb_ctrl_gui "b_refresh | '$pid' | '$label' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>			
			</button>
			<button>
				<label>exit</label>
				<action>'$script' --func tb_ctrl_gui "b_exit 	| '$pid'| '$label' | $ENTRY'$label' | $CBOXTB'$label' | '${wtitle}#${geometryfile}#${geometrylabel}'"</action>			
				<action type="exit">CLOSE</action>
			</button>
		</hbox>
		<terminal space-expand="false" space-fill="false" text-background-color="#F2F89B" text-foreground-color="#000000" 
			autorefresh="true" argv0="/bin/bash" visible="false">
			<variable>TERMINAL'$label'</variable>
			<height>'$term_heigth'</height>
			<input file>"'$terminal'"</input>
		</terminal>
	</vbox>'
}  
function tb_meta_info () {
	local db="$1" tb="$2" row="$3" parms=${@:4}
	is_table "$db" "$tb";if [ "$?" -gt 0 ];then return 1 ;fi
	if [ "${parms:${#parms}-1:1}" = "," ];then parms="${parms}null"  ;fi  # last nullstring not count 
	local parmlist=$(echo $parms | quote -l '"' -r '"' -d "#")
	IFS="#";local parmarray=($parmlist);unset IFS 
	local del="" del2="" del3="" line="" nparmlist="" 
	GTBNAME="" ;GTBTYPE="" ;GTBNOTN="" ;GTBDFLT="" ;GTBPKEY="";GTBMETA="" 
	GTBSELECT="";GTBINSERT="";GTBUPDATE="";GTBUPSTMT="";GTBSORT="";GTBMAXCOLS=-1
	meta_info_file=$(getfilename "$tpath/meta_info" "${tb}" "${db}" ".txt")
	local ip=-1 ia=-1  pk="-"
	sql_execute "$db" ".headers off\nPRAGMA table_info($tb)"   > "$meta_info_file"
	if [ "$?" -gt "0" ];then log "$FUNCNAME error $?: $db" ".headers off\nPRAGMA table_info($tb)";return 1;fi
	while read -r line;do
		GTBMAXCOLS=$(($GTBMAXCOLS+1))
		IFS=',';arr=($line);unset IFS;ip=$(($ip+1))
		GTBNAME=$GTBNAME$del"${arr[1]}";GTBTYPE=$GTBTYPE$del"${arr[2]}";GTBNOTN=$GTBNOTN$del"${arr[3]}"
		GTBDFLT=$GTBDFLT$del"${arr[4]}";GTBPKEY=$GTBPKEY$del"${arr[5]}"
		GTBMETA=$GTBMETA$del2"${arr[2]},${arr[3]},${arr[4]},${arr[5]}"
		if [ "${arr[2]}" = "INTEGER" ] || [ "${arr[2]}" = "REAL" ] ;then GTBSORT="${GTBSORT}${del2}1";else GTBSORT="${GTBSORT}${del2}0";fi
		if [ "${arr[5]}" = "1" ] ;then
			PRIMKEY="${arr[1]}";export ID=$ip;  
		else
			ia=$(($ia+1));value="${parmarray[$ia]}"
			if [ "$value" = "" ] && [ "${arr[3]}" = "0" ];then value="null";fi
			nparmlist=$nparmlist$del${parmarray[$ip]}
			GTBSELECT=$GTBSELECT$del3$"${arr[1]}" 	
			GTBUPSTMT=$GTBUPSTMT$del3$"${arr[1]} = %s" 
			GTBINSERT=$GTBINSERT$del3$"$value"	
			GTBUPDATE=$GTBUPDATE$del3$"${arr[1]} = $value";del3=","	
		fi
		del=",";del2='|'
	done < "$meta_info_file"
	if [ "$PRIMKEY" = "" ];then 
		PRIMKEY="rowid";ID=0
		GTBNAME="rowid$del$GTBNAME";GTBTYPE="INTEGER$del$GTBTYPE";GTBNOTN="1$del$GTBNOTN";GTBSORT="1$del2$GTBSORT"
		GTBDFLT="' '$del$GTBDFLT";GTBPKEY="1$del$GTBPKEY";GTBMETA="rowid$del2$GTBMETA"
	fi 
	if [ "$parmlist" = "" ];then return;fi
	nparmlist=${nparmlist//'"null"'/null}
	nparmlist=${nparmlist//\'null\'/null}
	GTBINSERT="insert into $tb (${GTBSELECT}) values (${GTBINSERT})"
	GTBUPDATE="update $tb set ${GTBUPDATE}\n where $PRIMKEY = $row";unset IFS
}
function tb_read_table() {
	local pid="$1" label="$2" db="$3" tb="$4" where=${@:5}  
	setmsg -i -d "label $label\ndb $db\ntb $tb\nwher $where\n"
	strdb=$(echo $db | tr '/ ' '_');exportfile="$epath/export_${tb}_${strdb}.csv";exportfile="$epath/export_${pid}_${label}.csv"
	tb_meta_info "$db" $tb
	if [ "$?" -gt 0 ];then echo "" > "$exportfile"; setmsg -n "no table $tb in $db";return  ;fi 
	if [ "$where" != "" ] &&  [ $(pos limit "where") -gt -1 ]; then
		xlimit="" 
	else
		xlimit="limit $limit"
	fi
	if [ "$export"  = "$true" ];then 
#		exportpath="$epath/export_${tb}_$(date "+%Y%m%d%H%M").csv"
		exportpath=$(getfilename "$epath/export" "$tb" $(date "+%Y%m%d%H%M") "$db" ".csv")
	else 
#		exportpath="$epath/export_${tb}.csv"
		exportpath=$(getfilename "$epath/export" "$tb" "$db" ".csv")
	fi
	if [ "$label" = "$tb" ];then off="off";else off="on";fi	
	if [ "$label" != "$tb" ] && [ $GTBMAXCOLS -gt $maxcols ];then
		setmsg -n "clone $tb! too much cols: $GTBMAXCOLS gt $maxcols"
	fi
	srow="$PRIMKEY";if [ "$GTBSELECT" != "" ];then srow="$srow"",""$GTBSELECT" ;fi 
	sql_execute $db ".separator |\n.header $off\nselect ${srow} from $tb $where $xlimit;" | tee "$exportpath" >  "$exportfile"
	error=$(<"$sqlerror")
	if [ "$error"  != "" ];		then return 1;fi
#	setconfig   "defaultwhere|$label $db $tb|$where" 
	setconfig   "defaultwhere|$db $tb|$where" 
	return 0
}
function uid_ctrl () {
	log debug $FUNCNAME $*
	local row="$1" db="$2" tb="$3"
	tb_meta_info "$db" "$tb"
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME\nerror Meta-Info\n$db\n$tb";return ;fi
	geometrylabel="geometry_uid_$tb"
#	geometryfile="$tpath/${geometrylabel}.txt"
	geometryfile=""
    row_change_xml="$tpath/change_row_${tb}.xml"	
    wtitle="dbms-rc-${tb}"
    if [ -f "${xpath}/change_row_${tb}.xml" ]; then
		row_change_xml="${xpath}/change_row_${tb}.xml"
	else
		ctrl_systb_rules  "$dbrules"  "$tbrules" 
		echo "<window title=\"$wtitle\" allow-shrink=\"true\">" > "$row_change_xml"
		uid_gui_get_xml $db $tb $row  >> "$row_change_xml"
		echo "</window>" >> "$row_change_xml"
	fi	
    if [ "$geometry_rc" = "" ];then geometry_rc=$(getconfig "parm_value" "geometry" "$geometrylabel" '800x500+100+200');fi
 	(erg=$(gtkdialog -f "$row_change_xml" --geometry=$geometry_rc );ctrl_rollback) & 
}
function uid_ctrl_gui () {
	log debug $FUNCNAME args: $@
	local parms=$*;IFS="|";parm=($parms);unset IFS 
	local func=$(trim_value ${parm[0]})  db=$(trim_value ${parm[1]})     tb=$(trim_value ${parm[2]}) 
	local field=$(trim_value ${parm[3]}) key=$(trim_value ${parm[4]})  	 entrys=$(trim_value ${parm[5]})
	local pid=$(trim_value ${parm[6]})   geometry=$(trim_value ${parm[7]})
	local msg="" mode="normal"
	tb_meta_info $db $tb "$entrys"
	if [ "$?" -gt 0 ];then func="button_clear"; setmsg -n "no table $tb in $db";fi 

	if [ "$field" = "unknown" ];then field="$PRIMKEY";fi
	file=$(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt")
	rulesfile=$(getfilename "$tpath/rules" "$db" "$tb" ".txt")
	setmsg -i -d --width=600 "$FUNCNAME\nfunc $func\ndb $db\ntb $tb\nfield $field\nkey $key\nentrys $entrys\npid $pid\nvalues $entrys"	
	case $func in
		 "entryp")   		[ "$key" != "" ] && id="$key" ||  id=$(getconfig parm_value defaultrowid "${db}_${tb}_${pid}")
							if [ "$id" = "insert" ]; then
								id=$(sql_execute "$db" ".headers off\nselect max($PRIMKEY) + 1 from $tb")
								mode="clear"
							fi							
							if [ "$id" = "" ];then id=$(sql_execute $db ".headers off\nselect $PRIMKEY from $tb limit 1");fi
							uid_read_tb "$mode" "$db" "$tb" "$pid" "$PRIMKEY" "$id";;
		 "button_back")   	uid_sql_execute "$db" "$tb" "lt" 	"$field" "$key" "$pid";;
		 "button_next")   	uid_sql_execute "$db" "$tb" "gt" 	"$field" "$key" "$pid";;
		 "button_read")   	uid_sql_execute "$db" "$tb" "eq" 	"$field" "$key" "$pid";;
		 "button_insert")   uid_sql_execute "$db" "$tb" "insert" "$field" "$key" "$pid" "$entrys"
							if [ $? -gt 0 ];then return;fi 
							;;
		 "button_update")   uid_sql_execute "$db" "$tb" "update" "$field" "$key" "$pid" "$entrys" ;;
		 "button_delete")   setmsg -q "$field=$key wirklich loeschen ?"
							if [ $? -gt 0 ];then setmsg "-w" "Vorgang abgebrochen";return  ;fi
							uid_sql_execute "$db" "$tb" "delete" "$field" "$key" "$pid" 
							if [ $? -gt 0 ];then return  ;fi
							if [ "$pid" != " " ];then
								uid_sql_execute "$db" "$tb" "gt" "$field" "$key" "$pid"
								if [ $? -gt 0 ];then uid_sql_execute "$db" "$tb" "lt" "$field" "$key" "$pid";fi
							fi
							;;
		 "button_clear")   	uid_read_tb "clear" "$db" "$tb" "$pid" "$PRIMKEY" "$key" ;;
		 "button_refresh")  uid_read_tb "read" "$db" "$tb" "$pid" "$PRIMKEY" "$key" ;;
		 "button_exit")   	find $tpath -name "*$pid*" -delete
							save_geometry "$geometry" ;;
		 "fileselect") 	    sfile=$(getfileselect "rule_selectdb")
							if [ "$?" -gt "0" ];then log "$FUNCNAME Suche abgebrochen";return  ;fi
							echo "$sfile" > $(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt")
							;;		
		 "command") 			uid_gui_get_rule "$db" "$tb" "$field"
							if [ "$?" = "$false" ];then return  ;fi
							if [ "$ACTION" = "" ];then return  ;fi
							uid_gui_rules "exe" "action" "$db" "$tb" "$field" "$key" "$entrys" "$pid" "$ACTION";;
		 *) 				setmsg -i -d --width=400 "func $func nicht bekannt\ndb $db\ntb $tb\nfield $field\nentry $entry"
	esac
	if [ "$msg" != "" ];then setmsg -n "$msg"  ;fi
}
function uid_ctrl_gui_defaults () {
	local db="$1" tb="$2" pid="$3" file=""
	IFS=",";name=($GTBNAME);unset IFS;
	IFS="|";arrmeta=($GTBMETA);unset IFS	
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		IFS=',';meta=(${arrmeta[$ia]});unset IFS 
		if   [ "${meta[2]}" != "" ];      then  field="${meta[3]}"  
		elif [ "${meta[1]}" = "0" ];  	  then  field="null"  
		elif [ "${meta[0]}" = "INTEGER" ];then  field="0"   
		else                               		field=""
		fi 
		echo "${name[$ia]} = $field" 
    done
}
function uid_gui_rules () {
	local mode="$1" tag="$2" db="$3" tb="$4" field="$5" entry="$6" entrys="$7" pid="$8" ACTION=${@:9} 
	setmsg -i -d --width=600 "$FUNCNAME 0\nACTION $ACTION\nmode $mode\ntag $tag\nftag $ftag\ndb $db\ntb $tb\nfield $field"
	xparm="$script --func uid_ctrl_gui \"command | $db | $tb | $field | $entry | $entrys | $pid\""
	local ftag="" label="" icon="" func="" action="" cmd="" arg=""
	IFS=";";action=($ACTION);unset IFS
	for arg in "${action[@]}" ;do
		func="${arg%\@*}"
		cmd="${arg##*\@}"
		for ftag in ${func//@/ };do 
		    set -- ${ftag//#/ }
		    ftag="$1";label="$2";icon="$3"
			if [ "$ftag" != "$tag" ];then continue  ;fi
			setmsg -i -d --width=600 "$FUNCNAME 1\nmode $mode\ntag $tag\nftag $ftag\ndb $db\ntb $tb\nfield $field"
			if [ "$mode"  = "xml" ];then 
				case "$tag" in
					"button") 	echo							"	        <button>"
								if [ "$label" != "" ];then echo	"	        	<label>$label<label>"  ;fi
								if [ "$icon"  != "" ];then echo	"	        	<input file stock=\"$icon\"></input>"  ;fi
								echo							"	        	<action>$xparm</action>"  
								echo							"	        </button>"  
							;;
					*)  		echo							"	        	<$tag>$xparm</$tag>"  
				esac
			else
                setmsg -i -d --width=600 "$FUNCNAME 2\nmode $mode\nftag $ftag\ndb $db\ntb $tb\nfield $field"
				$cmd "| $ftag | $db | $tb | $pid | $field | $entry | $entrys"
				break  
			fi
		done
	done
}
function uid_gui_get_xml () {
	local db="$1" tb="$2" key="$3" 
	sizetlabel=20;sizeentry=36;sizetext=46;ref_entry=""
	IFS=",";name=($GTBNAME);unset IFS;IFS="|";meta=($GTBMETA);unset IFS	
	entrys="";del=""
	rulesfile=$(getfilename "$tpath/rules" "$db" "$tb" ".txt")
	stmt="select * from $tbrules where rules_db = \"$db\" and rules_tb = \"$tb\" and rules_status < 9"
	sql_execute "$dbrules" ".mode line\n$stmt" > "$rulesfile"
	#~ log "$rulesfile"
	#~ log "sql_execute $dbrules .mode line\n$stmt $rulesfile"
	#~ setmsg -i "rf: pause"
	setconfig "defaultrowid|$db $tb $pid|$key"
	echo '<vbox hscrollbar-policy="1" vscrollbar-policy="1" space-expand="true" scrollable="true">'
	echo '	<entry width_chars="'$sizeentry'" space-fill="true" visible="false">'
	echo '		<variable>entrydummy</variable>'
	echo '		<input>'$script' --func uid_ctrl_gui "entryp | '$db '|' $tb '|' ${PRIMKEY} '| $entryp |' $entrys '|' ${pid}'"</input>'
	echo ' 	</entry>' 
	echo '  <entry auto-refresh="true" visible="false">'
	echo '		<variable>entrydummy2</variable>'
	echo '		<input file>"'$filesocket'"</input> '
	echo '		<action type="refresh">entrydummy</action>' 
	echo '	</entry>'
	echo '	<vbox space-expand="false">'
	echo '		<hbox>'
	echo '			<entry width_chars="'$sizeentry'" space-fill="true" auto-refresh="true">'
	echo '				<variable>entryp</variable>'
	echo ' 				<input file>"'$(getfilename "${tpath}/input" "$pid" "$tb" "$PRIMKEY" "$db" ".txt")'"</input>' 
	echo ' 			</entry>' 
	echo '			<text width-chars="46" justify="3"><label>'$PRIMKEY' (PK) (type,null,default,primkey)</label></text>'
	echo '		</hbox>'
	echo '	</vbox>'
	echo '	<vbox>'
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		uid_gui_get_rule "$db" "$tb" "${name[$ia]}"
		if [ "$?" = "$true" ];then func=$FUNC;visible="false" ;else func="";visible="true";fi
		echo    '		<hbox>' 
		entrys="${entrys}${del}"'$entry'"$ia";del="#"
		if  [ "$func" = "" ] || [ "$func" = "fileselect" ] ; then  					
			echo    ' 			<entry width_chars="'$sizeentry'" space-fill="true" auto-refresh="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<input file>"'$(getfilename "${tpath}/input" "$pid" "$tb" "${name[$ia]}" "$db" ".txt")'"</input>' 
			echo    ' 			</entry>' 
		else
            echo  	' 			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true">'
			echo 	' 				<variable>entry'$ia'</variable>'
			echo    ' 				<input file>"'$(getfilename "${tpath}/input" "$pid" "$tb" "${name[$ia]}" "$db" ".txt")'"</input>' 
			uid_gui_rules "xml" "action" "$db" "$tb" "${name[$ia]}" "\$entry${ia}" "$entrys" "$pid" "$ACTION"
		  	echo  	'			</comboboxtext>'
		fi
		if  [ "$func" = "fileselect" ] ; then  
			echo	'	        <button>'
			echo	'				<input file stock="gtk-open"></input>'
    		echo	' 				<action>'$script' --func uid_ctrl_gui "fileselect  | '$db '|' $tb '|' ${name[$ia]} '| $entry'$ia' | ' $entrys '|' ${pid}'"</action>'
			uid_gui_rules "xml" "action" "$db" "$tb" "${name[$ia]}" "\$entry${ia}" "$entrys" "$pid" "$ACTION"
			echo	'			</button>'
		fi
		uid_gui_rules "xml" "button" "$db" "$tb" "${name[$ia]}" "\$entry${ia}" "$entrys" "$pid" "$ACTION"
		echo  	' 			<text width-chars="'$sizetext'" justify="3"><label>'${name[$ia]}' ('${meta[$ia]}')</label></text>'   
		echo    '		</hbox>' 
	done
	echo '	</vbox>'
	echo '	<hbox>'
	for label in back next read insert update delete clear refresh;do
		echo '		<button><label>'$label'</label>'
		echo ' 			<action>'$script' --func uid_ctrl_gui "button_'$label'  | '$db '|' $tb '|' ${PRIMKEY} '| $entryp | ' $entrys '|' $pid '"</action>'
		echo '		</button>'
	done
	echo '	<button>'
	echo '		<label>exit</label>'
	echo '		<action>'$script' --func uid_ctrl_gui "button_exit  | '$db '|' $tb '|' ${PRIMKEY} '| $entryp | ' $entrys '|' ${pid} '|' ${wtitle}#${geometryfile}#${geometrylabel}'"</action>'			
	echo '		<action type="exit">CLOSE</action>'
	echo '	</button>'
	echo '	</hbox>'
	echo '</vbox>'  
}
function uid_gui_get_rule() {
	if [ "$norules" = "$true" ];then return 1;fi
	local db="$1" tb="$2" field="$3" value="" found=$false
#	rulesfile=$(getfilename "$tpath/rules" "$db" "$tb" ".txt")
	while read -r line;do
		set -- $line;var=$1;shift;shift;value=$*
		if [ "$value"   =  "$field"  ];then found=$true;fi	
		if [ "$value"   = "'$field'" ];then found=$true;fi	
		case $var in
			rules_type)     FUNC=$value	;;
			rules_db_ref) 	SDB=$value	;;
		esac
		if [ "$found" = "$false" ];then continue  ;fi		
		case $var in
			rules_tb_ref) 	STB=$value	;;
			rules_action) 	SCMD1=$(echo $value | tr '@' '@');ACTION=$SCMD1;LISTE=$SCMD1	;;
			rules_col_list) SCMD2=$value	;;
			rules_info)     break	;;
		esac
	done < "$rulesfile"
	return $found
}
function utils_ctrl () {
	local db="$1" tb="$2" func="$3" ifile="$4" drop_list="" height="260"
	local drop=$false create=$false edit=$false read=$false import=$false check_inuse=$false
	local dump=$false restore=$false commit=$false rollback=$false errmsg="" 
	list='import dump restore commit rollback rules'
	if [ "$tb" = "" ]; then
		list=$list' drop create(editor) create(gui) modify(editor) modify(gui)';height="390"		
	fi
	if [ "$func" = "" ];then 
		func=$(zenity --list --height=$height --column action $list)
	fi
	if [ "$(echo $func | grep 'rules')"	!= "" ]; 	then 
		if   [ "$tb" != "" ]; then
			setconfig "defaultwhere|$dbrules $tbrules|where rules_db = \"$db\" and rules_tb = \"$tb\""
		elif [ "$db" != "" ]; then
			setconfig "defaultwhere|$dbrules $tbrules|where rules_db = \"$db\""
		else
			setconfig "defaultwhere|$dbrules $tbrules| "
		fi
		ctrl_start_new_instance "set-rules" "$dbrules" "$tbrules" "--noselectDB"  &
		return
	fi
	if [ "$db"   = "" ];then db=$(getfileselect database_import --save);fi
	if [ "$db"   = "" ];then setmsg -n "abort..no db selected"; return ;fi
	if [ ! -f "$db" ];then func="create(editor)"  ;fi
	if [ "$(echo $func | grep 'create')" 	!= "" ]; 	then 
		tb=$(zenity --text "new table-name" --entry)
		if [ "$tb"   = "" ];then setmsg -n "abort... no tb entered"; return ;fi
		func=$(echo ${func/create/modify})
	fi
	if 	 [ "$(echo $func | grep 'drop')" 	!= "" ]; 	then drop=$true;check_inuse=$true									 
	elif [ "$(echo $func | grep 'editor')" 	!= "" ]; 	then create=$true;check_inuse=$true									 
	elif [ "$(echo $func | grep 'gui')" 	!= "" ]; 	then edit=$true;create=$true;check_inuse=$true						 
	elif [ "$(echo $func | grep 'read')" 	!= "" ]; 	then read=$true
	elif [ "$(echo $func | grep 'import')" 	!= "" ]; 	then import=$true 
	elif [ "$(echo $func | grep 'dump')" 	!= "" ]; 	then dump=$true
	elif [ "$(echo $func | grep 'restore')" != "" ]; 	then restore=$true
	else	setmsg -i "abort...func not known $func";return
	fi
	if [ "$tb" = "" ] &&  [ "$restore" = "$false" ]; then
		is_database "$db";if [ "$?" -gt "0" ];then setmsg -n "abort! no database\n$db";return;fi
		if [ "$import" = "$true" ]; then 
			tb=$(zenity --list --height=400 --column table 'tmp_import' $(dbms.sh --func tb_get_tables $db))
		else
			tb=$(zenity --list --height=400 --column table              $(dbms.sh --func tb_get_tables $db))
		fi 
		if [ "$tb" = "" ]; then setmsg -n "abort 892! no table selected";return;fi
	fi 
	if [ "$check_inuse" = "$true" ];then 
		find "$tpath" -name "*xx*" -exec  grep "$db" {} \; | grep "$tb" > "$tmpf"
		while read -r line;do
			setmsg -i --width=300 "abort! in use\ntb:$tb\ndb: $db";return
		done < "$tmpf"
	fi
	if [ "$check_inuse" = "$true" ] || [ "$import" = "$true" ]; then
		local dumpfile=$(getfilename "${tpath}/dump" "$table" "$db" ".sql") 
		if [ ! -f "$dumpfile" ];then utils_ctrl "$db" "$tb" "dump" "$dumpfile" ;fi
	fi 
	readfile=$(getfilename "$sqlpath/read" "${tb}" "${db}" ".sql")
	readcrtb=$(getfilename "$sqlpath/read" "${tbcreate}" "${dbcreate}" ".sql")
###	
	if 	 [ "$drop" = "$true" ]; then
		msg="delete $tb from $db"
		echo "	drop table if exists $tb;" > $readfile
	elif [ "$create" = "$true" ]; then
		msg="run  $readfile"
		is_database $db
		if [ $? -eq 0 ];then found=$(echo ".tables $tb" | sqlite3 $db);else found=$false;fi
		if [ "$found" = "" ]; then
			stmt="create table $tb (
				  ${tb}_id  	integer primary key autoincrement not null unique
				 ,${tb}_status  integer default 0
				 ,${tb}_name	text
				 ,${tb}_info	text)"
			sql_execute "$db" "$stmt"
			edit=$true
		fi
		tb_meta_info "$db" $tb;GTBINSERT=$GTBSELECT 
		if [ "$edit" = "$true" ]; then	
			utils_modify "$db" "$tb" 								>  $readfile
			if [ "$?" -gt 0 ];then setmsg -n "abbort..";return ;fi
		else
			echo "	drop table if exists ${tb}_copy;" 				>  $readfile
			echo "	create table ${tb}_copy as select * from $tb;"  >> $readfile
			echo "	drop table if exists $tb;" 						>> $readfile
			sql_execute $db  ".schema $tb"  						>> $readfile 
		fi
		if [ "$found" != "" ]; then
			if [ "$PRIMKEY" != "rowid" ]; then
			    GTBSELECT="${PRIMKEY},${GTBSELECT}"
			fi
 			echo "	insert into $tb  ($GTBSELECT) " 				>> $readfile
 			echo "	select            $GTBSELECT " 					>> $readfile
			echo "	from ${tb}_copy;" 								>> $readfile
		fi
		drop_list="$drop_list ${tb}_copy"
	elif [ "$read" = "$true" ]; then
		if [ ! -f "$ifile" ]; then
			ifile=$(getfileselect file_read)
		fi
		if [   -f "$ifile" ]; then
			sql_execute "$db" ".read $ifile";return
		else 
			errmsg="cancel...no file selected"
		fi
		return
	elif [ "$import" = "$true" ]; then
	    msg="run $readfile for insert/replace"
		if [ ! -f "$ifile" ]; then
			ifile=$(getfileselect file_import file_import)
		fi
		if [   -f "$ifile" ]; then
			utils_import "$db" "$tb" "$ifile" "$func" "$separator" > $readfile
		else 
			errmsg="cancel...no file selected"
		fi
	elif [ "$dump" = "$true" ]; then
		if [ "$ifile" != "" ] ;then
			file="$ifile"
		else
			file="${dpath}/dump_${tb}_$(date "+%Y_%m_%d_%H_%M")$(echo $db | tr '/.' '_').txt"
		fi
		echo "-- $tb $db"  > "$file"
		sql_execute "$db" ".dump $tb" |
		while read -r line;do
			echo $line
			if [ "${line:0:5}" = "BEGIN" ];then 
				echo "DROP  TABLE IF EXISTS $tb;"  
			fi
		done >> "$file"
		if [ "$ifile" != "" ] ;then return;fi
		setconfig "searchpath|dump_tb|$file"
		setmsg -n "success: $func $tb in $db to $file";return
	elif [ "$restore" = "$true" ]; then
		if [ "$ifile" = "" ] ;then
			ifile=$(getfileselect dump_tb)
			if [ "$?" -gt 0 ];then setmsg -i "abort restore";return;fi
			str=${ifile##*dump_};tb=${str%%_*};
		fi
	    is_table "$db" "$tb"
	    if [ "$?" -gt 0 ];then msg="create $tb in\n$db";found="$false";else msg="restore $tb in\n$db";found="$true";fi
	    setmsg -q --width=300 "$msg" 
	    if [ "$?" -gt 0 ];then setmsg -n --width=600 "abort: $func $tb in\n$db";return;fi
	    if [ "$found" = "$false" ];then 
			sql_execute "$db" ".read $ifile"
		else
			echo "drop table if exists ${tb}_dump;" > "$tmpf" 
			echo "create table ${tb}_dump as select * from $tb;" >> "$tmpf"
			cat "$ifile" >> "$tmpf"
			drop_list="$drop_list ${tb}_dump"
			sql_execute "$db" ".read $tmpf"
		fi	
		if [ "$?" -gt 0 ];then return;fi
		sql_execute "$db" "drop table if exists ${tb}_dump;" 
		if [ "$?" -gt 0 ];then return;fi
		setmsg -n --width=600 "succes: $func $tb from $ifile"
		uid_sql_execute_sync "restore" "$db" "$tb"
		return
	elif [ "$commit" 	= "$true" ]; then
		rm "${tpath}/dump*";return
	elif [ "$rollback" 	= "$true" ]; then
		ctrl_rollback;return
	fi	
	if [ "$errmsg" != "" ];then setmsg -i "$errmsg";return  ;fi
	trash=$(xdg-open $readfile)
	setmsg -q "$msg" 
	if [ "$?" = "1" ];then 
		return
	fi
	sql_execute $db ".read $readfile" 
	if [ "$?" -eq "0" ];then setmsg "success $msg";fi
	if [ "$drop" = "$true" ];then 
		stmt="delete from $tbparm where parm_type='defaulttable' and parm_field like \"%${db}%\" and parm_value = \"$tb\"" 
		sql_execute "$dbparm" "$stmt" 
	fi
	for tb in $drop_list;do
		setmsg -q "$tb loeschen?" 
		if [ "$?" = "0" ];then sql_execute $db "drop table if exists $tb;";fi
	done	 
	uid_sql_execute_sync
}
function utils_import () {
	local db="$1" tb="$2" file="$3" func="$4" delim="$5" nheader=""
	if [ "$delim" = "" ];then delim=$(getconfig "parm_value" "config" "separator" ",");fi
	delim=$(zenity --entry --text="enter column-separator " --entry-text="$delim")
	if [ "${#delim}" -ne "1" ];then errmsg="no separator";return 1;fi
	hl=$(head $file -n 1 | tr [:upper:] [:lower:])
	echo ".separator $delim"				 
	is_table "$db" "$tb";istable=$?
	if [ "$istable" = "$false" ]; then
		if [ "$tb" = "" ];then tb="tmp_import";fi
		echo "drop table if exists $tb;"	
		setmsg -q "has header $file ?"
		if 	[ "$?" -gt 0  ]; then
			echo "--need file with header $tmpf" 
			IFS="$delim";ahl=( $hl );unset IFS
			nline="";del=""
			for ((ia=0;ia<${#ahl[@]};ia++)) ;do nline=$nline$del'c'$ia;del=$delim;done
			echo "$nline" > $tmpf;cat "$file" >> "$tmpf";file="$tmpf"
		fi	 
		echo ".import \"$file\" $tb"				 
		return 0
	fi
	local tbcopy="$2_tmp" 
	tb_meta_info "$db" "$tb"
	il=$(echo $GTBSELECT | tr ',' "$delim" | tr [:upper:] [:lower:])
	rl=$(echo $GTBNAME   | tr ',' "$delim" | tr [:upper:] [:lower:]) 
	if [ "$hl" != "$il" ] && [ "$hl" != "$rl" ]; then
	    setmsg -q --width=300 "has header $file ?"
	    hasheader=$?
	else
		hasheader=$true
	fi
	IFS="$delim";ahl=( $hl );ail=( $il );arl=( $rl );unset IFS
	zhl="${#ahl[@]}";zil="${#ail[@]}";zrl="${#arl[@]}" 
	if   [ "${hl:${#hl}-1:1}" = "$delim" ];then zhl=$(($zhl+1))  ;fi ## last empty element not count
	if   [ "$hl"     = "$il" ];    	then func="insert"
	elif [ "$zhl"    = "$zil" ];   	then func="insert";nheader="$il" 
	elif [ "$hl"     = "$rl" ]; 	then func="update" 
	elif [ "$zhl"    = "$zrl" ];   	then func="update";nheader="$rl"  
	else errmsg="cannot handle $file";return 1				 
	fi
	#~ local dfile=$(getfilename "${tpath}/dump" "$tb" "$db" ".sql") 
	#~ if  [ ! -f "$dfile" ];then 
		#~ echo ".once $dfile"
		#~ echo ".dump $tb"
	#~ fi
	if [ "$nheader" != "" ]; then
		echo "--need file with exact header! new file: $tmpf"  
		echo "$nheader" > "$tmpf" 
		if [ "$hasheader" = "$false" ]; then
			cat "$file" >> "$tmpf" 
		else
			tail -n +2 "$file" >> "$tmpf" 
		fi
		file="$tmpf"
	fi
	echo "	drop table if exists $tbcopy;"	 
	echo ".import \"$file\" $tbcopy"			 
	echo ".separator ,"				 
	if  [ "$func"   = "insert" ]; 	then
		msg="insert to $tb $file "
		echo "	insert into $tb ($GTBSELECT)"	 
		echo "	select $GTBSELECT from $tbcopy;"			 
	else
		line="";del=""
		for ((ia=0;ia<${#arl[@]};ia++)) ;do
			line="${line}${del}b.${arl[$ia]}";del=","
		done
		msg="insert/update to $tb $file "	 
		echo "	insert or replace into $tb"		 
		echo "	select $line"					 
		echo "	from $tbcopy as b join $tb as a on b.$PRIMKEY = a.$PRIMKEY;"	 
		echo "--  "								 
		echo "	insert into $tb as a  " 		 
		echo "	select $line" 					 
		echo "	from $tbcopy as b"				 
		echo "	where b.${PRIMKEY} in ("		 
		echo "	select  a.${PRIMKEY} from $tbcopy as a "	 
		echo "	left join $tb as b  "			 
		echo "	on a.${PRIMKEY} = b.${PRIMKEY}"	 
		echo "	where b.${PRIMKEY} is null);"	 
	fi
	echo     "	drop table if exists $tbcopy;"	
}
function utils_modify () {
	local db="$1" tb="$2" 
	setconfig "system|modify_db|$db"
    utils_modify_create "$db" "$tb" > "$readcrtb" ###	create table for dialog	
    sql_execute "$dbparm" ".read $readcrtb"
    if [ "$?" -gt "0" ];then return 1;fi
### start dialog
   "$script" "$dbcreate" $tbcreate "--noselectDB" | grep -i "abort" |
    while read -r line; do return 1; done
    if [ "$?" -gt "0" ];then return 1 ;fi
    if [ "$?" -gt "0" ];then setmsg -n "abort modify $tb";return 1  ;fi
	utils_modify_script "$db" $tb 				  ###   create script	
}
function utils_modify_create () {
	local db="$1" tb="$2" ic=0 found=$false icheck=0 
	file=$(ctrl_systb_modify "$dbcreate" "$tbcreate")
	cat  "$sqlpath/create_table_${tbcreate}.sql" 
	echo "insert into $tbcreate (pos,field,type,nullable,default_value,primary_key) values"  
	tb_meta_info "$db" "$tb"  
	while read -r line;do
#	    log "$line"
	    IFS=",";fields=( $line );unset IFS;nline="";del=""
	    for ((ia=0;ia<${#fields[@]};ia++)) ;do
			arr=${fields[$ia]}
			case "$ia" in
				0)		arr="${arr}0";maxpos=$arr  ;;
				3)		if [ "$arr"  = "1" ];then  arr="false" ;else  arr="true" ;fi;;
				5)		if [ "$arr"  = "1" ];then  arr="true"  ;else  arr="false" ;fi;;
				*)  	nop
			esac
			arr=$(echo $arr | tr -d '"' )
#			nline="$nline$del\"$(remove_quotes $arr)\"";del=","
			nline="$nline$del\"$arr\"";del=","
		done
		echo "${delim}(${nline})"  
		delim=","
	done  < "$meta_info_file"
	echo ";" 
###	index info
	ixline=""
	sql_execute "$db" "pragma index_list($tb)" |  tr '[:upper:]' '[:lower:]' |
    while read iline; do
		IFS=",";arr=($iline);ixline="${arr[1]},${arr[2]},${arr[3]},"
		sql_execute "$db" "pragma index_info(${arr[1]})" |  tr '[:upper:]' '[:lower:]' | 
	    while read line; do
			IFS=",";arr=(${ixline}${line});unset IFS #;del=","
			stmt="set"  
			if [ "${arr[0]:0:16}" = "sqlite_autoindex" ];then  
				stmt="set isunique = \"true\"" 
			else 
				stmt="set ixname=\"${arr[0]}\""
			fi
			echo "update $tbcreate $stmt where field='${arr[5]}';" 
		done 
	done  	
	echo "update $tbcreate set auto_increment = \"true\" where primary_key = 'true' and type like 'integer';"  
	echo "update $tbcreate set default_value = null where default_value = '';" 
	echo "update $tbcreate set field_old = field;" 
###	foreign key info
	sql_execute "$db" "pragma foreign_key_list($tb)" |  tr '[:upper:]' '[:lower:]' |
    while read line; do
		IFS=",";arr=($line) 
		echo "update $tbcreate set ref_table = \"${arr[2]}\", ref_field = \"${arr[4]}\"," \
			 "on_update = \"$(echo ${arr[5]} | tr -d '"')\", on_delete = \"$(echo ${arr[6]} | tr -d '"')\" where field = \"${arr[3]}\";"  
	done 
###	check info
	erg=$(sql_execute "$db" ".schema $tb")
    str="${erg#*\(}"
    erg=",${str%\)*}"
    for ((ia=0;ia<${#erg};ia++)) ;do
		b="${erg:$ia:1}"
		if [ "$b" = "(" ];then ic=$(($ic+1));found=$false;fi
		if [ "$b" = ")" ];then ic=$(($ic-1));fi 
		if [ "$b" = ")" ] && [ "$ic" -eq 0 ];then
#			check=$(echo $check | tr "'" '"')
			if [ "$field" = "check" ];then 
				echo "	  insert into $tbcreate (field,check_const,pos) values (\"check$((icheck++))\",\"${check:1}\",\"$((maxpos + $icheck))\");"    
			else 
				echo "	  update $tbcreate set check_const = \"${check:1}\" where field = \"$field\";"
			fi
			continue
		fi 
		if [ "$ic" -gt 0 ];then check="${check}${b}";continue;fi
		if [ "$b"  = "," ];then found=$true;field="";check="";continue;fi
		if [ "$b"  = " " ] && [ "$found" = "$true" ] && [ "$field"  = "" ];then continue;fi
		if [ "$b"  = " " ] && [ "$found" = "$true" ] && [ "$field" != "" ];then found="$false";continue;fi
		if [ "$b" != " " ] && [ "$found" = "$true" ];then field="${field}${b}";continue;fi
	done 
}
function utils_modify_script () {
	local db="$1" tb="$2" del=""
	echo "	  drop table if exists ${tb}_copy;" 				
	echo "	  create table ${tb}_copy as select * from $tb;" 	
	echo "	  drop table if exists $tb;" 						
	echo "    create table if not exists $tb (" 
	stmt="select field,type
			 ,case when isunique = 'true' 		then 'unique' 			else '' end
			 ,case when nullable = 'true' 		then '' 				else 'not null' end
			 ,case when default_value != '' 	then 'default #' || default_value || '#'   else '' end
			 ,case when primary_key = 'true' 	then 'primary key' 		else '' end
			 ,case when auto_increment = 'true' then 'autoincrement' 	else '' end
			 ,case when check_const != '' 		then 'check(' || replace(check_const,',',';') || ')' 	else '' end
			  from $tbcreate where field not like 'check%' order by pos
		"
	sql_execute "$dbcreate" "$stmt" | tr '",' ' ' | tr '#' '"' | tr ';' ',' |
	while read -r f t line;do
		printf "%8s %-20s %-10s %s \n" "$del" "$f" "$t" "$line" 
		del=","
	done
	stmt="select check_const from $tbcreate where field like 'check%'" 
	sql_execute "$dbcreate" "$stmt" | trim -c '"' |
	while read -r  line;do 
	    $line
		printf "%8s %s\n" "," "check(${line})"
	done
 
	sql_execute "$dbcreate" "select distinct foreign_table from $tbcreate where foreign_table != ''" |
	while read -r line;do
		str1=$(sql_execute "$dbcreate" "select field from $tbcreate where foreign_table = '$line'" | fmt -w 500 | tr ' ' ',')
		str2=$(sql_execute "$dbcreate" "select foreign_field from $tbcreate where foreign_table = '$line'" | fmt -w 500 | tr ' ' ',')
		echo "   ,foreign key(${str1}) on ${line}(${str2})"
	done
	echo "    );"
	stmt="select 'create',case when isunique = 'true' then 'unique'	else '' end,'index if not exists',ixname from $tbcreate where ixname != ''"
	sql_execute "$dbcreate" "$stmt" |
	while read -r line;do 
	    ix=${line##*\,}
	    str=$(sql_execute "$dbcreate" "select field from $tbcreate where ixname = '$ix'" | fmt -w 500 | tr ' ' ',')
	    echo "    $(echo $line | tr ',"' ' ') on ${tbcreate}(${str});"	    
	done 
### trigger info
	sql_execute $db "select sql from sqlite_master where type = \"trigger\" and tbl_name = \"$tb\";" |  tr -d '"' | tr '[:upper:]' '[:lower:]'  
	echo "--"
	GTBINSERT=$(sql_execute "$dbcreate" "select field     from $tbcreate where field != '$PRIMARYKEY' and field not like 'check%' order by pos" | fmt -w 500 | tr ' ' ',')
	GTBSELECT=$(sql_execute "$dbcreate" "select field_old from $tbcreate where field != '$PRIMARYKEY' and field not like 'check%' order by pos" | fmt -w 500 | tr ' ' ',' | tr -d '"')
}
function rules_receive_parm () {
	local db="$1" tb="$2" parm=${@:3} nparm="" vparm="" del="" del2="" value="" avlue="" iv=0
	IFS=",";name=($GTBNAME);unset IFS
	IFS="#";value=($parm);unset IFS
  	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
#		arg=$(echo ${value[$iv]} | tr  ',' ' ' | tr -d '"')
		arg=$(echo ${value[$iv]} | tr  ',' ',' | tr -d '"')
		iv=$((iv+1))
		if [ "$arg" = "" ];    			then nparm=$nparm$del$arg;del="#";continue;fi
		if [ "$arg" = "null" ];			then nparm=$nparm$del$arg;del="#";continue;fi
		uid_gui_get_rule "$db" "$tb" "${name[$ia]}"
		if [ "$?" = "$false" ];			then nparm=$nparm$del$arg;del="#";continue;fi
		if [ "$SCMD2" = "all" ];		then nparm=$nparm$del$arg;del="#";continue;fi
		if [ "$SCMD2" = "" ]; 			then SCMD2=0;fi
		IFS=",";range=($SCMD2);unset IFS
		IFS=", ";avalue=($arg);unset IFS
		vparm="";del2=""
		for arg in ${range[@]}; do vparm=$vparm$del2${avalue[$arg]};del2=" ";done
		nparm=$nparm$del$vparm;del="#"
	done
	echo $nparm
}
function uid_read_tb () {
	local debug func="$1" db="$2" tb="$3" pid="$4" PRIMKEY="$5" rowid="$6" file="" sel=""
	log debug "$FUNCNAME $db $tb $pid $PRIMKEY $rowid "
	if [ "$func" = "clear" ]; then 
		uid_ctrl_gui_defaults > "$tmpf"
	else
		if [ "$PRIMKEY" = "rowid" ];then sel="rowid,*" ;else sel="*"  ;fi
		sql_execute "$db" ".nullvalue null\n.mode line\nselect $sel from $tb where $PRIMKEY = $rowid" > "$tmpf"
	fi
	local xxfile="${tpath}/input_${pid}_gui_xx.txt"
	echo "$db" "$tb" > "$xxfile"
	local ffound=$false entrys="" del=""
	while read -r field trash value;do
		ffound=$true
		if [ "$field" = "$PRIMKEY" ];then setconfig "defaultrowid|$db $tb $pid|$rowid";else entrys="$entrys$del$value";del='#'  ;fi
		file=$(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt")
		echo "$value" > "$file"
		uid_gui_get_rule "$db" "$tb" "$field";	
		if 	 [ "$?" = "$false" ] ;then  continue ;fi
		if 	 [ "$FUNC" = "reference" ]; then
			SCMD1=$(echo "$SCMD1" | tr ';' ' ')
			sql_execute "$SDB" "$SCMD1  = \"$value\"" 	>  "$file"		# show first db value
			sql_execute "$SDB" "$SCMD1 != \"$value\"" 	>> "$file"		# than others
		elif [ "$FUNC" = "fileselect" ]; then
			continue
		elif [ "$FUNC" = "table" ]; then
			sql_execute "$SDB" "$SCMD1  = \"$value\"" 	> "$file"		# nur aktuellen wert als erstes anzeigen
		elif [ "$FUNC" = "liste" ]; then
			if [ -f "$LISTE" ]; then
				readarray  aliste < "$LISTE"
			else								
				IFS='#,@,|'; aliste=($LISTE);unset IFS
			fi
			lng=${#field}
			for arg in "${aliste[@]}" ;do if [ "$value"  = "${arg:0:$lng}" ];then echo $arg;break ;fi;done > "$file"
			for arg in "${aliste[@]}" ;do if [ "$value" != "${arg:0:$lng}" ];then echo $arg		  ;fi;done >>  "$file"
		elif [ "$FUNC" = "command" ]; then 
			setmsg -i -d --width=600 "$FUNCNAME command\nexe\ninput\n$db\n$tb\n$pid\n$field\n$value"
			uid_gui_rules "exe" "input" "$db" "$tb" "$field" "$value" "$entrys" "$pid" "$ACTION" > "$file"
		else setmsg -i "$FUNCNAME type not known $FUNC"
		fi 						
	done  < "$tmpf" 
	if [ "$ffound" = "$true" ];then return ;fi
	setmsg -n "no row with $PRIMKEY $rowid"
	row=$(getconfig parm_value defaultrowid "${db}_${tb}_${pid}")
	erg=$(sql_execute "$db" "select exists(select 1 from $tb where $PRIMKEY = $row) limit 1")
	if [ "$erg" -lt 1 ];then $FUNCNAME "clear" ${@:2};return  ;fi
	filetbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "$PRIMKEY" "$db" ".txt") 				
	echo $(getconfig parm_value defaultrowid "${db}_${tb}_${pid}") > "$file"
}
function uid_sql_execute () {
	log  debug $FUNCNAME $@
	local db="$1" tb="$2" mode="$3" PRIMKEY="$4" row="$5" pid="$6" parm=${@:7}
	if [ "$row" = "" ];then row=$(getconfig parm_value defaultrowid "${db}_${tb}_${pid}");fi
	tb_meta_info $db $tb $row $(rules_receive_parm "$db" "$tb" "$parm")
	case "$mode" in
		 "delete"|"update"|"insert" )
			(echo $tb
			 sql_execute "$db" "pragma foreign_key_list($tb)" | grep -i "restrict\|update" | cut -d ',' -f3) | 
			 sort -u |
			 while read -r table;do
			    is_table "$db" "$tb";if [ "$?" -gt 0 ]; then continue;fi
				local file=$(getfilename "${tpath}/dump" "$table" "$db" ".sql") 
				if [ ! -f "$file" ];then utils_ctrl "$db" "$tb" "dump" "$file" ;fi
			 done
			 ;;
		*) nop
	esac
	local nkey="" 
	case "$mode" in
		 "eq")		uid_read_tb "read" "$db" "$tb" "$pid" "$PRIMKEY" "$row" ;;
		 "lt")		nkey=$(sql_execute "$db" ".header off\nselect $PRIMKEY from $tb where $PRIMKEY < $row order by $PRIMKEY desc limit 1");;
		 "gt")		nkey=$(sql_execute "$db" ".header off\nselect $PRIMKEY from $tb where $PRIMKEY > $row order by $PRIMKEY      limit 1");;
		 "delete")	sql_execute "$db" "delete from $tb where $PRIMKEY = $row " ;;
		 "update")	nkey=$row;sql_execute "$db" "$GTBUPDATE" ;;
#		 "insert")	nkey=$(sql_execute "$db" "${GTBINSERT};select last_insert_rowid()")
 		 "insert")	sql_execute "$db" "${GTBINSERT}";;
		  *)  		nop
	esac
	if [ "$?" -gt "0" ]  ;then msg="error $mode $PRIMKEY = $row";return 1;fi
	case $mode in
		"update"|"delete"|"insert") uid_sql_execute_sync "$func" "$db" "$tb" "$PRIMKEY" "$key" "$pid";;
	esac
	if [ "$mode" = "insert" ]  ;then 
		nkey=$(sql_execute "$db" "select max($PRIMKEY) from $tb")
	fi
	if [ "$nkey" != "" ] ;then 
		setconfig "defaultrowid|${db}_${tb}_${pid}|$nkey"
		uid_read_tb "read" "$db" "$tb" "$pid" "$PRIMKEY" "$nkey"
	else
		if [ "$mode" = "lt" ] || [ "$mode" = "gt" ] ;then 
			msg="$msg\nno row $mode $row"
			return 0
		fi
	fi
	case "$mode" in "eq"|"lt"|"gt")	return;; esac
	msg="succes $mode $PRIMKEY = $row"
}
function uid_sql_execute_sync () {
	echo $(date "+%Y_%m_%d_%H_%M_%S_%N") > "$filesocket" 
}
function getfilename () {
	local del="" file=""
	while [ $# -gt 0 ];do
		if [ -f "$1" ]; then arg=$(echo "$1" | tr '/._' '_#_');else arg="$1";fi
		file="$file$del$arg";shift;del="_"
	done
	echo "${file//_\./\.}" | tr -s '_'
}
function getfileselect () { 
	local type="searchpath" field="$1" save="${@:2}" mydb="" db="" path=""
	if [ "$field" = "--save" ];then save=$field ;field=""  ;fi
	if [ -f  "$field" ]; then
		path=$field;field=""
	else
	    path=$(getconfig "parm_value" "$type" "$field")
	fi
	if [ "$path" = "" ];	then path=$HOME;fi
	db=$(zenity --file-selection $save --title "select $type" --filename=$path)
	if [ "$db" = "" ];	then echo "";return 1;fi
	if [ "$field" = "database" ]; then
		is_database $db
		if [ "$?" -gt 0 ];then 
			echo "";return 1
		else
			mydb=$(ls -l "$db");mydb=${mydb##* }
		fi
	else
		mydb=$db
	fi  
	setconfig "$type|$field|$db"
	echo $mydb 
}
function is_database () { file -b "$*" | grep -q -i "sqlite"; }
function is_table () {	
	if [ "$#" -lt "2" ];then return 1;fi 
	is_database "$1"; if [ "$?" -gt "0" ];then return 1;fi
	local tb=$(sql_execute "$1" ".table $2")
	if [ "$tb" = "" ];then return 1;else return 0;fi
}
function setconfig () {
    local parm=$* field="" arr="" value="" type="" id=""
    IFS="|";arr=($parm);type="${arr[0]}";field=$(echo "${arr[1]}" | tr ' ' '_');value=$(echo "${arr[2]}" | remove_quotes);unset IFS
	value=${value//\"/\"\"}
	if [ "$type" = "wherelist" ]; then
		id=$(sql_execute $dbparm ".header off\nselect parm_id from $tbparm where parm_field = \"$field\" and parm_value = \"$value\" and parm_type = \"$type\" limit 1")
		if [ "$id" = "" ];then 
			id=$(sql_execute $dbparm ".header off\nselect max(parm_id) +1 from $tbparm")
		fi 
		type="${type}_${id}"
	else
		id=$(sql_execute $dbparm ".header off\nselect parm_id from $tbparm where parm_field = \"$field\" and parm_type = \"$type\"")
	fi
	if [ "$id" = "" ]; then 
		sql_execute "$dbparm" "insert into $tbparm (parm_type,parm_field,parm_value) values (\"$type\",\"$field\",\"$value\")"
	else
		if [ "$type" != "wherelist" ]; then
			sql_execute "$dbparm" "update $tbparm set parm_value = \"$value\" where parm_id = \"$id\""
		fi
	fi
	if [ "$?" -gt "0" ];then return 1 ;else return 0 ;fi
}
function getconfig () {
	if [ "$1" = "stmt" ];then getstmt="$true";shift ;else getstmt="$false" ;fi
	local getfield="$1" type="$2" field=$(echo "$3" | tr ' ' '_') default="$4" where=${@:5}
	ix=$(pos '%' $field);if [ "$ix" -gt "-1" ];then eq1="like"  ;else eq1="=" ;fi
	ix=$(pos '%' $type); if [ "$ix" -gt "-1" ];then eq2="like"  ;else eq2="=" ;fi
	stmt=".header off\nselect $getfield from $tbparm where parm_field $eq1 \"$field\" and parm_type $eq2 \"$type\" $where" 
	if [ "$getstmt" = "$true" ];then echo "$stmt";return;fi
	value=$(sql_execute $dbparm "$stmt") 
	if [ "$?" -gt "0" ];then return 1 ;fi
	if [ "$value" = "" ] &&  [ "$default" != "" ];then value="$default";setconfig   "$type|$field|$value" ;fi
	echo -e "$value";return 0
}
function trim_value   () { echo $* ; }
function tb_get_tables () {
	if [ "$#" -eq 0 ]; then return 1;fi
	local db="$1"
 	if [ "$db" = "" ];then  return ;fi
	if [ -d "$db" ];then setmsg "$db is folder\nselect sqlite database" ;return ;fi
	if [ "$#" -eq 1 ]; then
		sql_execute "$1" '.tables' | fmt -w 1 | grep -v -e '^ '  
	else
		local tb="$2"
		if [ "$tb" = "" ] || [ "$tb" = "null" ];then tb=" ";fi;echo $tb  
		sql_execute "$1" '.tables' | fmt -w 1 | grep -v -e '^ ' | grep -vw "$tb" 
	fi
	if [ "$?" -gt "0" ];then return 1;fi
}
function terminal_cmd () {
	local termfile="$1"  db="$(getconfig parm_value defaultdatabase $2)" 
	echo ".exit 2> /dev/null" 	>  "$termfile" 
	echo "sqlite3 $db" 			>> "$termfile"  
}
function remove_quotes () { quote --remove $* | tr -s '"' ; }
function x_read_csv () {
	local file=$*;[ ! -f "$file" ] && setmsg -w --width=400 "kein file $file" && return
	sql_execute $dbparm "drop table if exists tmpcsv;"
	sql_execute $dbparm ".import $file tmpcsv"
	noselectDB="$true";tb_ctrl $dbparm tmpcsv 
	gtkdialog  -f "$dfile"
	setmsg -q "speichern ?"
	if [ "$?" -gt "0" ];then return;fi
	sql_execute $dbparm "select * from tmpcsv" > "$file"
}
function rules_command () {
	pparm=$*;IFS="|";parm=($pparm);unset IFS  
	local func=$(trim_value ${parm[0]})  mode=$(trim_value ${parm[1]})
	local db=$(trim_value ${parm[2]})    tb=$(trim_value ${parm[3]}) 
	local pid=$(trim_value ${parm[4]})   field=$(trim_value ${parm[5]}) 
	local value=$(trim_value ${parm[6]}) entrys=$(trim_value ${parm[7]})
	IFS="#";arr=($entrys);unset IFS
	if [ "$func" = "rules" ]; then
		case "$field" in
			"rules_db"|"rules_tb"|"rules_field")	dbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_db"      "$db" ".txt")
													tbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_tb"      "$db" ".txt")	
													fdfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_field"   "$db" ".txt");;
			"rules_db_ref"|"rules_tb_ref")			dbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_db_ref"  "$db" ".txt")	
													tbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_tb_ref"  "$db" ".txt");;
			"foreign_table"|"foreign_field")		fdfile=$(getfilename "${tpath}/input" "$pid" "$tb" "foreign_field" "$db" ".txt") 
													tbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "foreign_table" "$db" ".txt");;
			"-")									nop;;
			*) setmsg -i "$FUNCNAME\nno rule for field $field";return
		esac
		db=$(getconfig parm_value "system" "modify_db") 
		case "$mode"  in
			 "input") 
						case "$field" in
							"rules_field")			rules_command_list_fields "${arr[3]}" "${arr[4]}" "${arr[5]}";;
							"rules_tb")				tb_get_tables	  "${arr[3]}" "${arr[4]}";; 
							"rules_tb_ref")			tb_get_tables	  "${arr[6]}" "${arr[7]}";; 
							"foreign_table")	    tb_get_tables     "$db"       "${arr[9]}";; 
							"foreign_field")		tb=$(head -n 1 $tbfile) 
													rules_command_list_fields "${db}" "${tb}" "${arr[10]}";;
							*) nop
						esac;;
			 "action") 	case "$field" in
							 "rules_tb")			rules_command_list_fields "${arr[3]}" "${arr[4]}" "" 	 > "$fdfile";;
							 "foreign_table")		rules_command_list_fields "${db}"     "${value}"  "" 	 > "$fdfile";;
							 "rules_db_ref")		tb_get_tables     "$(head -n 1 $dbfile)" "" 			 > "$tbfile";;
							 "rules_db")			tb_get_tables     "$(head -n 1 $dbfile)" "" 			 > "$tbfile";; 
							 *) nop
						esac;;
			 *) nop
		esac
	fi
}
function rules_command_list_fields () {
	local db="$1" tb="$2" field="$3"
	if [ "$tb" = "" ];then echo "";return ;fi
	if [ "$tb" = "null" ];then echo "";return ;fi
	setmsg -i -d "$FUNCNAME\ndb $db\ntb $tb\nfield $field"
	if [ "$field" != "" ]; then echo "$field";else field=" ";fi
    sql_execute "$db" "pragma table_info($tb)"  | cut -d ',' -f2  | grep -v "$field" 
}
function zz () { return; } 
	ctrl $*
	exit
