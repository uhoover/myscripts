#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
 source /home/uwe/my_scripts/my_functions.sh
 	trap "xexit" EXIT
function xexit () {
	if [ "$cmd" = "" ];then log stop;fi 
}
	set -e
	tagfile="/tmp/tag.txt"
	headfile="/tmp/taghead.txt"
	tmpf="/tmp/tmp.txt"
	db="/home/uwe/my_databases/music.sqlite"
	importtb="import"
#
function _amain () {
	if [ "$#" -lt "1" ];then set -- "/media/uwe/daten/music/Beethoven,Ludwig van/" ;fi
	pparms=$*;parm=""
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--tlog"|-t|--show-log-with-tail)  			log tlog ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--version"|-v)  				            echo "version 1.0.0" ;;
	        "--vb"|--verbose|--verbose-log)  			log verbose_on ;;
	        "--func"|-f|--execute-function)  			shift;cmd="nostop";log debug $pparms;$*;return ;;
	        "--help"|-h)								func_help $FUNCNAME;echo -e "\n     usage dbname [table --all]]" ;return;;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										parm="$parm $1";;
	    esac
	    shift
	done
	read_path_to_import $parm
	import_tags
}
function setmsg () { func_setmsg $*; }
function sql_execute () { func_sql_execute $*; }
function import_tags () {
	(echo "ID$(<"$headfile")";nl -n rn -v 0 $tagfile) > $TMPF
	sql_execute $db "DROP TABLE IF EXISTS import";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".separator '|'\n.import $TMPF import";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db "DROP TABLE IF EXISTS tracks";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read /home/uwe/my_databases/music.sqlite.docs/create_table_tracks.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql="insert into tracks select  \
		 null,tags_album,tags_title,tags_composer,tags_track,tags_artist,tags_genre,duration,size, \
		 filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate,probe_score from file"
	sql_execute $db "$sql";if [ "$?" -gt "0" ];then return  ;fi

}
function read_path_to_import () {
	if [ ! -d "$*" ];then setmsg -w --width=300 "kein Ordner: $*" ;return  ;fi
	[ -f "$tagfile" ] && rm "$tagfile" 
    find "$*" -type f |  
    while read -r file;do
		log debug "file $file"
		[ ! -f "$tagfile" ] && get_id3 "1" $file > "$headfile"
		get_id3 "2" $file >> "$tagfile"
	done  
}
function get_id3 () {
	col=$1;shift;file=$*;type="${file##*.}"
	case "$type" in
		"mp3"|"ogg"|"wav")	;;
		*) log "keine verarbeitung: $type $file";return
	esac
	get_id3_ffprobe "$*" | cut -d "=" -f$col > $tmpf
	line="";del="|";zc=0
	while read -r args;do
	    zc=$((zc+1))
	    arg=$(echo $args | tr -d '|\\"'  )
		line="$line$del$arg" 
		if [ $zc -eq 16 ]; then break;fi
	done  < "$tmpf"
	if [ "$zc" != "16" ];then log "$zc $line"  ;fi
 	if [ "$line" = "" ];then return  ;fi
	if [ "$col" == "1" ]; then
		echo "${line//format./}" | tr '.' '_'
	else
		echo $line
	fi
}
function get_id3_ffprobe () {
	ffprobe -loglevel quiet -show_format -print_format flat "$*"
#	ffprobe -show_format -print_format json "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title, -of default=noprint_wrappers=1:nokey=1 "$*"
}
	log file start
	_amain  $*
exit 
# insert into tracks select null,tags_album,tags_title,tags_composer,tags_track,tags_artist,tags_genre,duration,size,filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate,probe_score from file;

