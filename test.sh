#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
 source /home/uwe/my_scripts/my_functions.sh
function xexit () {
	retcode=$? 
	log stop 
}
 trap "xexit" EXIT
 set -e
 tagfile="/tmp/tag.txt"
 tmpf="/tmp/tmp.txt"
#
function get_id3 () {
	col=$1;shift;file=$*;type="${file##*.}"
	case "$type" in
		"mp3"|"ogg"|"wav")	;;
		*) log "err $type $file";return
	esac
	get_id3_ffprobe "$*" | cut -d "=" -f$col > $tmpf
	line="";del="";zc=0
	while read -r args;do
	    zc=$((zc+1))
	    arg=$(echo $args | tr -d '|\\"'  )
		line="$line$del$arg";del="|"
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
function _amain () {
	[ -f "$tagfile" ] && rm "$tagfile"
    find /media/uwe/daten/music/Beethoven\,Ludwig\ van/ -type f |  
    while read -r file;do
#		log "file $file"
		[ ! -f "$tagfile" ] && get_id3 1 $file > "$tagfile"
		get_id3 2 $file >> "$tagfile"
	done  
}
function _amain_ls () {
    cd "/home/uwe/mnt/daten/music/Beethoven,Ludwig van/Berliner Symphoniker/Beethoven - Ouvertures" 
	[ -f "$tagfile" ] && rm "$tagfile"
    ls -1 |  
    while read -r file;do
		log "file $file"
		[ ! -f "$tagfile" ] && get_id3 1 $file > "$tagfile"
		get_id3 2 $file >> "$tagfile"
	done  
}
function get_id3_ffprobe () {
	ffprobe -loglevel quiet -show_format -print_format flat "$*"
#	ffprobe -show_format -print_format json "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title "$*"
#	ffprobe -loglevel quiet -show_entries format_tags=album,artist,title, -of default=noprint_wrappers=1:nokey=1 "$*"
}
#	file=eigenes - logfile - logfile=syslog.txt - new log vorher loeschen - debug_on - echo_on - log_on - verbose_on
	log file start
	_amain test.sh
 
exit 
# insert into tracks select null,tags_album,tags_title,tags_composer,tags_track,tags_artist,tags_genre,duration,size,filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate,probe_score from file;

