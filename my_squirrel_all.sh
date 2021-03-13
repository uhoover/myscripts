#!/bin/bash
function gui_rc_entrys_hbox () {
	log $@
	PRIMKEY=$1;shift;ID=$1;shift;IFS=",";name=($1);unset IFS;shift;IFS="|";meta=($1);unset IFS
	for ((ia=0;ia<${#name[@]};ia++)) ;do
		if [ ""${name[$ia ]}"" == "$PRIMKEY" ];then continue ;fi
		echo '		<hbox>'  
		echo '			<text width-chars="20" justify="3"><label>'" "${name[$ia]}'</label></text>'  
		echo '			<entry width_chars="30"><variable>entry'$ia'</variable><input>tb_get_meta_val '$ia'</input></entry>' 
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
	local line=""
	for ((ia=1;ia<=${#name[@]};ia++)) ;do
		if [ "${name[$ia]}" == "$PRIMKEY" ];then continue;fi;
		line=$line' "$entry'"$ia"'"'
	done
	echo $line
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
			<entry width_chars="30"><variable>entryp</variable><input>tb_get_meta_val '"$ID"'</input></entry>
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
			<action>sql_rc_read lt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>next</label>
			<action>sql_rc_read gt '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>read</label>
			<action>sql_rc_read eq '$PRIMKEY' $entryp</action>
			<action type="enable">BUTTONAENDERN</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>insert</label>
			<action>sql_rc_update_insert insert $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>update</label><variable>BUTTONUPDATE</variable>
			<action>sql_rc_update_insert update $entryp '"$PRIMKEY" "$TSELECT" "$TNOTN" $(gui_rc_entrys_variable_list "$PRIMKEY" "$ID" "$TSELECT")'</action>
		</button>
		<button><label>delete</label>
			<action>sql_rc_delete '$PRIMKEY' $entryp</action>
			'"$(gui_rc_entrys_action_refresh $PRIMKEY $ID $TNAMES $TLINE)"'
		</button>
		<button><label>clear</label>
			<action type="enable">BUTTONUPDATE</action>
			<action>sql_rc_clear '"$(gui_rc_entrys_variable_list $PRIMKEY $ID $TNAMES $TLINE)"'</action>
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
function gui_tb_get_dialog () {
	log debug $@
	defaultdb=$1;shift;tb="$1";shift;tb2="$1";shift;defaulttable="$1";shift;defaultwhere="$1";shift;label="$1"  
	if [ "$tb2" != "-" ];
		then off="off";visible1="true" ;visible2="false"
		else off="on";visible1="false";visible2="true"
	fi  
	echo  '
	<vbox>
		<tree headers_visible="'$visible1'" autorefresh="true" hover_selection="false" hover_expand="true" exported_column="0">
			<label>'"$label"'</label>
			<height>500</height><width>600</width> 
			<variable>TREE'$tb'</variable>
			<input>sql_read_table '$tb' '$off' $CBOXENTRY'$tb' $CBOXDBSEL'$tb' $CBOXWHERE'$tb'</input>
			<action>sql_rc_ctrl $TREE'$tb' $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</action>
			<action type="enable">BUTTONAENDERN'$tb'</action>
		</tree>
		<frame click = selection >
			<hbox homogenoues="true">
				<comboboxtext space-expand="true" space-fill="true" visible="'$visible2'">
					<variable>CBOXDBSEL'$tb'</variable>
					<default>'"$defaultdb"'</default>
					<input file>'$tpath'/dblist.txt</input>
					<action type="refresh">CBOXENTRY'$tb'</action>
				</comboboxtext>
				<comboboxtext space-expand="true" space-fill="true" auto-refresh="true" allow-empty="false" visible="'$visible2'">
					<variable>CBOXENTRY'$tb'</variable>
					<default>'"$defaulttable"'</default>
					<sensitive>true</sensitive>
					<input>sql_read_table_parmtb ".header off\nselect tb from $parmtb where typ = 2 and active = 0 and db = \"$CBOXDBSEL'$tb'\";"</input>
					<action type="clear">TREE'$tb'</action>
					<action type="refresh">CBOXWHERE'$tb'</action>
					<action type="refresh">TREE'$tb'</action>
				</comboboxtext>
			</hbox>
			<comboboxentry auto-refresh="true">
				<variable>CBOXWHERE'$tb'</variable>
				<default>"'$defaultwhere'"</default>
				<input>sql_get_where $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</input>
				<action signal="activate" type="refresh">TREE'$tb'</action>
			</comboboxentry>
		</frame>
		<hbox>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT'$tb'</variable>
				<sensitive>true</sensitive> 
				<action>sql_rc_ctrl insert $CBOXENTRY'$tb' $CBOXDBSEL'$tb'</action>
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
function log () { 
	[ "$1" 			== "logon"  ] && log $(date +"%y-%m-%d-%T:%N") "--------- start" $0 && return;
	[ "$1" 			== "logoff" ] && log $(date +"%y-%m-%d-%T:%N") "--------- stop"  $0 && return;
	[ "$1" 			== "debug"  ] && [ "$logdebug" == "$false" ] 					   && return;
	[ "$1" 			== "debug"  ] && shift;
	[ "$1" 			== "-" 	    ] && shift && gxmessage $@
	[ "$logverbose" == "$true"  ] && set -- $(date +"%y-%m-%d-%T:%N") ${FUNCNAME[1]:0:10}  $@;
	echo -e "$@" >> "$lfile";
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
	erg=$(grep "$str" $tpath/default.txt)
	if [ "$erg" == "" ];then
		echo "insert into $parmtb (typ,active,db,tb,label,value,info) values ($typ,$active,\"$db\",\"$tb\",\"$lb\",\"$val\",\"$info\");"
	else
		echo "update $parmtb set typ=$typ,active=$active,db=\"$db\",tb=\"$tb\",label=\"$lb\",value=\"$val\",info=\"$info\" where id = $erg;"
	fi
}
function sql_read_table_parmtb () {
	echo -e $@ | sqlite3 $parmdb 2> $tpath/sql_error.txt | tr -d '\r'
	err=$(<$tpath/sql_error.txt)
	if [ "$err" != "" ];then log "- $@ $err";echo error;fi
}
function sql_rc_read () {
	log debug $@
	local mode=$1;shift;PRIMKEY=$1;shift;row=$1;
#	if [ "$row" == "NULL" ] || [ "$row" == "" ] || [ "$row" == "=" ];then echo "ID=$ID";return ;fi
	if [ "$row" == "NULL" ] || [ "$row" == "" ] || [ "$row" == "=" ];then row=$(cat $idfile);fi
	if [ "$mode" == "eq" ];then where="where $PRIMKEY = $row ;";fi
	if [ "$mode" == "lt" ];then where="where $PRIMKEY < $row order by $PRIMKEY desc limit 1;";fi
	if [ "$mode" == "gt" ];then where="where $PRIMKEY > $row order by $PRIMKEY      limit 1;";fi
	erg=$(sql_execute "$db" ".mode line\n.header off\nselect * from $tb $where")
	log debug $mode $row "erg = $erg"
	if [ "$erg" == "" ];then gxmessage -timeout 4 "keine id $mode $row gefunden"  ;return  ;fi
    echo -e "$erg" > "$valuefile"
    echo $row  > $idfile
    cp -f "$valuefile" "$valuefile.bak"
}
function sql_rc_ctrl () {
	log debug $@
	row="$1";shift;export tb="$1";shift;export db="$@"
	IFS="@";marray=($(tb_meta_info "$tb" "$db"));unset IFS
	PRIMKEY=${marray[0]};ID=${marray[1]}
	TNAME=${marray[2]};TTYPE=${marray[3]};TNOTN=${marray[4]};TDFLT=${marray[4]};TLINE=${marray[7]};TSELECT=${marray[8]}
	if [ "$TNAME" == "" ];then return  ;fi
	if [ "$row" == "insert" ]; then
		echo "" > "$valuefile" 
	else
		sql_rc_read eq $PRIMKEY $row > "$valuefile"
	fi
    row_change_xml="$tpath/change_row_${tb}.xml"
#    if [ ! -f "$row_change_xml" ];then gui_rc_get_dialog $row $tb $db $PRIMKEY $TNAME $TLINE  ;fi
    gui_rc_get_dialog $row $tb $db $PRIMKEY $ID $TNAME $TLINE $TNOTN $TSELECT 
	gtkdialog -f "$row_change_xml" & # 2> /dev/null  
}
function sql_rc_back () { sql_rc_read lt $@; }
function sql_rc_next () { sql_rc_read gt $@; }
#function sql_rc_clear () { cp -f "$valuefile" "$valuefile.bak";echo "" > "$valuefile" ; }
function sql_rc_clear () { echo "" > "$valuefile" ; }
function sql_rc_update_insert () {
    set +x
    log $@
	mode=$1;shift;ID="$1";shift;PRIMKEY="$1";shift;TSELECT="$1";shift;TNOTN="$1";shift
#	for arg in "$@";do echo ">" "$arg";done;return 
	local ia=0;local iline="";local uline="";local del="";local val=""
	IFS=",";names=($TSELECT);nulls=($TNOTN);unset IFS
	for ((ia=0;ia<${#names[@]};ia++)) ;do
        val=$(echo "$1" | tr -d '"');shift
#       echo $val
#	    if [ "$val" != "" ] && [ "$val" != "${val//\ /}" ]; then val='"'$val'"';fi # bei leerzeichen hochkomma erforderlich
	    if [ "$val" == "" ] && [ "$nulls[$ia]" != "1" ];    then  val='null';fi
#		echo $val
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
	[ "$erg" == "" ] && erg="$mode erfolgreich" && gxmessage -timeout 3 $erg
	if [ "$mode" == "insert" ];then
		row=$(sql_execute "$db" ".header off\nselect max($PRIMKEY) from $tb;" );
		sql_rc_read eq $PRIMKEY $row
	fi
}
function sql_rc_delete () {
	log $@
	PRIMKEY=$1;shift;ID=$1
#	id=$(tb_get_meta_val $ID)
	yesno "$PRIMKEY=$id wirklich loeschen ?"
	if [ $? -gt 0 ];then gxmessage --timeout 3 "Vorgang abgebrochen";return  ;fi
	erg=$(sql_execute $"$db" "delete from $tb where $PRIMKEY = $ID;")  
	[ "$erg" == "" ] && erg="delete erfolgreich" && gxmessage -timeout 3 $erg
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
	echo -e "$stmt" | sqlite3 "$db" 2> $tpath/sql_error.txt | tr -d '\r' 
	error=$(<$tpath/sql_error.txt)
	if [ "$error" != "" ];then log - "sql_execute $error" $db $stmt;echo $error;fi
}
function sql_read_table ()  {
	log debug $@
	view="$1";shift;off="$1";shift;local tb="$1";shift;local db="$1";shift;where=$(echo $@ | tr -d '"')
	sql_execute $db ".separator |\n.header $off\nselect * from $tb $where;" | tee $tpath/export_${tb}.txt  
	error=$(<$tpath/sql_error.txt);if [ "$error" != "" ];then return;fi
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
	local dfile="$tpath/cd.xml"; [ -f "$dfile" ] && rm "$dfile"
	local cfile="$tpath/cliste.txt";[ -f "$cfile" ] && rm "$cfile";local db=""	
	while [ "$#" -gt "0" ];do
		if   [ -f  "$1" ] && [ "$2" == "--all" ];then
			sql_read_table_parmtb ".header off\n.separator ' '\nselect tb,tb,db from $parmtb where typ = 2 and active = 0 and db = \"$db\";" >> "$cfile" 
			shift
		elif [ -f  "$1" ] && [ "$2" == "!" ];then
		    dblabel=$(basename $1);tblabel=${dblabel%%\.*}
			echo "$tblabel "-" $db" | tr -d '\r' >> "$cfile"
			shift
		elif [ -f  "$1" ];     				then db=$1
		elif [ "$db" == "" ] ;				then
		    sql_read_table_parmtb ".header off\n.separator ' '\nselect tb,tb,db from $parmtb where typ = 2 and active = 0 and tb = \"$1\";"  >> "$cfile" 
		else echo "$1 $1 $db" | tr -d '\r' >> "$cfile" 
		fi
	    shift		
	done
	if [ "$notable" == "$false" ];then echo "tabel $parmtb $parmdb" >> "$cfile";fi
	del="";notebook="<notebook space-expands=\"true\" tab-labels=\""
	local i=0
	while read -r line ;do
		i=$(($i+1))
		tb="${line%%\ *}"
		if [ "$tb" == "helptable" ];then continue;fi
		notebook="$notebook$del$tb";del="|"
	done < "$cfile"
	dfltsel0=".header off\nselect db from $parmtb where typ = 3 and active = 0 and db = "
	dfltsel1=".header off\nselect db,tb from $parmtb where typ = 4 and active = 0 and db = "
	dfltsel2=".header off\nselect value from $parmtb where typ = 5 and active = 0 and db = "
    str="_____";del="";label2="";for ((ia=1;ia<11;ia++)) ;do label2=$label2$del$str$ia$str;del="|";done
	if [ "$i" -gt "1" ];then echo $notebook"${del}table\">" > "$dfile";fi
	while read -r line;do		
		tblabel="${line%%\ *}";db="${line#*\ }";tb="${db%%\ *}";db="${db##*\ }"  
		if [ "$tb" == "helptable" ];then continue;fi
        dfltdb=$(sql_read_table_parmtb "$dfltsel0 \"$db\" and label = \"$tblabel\" limit 1;") 
 		if [ "$dfltdb" == "error" ]  ;then log "-" "error defaultdb $line";continue;fi
		eval  "export CBOXDBSEL$tblabel=\$dfltdb";
        dflttable=$(sql_read_table_parmtb "$dfltsel1 \"$db\" and label = \"$tblabel\" limit 1;") 
 		if [ "$dflttable" == "error" ]  ;then log "-" "error defaulttable $line";continue;fi
        db2="${dflttable%%\,*}";dflttable="${dflttable##*\,}" 
		eval  "export CBOXENTRY$tblabel=\$dflttable";
		dfltwhere=$(sql_read_table_parmtb "$dfltsel2 \"$db\" and label = \"$tblabel\" limit 1;"| tr -d '"')
		if [ "$dfltwhere" == "error" ]  ;then log "-" "error defaultwhere $line";continue;fi
		eval  "export CBOXWHERE$tblabel=\$dfltwhere";
        IFS="@";marray=($(tb_meta_info "$dflttable" "$db2"));unset IFS
        pk="${marray[0]}";label=$(echo "${marray[2]}"| tr ',' '|')
        if [ "$tblabel" == "tabel" ];then tb="-";fi
        if [ "$tb"      == "-" ];    then label=$label2;fi
		gui_tb_get_dialog "$dfltdb" "$tblabel" "$tb" "$dflttable" "$dfltwhere" "$label">> "$dfile" 
	done < "$cfile"
	if [ "$i" -gt "1" ];then echo "</notebook>" >> "$dfile";fi
	log  start gtkdialog -f $dfile
	gtkdialog  -f "$dfile"
}
function tb_db_names_user () {
	log debug $@ 
	local db="";local refresh=$1;shift;local dbsave=""
	if [ "$#" -lt "1" ]; then  where=";"; else where="and db = \"$@\";";fi
	sql_read_table_parmtb ".headers off\nselect distinct db from $parmtb where typ = 1 and active = 0 $where" > $tpath/dblist.txt
    export defaultdbsel=$(head -1 $tpath/dblist.txt)
	[ -f $tpath/nameslist.txt ] && rm $tpath/nameslist.txt
	[ -f $tpath/stmtlist.txt ] && rm $tpath/stmtlist.txt
	while read -r db; do
		tables=$(echo -e ".table" | sqlite3 $db) 
		for tb in $tables;do
			if [ "$tb" == "" ];then continue  ;fi
			echo $db $tb >> $tpath/nameslist.txt
		done
		if [ "$refresh" == "$true" ];then
			echo -e "delete from $parmtb where typ in (2) and db = \"$db\";" | sqlite3 $parmdb
		fi 	
	done < $tpath/dblist.txt
	log debug $@ 
	sql_read_table_parmtb "select typ,db,tb from $parmtb where typ in (2,3,4,5);" | tr -d '"' > $tpath/default.txt
	sql_read_table_parmtb ".headers off\n.separator ' '\nselect db,tb from $parmtb where typ = 2;" > $tpath/nameslist2.txt
	diff $tpath/nameslist.txt $tpath/nameslist2.txt |
	while read -r line;do
	    set -- $line;mode=$1;shift;db=$1;shift;tb=$1;shift
	    if [ "$mode" != "<" ] && [ "$1" != ">" ] ;then continue ;fi
#	    erg=$($(which rowchange) "info" "$tb" "$db");pk="${erg%%\ *}"
	    IFS="@";marray=($(tb_meta_info "$tb" "$db"));unset IFS;pk="${marray[0]}"
	    if [ "$pk" == "-" ]; 
	        then log $db $tb hat keinen primarykey;where="limit 150"
	        else where="where $pk >= 0 limit 150"
	    fi
	    if [ "$db" != "$dbsave" ]; then
			dblabel=$(basename $db);dblabel=${dblabel%%\.*}
			dbsave=$db
			sql_get_stmt 3 "(0)"    "$db" "$db" "$dblabel" "defaultdb"    "batch"   >> $tpath/stmtlist.txt
			sql_get_stmt 4 "(0)"    "$db" "$tb" "$dblabel" "defaulttable" "batch"	>> $tpath/stmtlist.txt
			sql_get_stmt 5 "(0)"    "$db" "$tb" "$dblabel" "$where" 	  "batch"	>> $tpath/stmtlist.txt
		fi
	    sql_get_stmt 2 "(0,1)"  "$db"  "$tb" ""     ""            "batch" 			>> $tpath/stmtlist.txt
	    sql_get_stmt 3 "(0)"    "$db"  "$db" "$tb" "defaultdb"    "batch" 			>> $tpath/stmtlist.txt
	    sql_get_stmt 4 "(0)"    "$db"  "$tb" "$tb" "defaulttable" "batch" 			>> $tpath/stmtlist.txt
	    sql_get_stmt 5 "(0)"    "$db"  "$tb" "$tb" "$where" 	  "batch"  			>> $tpath/stmtlist.txt
	done
	log debug $@ 
	sql_get_stmt 3 "(0)" "$parmdb" "$parmdb"  "tabel" "defaultdb"    "batch" 		>> $tpath/stmtlist.txt
	sql_get_stmt 4 "(0)" "$parmdb" "$parmtb"  "tabel" "defaulttable" "batch" 		>> $tpath/stmtlist.txt
	sql_get_stmt 5 "(0)" "$parmdb" "$parmtb"  "tabel" "where id >= 0 limit 150" "batch" >> $tpath/stmtlist.txt
	if [ ! -f $tpath/stmtlist.txt  ];then return ;fi
	grep "insert" $tpath/stmtlist.txt > $tpath/sqlread.txt
	err=$(sql_read_table_parmtb ".read \"$tpath/sqlread.txt\"")
	if [ "$err" != "" ];then log "-" tb_db_names_user $err ;fi
}
function tb_get_meta_val   () {
	nr=$1 #;nr2=$(($nr+1))
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
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}"
	export tpath="/tmp/${folder%%\.*}"  
	[ ! -d "$path" ]  && mkdir "$path"  
	[ ! -d "$tpath" ] && mkdir "$tpath"  
	export x_configfile="$path/.configrc"   
	export parmtb="parmneu" true=0 false=1
	export lfile="/honme/uwe/log/gtkdialog.txt" logdebug=$true logverbose=$true 
    tmpmodus=$false;master="/home/uwe/my_databases/parmtb.sqlite"	
    if [ "$tmpmodus" == "$true" ];then	  
	    [ ! -f "$tpath/$(basename $master)" ] && cp "$master" "$tpath"
	    master="$tpath/parmtb.sqlite" 
	fi
	export parmdb="$master" 
	export -f log  tb_db_names_user tb_meta_info
	export -f sql_read_table  sql_execute sql_read_table_parmtb sql_get_where
##
	export changexml="$tpath/change.xml" idfile="$tpath/id.txt" tmpf="$tpath/dialogtmp.txt"
	export tableinfo="$tpath/tableinfo.txt"  valuefile="$tpath/value.txt"
	export -f sql_rc_ctrl   sql_rc_clear   sql_rc_delete   sql_rc_read
	export -f gui_rc_get_dialog gui_rc_entrys_action_refresh gui_rc_entrys_hbox gui_rc_entrys_variable_list
	export -f tb_meta_info tb_get_meta_val log yesno sql_execute sql_rc_update_insert
	export TNAME="" TTYPE="" TNOTN="" TDFLT="" TPKEY="" TLINE="" TSELECT=""
##
#    if [ "$#" == "0" ];then set -- "sql_rc_ctrl" "3" "genre" "/root/my_databases/mymusic.sqlite" ;fi  
#    if [ "$#" == "0" ];then set --  "/root/my_databases/info.sqlite" "--all"  "$parmdb" "$parmtb";fi  
    if [ "$#" == "0" ];then set --  "$parmdb" "$parmtb";fi  	
    log "----";log "----";log "----";log "----";log logon
	if [ "$1" == "sql_rc_ctrl" ];then shift;sql_rc_ctrl $@;log logoff;exit ;fi  
	refresh=$false;notable=$false;parm=""
	while [ "$#" -gt 0 ];do
        if   [ "$1" == "--refresh" ]; then refresh=$true 
        elif [ "$1" == "--notable" ]; then notable=$true 
		else parm="$parm $1"
		fi
		shift
	done
	if [ ! -f "$tpath/refreshed.txt" ];then refresh=$true;touch "$tpath/refreshed.txt" ;fi
    tb_db_names_user $refresh #;exit
	tb_create_dialog $parm
	log logoff  

