#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: kontext-aktion aus geany
#
	set -o noglob
 source /home/uwe/my_scripts/my_functions.sh

#	trap xexit EXIT
#	set -e  # bei fehler sprung nach xexit
#
function msg () {
	zenity --notification --text="$*"
}
function f_79789789886083_20210210113916 () { # sqlite select * from genre where genre_id < 5 
0,"neuer Pfad",Info 
1,Blues, 
2,Classic Rock 
3,Country,NULLer 
4,Dance, 
} 
function sql_call () { # ".headers on\nselect * from genre where genre_id > 140 and genre_id < 145"
#	trap 'set +x;trap_at $LINENO 26;set -x' DEBUG
	dn=$(date "+%Y%m%d%H%M%S")
	di=$((99999999999999-$dn))
	log "f_${di}_${dn}" '() { # sqlite' "$@"	
	$* | tr -d '\r' |
	while read -r line;do log "$line";done   
	log log_off echo_on
	str=$(log stop);estr=$(echo $str | tr -d '\n')
	log log_on echo_off
	log "} # $estr" 
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
	erg=$(zenity --list --text="'$*'" --column="action" "reload" "import" "execute")
	log "gewaehlt $erg"
	case "$erg" in
		"execute") file_verarbeitung_execute	;;
		*) log "Abbruch"
	esac
	return
	while read -r line;do
	   log "= $line"
	done < $tmpf
}
function _amain () {
	erg=$(wc -l $tmpf) 
	zl=${erg%%\ *}
	if [ "$zl" -gt 1 ];then file_verarbeitung;return;fi
	erg=$1;func=${erg%%[\ \,\;]*}
	thisdb="/home/uwe/my_databases/music.sqlite"
	case "$func" in
		"select"|"update"|"insert"|"delete"|".import"|"reload"|".mode"|".header") sql_call sql_execute "$thisdb" $*;return;;
		"sqlite3"|"sql_execute"|"func_sql_execute") sql_call $*;return;;
	esac
	log debug "func = $func"
    erg="$(type -a $func)"
	log debug "rc = $? erg = $erg"
	if [ "$erg" != "" ]  ;then cmd_call $*;return  ;fi
	file_verarbeitung $*
}
function xexit() {
	retcode=0 
	log ende
}
	log file tlog 
	tmpf="/tmp/parm.txt"
	[ -f "$tmpf" ] && rm $tmpf
	xclip -o    > $tmpf 
	if [ "$#" -lt "1" ];then read erg < $tmpf; set -- $erg ;fi
	if [ "$#" -lt "1" ] || [ "$*" = "" ];then log "Abbruch: keine Parameter";exit ;fi
	_amain $* 
	echo "all done"
	read -p 'weiter mit taste'
	exit
#	 select * from track limit 10 
