#!/bin/bash
	source /home/uwe/my_scripts/my_functions.sh

/home/uwe/my_scripts/dbms.sh --func ctrl_manage_tb
exit

function create_tb () {

	db="$1";tb="$2" 
##### create tmp table to store table-info
	crtb="edit_$tb"
	echo "drop table if exists $crtb;" > $tmpf2  
	echo "create table   $crtb ( " \
	     "crtb_id        integer primary key autoincrement not null unique," \
	     "pos            integer not null," \
	     "field          text	 not null unique," \
	     "type           text    not null default \"text\"," \
	     "nullable       text,	 default_value  	text,	primarykey   text," \
	     "auto_increment text,	 isunique		text,	ixname		 text," \
	     "ref_field		 text,	 ref_table 	    text,	on_delete  	 text,	on_update   	 text);" >> $tmpf2  
	echo "insert into $crtb (pos,field,type,nullable,default_value,primarykey) values" >> $tmpf2
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
		echo "${delim}(${nline})" >> $tmpf2 
		delim=","
	done 
	echo ";" >> $tmpf2
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
		echo "update $crtb $stmt where field=\"${arr[5]}\";" >> $tmpf2
	done 
	echo "update $crtb set auto_increment = \"autoincrement\" where primarykey = 'primary key' and type = 'integer';" >> $tmpf2
###	foreign key info
	func_sql_execute "$db" "pragma foreign_key_list($tb)" |  tr '[:upper:]' '[:lower:]' |
    while read line; do
		IFS=",";arr=($line) 
		echo "update $crtb set ref_table = \"${arr[2]}\", ref_field = \"${arr[4]}\"," \
			 "on_update = \"${arr[5]}\", on_delete = \"${arr[6]}\" where field = \"${arr[3]}\";" >> $tmpf2
	done  
	setmsg -i pause
    func_sql_execute "/home/uwe/my_databases/parm.sqlite" ".read $tmpf2"
    if [ "$?" -gt "0" ];then return 1;fi
##### user action
	dbms.sh "/home/uwe/my_databases/parm.sqlite" $crtb "--notable" 1> /dev/null
##### create file for .read
	echo "-- "
	echo "    create table $tb ("
	export del="   "
	[ -f "$tmpf2" ] && rm $tmpf2
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
	db="$1";tb=$2;func="$3";true=0;false=1
#	db="/home/uwe/my_databases/test.sqlite";tb="mytable_neu";func="edit"
	db="/home/uwe/my_databases/music.sqlite";tb="track";nfunc="edit"
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
	import="/home/uwe/.dbms/import/my_table.csv"
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
			echo "	drop table   if     exists ${tb}_copy;" 		>  $tmpf
			echo "	alter table $tb rename to ${tb}_copy;"	>> $tmpf
		fi
		if [ "$drop" = "$true" ]; then echo "	drop table   if     exists $tb;" >> $tmpf;fi
		if [ "$edit" = "$true" ]; then		
			create_tb "$db" "$tb" 								>> $tmpf
		else
			echo  ".schema $tb" | sqlite3 $db 					>> $tmpf 
		fi
		if [ "$newtable" != "$true" ];then 
			echo "	insert into $tb  ($TSELECT) " 				>> $tmpf
			echo "	select            $TSELECT " 				>> $tmpf
			echo "	from ${tb}_copy;" 							>> $tmpf
		fi
		xdg-open $tmpf
		setmsg -q "$tmpf ausfuehren?" 
		if [ "$?" = "1" ];then 
			if [ "$newtable" = "$true" ];then func_sql_execute "$db" "drop table if exists $tb;";exit ; fi
			setmsg -n Abbruch;exit
		else	
			echo ".read $tmpf" | sqlite3 $db
		fi
		setmsg -q "${tb}_copy loeschen?" 
		if [ "$?" = "0" ];then echo "drop table if exists ${tb}_copy;" | sqlite3 $db  ;fi
	fi
	
