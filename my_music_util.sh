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
	#~ timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	#~ str="null,tags_album,null,tags_title,null,tags_composer,null,tags_artist, \
     #~ null,tags_genre,null,tags_date,duration,size,format_name,format_long_name, \
     #~ filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate, \
     #~ probe_score,$timestamp,null"
	#~ echo $str
	#~ exit
	set -e
	tagfile="/tmp/tag.txt"
	headfile="/tmp/taghead.txt"
	tmpf="/tmp/tmp.txt"
	db="/home/uwe/my_databases/music.sqlite"
	importtb="import"
#
function _amain () {
	if [ "$#" -lt "1" ];then set -- "/home/uwe/mnt/daten/music/Beethoven,Ludwig van/Konzerte/Klavierkonzerte_Nr_3_Nr_5" ;fi
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
 	sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_import.sql";if [ "$?" -gt "0" ];then return  ;fi
 	sql_execute $db ".separator '|'\n.import $tagfile import";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_track.sql";if [ "$?" -gt "0" ];then return  ;fi
#		return;
	#~ sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_album.sql";if [ "$?" -gt "0" ];then return  ;fi
	#~ sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_composer.sql";if [ "$?" -gt "0" ];then return  ;fi
	#~ sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_genre.sql";if [ "$?" -gt "0" ];then return  ;fi
	#~ sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_interpret.sql";if [ "$?" -gt "0" ];then return  ;fi
	#~ sql_execute $db ".read /home/uwe/my_scripts/resources/sql/create_table_title.sql";if [ "$?" -gt "0" ];then return  ;fi
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	sql="insert into  track select \
	        null,null,tags_album,null,tags_title,null,tags_composer,null,tags_artist, \
            null,tags_genre,null,tags_date,duration,size,format_name,format_long_name, \
            filename,nb_streams,nb_programs,start_time,bit_rate, \
            probe_score,\"$timestamp\",null \
         from import;"
	sql_execute $db "$sql";if [ "$?" -gt "0" ];then return  ;fi
#	echo $sql

}
function read_path_to_import () {
	if [ ! -d "$*" ];then setmsg -w --width=300 "kein Ordner: $*" ;return  ;fi
	[ -f "$tagfile" ] && rm "$tagfile" 
    find "$*" -type f |  
    while read -r file;do
		log debug "file $file"
		if [ "$zl" = "" ];then zl=0;fi
		zl=$((zl+1))
		get_id3 $zl $file >> "$tagfile"
	done  
}
function get_id3 () {
	zl=$1;shift;file=$*;type="${file##*.}"
	case "$type" in
		"mp3"|"ogg"|"wav")	;;
		*) log "keine verarbeitung: $type $file";zl=$((zl-1));return
	esac
#	get_id3_ffprobe "$*" | cut -d "=" -f2 > $tmpf
	get_id3_ffprobe "$*"  > $tmpf;echo "" >> $tmpf
	line="$zl";del="|";zc=0
	while read -r args;do
	    zc=$((zc+1))
	    tag=${args%%=*};arg=${args#*=}
	    if [ "$arg" = "" ];then arg="null"  ;fi
	    arg=$(echo $arg | tr -d '|\\"'  )
	    log $zc $tag $arg
		line="$line$del$arg" 
		if [ "$tag" = "format.tags.date" ]; then break;fi
	done  < "$tmpf"
#	if [ "$zc"   = "16" ];then line="$line$delnull"   ;fi
 	if [ "$line" = "" ];then return  ;fi
	echo $line
}
function get_id3_ffprobe () {
	ffprobe -loglevel quiet -show_format -print_format flat "$*"
#	ffprobe -show_format -print_format json "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title, -of default=noprint_wrappers=1:nokey=1 "$*"
}
function put_id3_ffprobe () {
	set -x
	in="$1";shift;out="$1";shift
	parm="ffmpeg -i $in -map 0 -y -codec copy -write_id3v2 1"
	while [ "$#" -gt "0" ];do
		parm="$parm -metadata $1="$2"";shift;shift
	done
	parm="$parm  $out";echo $parm 
	$parm
	if [ "$?" -gt 0 ];then setmsg -i "fehler";fi
	get_id3_ffprobe $out
#	ffmpeg -i 12-Daybreak.mp3 -map 0 -y -codec copy -write_id3v2 1 -metadata title="nightwash" -metadata genre="barock" 12-Daybreak2.mp3
#    my_music_util.sh --func put_id3_ffprobe 12-Daybreak.mp3 12-Daybreak2.mp3 title tageslicht genre new_wave

}

	log file start
	_amain  $*
exit 
# insert into tracks select null,tags_album,tags_title,tags_composer,tags_track,tags_artist,tags_genre,duration,size,filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate,probe_score from file;

