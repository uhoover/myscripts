#!/bin/bash
	source /home/uwe/my_scripts/my_functions.sh
	set -o noglob
function test_local () {
	local var1="init1" var2="init2"
#	var=$1
	echo func $var1 $var2
#	var1="done1";var2="done2"
}
function test_tee () {
	i=3
	( 	case "$i" in
		1)	echo -e "line11 \nline21";;
		2)	echo -e "line12 \nline22";;
		3)	echo -e "line13 \nline23";;
		*)  echo -e "line1x \nline2x"
		esac
	) | tee /tmp/grep.txt | 
	    grep    line2  
	    grep -v line2 /tmp/grep.txt 
#	) | tee /dev/tty | grep   line2 | grep -v line2
}
function read_to_array () {
	declare -a myarray
    ( echo line1
      echo line2
      echo line3) > /tmp/grep.txt
    readarray myarray < /tmp/grep.txt
    declare -p myarray
    if   [ "%cursor"% = "" ]; then
	elif [ "%cursor"% = "" ]; then
	else
	fi

}
	read_to_array
	exit
	var1="start1";var2="start2"
	test_local 
	echo call $var1 $var2	
	exit 
# /home/uwe/my_scripts/dbms.sh --func ctrl_manage_tb  /home/uwe/my_databases/testneu.sqlite third import
#	db="/home/uwe/my_databases/parm.sqlite";tb="rules";field="\"rules_type\""
	db="/home/uwe/my_databases/parm.sqlite";tb="rules";field="rules_type"
	tmpf="/tmp/create_tb.txt"
	sql_execute $db ".mode line\nselect * from $tb where rules_db = \"$db\" and rules_tb = \"$tb\" and rules_field = \"$field\"" > $tmpf
	while read -r line;do
		# func="$1";db1="$2";tb1="$3";field1="$4";db2="$5";tb2="$6";cmd1="$7";cmd2="$8"
		found=$true
#		value=$(trim_simple ${line#*=});field=$(trim_simple field=${line%=*})
		set -- $line;field=$1;value=$3
		echo ">$field< >$value<"
		case $field in
			rules_type)   FUNC=$value	;;
			rules_db_ref) 	SDB=$value	;;
			rules_tb_ref) 	TDB=$value	;;
			rules_action) 	SCMD1=$value;ACTION=$value	;;
			rules_col_list) SCMD2=$value	;;
		esac
	done < $tmpf
	echo "FUNC $FUNC SDB $SDB TDB $TDB  SCMD1 $SCMD1 SCMD2 $SCMD2 ACTION $ACTION"
 exit
