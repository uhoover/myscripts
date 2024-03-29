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
    log debug $FUNCNAME
}
function ctrl () {
	log file  
	rxvt="urxvt -depth 32 -bg [65]#000000 -geometry 40x20"
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}"
	tpath="$path/tmp";xpath="$path/xml" 
	dbpath="$HOME/db";sqlpath="$dbpath/sql";ipath="$dbpath/import" 
	epath="/var/tmp/export_${folder%%\.*}" 
	[ ! -d "$path" ]     && mkdir 	 "$path"  
	[ ! -d "$path/tmp" ] && mkdir 	 "$path/tmp"  
	[ ! -d "$xpath" ]	 && mkdir 	 "$xpath"  
	[ ! -d "$epath" ]    && mkdir 	 "$epath"   && ln -sf "$epath"    "$path"   
	[ ! -d "$ipath" ]    && mkdir -p "$ipath"   && ln -sf "$ipath"    "$path"   
	[ ! -d "$sqlpath" ]  && mkdir -p "$sqlpath" && ln -sf "$sqlpath"  "$path"   
	[   -d "$HOME/log" ]                        && ln -sf "$HOME/log" "$path"   
	script=$(readlink -f $0)  
	x_configfile="$path/.configrc" 
	dbparm="$path/parm.sqlite" 
	parmtb="parms"
	ctrl_master "$dbparm" "$parmtb" 
	limit=$(getconfig_db "parm_value" "config" "limit" 150)
	term_heigth=$(getconfig_db "parm_value" "config" "term_heigth" 8)
	wtitle=$(getconfig_db "parm_value" "config" "wtitle" "dbms")
	export=$(getconfig_db "parm_value" "config" "export" "$false")
	tmpf="$path/tmp/tmpfile.txt"   
	pparms=$*
	notable=$false;myparm="";nowidgets="false";X=400;Y=600
	ctrl_file
	source $x_configfile
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--tlog"|-t|--show-log-with-tail)  			log tlog ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--version"|-v)  				            echo "version 1.0.0" ;;
	        "--vb"|--verbose|--verbose-log)  			log verbose_on ;;
	        "--func"|-f|--execute-function)  			shift;cmd="nostop";log debug $pparms;$@;return ;;
	        "--notable"|--no-tab-with-db-selection)		notable=$true ;;
	        "--nolabel"|--no-notebook-label)			nolabel=$true ;;
	        "--nowidgets"|--no-extra-widgets)			nowidgets="true" ;;
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
	ctrl_tb $myparm	
}
function ctrl_master() {
	is_table "$1" "$2"; if [ $? -lt 1 ]; then return;fi 
	local db="$1";local tb="$2";ix=-1
	cat << EOF > $sqlpath/create_table_${tb}.sql
    create table if not exists $tb (
		parm_id		INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
		parm_status	TEXT default 0,
		parm_type	TEXT,
		parm_field	TEXT,
		parm_value	TEXT,
		parm_info	TEXT);
	create unique index ix1_$tb_field_type on $tb(parm_field,parm_type);
EOF
	cat << EOF > $ipath/${tb}.csv
$((++ix)),0,"boolean","true","0		true",null
$((++ix)),0,"boolean","false","1	 false",null
$((++ix)),0,"status","aktiv","0	 	aktiv",null
$((++ix)),0,"status","busy","1	   busy",null
$((++ix)),0,"status","ready","2	 	ready",null
$((++ix)),0,"status","done","3	   done",null
$((++ix)),0,"status","inaktiv","9	  inaktiv",null
EOF
	cat << EOF > $ipath/${tb}.sh
#!/bin/bash
	source /home/uwe/my_scripts/my_functions.sh 
	sql_execute $db ".read $sqlpath/create_table_${tb}.sql"
	if [ "$?" -gt "0" ]; then return;fi  
	sql_execute $db ".mode csv\n.import $ipath/${tb}.csv $tb" 
	if [ "$?" -gt "0" ]; then return;fi 
	sql_execute $db ".headers off\nselect 'eingefügt',count(*) from $tb" 
	echo $db $tb
	read -p "weiter mit beliebiger Taste" 
EOF
	chmod +x $ipath/${tb}.sh
	rxvt -e $ipath/${tb}.sh
}
function ctrl_file() {
	if [ ! -f "$x_configfile" ];then 
		echo "# defaultwerte etc:" 															>> "$x_configfile" 
		echo "# tpath=\"$path/tmp\"							#	target temporary files" 	>> "$x_configfile" 
		echo "# dbparm=\"$path/parm.sqlite\" 				#	parm database" 				>> "$x_configfile" 
		echo "# parmtb=\"parm\" 							#	parm table" 				>> "$x_configfile" 
		echo "# term_heigth=\"8\"							#	anzahl zeilen terminal"		>> "$x_configfile" 
		echo "# limit=150 									#	 " 							>> "$x_configfile" 
		echo "# tmpf=\"$path/tmp/dialogtmp.txt\" 			#	 " 							>> "$x_configfile" 	  
		echo "# export=\"$false\" 							#	always read to file " 		>> "$x_configfile" 	  
		echo "# geometry_tb=\"800x600+100+100\" 			#	set tb height,width,x,y " 	>> "$x_configfile" 	  
		echo "# geometry_rc=\"400x400+100+150\" 			#	set rc height,width,x,y " 	>> "$x_configfile" 	  
	fi 
}
function ctrl_tb () {
	dbliste=$(tb_get_labels $*)												# datenbanken und tabellen ermitteln
	IFS="|";arr=($dbliste);unset IFS
	if [ "${#arr[@]}" -lt "1" ];then setmsg -i "keine gueltigen Parameter";return 1 ;fi
	notebook="";for arg in ${arr[@]};do notebook="$notebook ${arg%%#*}";done 
    geometrylabel="geometry_$(echo $notebook | tr ' ' '_')"
    geometryfile="$tpath/${geometrylabel}.txt"
    xfile="xml_$(echo $notebook | tr ' ' '_').xml"
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
	 		log "$FUNCNAME label $1 db $2 tb $3"  
	  		tb_gui_get_xml "$1" "$2" "$3" >> $xmlfile 
		done
		echo "</notebook></window>" >> $xmlfile
	fi
    if [ "$geometry_tb" = "" ];then geometry_tb=$(getconfig_db "parm_value" "config" "$geometrylabel" '800x800+100+100');fi
##
	[ -f "$tmpf" ] && rm "$tmpf"
    gtkdialog -f "$xmlfile" --geometry="$geometry_tb" > $tmpf					# start dialog
##    
    while read -r line;do
		echo $line															# defaultwerte speichern
		field="${line%%\=*}";value=$(echo "${line##*\=}" | tr -d '"')
		if [ "${line:0:6}" = "CBOXTB" ];then  labela+=( ${field:6} ) ;fi  	# label
		if [ "${line:0:6}" = "CBOXTB" ];then cboxtba+=( $value ) ;fi 		# tabelle
		if [ "${line:0:5}" = "ENTRY" ]; then  entrya+=( $value ) ;fi 		# database
		if [ "${line:0:4}" = "TREE" ];  then   treea+=( $value ) ;fi 		# last selected row
    done < $tmpf
    for ((ia=0;ia<${#cboxtba[@]};ia++)) ;do
		#~ if [ "${entrya[$ia]}" != "" ];	then 
			#~ setconfig_db "defaultdatabase" 	"${labela[$ia]}"  							"${entrya[$ia]}" 
		#~ fi   
		#~ if [ "${cboxtba[$ia]}" != "" ];	then
			#~ setconfig_db "defaulttable"	"${labela[$ia]} ${entrya[$ia]}" 				"${cboxtba[$ia]}"  
		#~ fi     
		if [ "${treea[$ia]}" != "" ];	then
			setconfig_db "defaultrow" 	"${labela[$ia]} ${entrya[$ia]} ${cboxtba[$ia]}" "${treea[$ia]}" 
		fi   
	done
}
function ctrl_tb_gui () {
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	func=$(trim_value ${parm[0]});label=$(trim_value ${parm[1]});db=$(trim_value ${parm[2]});tb=$(trim_value ${parm[3]})
	db_gui=$(trim_value ${parm[4]});tb_gui=$(trim_value ${parm[5]});where_gui=$(trim_value ${parm[6]});row=$(trim_value ${parm[7]})
	where_gui_scroll=$(trim_value ${parm[7]})
	selection_mode=$(getconfig_db "parm_value" "config" "${label}_CBOXWH" "scroll")
	if [ "$selection_mode" = "edit" ];
		then where_gui="$where_gui"  
		else where_gui="$where_gui_scroll"  
	fi
	setmsg -i -d --width=600 "func $func\nmode $selection_mode\nlabel $label\ndb $db\ntb $tb\ndb_gui $db_gui\ntb_gui $tb_gui\nwhere_gui $where_gui\nrow $row"
	found=$true 
	if [ "$func"    = "entry" ];	then db_gui="" ;fi
	if [ "$db_gui" != "" ];			then db=$db_gui ;fi
	if [ "$db" 		= "dfltdb" ];	then db=$(getconfig_db parm_value defaultdatabase $label);fi
	if [ "$db" 		= "" ];			then found=$false;db=$(get_fileselect parm_value searchpath database);fi
	is_database $db
	if [ "$?" -gt "0" ];			then setmsg -w "keine Datenbank ausgewaehlt";return;fi
	if [ "$found"   = "$false" ];	then setconfig_db "defaultdatabase" "$label" "$db";return;fi
	if [ "$tb_gui" != "" ];			then tb=$tb_gui ;fi
	if [ "$tb" 		= "dflttb" ] || [ "$tb" 		= "" ];
									then
									     tb=$(getconfig_db parm_value defaulttable "${label}_${db}") 
										 if [ "$tb" 		= "" ];			then 
											tb=$(tb_get_tables "$db" "batch"| head -n1)
										 fi
		   								 setconfig_db "defaulttable" "$label $db" "$tb"
									fi
	if [ "$tb"      = "" ];			then setmsg -w "keine Tabelle gefunden";return;fi
	if [ "$where_gui" != "" ]; 		then where="$where_gui" ;fi
	if [ "$where"   = "" ]; 		then where=$(getconfig_db parm_value defaultwhere "${label}_${db}_${tb}" | remove_quotes);fi 
	case "$func" in
		"entry")   	echo $db ;;
		"fselect") 	db=$(get_fileselect parm_value searchpath database)
					is_database $db
					if [ "$?" = "0" ];then setconfig_db "defaultdatabase" "$label" "$db";fi
					return ;;
		"cboxtb") 	if [ "$label" = "$tb" ];then echo $tb;return;fi
					if [ "$db" = "" ];	then setmsg -e "keine Datenbank gefunden";return;fi 
					tb=$(getconfig_db parm_value defaulttable "${label}_${db}") 
		            if [ "$tb" != "" ];then echo $tb; else tb=" ";fi
		            tb_get_tables "$db" "batch" | grep -vw "$tb" ;;
		"cboxwh") 	#trap 'set +x;trap_at $LINENO 182;set -x' DEBUG
					where=$(getconfig_db parm_value defaultwhere "${label}_${db}_${tb}" | remove_quotes);
					if [ "$where" = "" ];then where=" ";fi
					echo $where
					getconfig_db parm_value "%wherelist%" "${label}_${db}_${tb}" | remove_quotes | grep -vw "$where"
					;;
		"tree") 	setmsg -i -d "$FUNCNAME\nfunc $func\ndb $db\ntb $tb \nwhere $where"
					tb_read_table $label "$db" $tb "$where" ;;
		"b_delete") ctrl_rc_gui "button_delete | $db | $tb | unknown | $row";;
		"b_config")	setconfig_db "defaultwhere" "$parmtb $dbparm $parmtb" "where parm_field like \"%${db}_${tb}%\" or parm_type = \"config\" order by parm_type"
					$rxvt -e $script $dbparm $parmtb --notable &  ;;
		"b_clone")	$rxvt -e $script $db	 $tb 	 --notable &  ;;
		"b_insert")	ctrl_rc "insert" "$db" "$tb" ;;
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
		lb=$(echo $TNAME | tr '_,' '-|');sensitiveCBOX="false";sensitiveFSELECT="false";sorttype=$TSORT 
	else
		lb=$(copies 30 '|');sensitiveCBOX="true";ID=0;sensitiveFSELECT="true";sorttype="1$(copies 29 '|0')"
	fi
	selection_mode=$(getconfig_db "parm_value" "config" "${label}_CBOXWH" "scroll")
	if [ "$selection_mode" = "edit" ];
		then visibleCBOXWH="true" ;visibleCBOXTH="false"  
		else visibleCBOXWH="false";visibleCBOXTH="true"  
	fi
	if [ "$selection_mode" = "scroll" ];	then visibleCBOXTH="true" ;else visibleCBOXTH="false"  ;fi
	if [ "$db"   = "dfltdb" ]; 	then cdb=$(getconfig_db parm_value defaultdatabase $label) ;else cdb="$db" ;fi
	if [ "$cdb" != "" ];       	then ctb=$(getconfig_db parm_value defaulttable   "${label}_$cdb") ;else ctb="$tb" ;fi
	if [ "$ctb" != "" ];	   	then row=$(getconfig_db parm_value defaultrow "${label}_${cdb}_${ctb}" |  tr -d '"' );else row="";fi
	if [ "$row" != "" ];   		then row="$(sql_execute $cdb '.header off\nselect count(*) from '$ctb' where rowid < '$row)"  ;fi
	if [ "$row" != "" ];   		then selected_row="selected-row=\"$row\"" ;else selected_row=""  ;fi
	terminal="${tpath}/cmd_${label}.txt"
	terminal_cmd "$terminal" "$label" "$db" 
	echo '    <vbox>
		<tree headers_visible="true" hover_selection="false" hover_expand="true" 
		 exported_column="'$ID'" sort-column="'$ID'" column-sort-function="'$sorttype'" '$selected_row'>
			<label>"'$lb'"</label>
			<variable>TREE'$label'</variable>
			<input>'$script' --func ctrl_tb_gui "tree | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label' | $TBOXWH'$label'"</input>
			<action>'$script' '$nocmd' --func ctrl_rc $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>	
			<action type="clear">CBOXWH'$label'</action>		
			<action type="refresh">CBOXWH'$label'</action>		
			<action type="clear">TBOXWH'$label'</action>		
			<action type="refresh">TBOXWH'$label'</action>		
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true">  
				<variable>ENTRY'$label'</variable> 
				<sensitive>false</sensitive>  
				<input>'$script' --func ctrl_tb_gui "entry | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</input>
				<action>'$script' --func terminal_cmd '$terminal' '$label' $ENTRY'$label'</action>
				<action type="refresh">TERMINAL'$label'</action>
			</entry> 
			<button space-fill="false">
            	<variable>BUTTONFSELECT'$label'</variable>
            	<sensitive>'$sensitiveFSELECT'</sensitive>
            	<input file stock="gtk-open"></input>
				<action>'$script' --func ctrl_tb_gui "fselect | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>
            	<action type="refresh">ENTRY'$label'</action>
            	<action type="refresh">CBOXTB'$label'</action>		
            	<action type="refresh">CBOXWH'$label'</action>		
            </button> 
		  </hbox>
			<comboboxtext space-expand="true" space-fill="true" allow-empty="false">
				<variable>CBOXTB'$label'</variable>
				<sensitive>'$sensitiveCBOX'</sensitive>
				<input>'$script' --func ctrl_tb_gui "cboxtb | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</input>
				<action type="refresh">CBOXWH'$label'</action>
				<action type="refresh">TBOXWH'$label'</action>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</comboboxtext>	
		</hbox>
		<hbox>
			<comboboxentry space-expand="true" space-fill="true" allow-empty="true" visible="'$visibleCBOXWH'">
				<variable>CBOXWH'$label'</variable>
				<input>'$script' --func ctrl_tb_gui "cboxwh | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</input>
				<action>'$script' --func setconfig_db "config" "'$label'_CBOXWH" "edit"</action>
				<action signal="activate" type="clear">TREE'$label'</action>
				<action signal="activate" type="refresh">TREE'$label'</action>
			</comboboxentry>
			<comboboxtext space-expand="true" space-fill="true" allow-empty="false" visible="'$visibleCBOXTH'">
				<variable>TBOXWH'$label'</variable>
				<input>'$script' --func ctrl_tb_gui "cboxwh | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $TBOXWH'$label'"</input>
				<action>'$script' --func setconfig_db "config" "'$label'_CBOXWH" "scroll"</action>
				<action type="clear">TREE'$label'</action>
				<action type="refresh">TREE'$label'</action>
			</comboboxtext>
			<button visible="'$visibleCBOXTH'">
				<label>edit-mode</label>
				<variable>BUTTONEDIT'$label'</variable>
				<action type="show">CBOXWH'$label'</action>
				<action type="hide">TBOXWH'$label'</action>
				<action type="refresh">CBOWWH'$label'</action>
				<action type="show">BUTTONVIEW'$label'</action>
				<action type="hide">BUTTONEDIT'$label'</action>
			</button>
			<button visible="'$visibleCBOXWH'">
				<label>scroll-mode</label>
				<variable>BUTTONVIEW'$label'</variable>
				<action type="hide">CBOXWH'$label'</action>
				<action type="show">TBOXWH'$label'</action>
				<action type="refresh">TBOXWH'$label'</action>
				<action type="show">BUTTONEDIT'$label'</action>
				<action type="hide">BUTTONVIEW'$label'</action>
			</button>
			<button>
				<label>settings</label>
				<variable>BUTTONCONFIG'$label'</variable>
				<action>'$script' --func ctrl_tb_gui "b_config | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>
			</button>	
		</hbox>
		<hbox>
			<button>
				<label>workbench</label>
				<action>xdg-open '$path' &</action>
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
				<action>'$rxvt -e $script' $ENTRY'$label' $CBOXTB'$label' --notable --window $CBOXTB'$label'_dbms &</action>
			</button>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$label'</variable>
				<action>'$script' --func ctrl_tb_gui "b_insert | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | $CBOXWH'$label'"</action>
			</button>
			<button visible="true">
				<label>update</label>
				<variable>BUTTONAENDERN'$label'</variable>
				<action>'$script' --func ctrl_rc $TREE'$label' $ENTRY'$label' $CBOXTB'$label'</action>
			</button>
			<button visible="true">
				<label>delete</label>
				<variable>BUTTONDELETE'$label'</variable>
				<action>'$script' --func ctrl_tb_gui "b_delete | '$label' | '$db' | '$tb' | $ENTRY'$label' | $CBOXTB'$label' | '$PRIMKEY' | $TREE'$label'"</action>			
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
				<label>exit</label>
				<action>'$script' --func save_geometry "'"${wtitle}#${geometryfile}#${geometrylabel}"'"</action>	
				<action type="exit">OK</action>
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
	local db="$1";shift;local tb="$1";shift;local row=$1;shift;local parms=$(echo $* | tr '#|' ',,' )
	if [ "${parms:${#parms}-1:1}" = "," ];then parms="${parms}null"  ;fi          # letzter delimiter wird nicht als element erkannt
	local parmlist=$(echo $parms | quote)
	local del="";local del2="";local del3="";local line=""
	TNAME="" ;TTYPE="" ;TNOTN="" ;TDFLT="" ;TPKEY="";TMETA="";TSELECT="";TUPDATE="";TSORT="";local ip=-1;local pk="-"
	sql_execute "$db" ".headers off\nPRAGMA table_info($tb)"   > $tmpf
	if [ "$?" -gt "0" ];then log "$FUNCNAME error $?: $db" ".headers off\nPRAGMA table_info($tb)";return 1;fi
	while read -r line;do
		IFS=',';arr=($line);unset IFS;ip=$(($ip+1))
		TNAME=$TNAME$del"${arr[1]}";TTYPE=$TTYPE$del"${arr[2]}";TNOTN=$TNOTN$del"${arr[3]}"
		TDFLT=$TDFLT$del"${arr[4]}";TPKEY=$TPKEY$del"${arr[5]}"
		TMETA=$TMETA$del2"${arr[2]},${arr[3]},${arr[4]},${arr[5]}"
		if [ "${arr[2]}" = "INTEGER" ] || [ "${arr[2]}" = "REAL" ] ;then TSORT="${TSORT}${del2}1";else TSORT="${TSORT}${del2}0";fi
		if [ "${arr[5]}" = "1" ] ;then
			PRIMKEY="${arr[1]}";export ID=$ip;  
		else
			TSELECT=$TSELECT$del3$"${arr[1]}" 	
			TUPDATE=$TUPDATE$del3$"${arr[1]} = %s";del3=","	
		fi
		del=",";del2='|'
	done < $tmpf
	if [ "$PRIMKEY" = "" ];then 
		PRIMKEY="rowid";ID=0
		TNAME="rowid$del$TNAME";TTYPE="INTEGER$del$TTYPE";TNOTN="1$del$TNOTN";TSORT="1$del2$TSORT"
		TDFLT="' '$del$TDFLT";TPKEY="1$del$TPKEY";TMETA="rowid$del2$TMETA"
	fi 
	if [ "$parmlist" = "" ];then return;fi
	parmlist=${parmlist//'"null"'/null}
	TINSERT="insert into $tb ($TSELECT) values ($parmlist)"
	IFS=",";TUPDATE="update $tb set "$(printf "${TUPDATE}\n" $parmlist)" where $PRIMKEY = $row";unset IFS
}
function tb_read_table() {
	label="$1";shift;local db="$1";shift;local tb="$1";shift;where=$*  
	tb_meta_info "$db" $tb
	if [ "$where" != "" ] &&  [ $(pos limit "where") -gt -1 ]; then
		xlimit="" 
	else
		xlimit="limit $limit"
	fi
	if [ "$export"  = "$true" ];then exportpath="$epath/export_${tb}_$(date "+%Y%m%d%H%M").csv" ;else exportpath="$epath/export_${tb}.csv";fi
	if [ "$label" 	= "$tb" ];	then off="off";srow="*" ;else off="on";srow="$PRIMKEY,$TSELECT"  ;fi		# jeder select wird archiviert
	if [ "$PRIMKEY" = "rowid" ];then srow="rowid,*" ;fi
	sql_execute $db ".separator |\n.header $off\nselect ${srow} from $tb $where $xlimit;" | tee "$exportpath" 
	error=$(<"$sqlerror")
	if [ "$error"  != "" ];		then return 1;fi
	if [ "$where" 	= "" ]; 	then return 0;fi 
	setconfig_db "defaultwhere"  	"$label $db $tb" "$where" 
	setconfig_db "wherelist $where" "$label $db $tb" "$where" 		
}
function ctrl_rc () {
	log $FUNCNAME $*
	if [ "$#" -gt "3" ];then setmsg -w  " $#: zu viele Parameter\n tabelle ohne PRIMKEY?" ;return  ;fi
	row="$1";shift;db="$1";shift;tb="$@"
	tb_meta_info "$db" "$tb"
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME\nerror Meta-Info\n$db\n$tb";return ;fi
	if [ "$row" = "insert" ]; then
		ctrl_rc_gui "button_clear | $db | $tb"
	else
		rc_sql_execute $db $tb eq $PRIMKEY $row 
	fi
	geometrylabel="geometry_rc_$tb"
	geometryfile="$tpath/${geometrylabel}.txt"
    row_change_xml="$path/tmp/change_row_${tb}.xml"	
    wtitle="dbms-rc-${tb}"
    if [ -f "${xpath}/change_row_${tb}.xml" ]; then
		row_change_xml="${xpath}/change_row_${tb}.xml"
	else	
		echo "<window title=\"$wtitle\" allow-shrink=\"true\">" > "$row_change_xml"
		rc_gui_get_xml $db $tb $row  >> "$row_change_xml"
		echo "</window>" >> "$row_change_xml"
	fi	
    if [ "$geometry_rc" = "" ];then geometry_rc=$(getconfig_db "parm_value" "config" "$geometrylabel" '100x100+100+150');fi
 	gtkdialog -f "$row_change_xml" --geometry=$geometry_rc & # 2> /dev/null  
}
function ctrl_rc_gui () {
	log debug $FUNCNAME $@
	pparm=$*;IFS="|";parm=($pparm);unset IFS 
	func=$(trim_value ${parm[0]});db=$(trim_value ${parm[1]});tb=$(trim_value ${parm[2]});entry=$(trim_value ${parm[3]})
	field=$(trim_value ${parm[3]});key=$(trim_value ${parm[4]});entry=$(trim_value ${parm[4]});values=$(trim_value ${parm[@]:5})
	if [ "$field" = "unknown" ];then tb_meta_info $db $tb;field=$PRIMKEY  ;fi
	case $func in
		 "entry")   	    if [ "$field" = "$key" ]; then 
								getconfig_db "parm_value" "rc_field" "${db}_${tb}_${field}" | remove_quotes;return 
							fi 
							value=$(getconfig_db "parm_value" "rc_field" "${db}_${tb}_${key}" "" "and parm_status < 9" | remove_quotes)	 
							if [ "$value" != ""  ];then echo $value ;return;fi
							IFS=',';meta=$(trim_value ${parm[6]});unset IFS
							if   [ "${meta[4]}" != "" ];      then  echo "${meta[4]}"  
							elif [ "${meta[3]}" = "0" ];  	  then  echo  NULL  
							elif [ "${meta[2]}" = "INTEGER" ];then  echo "0"   
							else                               		echo ""
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
							if [ $? -gt 0 ];then  return  ;fi
							nkey=$(rc_sql_execute "$db" "$tb" "gt" "$field" "$key")  
							if [ "$nkey" = "" ];then nkey=$(rc_sql_execute "$db" "$tb" "lt" "$field" "$key");fi
							if [ "$nkey" = "" ];then return;fi
							rc_sql_execute "$db" "$tb" "eq" "$field" "$nkey"  
							;;
		 "button_clear")   	sql_execute "$dbparm" "update $parmtb set parm_status = 9 where parm_type = \"rc_field\" and parm_field like \"%${db}_${tb}%\""
							;;
		 "button_refresh")  sql_execute "$dbparm" "update $parmtb set parm_status = 0 where parm_type = \"rc_field\" and parm_field like \"%${db}_${tb}%\""
							;;
		 "cbox_i")          rc_gui_get_cmd "$db" "$tb" "$key";									# regel ermitteln
							entry=$($FUNCNAME "entry | $db | $tb | $field | $key" )				# entry ermitteln recursiv funktioniert!
							if 	 [ "$FUNC" = "reference" ]; then
								sql_execute "$SDB" "$SCMD1  = \"$entry\"";						# aktuellen wert als erstes anzeigen
								sql_execute "$SDB" "$SCMD1 != \"$entry\"";						# dann die anderen
							elif [ "$FUNC" = "table" ]; then
								sql_execute "$SDB" "$SCMD1  = \"$entry\"";						# aktuellen wert als erstes anzeigen
							else
								IFS='#';liste=($LISTE);unset IFS
								lng=${#entry}
								for arg in "${liste[@]}" ;do if [ "$entry"  = "${arg:0:$lng}" ];then echo $arg;break ;fi;done
								for arg in "${liste[@]}" ;do if [ "$entry" != "${arg:0:$lng}" ];then echo $arg		 ;fi;done
							fi 	
							;;
		 "cbox_a")        	rc_gui_get_cmd "$db" "$tb" "$key"		  					
							if [ "$FUNC" = "liste" ];then SCMD2="$LCMD"  ;fi
							if [ "$FUNC" = "table" ];then 
								$rxvt -e $script "$SDB" "$STB" "--notable" 
								values=$(getconfig_db parm_value defaultrow "${STB}_${SDB}_${STB}" |  tr -d '"' )
								setmsg -q "wert $values uebernehme?" 
								if [ "$?" != "0" ];then return ;fi
								if [ "$values" = "" ];then return 1;fi
							fi 
							erg=$(set_rc_value_extra "$key" "$SCMD2" "$values")
							setconfig_db "rc_field" "$db $tb $key" "$erg"
		                    ;;
		 "fileselect") 	    sfile=$(get_fileselect "selectfile" "$entry" "letzter Pfad Fileselect")
							if [ "$?" -gt "0" ];then log "$FUNCNAME Suche abgebrochen"  ;fi
							setconfig_db "rc_field" "${db} ${tb} $field" "$sfile"
							;;		
		 "action") 		    rc_gui_get_cmd "$db" "$tb" "$field"
							$ACTION "$entry" ;;
		 *) 				setmsg -i   --width=400 "func $func nicht bekannt\ndb $db\ntb $tb\n$field\nentry $entry"
	esac
}
function rc_gui_get_xml () {
	log debug "$FUNCNAME ID $ID $@"
	db="$1";shift;tb="$1";shift;key="$1"
	sizetlabel=20;sizeentry=36;sizetext=46;ref_entry=""
	eval 'cmd_ref=$'$(get_field_name $db$tb"_ref")
    eval 'cmd_fsl=$'$(get_field_name $db$tb"_fsl")
    eval 'cmd_bln=$'$(get_field_name $db$tb"_bln")
    IFS=",";name=($TNAME);unset IFS;IFS="|";meta=($TMETA);unset IFS
	echo '<vbox hscrollbar-policy="0" vscrollbar-policy="0" space-expand="true" scrollable="true">'
	echo '	<vbox space-expand="false">'
	echo '		<hbox>'
	echo '			<entry width_chars="'$sizeentry'" space-fill="true">'
	echo '				<variable>entryp</variable>'
	echo '				<input>'$script' --func ctrl_rc_gui "entry | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ID]} '|' ${meta[$ID]}'"</input>'
	echo '			</entry>'
	echo '			<text width-chars="46" justify="3"><label>'$PRIMKEY' (PK) (type,null,default,primkey)</label></text>'
	echo '		</hbox>'
	echo '	</vbox>'
	echo '  <vbox>'
    entrys="";del=""
   	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" = "$PRIMKEY" ];then continue ;fi
		if [ "${name[$ia]}" = "rowid" ];then continue ;fi
		rc_gui_get_cmd "$db" "$tb" "${name[$ia]}"
		if [ "$?" = "$true" ];then func=$FUNC;visible="false" ;else func="";visible="true";fi
		echo    '	<hbox>' 
		IFS='#';set -- $cmd;unset IFS
		if  [ "$func" = "" ] || [ "$func" = "fileselect" ] ; then 
			echo    ' 			<entry width_chars="'$sizeentry'"  space-fill="true">'  
			echo    ' 				<variable>entry'$ia'</variable>' 
			echo    ' 				<sensitive>true</sensitive>' 
			echo    ' 				<input>'$script' --func ctrl_rc_gui "entry  | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]} '|' ${meta[$ia]}'"</input>' 
			echo    ' 			</entry>' 
		fi
		entrys="${entrys}${del}"'$entry'"$ia";del="#"
		if [ "$func" = "fileselect" ] ; then 
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
            echo    '    			<action>'$script' --func ctrl_rc_gui "'$func' | '$db '|' $tb '|' ${name[$ia]} '| $entry'$ia'"</action>'
            echo	'    			<action type="refresh">entry'$ia'</action>'	
            echo	'			</button>' 	
		fi
		if 	[ "$func" = "reference" ] || [ "$func" = "liste" ] || [ "$func" = "table" ];then 
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
		  if 	[ "$func" != "table" ];then	
			echo  	'               <action>'$script' --func ctrl_rc_gui  "cbox_a  | '$db '|' $tb '|' ${PRIMKEY} '|' ${name[$ia]}' | $entry'$ia'_'$ia'"</action>'
			echo  	'               <action type="refresh">entry'$ia'</action>'
		  fi
		  	echo  	'       	</comboboxtext>'	
		  if 	[ "$func" = "table" ];then
			echo 	'			<button>'
            echo	'				<label>table</label>'
            echo    '    			<action>'$script' --func ctrl_rc_gui  "cbox_a  | '$db '|' $tb '|' ${PRIMKEY} '|'${name[$ia]} '| $entry'$ia'"</action>'
            echo	'    			<action type="refresh">entry'$ia'_'$ia'</action>'
            echo  	'               <action type="refresh">entry'$ia'</action>'	
            echo	'			</button>' 	
		  fi
		fi
		if 	[ "$func" = "cmd" ] ;then echo ${@:2};fi 
		echo  	' 			<text width-chars="'$sizetext'" justify="3"><label>'${name[$ia]}' ('${meta[$ia]}')</label></text>'   
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
	echo '	<button>'
	echo '		<label>exit</label>'
	echo '		<action>'$script' --func save_geometry "'"${wtitle}#${geometryfile}#${geometrylabel}"'"</action>'	
	echo '		<action type="exit">CLOSE</action>'
	echo '	</button>'
	echo '	</hbox>'
	echo '</vbox>'  
}
function rc_entrys_refresh () {
	log debug $FUNCNAME $@
	IFS=",";name=($TNAME);unset IFS;shift
	IFS="|";meta=($TMETA);unset IFS
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
#	if [ "$mode" = "update" ] || [ "$mode" = "insert" ];		then 
	     parm=$*
	     tb_meta_info $db $tb $row $parm
#	fi
	if [ "$mode" = "eq" ];		then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" = "delete" ];	then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" = "lt" ];		then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" = "gt" ];		then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	if [ "$PRIMKEY" = "rowid" ];then srow="rowid," ;else srow="";fi #;srow="$PRIMKEY,$TSELECT"
	case "$mode" in
		 "delete")	erg=$(sql_execute "$db" "delete from $tb $where") ;;
		 "update")	erg=$(sql_execute "$db" "$TUPDATE") ;;
		 "insert")	erg=$(sql_execute "$db" "$TINSERT") ;;
		  *)  		erg=$(sql_execute "$db" ".mode line\n.header off\nselect ${srow}* from $tb $where")
	esac
	if [ "$?" -gt "0" ];		then return 1;fi
	if [ "$mode" = "delete" ];	then setmsg -n "success delete";return  ;fi
	if [ "$mode" = "insert" ];	then setmsg -n "success insert";return  ;fi
	if [ "$mode" = "update" ];	then setmsg -n "success update";return  ;fi
	if [ "$erg"  = ""  ];		then setmsg -i "keine id $mode $row gefunden"  ;return 1;fi
    echo -e "$erg" > "$tmpf"
    sql_execute "$dbparm" "delete from $parmtb where parm_field like \"$db $tb %\" and parm_type = \"rc_field\"" 
    while read -r line;do
		setconfig_db "rc_field" "${db} ${tb} $(trim_value ${line%%\=*})" "$(trim_value ${line##*\=})"
	done < "$tmpf"
}
function setmsg () { func_setmsg $*; }
function get_field_name () { echo $(readlink -f "$*") | tr -d '/.'; }
function get_fileselect () {
	getfield="$1";shift;type="$1";shift;field="$*" 
	path=$(getconfig_db $getfield $type "$field")
	if [ "$path" = "" ];	then path=$HOME;fi
	mydb=$(zenity --file-selection --title "select $type" --filename=$path)
	if [ "$mydb" = "" ];	then echo "";return 1;fi
	setconfig_db "searchpath" "$field" "$mydb"  
	echo $mydb 
}
function is_database () { file -b "$*" | grep -q -i "sqlite"; }
function is_table () {	
	if [ "$#" -lt "2" ];then return 1;fi 
	tb=$(sql_execute "$1" ".table $2")
	if [ "$tb" = "" ];then return 1;else return 0;fi
}
function setconfig_db () {
	type="$1";shift;field=$(echo "$1" | tr ' ' '_');shift;value=$*
	if [ "$type" = "wherelist" ]; then
		id=$(sql_execute $dbparm ".header off\nselect parm_id from $parmtb where parm_field = '$field' and parm_value = '$value' and parm_type = '$type' limit 1")
	else
		id=$(sql_execute $dbparm ".header off\nselect parm_id from $parmtb where parm_field = '$field' and parm_type = '$type'")
	fi
	if [ "$id" = "" ]; then 
		sql_execute "$dbparm" "insert into $parmtb (parm_type,parm_field,parm_value) values ('$type','$field','$value')"
	else
		if [ "$type" != "wherelist" ]; then
			sql_execute "$dbparm" "update $parmtb set parm_value = '$value' where parm_id = $id"
		fi
	fi
	if [ "$?" -gt "0" ];then return 1 ;else return 0 ;fi
}
function getconfig_db () {
	getfield="$1";shift;type="$1";shift;field="$1";field=$(echo "$field" | tr ' ' '_');shift;default="$1";shift;where=$*
	ix=$(pos '%' $field);if [ "$ix" -gt "-1" ];then eq1="like"  ;else eq1="=" ;fi
	ix=$(pos '%' $type); if [ "$ix" -gt "-1" ];then eq2="like"  ;else eq2="=" ;fi
	value=$(sql_execute $dbparm ".header off\nselect $getfield from $parmtb where parm_field $eq1 \"$field\" and parm_type $eq2 \"$type\" $where") 
	if [ "$?" -gt "0" ];then setmsg -i "$FUNCNAME sql_error";return 1 ;fi
	if [ "$value" = "" ] &&  [ "$default" != "" ];then value="$default";setconfig_db "$type" "$field" "$value" ;fi
	echo -e "$value";return 0
}
function set_rc_value_extra   () {
	field=$1;shift;range="$1";shift;value=$(echo $* | tr  ',' ' ' | tr -d '"')
	if [ "$range" = "" ]; 			then range=0;fi
	if [ "$value" = "" ]; 			then return;fi
	if [ "$range" = "all" ]; 		then echo $values;return;fi
	if [ "${value:2:2}" = "--" ]; 	then return;fi
	IFS=",";range=($range);unset IFS
	IFS=" ";value=($value);unset IFS
	parm="";del=""
	for arg in ${range[@]}; do parm=$parm$del${value[$arg]};del=" ";done	
	setmsg -i -d "$FUNCNAME break\n$parm"
	setconfig_db  "$parm"
	echo $parm
}
function trim_value   () { echo $* ; }
function tb_get_tables () {
	log debug $FUNCNAME $* 
 	if [ "$1" = "" ];then  return ;fi
	if [ -d "$1" ];then setmsg "$1 ist ein Ordner\nBitte sqlite_db ausaehlen" ;return ;fi
	sql_execute "$1" '.tables' | fmt -w 2 | grep -v -e '^$'  
	if [ "$?" -gt "0" ];then return 1;fi
}
function sql_execute () { func_sql_execute $*; } 
function terminal_cmd () {
	termfile="$1" ;local db="$(getconfig_db parm_value defaultdatabase $2)" 
	echo ".exit 2> /dev/null" 	>  "$termfile" 
	echo "sqlite3 $db" 			>> "$termfile"  
}
function remove_quotes () { quote --remove $* | tr -s '"' ; }
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
