#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: kontext-aktion aus geany
#
	set -o noglob
 source /home/uwe/my_scripts/my_functions.sh
	parmfile="$HOME/clipparm.txt"
#	echo "parmdb=\"/home/uwe/my_databases/music.sqlite\"" > "$parmfile"
#	echo "logfile=\"/tmp/parm.log\"" >> "$parmfile"
#   select * from import where rowid < 10;
	[ ! -f "$parmfile" ] && echo "pdb=\"/home/uwe/my_databases/music.sqlite\"" > "$parmfile"
	[ -f "$parmfile" ] && source "$parmfile"
#
function aexit() {
	retcode=0 
}
	trap aexit EXIT
#	set -e  # bei fehler sprung nach xexit
# 	select * from composer limit 10
function ctrl () {
#  .headers on\nselect * from track where track_id < 10;  
	local func="" cmd="" db="" tb=""
	tmpf="/tmp/parm.txt"
	tmpf2="/tmp/parm2.txt"
	[ -f "$tmpf" ] && rm $tmpf
	[ -f "$tmpf2" ] && rm $tmpf2
	xclip -o > "$tmpf" 2> /dev/null 
	parm=$(<"$tmpf")
#	[ $? -gt 0 ] && setmsg -n no data in clipboard && return
	[ "$parm" = "" ] && parm=".headers on\nselect * from track limit 10;"
	func=$(echo ${parm%% *} |  tr '[:upper:]' '[:lower:]')
	case $func in
		 select|update|insert|delete|reload|.*) cmd="sql_execute $pdb $parm";;
		 sql_execute|func_sql_execute) cmd=$parm;;
	esac
	if [ "$cmd" = "" ]; then
		command -v $func >/dev/null
		[ $? -eq 0 ] && cmd=$parm && type='cmd'
	fi
	if [ "$cmd" = "" ]; then
		set -- $parm
		while [ $# -gt 0 ];do 
			[ "$1" = "sqlite" ] && db=$2 && shift
			[ "$1" = "from" ] 	&& tb=$2 && break
			shift
		done
		setmsg -i "db $db\ntb $tb"
		if [ "$db" != "" ] && [ "$tb" != "" ];then
		   tail -n +2 $tmpf | head -n -1 > $tmpf2
		   /home/uwe/my_scripts/dbms.sh --func utils_ctrl "$db" "$tb" import "$tmpf2"
		   return
		fi
	fi
	if [ "$cmd" = "" ]; then
		/home/uwe/my_scripts/dbms.sh --func utils_ctrl "$pdb" "$ptb" "" "$tmpf"
		return
	fi
	dn=$(date "+%Y%m%d%H%M%S")
	di=$((99999999999999-$dn))
	lfile="/home/uwe/log/rs.sh"
	if [ "$type" = "cmd" ]; then
		echo "x_${di}_${dn} () { # $cmd" >> "$lfile" 	
	else
		echo "rs_${di}_${dn} () { # sqlite $pdb $cmd" >> "$lfile" 	
	fi
#	setmsg -i "$LINENO $FUNCNAME pause"
	$cmd >> "$lfile"
	urxvt -e bash -c "cat $lfile;read -p 'press enter to continue'"
#	urxvt -e bash -c $cmd | while read line;do echo "$line" >> "$lfile";echo $line;done    
#	urxvt -e bash -c $cmd | while read line;do echo "$line" >> "$lfile";echo $line ;done;read -p ' weiter mit taste'   
	str=$(log logoff);estr=$(echo $str | tr -d '\n')
	echo "} # $estr" >> "$lfile"
	set +x
	return
#	[ "$parm" = "" ] && parm=$(<$tmpf | tr '\n' ' ')
	if [ "$#" -lt "1" ];then read erg < $tmpf; set -- $erg ;fi
	if [ "$#" -lt "1" ] || [ "$*" = "" ];then log "Abbruch: keine Parameter";exit ;fi
	erg=$(wc -l $tmpf) 
	zl=${erg%%\ *}
	erg=$1;func=$(echo ${erg%%[\ \,\;]*} | tr [:upper:] [:lower:])  
 	[ "$pdb" = "" ] && pdb="/home/uwe/my_databases/music.sqlite"
	case "$func" in
		"select"|"update"|"insert"|"delete"|".import"|"reload"|".mode"|".headers"|"-header") sql_call sql_execute "$pdb" ".read \"$tmpf\"";return;;
		"sqlite3"|"sql_execute"|"func_sql_execute") sql_call $parm;return;;
	esac
	if [ "$zl" -gt 1 ];then file_verarbeitung;return;fi
    erg="$(type -a $func)"
	log debug "rc = $? erg = $erg"
	if [ "$erg" != "" ]  ;then cmd_call $*;return  ;fi
	file_verarbeitung $*
	echo "all done"
	read -p 'weiter mit taste'
}
function sql_call () { #  '.headers on \\nselect * from genre where genre_id > 140'
	pref=$1;skip
	dn=$(date "+%Y%m%d%H%M%S")
	di=$((99999999999999-$dn))
	echo ".read "
	log "${pref}_${di}_${dn}" '() { # sqlite' "$pdb $(cat $tmpf | tr '\n' ' ')" 	
	$* | tr -d '\r' |
	while read -r line;do log "$line";done   
	log log_off echo_on
	str=$(log stop);estr=$(echo $str | tr -d '\n')
	log log_on echo_off
	log "} # $estr" 
	echo "stop"
}
function cmd_call () {
	log debug "command: $*" # echo uwe ist nicht ganz doof
	rxvt -e bash -c "$*;read -p 'weiter mit beliebiger Taste'"
}
function file_verarbeitung_execute () {
	log "execute"
	translate -i '_function' -o 'function' $tmpf > /tmp/parm.sh
	chmod +x /tmp/parm.sh
	rxvt -e bash -c "/tmp/parm.sh;read -p 'weiter mit taste'"
}
function file_verarbeitung () {
	log "file verarbeitung: $*"  
	local db="" tb="" erg=""
	while read line;do
		found=$false
		if [ "$db" = "" ];then
			for str in $line;do
				[ "$str" = "sqlite" ] && found=$true && continue
				[ "$str" = "from" ]   && found=$true && continue
				[ "$found" = "$false" ]   &&  continue
				if [ "$db" = "" ] ;then db=$str;found=$false;continue;fi
				tb=$str
				break
			done
		fi
		[ "$db" = "" ] && break
		[ "$tb" = "" ] && break
		[ "${line:0:3}" = "rs_" ] && continue
		[ "${line:0:1}" = "}" ] && break
		echo $line >> $tmpf2
	done < $tmpf
	if [ "$db" != "" ] && [ "$tb" != "" ];then
		erg="reload";tmpf=$tmpf2
	else 
		erg=$(zenity --list --text="'$*'" --column="action" "reload" "import" "execute" "sql_execute")
		[ $? -gt 0 ] && return
	fi
	log "gewaehlt $erg"
	case "$erg" in
		"execute") file_verarbeitung_execute	;;
		"sql_execute") sql_execute $*	;;
		*) /home/uwe/my_scripts/dbms.sh --func utils_ctrl "$db" "$tb" "$erg" "$tmpf"
	esac
	return
	while read -r line;do
	   log "= $line"
	done < $tmpf
}
    ctrl $*