function is_database () { file -b "$*" | grep -q -i "sqlite"; }
function is_table () {	
	if [ "$#" -lt "2" ];then return 1;fi 
	is_database "$1"; if [ "$?" -gt "0" ];then return 1;fi
	tb=$(sql_execute "$1" ".table $2")
	if [ "$tb" = "" ];then return 1;else return 0;fi
}
function func_import () {
	db="$1";tb="$2";file="$3";func="";local delim="$5";tbcopy="${tb}_tmp"
	readfile="/home/uwe/tmp/readfile.txt"
	echo ".separator $delim"				>   "$readfile"
	hl=$(head $file -n 1 | tr [:upper:] [:lower:])
	set +x
	is_table "$db" "$tb";istable=$?
	if [ "$istable" = "$false" ]; then
		func='import'
	else
		func_tb_meta_info "$db" "$tb"
		il=$(echo $TSELECT | tr ',' "$delim" | tr [:upper:] [:lower:])
		rl=$(echo $TNAME   | tr ',' "$delim" | tr [:upper:] [:lower:]) 
		zhl="${#ahl[@]}";zil="${#ail[@]}";zrl="${#arl[@]}";
	fi
	if [ "$hl" != "$il" ] && [ "$hl" != "$rl" ]; then
	    setmsg -q "has header $file ?"
	    hasheader=$?
	else
		hasheader=$true
	fi
	IFS="$delim";ahl=( $hl );ail=( $il );arl=( $rl );unset IFS
	zhl="${#ahl[@]}";zil="${#ail[@]}";zrl="${#arl[@]}";
	if  [ "${hl:${#hl}-1:1}" = "$delim" ];then zhl=$(($zhl+1))  ;fi ## last empty element not count
	if   [ "$func"   = "import" ]; 	then nop
	elif [ "$hl"     = "$il" ];    	then func="insert" 
	elif [ "$zhl"    = "$zil" ];   	then func="insert" 
	elif [ "$hl"     = "$rl" ]; 	then func="update" 
	elif [ "$zhl"    = "$zrl" ];   	then func="update"  
	else								 msg="cannot handle $file";return 				 
	fi
	if [ "$hasheader" = "$true" ]; then
		if 	[ "$func" = "insert" ] || [ "$func" = "update" ];then
			echo "--need file without header new file: $tmpf" >> $readfile
			tail +2 "$file" > "$tmpf";file="$tmpf"
		fi
	else
		if 	[ "$func" = "insert" ]; then
			echo "--need file with header $tmpf" >> $readfile
			nline="";del=""
			for ((ia=0;ia<${#ahl[@]};ia++)) ;do nline=$nline$del'col-'$ia;del=$delim;done
			echo "$nline" > $tmpf;cat "$file" >> "$tmpf";file="$tmpf"
		fi
	fi
	if   [ "$func"   = "import" ]; 	then
		echo ".import \"$file\" $tb"			>>  "$readfile"
	elif [ "$func"   = "insert" ]; 	then
		echo "	drop table if exists tmpiu;"	>>  "$readfile"
		echo ".import \"$file\" tmpiu"			>>  "$readfile"
		echo "	insert into $tb ($TSELECT)"		>>  "$readfile"
		echo "	select * from tmpiu;"			>>  "$readfile"
	else
		echo ".import \"$file\" $tbcopy"		>>  "$readfile"
		echo "	insert or replace into $tb"		>>  "$readfile"
		echo "	select $line"					>>  "$readfile"
		echo "	from $tbcopy as b join $tb as a on b.$PRIMKEY = a.$PRIMKEY;"	>>  "$readfile"
		echo "--  "								>>  "$readfile"
		echo "	insert into $tb as a  " 		>>  "$readfile"
		echo "	select $line" 					>>  "$readfile"
		echo "	from $tbcopy as b"				>>  "$readfile"
		echo "	where b.${PRIMKEY} in ("		>>  "$readfile"
		echo "	select  a.${PRIMKEY} from $tbcopy as a "	>>  "$readfile"
		echo "	left join $tb as b  "			>>  "$readfile"
		echo "	on a.${PRIMKEY} = b.${PRIMKEY}"	>>  "$readfile"
		echo "	where b.${PRIMKEY} is null);"	>>  "$readfile"
	fi
}
function func_import_alt () {
	db="$1";tb="$2";file="$3";func="$4";local delim="$5";tbcopy="${tb}_tmp"
	readfile="/home/uwe/tmp/readfile.txt"
	echo ".separator $delim"				>   "$readfile"
	is_table "$db" "$tb"
	if [ "$?" -gt "0" ]; then
		func="insert"
		if 	[ "$hl"  = "$il"  ]; then 
			hasheader=$false
		else
			setmsg -q "first line = header"
			hasheader=$?
		fi
		if [ "$hasheader" = "$true"]; then 
			echo "--need file with header $tmpf" >> $readfile
			echo "$il" > $tmpf;cat "$file" >> "$tmpf";file="$tmpf"
		fi
	else
		func_tb_meta_info "$db" "$tb"
		hl=$(head $file -n 1 | tr [:upper:] [:lower:])
		il=$(echo $TSELECT | tr ',' "$delim" | tr [:upper:] [:lower:])
		rl=$(echo $TNAME   | tr ',' "$delim" | tr [:upper:] [:lower:]) 
		IFS="$delim";ahl=( $hl );ail=( $il );arl=( $rl );unset IFS
		zhl="${#ahl[@]}";zil="${#ail[@]}";zrl="${#arl[@]}";
		if  [ "${hl:${#hl}-1:1}" = "$delim" ];then zhl=$(($zhl+1))  ;fi ## last empty element not count
		if 	 [ "$zhl" = "$zil" ]; then func="insert" 
		elif [ "$zhl" = "$zrl" ]; then 
			func="update"
			if 	[ "$hl"  = "$rl"  ]; then 
				hasheader=$true
			else
				setmsg -q "first line = header"
				hasheader=$?
			fi
			if [ "$hasheader" = "$true"]; then 
				echo "--need file without header $tmpf" >> $readfile
				tail +2 "$file" > "$tmpf";file="$tmpf"
			fi
		else    setmsg -i "cannot handle $file\ncolumn expected for insert $zil\ncolumn expected for update $zil\nfound $zhl";return 1   
		fi
	fi
 	if [ "$func" = "update" ]; then
		del="";line="";for ((ia=0;ia<${#arl[@]};ia++)) ;do line="$line${del}b.${arl[$ia]}";del=",";done
#		echo "drop table if exists tmp;"  		>>  "$readfile"
#		echo ".import $file tmp"				>>  "$readfile"
		echo "	drop table if exists $tbcopy;"  	>>  "$readfile"
		sql_execute "$db" ".schema $tb" | tr [:upper:] [:lower:] |
		while read -r line;do
			erg=$(echo $line | grep 'create' | grep 'table')
			if [ "$erg" = "" ]; then
				nline=$line
			else
				nline=${line//$tb/$tbcopy}
			fi
			zline=${nline%%\;*}
			if [ "$nline" != "$zline" ];then 
				echo "$zline ;" 				>>  "$readfile"
				break
			else 
				echo $nline  					>>  "$readfile"
			fi
		done
#		echo "insert into $tbcopy select * from tmp;"	>>  "$readfile"
		echo ".import \"$file\" $tbcopy"			>>  "$readfile"
		echo "	insert or replace into $tb"		>>  "$readfile"
		echo "	select $line"						>>  "$readfile"
		echo "	from $tbcopy as b join $tb as a on b.$PRIMKEY = a.$PRIMKEY;"	>>  "$readfile"
		echo "--  "								 >>  "$readfile"
		echo "	insert into $tb as a  " 		>>  "$readfile"
		echo "	select $line" 					>>  "$readfile"
		echo "	from $tbcopy as b"				>>  "$readfile"
		echo "	where b.${PRIMKEY} in ("		>>  "$readfile"
		echo "	select  a.${PRIMKEY} from $tbcopy as a "	>>  "$readfile"
		echo "	left join $tb as b  "			>>  "$readfile"
		echo "	on a.${PRIMKEY} = b.${PRIMKEY}"	>>  "$readfile"
		echo "	where b.${PRIMKEY} is null);"	>>  "$readfile"
	else
		echo "	drop table if exists tmpiu;"	>>  "$readfile"
		echo ".import \"$file\" tmpiu"			>>  "$readfile"
		echo "	insert into $tb ($TSELECT)"		>>  "$readfile"
		echo "	select * from tmpiu;"			>>  "$readfile"
	fi
}
function create_tb () {

	db="$1";tb="$2" 
##### create tmp table to store table-info
	crtb="edit_$tb"
	echo "drop table if exists $crtb;" > $tmpf  
	echo "create table   $crtb ( " \
	     "crtb_id        integer primary key autoincrement not null unique," \
	     "pos            integer not null," \
	     "field          text	 not null unique," \
	     "type           text    not null default \"text\"," \
	     "nullable       text,	 default_value  	text,	primarykey   text," \
	     "auto_increment text,	 isunique		text,	ixname		 text," \
	     "ref_field		 text,	 ref_table 	    text,	on_delete  	 text,	on_update   	 text);" >> $tmpf  
	echo "insert into $crtb (pos,field,type,nullable,default_value,primarykey) values" >> $tmpf
###	table info
	func_sql_execute "$db" "pragma table_info($tb)" |  tr '[:upper:]' '[:lower:]' |
	while read -r line;do
	    IFS=",";fields=( $line );unset IFS;nline="";del=""
	    for ((ia=0;ia<${#fields[@]};ia++)) ;do
			arr=$(echo ${fields[$ia]} | tr -d '"' | tr -d "'")
			if [ "$arr" = "0" ] && [ "$ia" != "0" ] ;then arr=""  ;fi
			case "$ia" in
				3)		if [ "$arr"  = "1" ];then  arr="not null" ;fi;;
				5)	    if [ "$arr"  = "1" ];then  arr="primary key";fi;;
				*)  
			esac
			nline="$nline$del\"$arr\"";del=","
		done
		echo "${delim}(${nline})" >> $tmpf 
		delim=","
	done 
	echo ";" >> $tmpf
	set -x
###	index info
	func_sql_execute "$db" "pragma index_list($tb)" |  tr '[:upper:]' '[:lower:]' |
    while read line; do
		IFS=",";arr=($line);printf "${arr[1]},${arr[2]},${arr[3]},"
		func_sql_execute "$db" "pragma index_info(${arr[1]})" |  tr '[:upper:]' '[:lower:]'  
	done |	
    while read line; do
		IFS=",";arr=($line);unset IFS;del=","
		stmt="set"  
		if [ "${arr[0]:0:16}" != "sqlite_autoindex" ];then  stmt="set ixname=\"${arr[0]}\"";else stmt="set";del=" ";fi
		if [ "${arr[2]}" = "u" ];then  stmt="${stmt}${del}isunique=\"unique\"";del=",";fi
		echo "update $crtb $stmt where field=\"${arr[5]}\";" >> $tmpf
	done 
	echo "update $crtb set auto_increment = \"autoincrement\" where primarykey = 'primary key' and type = 'integer';" >> $tmpf
###	foreign key info
	func_sql_execute "$db" "pragma foreign_key_list($tb)" |  tr '[:upper:]' '[:lower:]' |
    while read line; do
		IFS=",";arr=($line) 
		echo "update $crtb set ref_table = \"${arr[2]}\", ref_field = \"${arr[4]}\"," \
			 "on_update = \"${arr[5]}\", on_delete = \"${arr[6]}\" where field = \"${arr[3]}\";" >> $tmpf
	done  
	setmsg -i pause
    func_sql_execute "/home/uwe/my_databases/parm.sqlite" ".read $tmpf"
    if [ "$?" -gt "0" ];then return 1;fi
    droptb="$droptb $crtb"
##### user action
	dbms.sh "/home/uwe/my_databases/parm.sqlite" $crtb "--notable" 1> /dev/null
##### create file for .read
	echo "-- "
	echo "    create table $tb ("
	export del="   "
	[ -f "$tmpf" ] && rm $tmpf
	stmt="select field,type,primarykey,auto_increment,nullable,isunique,default_value,
		 ixname,ref_table,ref_field,on_delete,on_update,pos from $crtb;"  
	func_sql_execute "/home/uwe/my_databases/parm.sqlite" $stmt  |  tr -d '"' |
	while read -r line;do
		IFS=",";fields=( $line );unset IFS;nline="$del";if [ "$nline" = "" ];then nline="       "  ;fi
	    for ((ia=0;ia<${#fields[@]};ia++)) ;do
			arr=$(echo ${fields[$ia]})  
			case "$arr" in
				 null)			arr='' ;;
				 "no action")	arr='' ;;
				*)  
			esac
			case "$ia" in
				6)	   if [ "$arr"  != "" ];then  arr="default \"$arr\"";fi;;
				7)	   if [ "$arr"  != "" ];then
						   if [ "${fields[5]}"  != "" ];then  
								echo "create#unique#index#$arr ${fields[0]}" >> $tmpf2 
						   else echo "create#index#$arr ${fields[0]}" >> $tmpf2
						   fi
						   continue
					   fi;;
				8)	   if [ "$arr"  != "" ];then
							echo "foreign#key#${fields[8]}|$(right -t ${fields[12]} -l 4 -p '0')|${fields[0]}|${fields[8]}|${fields[9]}|${fields[10]}|${fields[11]}" >> $tmpf2
					   fi
					   break;; 				   
				*)  
			esac
			nline="$nline $arr";del="      ,"
		done
		echo "  "$(echo $nline | tr -s ' ')
	done
	if 	[ -f  "$tmpf2" ];then  
		[ -f "${tmpf2}.bak" ] && rm "${tmpf2}.bak" 
		grep "foreign#" "$tmpf2" | sort   > "${tmpf2}.bak" 	
		if 	[ -f  "${tmpf2}.bak" ];then 
			nline="";old="";reftb="";from="";to="";ondelete="";onupdate=""
			while read -r line;do
				IFS='|';fields=($line);unset IFS
				if [ "${fields[0]}"  != "$old" ];then
					if [ "$from" != "" ];then  echo "  ,foreign key(${from}) references ${reftb}(${to}) $ondelete $onupdate "  ;fi
					from="${fields[2]}";reftb="${fields[3]}";to="${fields[4]}"
					if [ "${fields[5]}" != "" ] && [ "${fields[5]}" != "no action" ];then ondelete="on delete ${fields[5]}" ;else ondelete="" ;fi
					if [ "${fields[6]}" != "" ] && [ "${fields[6]}" != "no action" ];then onupdate="on update ${fields[6]}" ;else onupdate="" ;fi
					old="${fields[0]}"
				else
					from="${from},${fields[2]}"
					to="${to},${fields[4]}"
				fi 
			done < "${tmpf2}.bak"
		fi
		if [ "$from" != "" ];then  echo "  ,foreign key(${from}) references ${reftb}(${to}) $ondelete $onupdate "   ;fi
	fi
	echo "	);"
	nline="";old=""
	grep "create#" "$tmpf2" | sort   > "${tmpf2}.bak" 
	while read -r line;do
		fields=($line)
		if [ "${fields[0]}"  != "$old" ];then
			old="${fields[0]}"
			if [ "$nline" != "" ];then echo "	drop index if exists ${old##*\#};"; echo "	${nline});" | tr '#' ' ' ;fi
			nline="${fields[0]} on ${tb}(""${fields[1]}"
		else
			nline="${nline},${fields[1]}"
		fi 
	done < "${tmpf2}.bak"
	if [ "$nline" != "" ];then  echo "	drop index if exists ${old##*\#};";echo "	${nline});"  | tr '#' ' '  ;fi
### trigger info
	echo "select sql from sqlite_master where type = \"trigger\" and tbl_name = \"$tb\";"  | 
		sqlite3 "$db" |  tr -d '\r' |  tr -d '"' | tr '[:upper:]' '[:lower:]'  
	echo "--"
}
	db="$1";tb=$2;func="$3";true=0;false=1;msg="";droptb=""
#	db="/home/uwe/my_databases/test.sqlite";tb="mytable_neu";func="edit"
	db="/home/uwe/my_databases/test.sqlite";tb="composer";func="import"
	if [ "$func" = "" ]; then func=$(zenity --list --column action "drop" "schema" "modify" "new_table" "import");fi
	if [ "$(echo $func | grep 'drop')"	 	!= "" ]; 	then drop=$true;				else drop=$false;	fi 
	if [ "$(echo $func | grep 'schema')" 	!= "" ]; 	then create=$true;				else create=$false;	fi 
	if [ "$(echo $func | grep 'modify')"	!= "" ]; 	then edit=$true;create=$true;	else edit=$false;	fi 
	if [ "$(echo $func | grep 'new_table')" != "" ]; 	then tb=$(zenity --text "enter table name" --entry) ;fi 
	if [ "$(echo $func | grep 'new_table')" != "" ]; 	then edit=$true;create=$true;newtable=$true;	else edit=$false;newtable=$false;fi 
	if [ "$(echo $func | grep 'import')" != "" ]; 		then import=$true;	else import=$false;	fi 
	if [ "$db" = "" ];then db=$(dbms.sh --func get_fileselect parm_value searchpath database --save);fi
	if [ "$db" = "" ];then setmsg -n "abort..no db selected"; exit ;fi
	if [ -f "$db" ] && [ "$tb" = "" ]; then tb=$(zenity --text "neu ueberschreiben " --list --editable --column tabelle $(echo ".tables" | sqlite3 $db) "new");fi 
	if [ "$tb" = "" ] || [ "$tb" = "new" ];then tb=$(zenity --text "neue Tabelle" --entry) ;fi
	if [ "$tb" = "" ];then setmsg -n "abort..no tb selected"; exit ;fi
	tmpf="/tmp/create_tb.txt"
	tmpf2="/tmp/create_tb2.txt"
	ifile="/home/uwe/tmp/create_tb.txt"
	if [ "$import" = "$true" ]; then
		func_import "$db" "$tb" "$ifile" "$func" "|"
	fi
	if [ "$create" = "$true" ]; then
		found=$(echo ".tables $tb" | sqlite3 $db)
		if [ "$found" = "" ]; then
			func_sql_execute "$db" "create table $tb (${tb}_id  integer primary key autoincrement not null unique,${tb}_name	text);"
			edit=$true
		else
			newtable=$false
		fi
		func_tb_meta_info $db $tb;TINSERT=$TSELECT
		if [ "$newtable" != "$true" ];then 
			echo "	drop table   if     exists ${tb}_copy;" 	>  $readfile
			echo "	alter table $tb rename to ${tb}_copy;"		>> $readfile
		fi
		if [ "$drop" = "$true" ]; then echo "  drop table if exists $tb;" >> $readfile;fi
		if [ "$edit" = "$true" ]; then		
			create_tb "$db" "$tb" 								>> $readfile
		else
			echo  ".schema $tb" | sqlite3 $db 					>> $readfile 
		fi
		if [ "$newtable" != "$true" ];then 
			echo "	insert into $tb  ($TSELECT) " 				>> $readfile
			echo "	select            $TSELECT " 				>> $readfile
			echo "	from ${tb}_copy;" 							>> $readfile
		fi
	fi
	if [ "$msg" != "" ];then setmsg -i "$msg";exit ;fi
	xdg-open $readfile
	setmsg -q "$readfile ausfuehren?" 
	if [ "$?" = "1" ];then 
		setmsg -n "job canceld"
	else	
		echo ".read $tmpf" | sqlite3 $db
	fi
	setmsg -q "delete ${droptb ?" 
	if [ "$?" = "1" ];then return; fi
	for tb in $droptb ;do  echo "drop table if exists ${tb};" | sqlite3 $db  ;done
