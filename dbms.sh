#!/bin/bash
# author uwe suelzle
# created 2021-03-16
# version 0.9.8
# function: dbms for sqlite
# 
 trap _exit EXIT
 set -o noglob
function _exit() {
	if [ "$cmd" != "" ];then return  ;fi
	local ix=$(ps -ax | grep -v grep | grep "gtkdialog -f" | grep -c "$tpath")
  	[ $ix -gt 0 ] && return  	
  	log logoff
  	log_histfile 
}
function ftest () {
	echo arg $*
	[ "$*" = "" ] && return || arg=$*
	[ "${arg:0:1}" != "$_quote" ] && echo $arg | tr -s $_quote && return
	$FUNCNAME ${arg:1:${#arg}-2}
}
function ctrl () {	
	declare true=0 false=1 debug=1 trapoff=1 logenable=0 echoenable=1
	script=$(fullpath $0) 
	folder="$(basename $script)";path="$HOME/.${folder%%\.*}"
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
	pid=$$;_quote='"'
	tmpf="$tpath/tmpfile.txt"   
	tmpf2="$tpath/tmpfile2.txt"   
	pparms=$*
	gtkdialog -v | grep -iq "VTE" && [ $? -eq 0 ] && terminal=$true || terminal=$false
	selectDB=$true;rules=$true;header=$true;
	myparm="";X=400;Y=600
	dbparm="$path/sysmaster.sqlite" && tbparm="sysparms"	&& ctrl_systables "$dbparm"  "$tbparm"
	dbrules="$dbparm" 				&& tbrules="sysrules"	&& ctrl_systables "$dbrules" "$tbrules"
	dbhelp="$dbparm" 				&& tbhelp="syshelp"	    && ctrl_systables "$dbhelp"  "$tbhelp"
	dbcreate="$dbparm" 				&& tbcreate="syscreate"	
	limit=$(getconfig "parm_value" "config" "limit" 500)
	maxcols=$(getconfig "parm_value" "config" "maxcols" 30)
	term_heigth=$(getconfig "parm_value" "config" "term_heigth" 8)
	wtitle=$(getconfig "parm_value" "config" "wtitle" "dbms")
	export=$(getconfig "parm_value" "config" "export" "$false")
	separator=$(getconfig "parm_value" "config" "separator" "|" | tr -d '"')
	delimiter="|"
	x_configfile="$path/.configrc" 
	x_ctrl_check_files $x_configfile
	source $x_configfile
	if [ $# -eq 1 ] && [ -f "$@" ]; then
		is_database "$@"
		if [ $? -gt 0 ];then utils_ctrl "" "" "" "$@";exit ;fi
	fi
	declare -g	GTBNAME="" 	 GTBTYPE=""   GTBNOTN="" GTBDFLT="" GTBPKEY="" GTBMETA="" GTBSELECT="" GTBINSERT="" 
	declare -g  GTBUPDATE="" GTBUPSTMT="" GTBSORT="" GTBMAXCOLS=-1
	name="start"
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--tlog"|-t|" show log with tail")  		log tlog ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--version"|-v)  				            echo "version 0.9.8" ;;
	        "--func"|-f|" execute function")  			shift;cmd="nostop";log debug $pparms;$@;return ;;
	        "--noselectDB"|"no default tab")			selectDB=$false ;;
	        "--noheader"|"  no header for db-tab")		header=$false;;
	        "--norules"|"   for uid gui")				rules=$false;;
	        "--noterminal")								terminal=$false;;
	        "--window"|-w|"window title")			    shift;wtitle="$1" ;;
	        "--geometry_tb"|--gtb|"HEIGHTxWIDTH+X+Y")	shift;geometry_tb="$1" ;;
	        "--geometry_rc"|--grc|"HEIGHTxWIDTH+X+Y")	shift;geometry_rc="$1" ;;
	        "--help"|-h)								help $FUNCNAME;echo -e "\n     usage [ dbname [table ] --all  ]" ;return;;
	        "--all"|"       tab for each table of db")	myparm="$myparm $1";;
	        "--trap_at"|"   trap at line")				shift;trapfield="$1";             trap 'set +x;trap_at     $LINENO $trapfield           ;set -x' DEBUG;shift;;
	        "--trap_when"|"	   when field has value")   shift;trapfield="$1";trapval="$2";trap 'set +x;trap_when   $LINENO $trapfield $trapval  ;set -x' DEBUG;shift;shift;;
	        "--trap_change"|"    value changed")		shift;trapfield="$1";trapval="$2";trap 'set +x;trap_change $LINENO $trapfield ;set -x' DEBUG;shift;shift;;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										myparm="$myparm $1";;
	    esac
	    shift
	done
	local ix=$(ps -ax | grep -v grep | grep "gtkdialog -f" | grep -c "$tpath")
  	[ $ix -eq 0 ] && [ "$cmd" = "" ] && log logon
	tb_ctrl $myparm	
}
function ctrl_systables() {
	local db="$1" tb="$2"
	is_table "$db" "$tb";if [ $? -eq $true ];then return ;fi
	local file=$(getfilename "$sqlpath/create_systable" "$tb" $(echo "$db" | tr '/.' '-#') ".sql")
	sql_execute "$db" ".read" "$file"
}
function ctrl_rollback () {
	pid=$*
	if [ "$pid" != "" ]; then
		find $tpath -name "*$pid*" -delete
		sql_execute "$dbparm" "delete from $tbparm where parm_type = 'defaultrowid' and parm_field like '%$pid'"
	fi
	[ 0 -lt $(find /tmp/.dbms -name "*xx*" | wc -l) ] && return
	local found=$false
	find "${tpath}" -name "dump*" |
	while read -r file;do
		if [ "$found" = "$false" ]; then 	
			setmsg -q "commit all changes"
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
	dbliste=$(tb_get_labels $*)												# inquire databases/tables
	IFS="|";arr=($dbliste);unset IFS
	if [ "${#arr[@]}" -lt "1" ];then setmsg -i "no valid parameter";return 1 ;fi
	notebook="";for arg in ${arr[@]};do notebook="$notebook ${arg%%#*}";done 
    geometrylabel="geometry_$(echo $notebook | tr ' ' '_')"
    geometryfile=""
    xfile="xmltb_$(echo $notebook | tr ' ' '_').xml"
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
	  		y_get_xml_tb "$1" "$2" "$3" "$pid"  | grep -v '^exclude' | grep -v '^#' >> $xmlfile 
		done
		echo "</notebook></window>" >> $xmlfile
	fi
    if [ "$geometry_tb" = "" ];then geometry_tb=$(getconfig "parm_value" "geometry" "$geometrylabel" '800x800+100+100');fi
##
    log "run   main dialog $xmlfile $pid"
    gtkdialog -f "$xmlfile" --geometry="$geometry_tb" > $tmpf				 
    find $tpath -name "*$pid*" -delete
    log "end   main dialog $xmlfile $pid"
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
			setconfig   "defaulttable|${entrya[$ia]}|${cboxtba[$ia]}"  
		fi     
		if [ "${treea[$ia]}" != "" ];	then
			setconfig   "defaultrow|${labela[$ia]}_${entrya[$ia]} ${cboxtba[$ia]}|${treea[$ia]}" 
		fi   
	done
	ctrl_rollback 
}
function tb_ctrl_gui () {
#	log $*
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	local func=$(trim_value ${parm[0]}) pid=$(trim_value ${parm[1]}) label=$(trim_value ${parm[2]}) 
	local db=$(trim_value ${parm[3]})   tb=$(trim_value ${parm[4]})  value=$(trim_value ${parm[@]:5})
	dbfile="${tpath}/input_${pid}_${label}_db.txt"
	tbfile="${tpath}/input_${pid}_${label}_tb.txt"
	whfile="${tpath}/input_${pid}_${label}_wh.txt"
	xxfile="${tpath}/input_${pid}_${label}_xx.txt"
	terminalfile="${tpath}/input_${pid}_${label}_cmd.txt"
	is_database $db
	if [ $? -gt 0 ];then 
		db=$(getconfig parm_value defaultdatabase $label)
		is_database $db
		if [ $? -gt 0 ];then 
			db=$(getfileselect database)			
			if [ "$db" = "" ];then
				db=$dbhelp;tb=$tbhelp
			fi
		fi
	fi
	is_table "$db" $tb
	if [ $? -gt 0 ];then 
		tb=$(getconfig parm_value defaulttable $db)
		is_table "$db" $tb
		if [ $? -gt 0 ];then 
			tb_get_tables "$db" |
			while read -r tb;do 
				setconfig "defaulttable|$db|$tb"
				break
			done
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
		            tb_get_where "$db" "$tb" > "$whfile"
		            terminal_cmd "$terminalfile" "$label" "$db" 
		            if [ "$value" = "defaultwhere" ];then wh=$(remove_quotes $(getconfig parm_value defaultwhere "${db} ${tb}"))  ;fi
					tb_read_table "$pid" "$label" "$db" "$tb" "$wh";;
		"fselect") 	db=$(getfileselect database)
					is_database $db
					if [ "$?" -gt 0 ];then setmsg -i "$db\nno db";return;fi
					setconfig   "defaultdatabase|$label|$db"
					$FUNCNAME "input | $pid | $label | $db | | ";;
		"table") 	wh=$(remove_quotes $(getconfig parm_value defaultwhere "${db} ${tb}"))
					tb_get_where "$db" "$tb" "$wh" > "$whfile"
					tb_read_table "$pid" "$label" "$db" "$tb" "$wh"
					setconfig   "defaulttable|$db|$tb";;
	    "b_utiltb") utils_ctrl "$db" "$tb";;
		"b_utils")  if [ "$label" = "selectDB" ];then mydb="" ;else mydb="$db"  ;fi
					utils_ctrl "$mydb" "";;
		"where") 	tb_read_table "$pid" "$label" "$db" "$tb" "$value";;
		"b_wh_del")	nwhere=${value//\"/\"\"}
					stmt="delete from $tbparm where parm_field = '${db}_${tb}' and parm_value = \"$nwhere\""
					sql_execute "$dbparm" "$stmt"
		            tb_get_where "$db" "$tb" > "$whfile";;
		"b_wh_new") nwhere=$(zenity --width=600 --entry --entry-text="$value" --text="use double qoute if necessary")
					if [ "$nwhere" = "" ];then return;fi 
					sql_execute "$db" "explain select * from $tb $nwhere"
					if [ "$?" -gt "0" ];then return ;fi
					setconfig   "defaultwhere|$db $tb|$nwhere" 	
					setconfig   "wherelist|$db $tb|$nwhere"  
		            tb_get_where "$db" "$tb" "$nwhere" > "$whfile" 
					tb_read_table "$pid" "$label" "$db" "$tb" "$nwhere";;
		"b_delete") uid_ctrl_gui "button_delete | $db | $tb | unknown | $value ||||";;
		"b_update") uid_ctrl "$value" "$db" "$tb";;
		"b_config")	setconfig   "defaultwhere|$dbparm $tbparm|where parm_field like \"%${db}_${tb}\" or parm_type = \"config\"" 
					ctrl_start_new_instance "rx_settings" "$dbparm $tbparm --noselectDB";;
		"b_clone")	ctrl_start_new_instance "rx_clone_$tb" "$db $tb --noselectDB";;
		"b_help")	ctrl_start_new_instance "rx_help_$tb" "$dbhelp $tbhelp --noselectDB";;
		"b_insert")	uid_ctrl "insert" "$db" "$tb" ;;
		"b_refresh") $FUNCNAME "input | $pid | $label | $db | $tb | defaultwhere" ;;
		"b_exit")	save_geometry "$value" ;;
		*) 			setmsg -w "$func nicht bekannt"
	esac
}
function ctrl_start_new_instance () {
#	rxvt="urxvt -depth 32 -bg [65]#000000 -geometry 40x20"
	rxvt="urxvt -bg [100]#FFFFDA -geometry 40x20"
	$rxvt -title "$1" -e $script ${@:2}
}
function tb_get_where () {
	local db="$1" tb="$2" wh="${@:3}"
	if [ "$wh" = "" ];then wh=$(remove_quotes $(getconfig parm_value defaultwhere "${db}_${tb}"));fi 
	if [ "$wh" = "" ];then wh=" ";else echo "$wh";fi
	echo "limit $limit" 
	getconfig parm_value "wherelist%" "${db}_${tb}" | while read line;do remove_quotes $line;done | grep -vw "$wh" | sort
}
function tb_get_labels() {
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
	if [ "$selectDB" = "$true" ];then arr="$arr${del}selectDB##";fi
	echo $arr
}
function tb_meta_info () {
	local db="$1" tb="$2" row="$3" parms=${@:4}
	is_table "$db" "$tb";if [ "$?" -gt 0 ];then return 1 ;fi
	if [ "${parms:${#parms}-1:1}" = "|" ];then parms="${parms}null"  ;fi  # last nullstring not count 
	local parmlist=$(quote -d "|" $parms)
	IFS="|";local parmarray=($parmlist);unset IFS 
	local del="" del2="" del3="" line="" nparmlist="" 
	GTBNAME="" ;GTBTYPE="" ;GTBNOTN="" ;GTBDFLT="" ;GTBPKEY="";GTBMETA="" 
	GTBSELECT="";GTBINSERT="";GTBUPDATE="";GTBUPSTMT="";GTBSORT="";GTBMAXCOLS=-1
	meta_info_file=$(getfilename "$tpath/meta_info" "${tb}" "${db}" ".txt")
	local ip=-1 ia=-1  
	sql_execute "$db" ".headers off\nPRAGMA table_info($tb)"   > "$meta_info_file"
	[ "$?" -gt "0" ] && log "error $?: $db" ".headers off\nPRAGMA table_info($tb)" && return 1
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
	strdb=$(echo $db | tr '/ ' '_');exportfile="$epath/export_${tb}_${strdb}.csv";exportfile="$epath/export_${pid}_${label}.csv"
	tb_meta_info "$db" $tb
	if [ "$?" -gt 0 ];then echo "" > "$exportfile"; setmsg -n "no table $tb in $db";return  ;fi 
#	if [ "$where" != "" ] || [ $(pos limit "where") -gt -1 ]; then
	if [ $(pos limit "$where") -gt -1 ]; then
		xlimit="" 
	else
		xlimit="limit $limit"
	fi
	if [ "$export"  = "$true" ];then 
		exportpath=$(getfilename "$epath/export" "$tb" $(date "+%Y%m%d%H%M") "$db" ".csv")
	else 
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
	setconfig   "defaultwhere|$db $tb|$where" 
}
function uid_ctrl () {
	log debug $*
	local row="$1" db="$2" tb="$3"
	tb_meta_info "$db" "$tb"
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME\nerror Meta-Info\n$db\n$tb";return ;fi
	geometrylabel="geometry_uid_$tb"
	geometryfile=""
	row_change_xml=$(getfilename "$tpath/xmluid" "${tb}" "${db}" ".xml")
    wtitle="dbms-rc-${tb}"
    if [ -f "${xpath}/change_row_${tb}.xml" ]; then
		row_change_xml="${xpath}/change_row_${tb}.xml"
	else
		echo "<window title=\"$wtitle\" allow-shrink=\"true\">" > "$row_change_xml"
		y_get_xml_uid $db $tb $row | grep -v -e '^$ ' | grep -v  -e '^#'  >> "$row_change_xml"
		echo "</window>" >> "$row_change_xml"
	fi	
    if [ "$geometry_rc" = "" ];then geometry_rc=$(getconfig "parm_value" "geometry" "$geometrylabel" '800x500+100+200');fi
 	log "run  uid dialog $row_change_xml $pid"
 	(erg=$(gtkdialog -f "$row_change_xml" --geometry=$geometry_rc );ctrl_rollback $pid;log "end  uid dialog $row_change_xml $pid") & 
}
function uid_ctrl_gui () {
	log debug $@
	local parms=$*;IFS="|";parm=($parms);unset IFS 
	local func=$(trim_value ${parm[0]})  	db=$(trim_value ${parm[1]})     tb=$(trim_value ${parm[2]}) 
	local field=$(trim_value ${parm[3]}) 	key=$(trim_value ${parm[4]})  	pid=$(trim_value ${parm[5]}) 
	local xlabel=$(trim_value ${parm[6]}) 	entrys="" del=""
	for ((ia=7;ia<${#parm[@]};ia++)) ;do
		entrys="$entrys$del$(trim_value ${parm[$ia]})";del='|'
	done
	local msg="" mode="normal" geometry=$xlabel
	tb_meta_info $db $tb "$entrys"
	if [ "$?" -gt 0 ];then func="button_clear"; setmsg -n "no table $tb in $db";fi 
	if [ "$field" = "unknown" ];then field="$PRIMKEY";fi
	file=$(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt")
	rulesfile=$(getfilename "$tpath/rules" "$db" "$tb" ".txt")
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
		 "button_insert")   uid_sql_execute "$db" "$tb" "insert" "$field" "$key" "$pid" "$entrys"
							if [ $? -gt 0 ];then return;fi 
							;;
		 "button_update")   uid_sql_execute "$db" "$tb" "update" "$field" "$key" "$pid" "$entrys" ;;
		 "button_delete")   setmsg -q "$field=$key delete ?"
							if [ $? -gt 0 ];then return  ;fi
							uid_sql_execute "$db" "$tb" "delete" "$field" "$key" "$pid" 
							if [ $? -gt 0 ];then return  ;fi
							if [ "$pid" != " " ];then
								uid_sql_execute "$db" "$tb" "gt" "$field" "$key" "$pid"
								if [ $? -gt 0 ];then uid_sql_execute "$db" "$tb" "lt" "$field" "$key" "$pid";fi
							fi
							;;
		 "button_clear")   	uid_read_tb "clear" "$db" "$tb" "$pid" "$PRIMKEY" "$key" ;;
		 "button_refresh")  uid_read_tb "read"  "$db" "$tb" "$pid" "$PRIMKEY" "$key" ;;
		 "button_exit")   	save_geometry "$geometry" ;;
		 "fileselect") 	    sfile=$(getfileselect "$key")
							if [ "$?" -gt "0" ];then log "Suche abgebrochen";return  ;fi
							echo "$sfile" > $(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt")
							;;		
		 "command") 		uid_gui_get_rule "$db" "$tb" "$field"
							if [ "$?" = "$false" ];then return  ;fi
							if [ "$RULES_ACTION" = "" ];then return  ;fi
							uid_gui_rules "exe" "action" "$db" "$tb" "$field" "$key" "$entrys" "$pid" "$xlabel" "$RULES_ACTION";;
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
	local mode="$1" tag="$2" db="$3" tb="$4" field="$5" entry="$6" entrys="$7" pid="$8" xlabel="$9" RULES_ACTION=${@:10} 
	xparm="$script --func uid_ctrl_gui \"command | $db | $tb | $field | $entry | $entrys | $pid\""
	local ftag="" label="" icon="" func="" action="" cmd="" arg=""
	if [ "$RULES_ACTION" = "" ];then RULES_ACTION=$xlabel ;fi
	IFS=";";action=($RULES_ACTION);unset IFS
	if [ "$tag" = "input" ];then echo "$entry" > $(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt");fi
	for arg in "${action[@]}" ;do
		func="${arg%\@*}"
		cmd="${arg##*\@}"
		for ftag in ${func//@/ };do 
		    set -- ${ftag//&/ }
		    ftag="$1";label="$2";icon="$3"
		    if [ "$mode" != "xml" ]   && [ "$ftag" = "button" ]; then ftag="action";fi  # button has only action method
			if [ "$ftag" != "$tag" ]; then continue    ;fi
			if [ "$mode"  = "xml" ];  then 
				case "$tag" in
					"button") 	echo							'				<button>'
								if [ "$label" != "" ];then echo	'					<label>'$label'</label>'  ;fi
								if [ "$icon"  != "" ];then echo	'					<input file stock="'$icon'"></input>'  ;fi
								xparm="$script --func uid_ctrl_gui \"command | $db | $tb | $field | $entry | $pid | $label | $entrys\""
								echo							'					<action>'$xparm'</action>'  
								echo							'				</button>'  
							;;
					*)  		echo							'				<$tag>'$xparm'</$tag>'  
				esac
			else
				$cmd "| $ftag | $db | $tb | $pid | $xlabel | $field | $entry | $entrys"
				break  
			fi
		done
	done
}
function uid_gui_get_rule() {
	if [ "$rules" = "$false" ];then return 1;fi
	local db="$1" tb="$2" field="$3" value="" found=$false 
	while read -r line;do
		set -- $line;var=$1;shift;shift;value=$*
		if [ "$value"   =  "$field"  ];then found=$true;fi	
		if [ "$value"   = "'$field'" ];then found=$true;fi	
		case $var in
			rules_type)     RULES_TYPE=$value	;;
			rules_db_ref) 	RULES_DB_REF=$value	;;
		esac
		if [ "$found" = "$false" ];then continue  ;fi		
		case $var in
			rules_tb_ref) 	RULES_TB_REF=$value	;;
			rules_action) 	RULES_ACTION=$(echo $value | tr '@' '@');;
			rules_col_list) RULES_COL_LIST=$value	;;
			rules_info)     break	;;
		esac
	done < "$rulesfile"
	if [ "$RULES_TYPE" = "blob" ]; then
		RULES_ACTION="button&show@/home/uwe/my_scripts/dbms.sh --func rules_command blobshow;button&store@/home/uwe/my_scripts/dbms.sh --func rules_command blobstore;"
		RULES_TYPE="command"
		RULES_TYPE_O="blob"
	fi
	return $found
}
function utils_ctrl () {
	local db="$1" tb="$2" func="$3" ifile="$4" drop_list="" height="280"
	local drop=$false create=$false edit=$false read=$false import=$false check_inuse=$false editor=$true
	local dump=$false restore=$false commit=$false rollback=$false reload=$false errmsg="" 
	list='import reload dump restore commit rollback rules'
	if [ "$tb" = "" ]; then
		list=$list' drop create(editor) create(gui) modify(editor) modify(gui) read';height="390"		
	fi
	[ "$ifile" != "" ] && [ -f "$ifile" ] && list="import read reload" && height="200"
	if [ "$func" = "" ];then 
		func=$(zenity --list --height=$height --column action $list)
	fi
	if [ "$func" = "" ];then return ;fi
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
	elif [ "$(echo $func | grep 'reload')" 	!= "" ]; 	then reload=$true 
	elif [ "$(echo $func | grep 'dump')" 	!= "" ]; 	then dump=$true
	elif [ "$(echo $func | grep 'restore')" != "" ]; 	then restore=$true
	else	setmsg -i "abort...func not known $func";return
	fi
	if [ $read = $true ] || [ $import = $true ] || [ $reload = $true ]; then
		if [ ! -f "$ifile" ]; then
			ifile=$(getfileselect file_read)
		fi
		if [ !  -f "$ifile" ]; then setmsg -n "abort! no file selected\n$db";return;fi
	fi
	if [ "$tb" = "" ] &&  [ "$restore" = "$false" ] &&  [ "$read" = "$false" ]; then
		is_database "$db";if [ "$?" -gt "0" ];then setmsg -n "abort! no database\n$db";return;fi
		if [ "$import" = "$true" ]; then 
			tb=$(zenity --list --height=400 --column table 'tmp_import' 'other' $($script --func tb_get_tables $db))
			if [ "$tb" = "other" ];then tb=$(zenity --entry --text="new table name")  ;fi
		else
			tb=$(zenity --list --height=400 --column table $($script --func tb_get_tables $db))
		fi 
		if [ "$tb" = "" ]; then setmsg -n "abort! no table selected";return;fi
		if [ $reload = $true ];then import=$true  ;fi
	fi 
	if [ "$check_inuse" = "$true" ];then 
		find "$tpath" -name "*xx*" -exec  grep "$db" {} \; | grep "$tb" > "$tmpf"
		while read -r line;do
			setmsg -i --width=300 "abort! in use\ntb:$tb\ndb: $db";return
		done < "$tmpf"
	fi
	if [ "$check_inuse" = "$true" ] || [ "$import" = "$true" ]; then
		local dumpfile=$(getfilename "${tpath}/dump" "$tb" "$db" ".sql") 
		if [ ! -f "$dumpfile" ];then utils_ctrl "$db" "$tb" "dump" "$dumpfile" ;fi
	fi 
	readfile=$(getfilename "$sqlpath/read" "${tb}" "${db}" ".sql")
	readcrtb=$(getfilename "$sqlpath/read" "${tbcreate}" "${dbcreate}" ".sql")
###	
	if 	 [ "$drop" = "$true" ]; then
		msg="delete $tb from $db";editor=$false
		echo "	drop table if exists $tb;" > $readfile
	elif [ "$create" = "$true" ]; then
		msg="create/modify $tb"
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
 		echo "-- ,foreign key(field[,field]) on tbname(field[,field]);" 		 			>> $readfile
 		echo "--  create [unique] index indexname on tb(field[,field]);" 	 				>> $readfile
 		echo "--  create trigger triggername [after | before] [insert | update] on trtb" 	>> $readfile 
 		echo "--  begin" 											 						>> $readfile 
 		echo "--  	insert into othertb (othertb.field) value (new.trtbfield"; 				>> $readfile 
 		echo "--  end;"												 						>> $readfile 
		drop_list="$drop_list ${tb}_copy"
	elif [ "$read" = "$true" ]; then
		msg="execute $ifile";readfile=$ifile
	elif [ "$import" = "$true" ]; then
	    msg="insert/reload into $tb"
		utils_import "$db" "$tb" "$ifile" "$separator"  > $readfile
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
	    if [ "$?" -gt 0 ];then 
			msg="create $tb in $db" 
			readfile="$ifile"
		else 
			msg="restore $tb in $db"
 			echo "drop table if exists ${tb}_dump;" 				> 	"$readfile" 
			echo "create table ${tb}_dump as select * from $tb;" 	>> 	"$readfile"
			cat "$ifile" 											>> 	"$readfile"
			drop_list="$drop_list ${tb}_dump"
		fi	
	elif [ "$commit" 	= "$true" ]; then
		rm "${tpath}/dump*";return
	elif [ "$rollback" 	= "$true" ]; then
		ctrl_rollback;return
	fi	
	if [ "$errmsg" != "" ];then setmsg -i "$errmsg";return  ;fi
	if [ $editor -eq $true ];then trash=$(xdg-open $readfile);fi
	setmsg -q --width=300 "$msg\nrun $readfile" 
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
	ctrl_uid_sync
}
function utils_import () {
	local db="$1" tb="$2" file="$3" delim="$4" func="" nheader="" l1 l2
	hl=$(head $file -n 1 | tr [:upper:] [:lower:]) 	
	if [ "${#delim}" -eq 1 ];then
		l1=${#hl}
		l2=$(echo $hl | tr -d "$delim" | wc -m)
		l2=$(($l2-1))
		if [ $l1 -le $l2 ];then delim=""  ;fi
	fi
	if [ "$delim" = "" ];then  
		delim=$(zenity --entry --text="enter column-separator " --entry-text="$separator")
	fi
	if [ ${#delim} -ne 1 ];then errmsg="no separator: $delim";return 1;fi
	stmt="update $tbparm set parm_value = \"$delim\" where parm_type = 'config' and parm_field = 'separator'"
	sql_execute "$dbparm" "$stmt" # delim '|' normaliy reserved
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
	local tbcopy="${tb}_tmp" 
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
	if  [ "$func"   = "insert" ]; 	then
		msg="insert to $tb $file "
		echo "	insert into $tb ($GTBSELECT)"	 
		echo "	select $GTBSELECT from $tbcopy;"			 
	else
	    echo "pragma foreign_keys=OFF;"
		line="";del=""
		for ((ia=0;ia<${#arl[@]};ia++)) ;do
			line="${line}${del}b.${arl[$ia]}";del=","
		done
		msg="insert/update to $tb $file "	 
		echo "--  update"
		echo "	insert or replace into $tb"		 
		echo "	select $line"					 
		echo "	from $tbcopy as b join $tb as a on b.$PRIMKEY = a.$PRIMKEY;"	 
		echo "--  insert primary key with value"
		echo "	insert into $tb as a  " 		 
		echo "	select $line" 					 
		echo "	from $tbcopy as b"				 
		echo "	where  b.${PRIMKEY} is not null"		 
		echo "	and    b.${PRIMKEY} not in ('null','')"		 
		echo "	and    b.${PRIMKEY} in ("		 
		echo "	select a.${PRIMKEY} from $tbcopy as a "	 
		echo "	left join $tb as b  "			 
		echo "	on a.${PRIMKEY} = b.${PRIMKEY}"	 
		echo "	where b.${PRIMKEY} is null);"	 	 
		echo "--  insert primary key has no value"
		line="";del=""
		for ((ia=0;ia<${#ail[@]};ia++)) ;do
			line="${line}${del}b.${ail[$ia]}";del=","
		done								 
		echo "	insert into $tb as a ($GTBSELECT) " 		 
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
	cat  $(getfilename "$sqlpath/create_systable" "$tbcreate" $(echo "$dbcreate" | tr '/.' '-#') ".sql")
	echo "insert into $tbcreate (pos,field,type,nullable,default_value,primary_key) values"  
	tb_meta_info "$db" "$tb"  
	while read -r line;do
	    IFS=",";fields=( $line );unset IFS;nline="";del=""
	    for ((ia=0;ia<${#fields[@]};ia++)) ;do
			arr=${fields[$ia]}
			case "$ia" in
				0)		arr="${arr}0";maxpos=$arr  ;;
				3)		if [ "$arr"  = "1" ];then  arr="false" ;else  arr="true" ;fi;;
				5)		if [ "$arr"  = "1" ];then  arr="true"  ;else  arr="false" ;fi;;
				*)  	:
			esac
			arr=$(echo $arr | tr -d '"' )
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
	local db="$1" tb="$2" parm=${@:3} nparm="" vparm="" del="" del2="" value="" avlue="" iv=-1
	IFS=",";name=($GTBNAME);unset IFS
	IFS="|";value=($parm);unset IFS
  	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}"  = "$PRIMKEY" ];	then continue ;fi
		iv=$((iv+1))
		arg=$(echo "${value[$iv]}" | tr  ',' ',' | tr -d '"')
		uid_gui_get_rule "$db" "$tb" "${name[$ia]}"
		if [ "$?" = "$false" ];					then nparm=$nparm$del$arg;del="|";continue;fi
		if [ "$RULES_TYPE_O" = "blob" ];		then nparm=$nparm$del$(echo ${name[$ia]} | tr -d '"');del="|";continue;fi
		if [ "$arg" = "" ];    					then nparm=$nparm$del$arg;del="|";continue;fi
		if [ "$arg" = "null" ];					then nparm=$nparm$del$arg;del="|";continue;fi
		if [ "$RULES_COL_LIST" 	= "all" ];		then nparm=$nparm$del$arg;del="|";continue;fi
		if [ "$RULES_COL_LIST" 	= "" ]; 		then RULES_COL_LIST=0;fi
		IFS=",";range=($RULES_COL_LIST);unset IFS
		IFS=", ";avalue=($arg);unset IFS
		vparm="";del2=""
		for arg in ${range[@]}; do vparm=$vparm$del2${avalue[$arg]};del2=" ";done
		nparm=$nparm$del$vparm;del="|"
	done
	echo $nparm
}
function uid_read_tb () {
	local func="$1" db="$2" tb="$3" pid="$4" PRIMKEY="$5" rowid="$6" file="" sel=""
	log debug "$db $tb $pid $PRIMKEY $rowid "
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
		if [ "$field" = "$PRIMKEY" ];then setconfig "defaultrowid|$db $tb $pid|$rowid";else entrys="$entrys$del$value";del='|'  ;fi
		file=$(getfilename "${tpath}/input" "$pid" "$tb" "$field" "$db" ".txt")
		echo "$value" > "$file"
		uid_gui_get_rule "$db" "$tb" "$field";	
		if 	 [ "$?" = "$false" ] ;then  continue ;fi
		if 	 [ "$RULES_TYPE" = "reference" ]; then
			RULES_ACTION=$(echo "$RULES_ACTION" | tr ';' ' ')
			sql_execute "$RULES_DB_REF" "$RULES_ACTION  = \"$value\"" 	>  "$file"		# show value fom db first
			sql_execute "$RULES_DB_REF" "$RULES_ACTION != \"$value\"" 	>> "$file"		# than others
		elif [ "$RULES_TYPE" = "fileselect" ]; then
			continue
		elif [ "$RULES_TYPE" = "table" ]; then
			sql_execute "$RULES_DB_REF" "$RULES_ACTION  = \"$value\"" 	> "$file"		# show value fom db first
		elif [ "$RULES_TYPE" = "liste" ]; then
			if [ -f "$RULES_ACTION" ]; then
				readarray  aliste < "$RULES_ACTION"
			else								
				IFS='#,@,|'; aliste=($RULES_ACTION);unset IFS
			fi
			lng=${#field}
			for arg in "${aliste[@]}" ;do if [ "$value"  = "${arg:0:$lng}" ];then echo $arg;break ;fi;done > "$file"
			for arg in "${aliste[@]}" ;do if [ "$value" != "${arg:0:$lng}" ];then echo $arg		  ;fi;done >>  "$file"
		elif [ "$RULES_TYPE" = "command" ]; then 
			uid_gui_rules "exe" "input" "$db" "$tb" "$field" "$value" "$entrys" "$pid" "none" "$RULES_ACTION" > "$file"
		else setmsg -i "$FUNCNAME type not known $RULES_TYPE"
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
		*) :
	esac
	local nkey="" 
	case "$mode" in
		 "eq")		uid_read_tb "read" "$db" "$tb" "$pid" "$PRIMKEY" "$row" ;;
		 "lt")		nkey=$(sql_execute "$db" ".header off\nselect $PRIMKEY from $tb where $PRIMKEY < $row order by $PRIMKEY desc limit 1");;
		 "gt")		nkey=$(sql_execute "$db" ".header off\nselect $PRIMKEY from $tb where $PRIMKEY > $row order by $PRIMKEY      limit 1");;
		 "delete")	sql_execute "$db" "delete from $tb where $PRIMKEY = $row " ;;
		 "update")	nkey=$row;sql_execute "$db" "$GTBUPDATE" ;;
 		 "insert")	sql_execute "$db" "${GTBINSERT}";;
		  *)  		:
	esac
	if [ "$?" -gt "0" ]  ;then msg="error $mode $PRIMKEY = $row";return 1;fi
	case $mode in
		"update"|"delete"|"insert") ctrl_uid_sync "$func" "$db" "$tb" "$PRIMKEY" "$key" "$pid";;
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
function ctrl_uid_sync () {
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
		path="$field";field=""
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
    IFS="|";arr=($parm);type="${arr[0]}";field=$(echo "${arr[1]}" | tr ' ' '_');value=$(remove_quotes ${arr[2]});unset IFS
	value=${value//\"/\"\"}
	if [ "$type" = "wherelist" ]; then
		id=$(sql_execute $dbparm ".header off\nselect parm_id from $tbparm where parm_type like \"wherelist%\" and parm_field = \"$field\" and parm_value = \"$value\"  limit 1")
		if [ "$id" = "" ];then 
			id=$(sql_execute $dbparm ".header off\nselect max(parm_id) +1 from $tbparm")
			type="${type}_${id}"
			sql_execute "$dbparm" "insert into $tbparm (parm_type,parm_field,parm_value) values (\"$type\",\"$field\",\"$value\")"
		fi 
		return $?
	else
		id=$(sql_execute $dbparm ".header off\nselect parm_id from $tbparm where parm_field = \"$field\" and parm_type = \"$type\"")
	fi
	if [ "$id" = "" ]; then 
		sql_execute "$dbparm" "insert into $tbparm (parm_type,parm_field,parm_value) values (\"$type\",\"$field\",\"$value\")"
	else
		sql_execute "$dbparm" "update $tbparm set parm_value = \"$value\" where parm_id = \"$id\""
	fi
    return $?
}
function setconfig_alt () {
    local parm=$* field="" arr="" value="" type="" id=""
    IFS="|";arr=($parm);type="${arr[0]}";field=$(echo "${arr[1]}" | tr ' ' '_');value=$(remove_quotes ${arr[2]});unset IFS
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
		sql_execute "$1" '.tables' | fmt -w 1 | grep -v -e '^ ' | grep -vw "$tb" | sort
	fi
	if [ "$?" -gt "0" ];then return 1;fi
}
function terminal_cmd () {
	local termfile="$1"  db="$(getconfig parm_value defaultdatabase $2)" 
	echo ".exit 2> /dev/null" 	>  "$termfile" 
	echo "sqlite3 $db" 			>> "$termfile"  
}
function rules_command () {
	pparm=$*;IFS="|";parm=($pparm);unset IFS  
	local func=$(trim_value ${parm[0]})  mode=$(trim_value ${parm[1]})
	local db=$(trim_value ${parm[2]})    tb=$(trim_value ${parm[3]}) 
	local pid=$(trim_value ${parm[4]})   xlabel=$(trim_value ${parm[5]}) field=$(trim_value ${parm[6]}) 
	local value=$(trim_value ${parm[7]}) entrys=$(trim_value ${parm[8]})
	IFS="|";arr=($entrys);unset IFS
	case "$func" in
	rules)
		case "$field" in
			"rules_db"|"rules_tb"|"rules_field")	dbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_db"      "$db" ".txt")
													tbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_tb"      "$db" ".txt")	
													fdfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_field"   "$db" ".txt");;
			"rules_db_ref"|"rules_tb_ref")			dbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_db_ref"  "$db" ".txt")	
													tbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "rules_tb_ref"  "$db" ".txt");;
			"foreign_table"|"foreign_field")		fdfile=$(getfilename "${tpath}/input" "$pid" "$tb" "foreign_field" "$db" ".txt") 
													tbfile=$(getfilename "${tpath}/input" "$pid" "$tb" "foreign_table" "$db" ".txt");;
			"-")									:;;
			*) setmsg -i "$FUNCNAME\nno rule for field $field";return
		esac
		db=$(getconfig parm_value "system" "modify_db") 
		case "$mode"  in
			 "input") 
						case "$field" in
							 "rules_field")			rules_command_list_fields 	"${arr[3]}" "${arr[4]}" "${arr[6]}";;
							 "rules_tb")			tb_get_tables	 			"${arr[3]}" "${arr[4]}";; 
							 "rules_tb_ref")		tb_get_tables	  			"${arr[7]}" "${arr[8]}";; 
							 "foreign_table")	    tb_get_tables     			"$db"       "${arr[10]}";; 
							 "foreign_field")		tb=$(head -n 1 $tbfile) 
													rules_command_list_fields 	"${db}" "${tb}" "${arr[11]}";;
							*) :
						esac;;
			 "action") 	case "$field" in
							 "rules_tb")			rules_command_list_fields "${arr[3]}" "${arr[4]}" "" 	 > "$fdfile";;
							 "foreign_table")		rules_command_list_fields "${db}"     "${value}"  "" 	 > "$fdfile";;
							 "rules_db_ref")		tb_get_tables     "$(head -n 1 $dbfile)" "" 			 > "$tbfile";;
							 "rules_db")			tb_get_tables     "$(head -n 1 $dbfile)" "" 			 > "$tbfile";; 
							 *) :
						esac;;
			 *) :
		esac
		;;
	play)
		[ ! -f "$value" ] && return
		[ -d "$value" ] && xine "$value" && return
		type=${value##*\.}
		case "$type" in
			mp3|ogg) xine "$value";;
			*) xdg-open "$value"
		esac
		;;
	blob*)
		tb_meta_info "$db" $tb
		key=$(head -n 1 $(getfilename "${tpath}/input" "$pid" "$tb" "$PRIMKEY" "$db" ".txt"))
		if [ "$func" = "blobshow" ] && [ "$xlabel" = "show" ];then 
			file=$(getfilename "${tpath}/blob" "$pid" "$tb" "rules_db" "$db")
			sql_execute "$db" "select writefile('$file',$field) from $tb where $PRIMKEY = $key"
			[ $? -gt 0 ] && return 
			$FUNCNAME  "play | $mode | $db | $tb | $pid | none | $field |$file" &
		fi
		if [ "$func" = "blobstore" ] && [ "$xlabel" = "store" ];then 
			file=$(getfileselect "searchblobfile")
			[ $? -gt 0 ] && return
			sql_execute "$db" "update $tb set $field = readfile('$file') where $PRIMKEY = $key"
			[ $? -eq 0 ] && setmsg -n "success update blob $file" && ctrl_uid_sync
		fi
		;;
	*)	setmsg -w "$FUNCNAME\nfunction not known\n$func"
	esac
}
function rules_command_list_fields () {
	local db="$1" tb="$2" field="$3"
	if [ "$tb" = "" ];then echo "";return ;fi
	if [ "$tb" = "null" ];then echo "";return ;fi
	if [ "$field" != "" ]; then echo "$field";else field=" ";fi
    sql_execute "$db" "pragma table_info($tb)"  | cut -d ',' -f2  | grep -v "$field" 
}
function sql_execute () {
	set -o noglob 
	if [ "$sqlerror" = "" ];then sqlerror="/tmp/sqlerror.txt";touch $sqlerror;fi
	local db="$1";shift;stmt="$@"
	echo -e "$stmt" | sqlite3 "$db"  2> "$sqlerror"  | tr -d '\r'   
	error=$(<"$sqlerror")
	if [ "$error"  = "" ];then return 0;fi
	log "$FUNCNAME sql_error: $stmt"
	setmsg -e --width=400 "sql_execute\n$error\ndb $db\nstmt $stmt" 
	return 1
}
function pos () {
	local str pos x
	if [ "${#1}" -gt "${#2}" ] ; then
	   str="$1";pos="$2"
	else  
	   str="$2";pos="$1"
	fi 
    x="${str%%$pos*}"
    [[ "$x" = "$str" ]] && echo -1 || echo "${#x}"
}
function setmsg () {
	oldstate="$(set +o | grep xtrace)";set +x
	local parm="--notification";local text=""
	log debug $*
	while [ "$#" -gt "0" ];do
		case "$1" in
		"--width"*)				parm="$parm $1"				;;
		"-t"|"--timeout"*)		parm="$parm --timeout $2";shift;;
		"-w"|"--warning") 		parm="--warning"			;;
		"-e"|"--error")   		parm="--error"				;;
		"-i"|"--info")    		parm="--info" 		 		;;
		"-n"|"--notification")  parm="--notification"		;;
		"-q"|"--question")	    parm="--question"			;;
		"-d"|"--debug")	        if [  $debug -eq $false ];then  return  ;fi		;;
		"-*" )	   				parm="$parm ""$1"			;;
		*)						text="$text ""$1"			;;
		esac
		shift
	done
	text=$(echo $text | tr '"<>' '_' | tr "'" '_')
	if [ "$text" != "" ];then text="--text='$text'" ;fi
	eval "$oldstate"
	eval 'zenity' $parm $text 
	return $?
}
function remove_quotes () {
	[ "$*" = "" ] && return || local arg=$*
	[ "${arg:0:1}" != "$_quote" ] && echo $arg | tr -s $_quote && return
	$FUNCNAME ${arg:1:${#arg}-2}
}
function quote () {
	local ldelim=$separator lquote=$_quote
	[ "$1" = "-d" ] && ldelim=$2 && shift && shift  
	[ "$1" = "-q" ] && lquote=$2 && shift && shift  
	arg=$*
	IFS=$ldelim;local arr=($arg);unset IFS
	local del="" line=""
	for ((ia=0;ia<${#arr[@]};ia++)) ;do
		line="$line$del$lquote$(remove_quotes ${arr[$ia]})$lquote"
		del=$ldelim
	done
	echo "$line"
}
function save_geometry (){
	str=$*;IFS='#';local arr=( $str );unset IFS; local window=${arr[0]} gfile=${arr[1]} glabel=${arr[2]}
	XWININFO=$(xwininfo -stats -name "$window")
	if [ "$?" -ne "0" ];then func_setmsg -i "error XWINFO";return  ;fi
	HEIGHT=$(echo "$XWININFO" | grep 'Height:' | awk '{print $2}')
	WIDTH=$(echo "$XWININFO" | grep 'Width:' | awk '{print $2}')
	X1=$(echo "$XWININFO" | grep 'Absolute upper-left X' | awk '{print $4}')
	Y1=$(echo "$XWININFO" | grep 'Absolute upper-left Y' | awk '{print $4}')
	X2=$(echo "$XWININFO" | grep 'Relative upper-left X' | awk '{print $4}')
	Y2=$(echo "$XWININFO" | grep 'Relative upper-left Y' | awk '{print $4}')
	X=$(($X1-$X2))
	Y=$(($Y1-$Y2))
	setconfig "geometry|$glabel|${WIDTH}x${HEIGHT}+${X}+${Y}"
}
function log () { 
	[  $# 	-eq 0  			]   &&	 return;	
	[ ""	= "$logfile"  	]   && 	 log_getfilename $script 	 
	[ "$1"  = "log_disable" ]   && 	 logenable=$false			  && log ${@:2} 	&& return
	[ "$1"  = "log_enable" ]    && 	 logenable=$true			  && log ${@:2} 	&& return
	[ "$1"  = "echo_disable" ]  && 	 echoenable=$false			  && log ${@:2} 	&& return
	[ "$1"  = "echo_enable" ]   && 	 echoenable=$true			  && log ${@:2} 	&& return
	[ "$1"  = "logon"  ]        && 	 set -- "start " $script	  && rm "$logfile"  		
	[ "$1" 	= "logoff" ]       	&& 	 set -- "stop  " $script "\n"	    				 
	[ "$1"  = "loglineno"  ]    && 	 lineno=$(printf "%03d\n" $2) && log ${@:3} 	&& return
	[ "$1" 	= "file" ]    	    && 	 logfile="$2" 				  && log ${@:3}		&& return
	[ "$1" 	= "tlog" ]    	    && 	 tlog 						  && log ${@:2}		&& return
	[ "$1" 	= "debug"  ]        && [ $debug -eq $false ]   	  	  && return
	[ "$1" 	= "debug_on" ] 	    &&   $debug=$true		 		  && log ${@:2}		&& return
	[ "$1" 	= "debug_off" ]     &&   $debug$false			 	  && log ${@:2}		&& return
	[ "$1" 	= "debug"  ] 	    && 	 shift;
	[  $logenable  -ne $false ] &&	 printf "%s %-20s %s" "$(date +"%y-%m-%d-%T:%N")" "${FUNCNAME[1]}" >> "$logfile";
	[  $logenable  -ne $false ] && 	 echo -e $lineno $* >> "$logfile"
	[  $echoenable -eq $true ]  && 	 echo -e $lineno $*  
}
function log_getfilename () {
	local file=${@:-$0}
	[ ! -d "$HOME/log" ] && mkdir [ -d "$HOME/log" ]
	file=${file##*/}
	export logfile="$HOME/log/"${file%.*}".log"	
}
function log_histfile () {
	histfile="${logfile%\.*}_hist.${logfile##*\.}" 
	if [ ! -f "$histfile" ];then 
		cp    "$logfile" "$histfile"
	else  
		cat   "$logfile" "$histfile"  > "$tmpf"
		cp -f "$tmpf"    "$histfile"
	fi
}
function tlog () {
	local file=$@; if [ "$file" = "" ];then file=$logfile ;fi
	if [ "$(ps -F -C tail | grep "$file")" != "" ];then  return;fi # laeuft schon
	urxvt --geometry 100X15 --background "#F4FAB4" --foreground black --title "tlog: $file"  -e tail -f -n+1  $file &
}
function trap_help () {
    echo "debug at     LINENO         : trap 'set +x;trap_at     $LINENO  174;         set +x' DEBUG"
    echo "debug when   field eq  value: trap 'set -x;trap_when   $LINENO $field value ;set +x' DEBUG"
    echo "debug change field new value: trap 'set +x;trap_change $LINENO $field;       set +x' DEBUG"
}
function trap_off()    { set +x;trapoff=$true; }
function trap_at() 	   { lineno=$1;trap_while "$1:at lineno >= $2"   "$true"  "lineno" "$2" ; }
function trap_when()   { 		   trap_while "$1:when $2 = $3"      "$true"  "$2"     "$3"; } 
function trap_change() {   		   trap_while "$1:change $2 $compare_value to $(eval 'echo $'$2)" "$false" "$2" "$compare_value"; } 
function trap_while()  {
    local msg="$1" eq="$2" field="$3" value=""
    eval 'value=$'$field 
	[ $eq -eq $true  ] && [ "$value" != "$compare_value" ] && return
	[ $eq -eq $false ] && [ "$value"  = "$compare_value" ] && return
	if [ $trapoff -eq  $true ]; then  return; fi  
	compare_value="$value"
	msg="$msg:${BASH_COMMAND} --> " 
	while true ; do
		[ $trapoff -eq  $true ] && break  
		read -u 4 -p "$msg " cmd
		[ "$cmd" = "" ] && break      
		case $cmd in
				vars ) ( set -o posix ; set );;
				ende ) ;;
				* ) eval $cmd;;
		esac
	done
}
function fullpath () {
	[ -d $* ] && echo  $(cd -- $* && pwd) && return 0
	[ -f $* ] && echo "$(cd -- "$(dirname $*)" && pwd)/$(basename $*)" && return 0
	return 1
}
function help () {
    [ $# -gt 1 ] && echo "         Wert unzulaessig: $2"
    echo "         $1 -- usage:"
    type -a "$1" | grep -e '\"\-\-' | tr '|")' " "
}
function y_get_xml_tb () {
	local label="$1" db="$2" tb="$3" pid="$4" header_visible="true" xterminal="exclude"
	if [ "$label" = "$tb" ]; then
		tb_meta_info "$db" "$tb"
		lb=$(echo $GTBNAME | tr '_,' '-|');sensitiveCBOX="false";sensitiveFSELECT="false";sortcol=$GTBSORT 
	else
		lb="c1";sortcol="1"
		for ((ia=2;ia<=$maxcols;ia++)) ;do
			lb=$lb"|c"$ia
			sortcol=$sortcol"|0"
		done
		sensitiveCBOX="true";ID=0;sensitiveFSELECT="true" 
	fi
    if [ "$label" = "selectDB" ];then 
		visibleFSELECT="true";utils="utils"
		if [ "$header" = "$false" ];then header_visible="false"  ;fi
	else 
		visibleFSELECT="false";utils="db_utils"
	fi
	if [ "$row" != "" ];   		 then row="$(sql_execute $cdb '.header off\nselect count(*) from '$ctb' where rowid < '$row)"  ;fi
	if [ "$row" != "" ];   		 then selected_row="selected-row=\"$row\"" ;else selected_row=""  ;fi
	terminalfile="${tpath}/input_${pid}_${label}_cmd.txt"
	exportfile="$epath/export_${pid}_${label}.csv"
	dbfile="${tpath}/input_${pid}_${label}_db.txt"
	tbfile="${tpath}/input_${pid}_${label}_tb.txt"
	whfile="${tpath}/input_${pid}_${label}_wh.txt"
	script="/home/uwe/my_scripts/dbms.sh"
	if [ $terminal -eq $true ];then xterminal="";fi
	cat <<EOF 
	<vbox>
		<entry visible="false">
            <variable>DUMMY$label</variable>
			<input>$script --func tb_ctrl_gui "input | $pid | $label | $db | $tb | defaultwhere"</input>
        </entry>
        <entry auto-refresh="true" visible="false">
            <variable>DUMMY2$label</variable>
			<input file>"$filesocket"</input> 
			<action type="refresh">DUMMY$label</action>
		</entry>
		<tree headers_visible="$header_visible" hover-selection="false" hover-expand="true" auto-refresh="true" 
		 exported_column="$ID" sort-column="$ID" column-sort-function="$sortcol" $selected_row>
			<label>"$lb"</label>
			<variable>TREE$label</variable>
			<input file>"$exportfile"</input>			
			<action>$script $nocmd --func uid_ctrl \$TREE$label \$ENTRY$label \$CBOXTB$label</action>				
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true" auto-refresh="true">  
				<variable>ENTRY$label</variable> 
				<sensitive>false</sensitive>  
				<input file>"$dbfile"</input>
			</entry> 
			<button space-fill="false" visible="$visibleFSELECT">
            	<variable>BUTTONFSELECT$label</variable>
            	<input file stock="gtk-open"></input>
				<action>$script --func tb_ctrl_gui "fselect | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
				<action type="refresh">TERMINAL$label</action>
            </button> 
		  </hbox>
			<comboboxtext space-expand="true" space-fill="true"  auto-refresh="true">
				<variable>CBOXTB$label</variable>
				<sensitive>$sensitiveCBOX</sensitive>
				<input file>"$tbfile"</input>			
				<action>$script --func tb_ctrl_gui "table    | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</comboboxtext>	
			<button>
				<label>tb_utils</label>
				<action>$script --func tb_ctrl_gui "b_utiltb | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
		</hbox>
		<hbox>
			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true">
				<variable>CBOXWH$label</variable>
				<input file>"$whfile"</input>
				<action>$script --func tb_ctrl_gui "where    | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>
			</comboboxtext>
			<button visible="true">
				<label>delete</label>
				<variable>BUTTONWHEREDELETE$label</variable>
				<action>$script --func tb_ctrl_gui "b_wh_del  | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>
			</button>
			<button visible="true">
				<label>edit</label>
				<variable>BUTTONWHEREEDIT$label</variable>
				<action>$script --func tb_ctrl_gui "b_wh_new  | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>
			</button>
			<button>
				<label>settings</label>
				<variable>BUTTONCONFIG$label</variable>
				<action>$script --func tb_ctrl_gui "b_config  | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>	
		</hbox>
		<hbox>
			<button>
				<label>help</label>
				<variable>BUTTONHELP$label</variable>
				<action>$script --func tb_ctrl_gui "b_help     | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
			<button>
				<label>workdir</label>
				<action>xdg-open $path &</action>
			</button>
			<button>
				<label>$utils</label>
				<action>$script --func tb_ctrl_gui "b_utils	   | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button> 
$xterminal			<button>
$xterminal				<label>show terminal</label>
$xterminal				<variable>BUTTONSHOW$label</variable>
$xterminal				<action type="show">TERMINAL$label</action>
$xterminal				<action type="show">BUTTONHIDE$label</action>
$xterminal				<action type="hide">BUTTONSHOW$label</action>
$xterminal			</button>
$xterminal			<button visible="false">
$xterminal				<label>hide terminal</label>
$xterminal				<variable>BUTTONHIDE$label</variable>
$xterminal				<action type="hide">TERMINAL$label</action>
$xterminal				<action type="show">BUTTONSHOW$label</action>
$xterminal				<action type="hide">BUTTONHIDE$label</action>
$xterminal			</button> 
			<button>
				<label>clone</label>
				<variable>BUTTONCLONE$label</variable>
				<action>$script --func tb_ctrl_gui "b_clone     | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT$label</variable>
				<action>$scrip --func tb_ctrl_gui "b_insert    | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
			<button>
				<label>update</label>
				<variable>BUTTONAENDERN$label</variable>
				<action>$script --func tb_ctrl_gui "b_update    | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$TREE$label"</action>
			</button>
			<button>
				<label>delete</label>
				<variable>BUTTONDELETE$label</variable>
				<action>$script --func tb_ctrl_gui "b_delete    | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$TREE$label"</action>			
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD$label</variable>
				<action>$script --func tb_ctrl_gui "b_refresh | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action> 			
$xterminal				<action type="clear">TERMINAL$label</action> 
$xterminal				<action type="refresh">TERMINAL$label</action> 
			</button>
			<button>
				<label>exit</label>
				<action>$script --func tb_ctrl_gui "b_exit 	| $pid| $label | \$ENTRY$label | \$CBOXTB$label | ${wtitle}#${geometryfile}#${geometrylabel}"</action>			
				<action type="exit">CLOSE</action>
			</button>
		</hbox> 
$xterminal		<terminal space-expand="false" space-fill="false" text-background-color="#F2F89B" text-foreground-color="#000000" 
$xterminal			autorefresh="true" argv0="/bin/bash" visible="false">
$xterminal			<variable>TERMINAL$label</variable>
$xterminal			<height>$term_heigth</height>
$xterminal			<input file>"$terminalfile"</input>
$xterminal		</terminal> 
	</vbox> 
EOF
}  
function y_get_xml_uid () {
	local db="$1" tb="$2" key="$3" 
	sizetlabel=20;sizeentry=36;sizetext=46;ref_entry=""
	IFS=",";name=($GTBNAME);unset IFS;IFS="|";meta=($GTBMETA);unset IFS	
	entrys="";del=""
	rulesfile=$(getfilename "$tpath/rules" "$db" "$tb" ".txt")
	stmt="select * from $tbrules where rules_db = \"$db\" and rules_tb = \"$tb\" and rules_status < 9"
	sql_execute "$dbrules" ".mode line\n$stmt" > "$rulesfile"
	setconfig "defaultrowid|$db $tb $pid|$key"
cat <<EOF 
	<vbox hscrollbar-policy="1" vscrollbar-policy="1" space-expand="true" scrollable="true">
		<entry width_chars="$sizeentry" space-fill="true" visible="false">
			<variable>entrydummy</variable>
			<input>$script --func uid_ctrl_gui "entryp | $db | $tb | \$PRIMKEY | \$entryp | $pid | none | \$entrys"</input>
		</entry> 
		<entry auto-refresh="true" visible="false">
			<variable>entrydummy2</variable>
			<input file>"$filesocket"</input>
			<action type="refresh">entrydummy</action> 
		</entry>
		<vbox space-expand="false">
			<hbox>
				<entry width_chars="$sizeentry" space-fill="true" auto-refresh="true">
					<variable>entryp</variable>
					<input file>"$(getfilename ${tpath}/input $pid $tb $PRIMKEY $db .txt)"</input>
				</entry> 
				<text width-chars="46" justify="3"><label>$PRIMKEY (PK) (type,null,default,primkey)</label></text>
			</hbox>
		</vbox>
		<vbox>
EOF
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		uid_gui_get_rule "$db" "$tb" "${name[$ia]}"
		if [ "$?" = "$true" ];then func=$RULES_TYPE;visible="false" ;else func="";visible="true";fi
cat <<EOF
			<hbox> 
EOF
		entrys="${entrys}${del}"'$entry'"$ia";del="|"
		if  [ "$func" = "" ] || [ "$func" = "fileselect" ] ; then 
cat <<EOF 					
				<entry width_chars="$sizeentry" space-fill="true" auto-refresh="true">  
					<variable>entry$ia</variable> 
					<input file>"$(getfilename ${tpath}/input $pid $tb ${name[$ia]} $db .txt)"</input> 
				</entry>
EOF
		else
cat <<EOF 
				<comboboxtext space-expand="true" space-fill="true" auto-refresh="true">
					<variable>entry$ia</variable>
					<input file>"$(getfilename ${tpath}/input $pid $tb ${name[$ia]} $db .txt)"</input> 
					$(uid_gui_rules "xml" "action" "$db" "$tb" "${name[$ia]}" "\$entry${ia}" "$entrys" "$pid" "$RULES_ACTION")
				</comboboxtext>
EOF
		fi
		if  [ "$func" = "fileselect" ] ; then
cat <<EOF  
				<button>
					<input file stock="gtk-open"></input>
					<action>$script --func uid_ctrl_gui "fileselect | $db | $tb | ${name[$ia]} | \$entry$ia | ${pid} | none | $entrys "</action>
					$(uid_gui_rules "xml" "action" "$db" "$tb" "${name[$ia]}" "\$entry${ia}" "$entrys" "$pid" "$RULES_ACTION")
				</button>
EOF
		fi
		if  [ "$func" != "" ] ; then
cat <<EOF  
		$(uid_gui_rules "xml" "button" "$db" "$tb" "${name[$ia]}" "\$entry${ia}" "$entrys" "$pid" "$RULES_ACTION")
EOF
		fi
cat <<EOF 
				<text width-chars="$sizetext" justify="3"><label>${name[$ia]} (${meta[$ia]})</label></text>   
			</hbox> 
EOF
	done
cat <<EOF 
		</vbox> 
		<hbox> 
EOF
	for label in back next insert update delete clear refresh;do
			cat <<EOF 
			<button><label>$label</label>
				<action>$script --func uid_ctrl_gui "button_$label | $db | $tb | $PRIMKEY | \$entryp | $pid | none | $entrys "</action>
			</button>
EOF
	done
cat <<EOF 
			<button>
				<label>exit</label>
				<action>$script --func uid_ctrl_gui "button_exit | $db | $tb | $PRIMKEY | \$entryp | ${pid} | ${wtitle}#${geometryfile}#${geometrylabel} | $entrys "</action>			
				<action type="exit">CLOSE</action>
			</button>
		</hbox>
	</vbox> 
EOF
}
function x_ctrl_check_files() {
	local file="$x_configfile"	
	if [ ! -f "$file" ];then 
			cat <<EOF > "$file"
# defaultwerte etc:" 															 
# tpath=\"$tpath\"							#	target temporary files 
# dbparm=\"$path/parm.sqlite\" 				#	parm database 
# tbparm=\"parm\" 							#	parm table 
# term_heigth=\"8\"							#	anzahl zeilen terminal  
# limit=150 								#	  
# tmpf=\"$tpath/dialogtmp.txt\" 			#	  
# export=\"$false\" 						#	always read to file  	  
# geometry_tb=\"800x600+100+100\" 			#	set tb height,width,x,y  
# geometry_rc=\"600x400+100+150\" 			#	set rc height,width,x,y 
EOF
	fi
	db="$dbparm";tb="$tbparm";local file=$(getfilename "$sqlpath/create_systable" "$tb" $(echo "$db" | tr '/.' '-#') ".sql")  
	if [ ! -f "$file" ]; then
		cat <<EOF > "$file"
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
	fi
	db="$dbrules";tb="$tbrules";local file=$(getfilename "$sqlpath/create_systable" "$tb" $(echo "$db" | tr '/.' '-#') ".sql")  
	if [ ! -f "$file" ]; then
		cat <<EOF > "$file"
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
	fi
	db="$dbcreate";tb="$tbcreate";local file=$(getfilename "$sqlpath/create_systable" "$tb" $(echo "$db" | tr '/.' '-#') ".sql")  
	if [ ! -f "$file" ]; then
		cat <<EOF > "$file"
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
	fi
	db="$dbhelp";tb="$tbhelp";local file=$(getfilename "$sqlpath/create_systable" "$tb" $(echo "$db" | tr '/.' '-#') ".sql")  
	if [ ! -f "$file" ]; then
		cat <<EOF > "$file"
create table $tb(
"syshelp_id" 	integer primary key autoincrement unique not null,
"syshelp_topic" text,
"syshelp_type" 	text,
"syshelp_note" 	text,
"syshelp_line" 	integer
);
insert into $tb 
	(syshelp_topic,syshelp_type,syshelp_note)
	VALUES 
 ('general','purpose','A small and very basic sqlite-tool.') 
,('general','purpose','The main dialog uses the notebook widget.') 
,('general','purpose','Each notebook-tab points to a table or a database.') 
,('general','purpose','The aim is to group tables for a special project.') 
,('general','dependency','gtkdialog 0.8.3') 
,('general','dependency','zenity 3.32.0') 
,('general','dependency','bash 5.0.17(1)') 
,('general','usage','Expect a list of databases ,optionaly with a list of tables') 
,('general','usage','The general tab selectDB is added by default')
,('general','usage','example: myscript mydb1 mytb1 mytb2 mydb2 mydb3 --all')
,('general','usage','-- myscript mydb1 mytable1 mytable2 mydb1')
,('parameter','--tlog -t','show log with tail')
,('parameter','--debug -d','log more verbose')
,('parameter','--version -v','')
,('parameter','--func -f','direct execute a function - helpful for testing')
,('parameter','--noselectdb','no default notebook tab')
,('parameter','--noheader','omit show the column headers c1 c2 c3 ... c30')
,('parameter','--noheader','if a tab refers to a db, there are restrictions for the table widget.')
,('parameter','--noheader','the header strings are pre build and so they cannot match a tb.')
,('parameter','--norules','omit defined rules for the uid-dialog to see utils')
,('parameter','--noterminal','omit terminal widget in main dialog')
,('parameter','--window -w ','window title')
,('parameter','--geometry_tb --gtb','format: heightxwidth+x+y')
,('parameter','--geometry_rc --grc','format: heightxwidth+x+y')
,('parameter','--help -h','')
,('parameter','--trap_at','trap at line only takes effect if running from terminal')
,('parameter','--trap_when','trap when field equal')
,('parameter','--trap_change','trap when value changed')
,('tb_dialog','notebook tab','well done for a tb,for a db c1 c2 ...')
,('tb_dialog','tree','')
,('tb_dialog','entry','active database,not sensitive')
,('tb_dialog','button select','select database dialog, only visible for selectDB')
,('tb_dialog','listbox tables','with last selected table on top')
,('tb_dialog','button tb_utils','call utils with active database and table')
,('tb_dialog','listbox where','last where-clauses,must start with where,order or limit')
,('tb_dialog','button delete','delete selected where clause')
,('tb_dialog','button delete','edit selected where clause')
,('tb_dialog','button settings','get new instance with systable to list all about this tb')
,('tb_dialog','button workdir','') 
,('tb_dialog','button db_utils','call utils with active database (if tab is database)')
,('tb_dialog','button utils','call utils (if tab is selectDB)')
,('tb_dialog','button show terminal','if terminal is not visible')
,('tb_dialog','button hide terminal','if terminal is visible')
,('tb_dialog','button clone','start a new (and propper) instance with active db and tb')
,('tb_dialog','button insert','start uid dialog')
,('tb_dialog','button update','start uid dialog')
,('tb_dialog','button delete','delete marked row')
,('tb_dialog','button refresh','read tb and clear and refresh all widgets')
,('tb_dialog','button exit','good bye and save geometry')
,('utils','import','import file to (new) table')
,('utils','reload','insert/update existing tb from file')
,('utils','dump','unload tb for restoring or copy to other db')
,('utils','restore','')
,('utils','rules','start new instance to manage rules for uid')
,('utils','drop','')
,('utils','read','execute sql from file')
,('utils','create(editor)','create sql with editor')
,('utils','create(gui)','create sql with gui - experimentaly')
,('utils','modify(editor)','create sql with editor containing unload,tb schema and reload data')
,('utils','modify(gui)','same as above but with gui - experimentaly')
,('rules','general','the uid dialog creates one entry fields for each column.')
,('rules','general','if a rule exists for a field, a combobox will be generated instead.')
,('rules','general','the combobox gets the data from sql,file or string')
,('rules','general','the rules dialog itself is designed with rules')
,('rules','general','and gives examples, what is possible')
,('rules','general','recommended columns: rules_tyoe,rules_db,rules_tb and rules_action')
,('rules','type=liste','expect in rules_action a string with separator @ or an existing filename')
,('rules','type=boolean','system')
,('rules','type=fileselect','')
,('rules','type=reference','get values from other table ')
,('rules','type=table','experimental: if table too big for reference start new instance')
,('rules','type=table','mark row and exit, value will transported')
,('rules','type=table','works only with foreign key ')
,('rules','type=command','execute semicolon separated commands in rules_action ')
,('rules','type=command','prefix input@: command is executed in the input method ')
,('rules','type=command','prefix button@: add extra button and perfom action ')
,('rules','type=command','prefix action@: command is executed when widget is activated')
,('uid_dialog','general','')
,('uid_dialog','entry','either entry field /default) or combobox (if rule exists)')
,('uid_dialog','text','meta infos')
,('uid_dialog','button back','')
,('uid_dialog','button next','')
,('uid_dialog','button insert','')
,('uid_dialog','button update','')
,('uid_dialog','button delete','')
,('uid_dialog','button clear','')
,('uid_dialog','button refresh','')
,('uid_dialog','button exit','good bye and save geometry');
update $tb set syshelp_line = syshelp_id * 100;
EOF
	fi
}
function zz () { return; } 
	ctrl $*

