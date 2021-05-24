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
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}" 
	[ ! -d "$path" ]     && mkdir "$path" 
	tagfile="$path/tag.txt"
	readfile="$path/find.txt"
	headfile="$path/taghead.txt"
	readpath="/home/uwe/my_scripts/resources/sql"
	tmpf="/tmp/tmp.txt"
	db="/home/uwe/my_databases/music.sqlite"
	importtb="import"
#
function _amain () {
	pparms=$*;parm="";path="/home/uwe/mnt/daten/music/"
	log file start tlog
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--path"|-p) 					 			shift;path="$1";;
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
	read_path_to_import $path
#  	import_tags
}
function setmsg () { func_setmsg $*; }
function sql_execute () { func_sql_execute $*; }
function import_tags () {
 	sql_execute $db ".read $readpath/create_table_import.sql";if [ "$?" -gt "0" ];then return  ;fi
 	sql_execute $db ".separator '|'\n.import $tagfile import";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_table_track.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_trigger_on_track.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_table_album.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_table_title.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_table_composer.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_table_genre.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $readpath/create_table_artist.sql";if [ "$?" -gt "0" ];then return  ;fi
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	sql="insert into  track select \
	        null,null,tags_album,null,tags_title,null,tags_composer,null,tags_artist, \
            null,tags_genre,null,tags_date,duration,size,format_name,format_long_name, \
            filename,nb_streams,nb_programs,start_time,bit_rate, \
            probe_score,\"$timestamp\",null \
         from import;"
	sql_execute $db "$sql";if [ "$?" -gt "0" ];then return  ;fi
}
function read_path_to_import () {
	if [ ! -d "$*" ];then setmsg -w --width=300 "kein Ordner: $*" ;return  ;fi
	[ -f "$tagfile" ] && rm "$tagfile" 
    find "$*" -type f > $readfile  
    while read -r file;do
		log debug "file $file"
		if [ "$zl" = "" ];then zl=0;zm=0;fi
		zl=$((zl+1));zm=$((zm+1))
		if [ "$zm" -gt "49" ];then log $zl $file;zm=0  ;fi
		get_id3 $zl "$file" >> "$tagfile"
	done  < $readfile
	log $FUNCNAME gelesen #$(wc -l $tagfile )
}
function get_id3 () {
	zl=$1;shift;file=$*;type="${file##*.}"
	case "$type" in
		"mp3"|"ogg"|"wav")	;;
		*) log debug "keine verarbeitung: $type $file";zl=$((zl-1));return
	esac
#	get_id3_ffprobe "$*" | cut -d "=" -f2 > $tmpf
	get_id3_ffprobe "$file"  > $tmpf 2>$tmpf; echo "" >> $tmpf
	declare -a arr=( null null null null null null null null null null null null null null null null null )
	zc=0
	while read -r args;do
		if [ "${args:0:5}" = "title" ] || [ "${args:0:6}" = "artist" ] || [ "${args:0:5}" = "genre" ]  ||
	       [ "${args:0:4}" = "date" ]  || [ "${args:0:5}" = "album" ]  || [ "${args:0:5}" = "track" ];then 
			strf="${args%%\ *}"
			strl="${args#*\:\ }"
			args="format.tags."$strf"=\"$strl\""
		fi
	    tag=${args%%=*};arg=${args#*=};arg=$(echo $arg | tr -d '\\"')
	    zc=$((zc+1))
	    case "$tag" in
			format.filename) 		 arr[0]=$arg ;;
			format.nb_streams) 		 arr[1]=$arg ;;  
			format.nb_programs) 	 arr[2]=$arg ;; 
			format.format_name) 	 arr[3]=$arg ;; 
			format.format_long_name) arr[4]=$arg ;; 
			format.start_time) 		 arr[5]=$arg ;; 
			format.duration)		 arr[6]=$arg ;; 
			format.size) 			 arr[7]=$arg ;;
			format.bit_rate) 		 arr[8]=$arg ;; 
			format.probe_score) 	 arr[9]=$arg ;; 
			format.tags.title) 		arr[10]=$arg ;; 
			format.tags.artist) 	arr[11]=$arg ;; 
			format.tags.album) 		arr[12]=$arg ;; 
			format.tags.track) 		arr[13]=$arg ;; 
			format.tags.genre) 		arr[14]=$arg ;; 
			format.tags.composer) 	arr[15]=$arg ;; 
			format.tags.date) 		arr[16]=$arg ;; 
			*)  zc=$((zc-1))
		esac
	done  < "$tmpf"
	if [ "${arg[10]}" = "null" ]; then
	     title="${arr[0]##*\/}";arg[10]="${title%\.*}"
	fi
	if [ "${arg[12]}" = "null" ]; then
	     file="${arr[0]%\/*}";arg[9]="${file##*\/}"
	fi
 	if [ "$zc" -lt "16" ];then log debug "$FUNCNAME zu wenig tags $zc tags $file";fi
 	line="$zl";del=" | "
 	for arg in "${arr[@]}";do line=$line$del$arg;done
 	unset arr
 	if [ "$line" = "" ];then return  ;fi
	echo $line
}
function get_id3_alt () {
	zl=$1;shift;file=$*;type="${file##*.}"
	case "$type" in
		"mp3"|"ogg"|"wav")	;;
		*) log debug "keine verarbeitung: $type $file";zl=$((zl-1));return
	esac
#	get_id3_ffprobe "$*" | cut -d "=" -f2 > $tmpf
	get_id3_ffprobe "$file"  > $tmpf;echo "" >> $tmpf
	line="$zl";del="|";zc=0
	while read -r args;do
	    tag=${args%%=*};arg=${args#*=}
	    if [ "$tag" = "format.tags.TYER" ]; then continue;fi
	    zc=$((zc+1))
	    if [ "$arg" = "" ];then arg="null"  ;fi
	    arg=$(echo $arg | tr -d '|\\"'  )
	    log debug $zc $tag $arg
		line="$line$del$arg" 
		if [ "$tag" = "format.tags.date" ]; then break;fi
		if [ "${tag:0:22}" = "format.tags.id3v2_priv" ]; then break;fi
	done  < "$tmpf"
 	if [ "$zc"   = "16" ];then line="$line$delnull"   ;fi
# 	if [ "$zc" -ne "17" ];then setmsg -i "$FUNCNAME $zc $file";exit   ;fi
 	if [ "$zc" -ne "17" ];then log "$FUNCNAME error $zc tags $file";return   ;fi
 	if [ "$line" = "" ];then return  ;fi
	echo $line
}
function get_id3_ffprobe () {
	ffprobe -show_format -print_format flat "$*"
	if [ "$?" -gt "0" ];then log "$FUNCNAME error $? $*";fi
#	ffprobe -loglevel quiet -show_format -print_format flat "$*"
#	ffprobe -show_format -print_format json "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title, -of default=noprint_wrappers=1:nokey=1 "$*"
}
function put_id3_ffprobe () {
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

