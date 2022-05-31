#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
 source /home/uwe/my_scripts/myfunctions.sh
 	trap "_exit" EXIT
function _exit () {
	[ $func -eq $true ] && exit
	log logoff 
}
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}" ;tpath="/tmp/.${folder%%\.*}" 
	[ ! -d "$path" ]     && mkdir "$path" 
	[ ! -d "$tpath" ]    && mkdir "$tpath" 
	tagfile="$path/tag.txt"
	readfile="$path/find.txt"
	headfile="$path/taghead.txt"
#	sqlpath="/home/uwe/db/sql/music/"; [ ! -d "sqlpath" ] && mkdir -p "$sqlpath"
	sqlpath="$path/sql/"; [ ! -d "sqlpath" ] && mkdir -p "$sqlpath"
	tmpf="/$tpath/tmp.txt"
	readfile="/$tpath/read.txt"
	db="/home/uwe/my_databases/music.sqlite"
#	db="$tpath/music.sqlite"
	parmfile="/tmp/parmfile.txt"
    echo 'pdb="'$db'"' > "$parmfile" 
	importtb="import"
	dbms="/home/uwe/my_scripts/dbms.sh"
#
function _amain () {
	pparms=$*;parm="";local mypath="/media/uwe/daten/music";func=$false;rename_it=$false;drop_it=$false
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--path"|-p) 					 			shift;mypath="$1";;
	        "--tlog"|-t|--show-log-with-tail)  			log tlog ;;
	        "--rename"|-r)  				            rename_it=$true ;;
	        "--debug"|-d)  				                log debug_on ;;
	        "--drop")  				                  	drop_it=$true ;;
	        "--version"|-v)  				            echo "version 1.0.0" ;;
	        "--func"|-f|--execute-function)  			shift;func=$true;log debug $pparms;$*;return ;;
	        "--help"|-h)								func_help $FUNCNAME;echo -e "\n     usage dbname [table --all]]" ;return;;
	        -*)   										func_help $FUNCNAME;return;;
	        *)    										parm="$parm $1";;
	    esac
	    shift
	done
 	log logon 
# 	ftest2;return select * from album
# 	mypath="/media/uwe/media/Musik/radioripps"
# 	read_path_to_import $mypath
 	[ -f "$db" ] && rm -r "$db"
 	check_tb
  	import_tags
}
function ftest () {
	
		cat << EOF
--  album from filename		
	select  replace(a.filename,replace(a.filename, rtrim(a.filename, replace(a.filename, '/', '')), ''),'') from import a where album = '';
 
	                               replace(filename, '/', '')   from import where title like 'www.%';
--  title from filename		
	select                                replace(filename, '/', '')   from import where title like 'www.%';
	select                 rtrim(filename,replace(filename, '/', ''))  from import where title like 'www.%';
	select  replace(filename,rtrim(filename,replace(filename, '/', '')),'')  from import where title like 'www.%';
	select  replace(a.filename,replace(a.filename, rtrim(a.filename, replace(a.filename, '/', '')), ''),'') from import a where rowid < 10;
	update import 
	set    title = (select  replace(filename,rtrim(filename,replace(filename, '/', '')),''))
	where  filename like '%rollende%'; 

--	track nr
	
    SELECT  distinct
		a.id
	   ,a.album
	   ,a.title
       ,replace(a.filename, rtrim(a.filename, replace(a.filename, '/', '')), '')
       ,(
		select count(*) + 1
		from  (select distinct b.title 
			   from   import b 
			   where b.filename < a.filename and 
                     replace(a.filename,replace(a.filename, rtrim(a.filename, replace(a.filename, '/', '')), ''),'') = 
                     replace(b.filename,replace(b.filename, rtrim(b.filename, replace(b.filename, '/', '')), ''),'')  
             )
	   )
    from import a
	where
--		a.filename like '%lords %'
		a.track = ''
	order by a.album,a.title
	;
	
    SELECT  distinct
		a.track_album
	   ,a.track_title
       ,replace(a.track_filename, rtrim(a.track_filename, replace(a.track_filename, '/', '')), '')
       ,(
		select count(*) + 1
		from  (select distinct b.track_title 
			   from   track b 
			   where a.track_album = b.track_album and b.track_title < a.track_title and 
                     replace(a.track_filename,replace(a.track_filename, rtrim(a.track_filename, replace(a.track_filename, '/', '')), ''),'') = 
                     replace(b.track_filename,replace(b.track_filename, rtrim(b.track_filename, replace(b.track_filename, '/', '')), ''),'')  
             )
	   )
    from track a
	where
		a.track_filename like '%lords %'
	order by a.track_album,a.track_title
	;
	
	
	select track_album,track_title,(select count(*) from track  b where track_album = a.track_album and track_title < a.track_title and track_filename like '%lords %') from track a where track_filename like '%lords %' order by track_album,track_title;
	select track_album,track_title,(select count(*) from track  b where track_album = a.track_album and track_title < a.track_title and track_filename like '%lords %' group by b.track_album) from track a where track_filename like '%lords %' order by track_album,track_title;
	select track_album,track_title,(select track_album,count(*) from track b where a.track_album = b.track_album and b.track_title < a.track_title and b.track_filename like '%lord%' group by b.track_album) from track a where a.track_filename like '%lord%';
	
	select a.track_album,a.track_title,a.track_nr,nr from track a left join (select count(*) as nr from track b where a.track_title < b.track_title) on a.track_album = b.track_album where track_filename like '%lord%';

EOF
}
function ftest2 () {
	cat << EOF > $tmpf
.headers off
	select 
		album_id
	   ,album
	   ,title
	   ,(
	    select count(*) from import b
	    where 	rtrim(b.filename,replace(b.filename, '/', '')) = rtrim(a.filename,replace(a.filename, '/', ''))
	    )
	from import a
	where tracktotal = "";    
EOF
	sql_execute "$db" ".read $tmpf" |
	while IFS=',' read  id album title nr;do
		echo "$id $album $title $nr;"
#		echo "update import set track = $nr where id = $id;"
	done
}
function ftest3 () {
#	cat << EOF | while IFS= read -r l;do  ftest2 "$l";done
	cat << EOF | while read l;do ftest2 $l;done	
{
Input #0, ogg, from '/media/uwe/daten/music/Harfe/Deilmann, Uta/Harfenklaenge/8 - Vers la source dans le bois (Marcel Tournier).ogg':
  Duration: 00:04:25.77, start: 0.000000, bitrate: 141 kb/s
    Stream #0:0: Audio: vorbis, 44100 Hz, stereo, fltp, 160 kb/s
    Metadata:
      TITLE           : Vers la source dans le bois (Marcel Tournier)
      ARTIST          : Deilmann, Uta
      track           : 8
      TRACKTOTAL      : 11
      ALBUM           : Harfenklänge
      GENRE           : Klassik
      DISCID          : 7f0bd00b
      MUSICBRAINZ_DISCID: wLVgb_OTna9izv3jr1VN2Vu7M_g-
    "format": {
        "filename": "/media/uwe/daten/music/Harfe/Deilmann, Uta/Harfenklaenge/8 - Vers la source dans le bois (Marcel Tournier).ogg",
        "nb_streams": 1,
        "nb_programs": 0,
        "format_name": "ogg",
        "format_long_name": "Ogg",
        "start_time": "0.000000",
        "duration": "265.773333",
        "size": "4698502",
        "bit_rate": "141428",
        "probe_score": 100
    }
}
EOF
}
function check_tb () {
	for tb in album artgrp artist catalog composer genre genrelist instrument instrumentation title track vtrack; do
		file="${sqlpath}/create_table_${tb}.sql"
		[ -f $file ] && rm "$file"
		[ ! -f $file ] && (echo "	drop table if exists $tb;";y_get_create_stmt "$tb") > "$file"
		is_table "$db" "$tb" 
		[ $? -eq $true ] && continue
		sql_execute "$db" ".read $file"
		echo $? $tb $db  
	done
}
function import_tags () {
    sql_execute "$db" "drop table if exists import"
#    head -n 10 "$tagfile";return
	is_table "$db" "import"
	[ $? -eq $false ] && [ -f "$tagfile" ] && sql_execute "$db" ".separator |\n.import $tagfile import"
	sql_import | grep -v '#' > "$readfile"
#	setmsg -i "$LINENO $FUNCNAME pause"
	sql_execute "$db" ".read $readfile"
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	    #~ title="filename nb_streams nb_programs format_name format_long_name start_time duration size bit_rate probe_score encoder \
#~ title artist album track tracktotal genre composer date comment url"
	sql="insert into  track select \
	        null,null,album,null,title,null,track,tracktotal,composer,null,artist, \
            null,genre,null,date,comment,duration,size,format_name,format_long_name, \
            filename,nb_streams,nb_programs,start_time,bit_rate, \
            probe_score,\"$timestamp\",null \
         from import;"
	sql_execute $db "$sql";if [ "$?" -gt "0" ];then return  ;fi
	for tb in import track album title composer genre artist;do
		log "$tb		: $(sql_execute $db '.header off\nselect count(*) from' $tb)" 
	done
}
#~ format.filename) 		 arr[0]=$arg ;;
#~ format.nb_streams) 		 arr[1]=$arg ;;  
#~ format.nb_programs) 	 arr[2]=$arg ;; 
#~ format.format_name) 	 arr[3]=$arg ;; 
#~ format.format_long_name) arr[4]=$arg ;; 
#~ format.start_time) 		 arr[5]=$arg ;; 
#~ format.duration)		 arr[6]=$arg ;; 
#~ format.size) 			 arr[7]=$arg ;;
#~ format.bit_rate) 		 arr[8]=$arg ;; 
#~ format.probe_score) 	 arr[9]=$arg ;; 
#~ format.tags.title) 		arr[10]=$arg ;; 
#~ format.tags.artist) 	arr[11]=$arg ;; 
#~ format.tags.album) 		arr[12]=$arg ;; 
#~ format.tags.track) 		arr[13]=$arg ;; 
#~ format.tags.genre) 		arr[14]=$arg ;; 
#~ format.tags.composer) 	arr[15]=$arg ;; 
#~ format.tags.date) 		arr[16]=$arg ;; 

#~ format.filename="/media/uwe/media/Musik/radioripps/deutschlandfunkkultur_Interpretationen_2021_03_28_15_05.mp3"
#~ format.nb_streams=1
#~ format.nb_programs=0
#~ format.format_name="mp3"
#~ format.format_long_name="MP2/3 (MPEG audio layer 2/3)"
#~ format.start_time="0.011021"
#~ format.duration="6899.064000"
#~ format.size="110385793"
#~ format.bit_rate="128000"
#~ format.probe_score=51
#~ format.tags.icy_description="Deutschlandfunk Kultur. Das Feuilleton im Radio."
#~ format.tags.icy_genre="Information"
#~ format.tags.icy_name="Deutschlandfunk Kultur"
#~ format.tags.icy_pub="0"
#~ format.tags.icy_url="https://www.deutschlandfunkkultur.de/"
#~ format.tags.StreamTitle="Ich sehe keinen Kompromiss bei Auslandseinsätzen, Janine Wissler & Linken-Vorsitzende"
#~ format.tags.encoder="Lavf58.29.100"
function write_files () { echo $* >> $readfile; }
function read_path_to_import () {
	local mypath=$* 
	log   mypath*
	if [ ! -d "$mypath" ];then setmsg -w --width=300 "no folder: $mypath" ;return  ;fi
	if [ $rename_it -eq $true ];then # leading and tailing spaces are not very good
		find "$mypath" -type f  | 
		while IFS='' read file;do 
			[ "${file:${#file}-1:1}" != " " ] && continue
			mv "${file}" "$(trim_space  $file)"
		done
    fi
    title="filename nb_streams nb_programs format_name format_long_name start_time duration size bit_rate probe_score encoder \
title artist album track tracktotal genre composer date comment url"
	IFS=" ";arr=($title);unset IFS  
    echo "id $title" | tr ' ' '|'  > "$tagfile"
	(find "$mypath" -type f -print0 | xargs -0 -i -n 1 echo \"{}\" | grep ".mp3\|.ogg\|.wav" | grep -v ".lnk"  | 
		xargs -i -n 1 ffprobe -hide_banner -show_format -print_format flat "{}" 2>&1 ) | grep -v 'format.tag' | grep '^    \|^format.'|
		while IFS=':=' read field value;do 
			field=$(echo "$field" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
			value=$(echo $value | tr -d '"')
			test -z "${value//[0-9\.\,]}"; [ $? -eq $false ] && value="\"$value\""
			case "$field" in
				streamtitle)		field="title";;  
				icy-name)			field="artist";; 		
				icy-description)	field="comment";; 			
				icy-genre)			field="genre";; 			
				icy-url)			field="url";; 		
				*) :
			esac
			field="${field##*\.}"
			for ((ia=0;ia<${#arr[@]};ia++)) ;do
				[ "$field" = "${arr[$ia]}" ] &&  val[$ia]="$value" && break
			done
			case "$field" in
				probe_score) 	if 	[ "${val[0]}" != "" ]; then
									[ "$zi" = "" ] && zi=1 || : $((zi++))
									[ $((zi%100)) -eq 0 ] && echo "verarbeite $zi"
									line="$zi" 
									for ((ia=0;ia<${#arr[@]};ia++)) ;do
										line="${line}|${val[$ia]}"
										val[$ia]=""
									done
									echo $line  >> "$tagfile"
								fi;;
			esac
		done
}
function read_path_to_import_neu2 () {
	local mypath=$* 
	log   mypath*
	if [ ! -d "$mypath" ];then setmsg -w --width=300 "no folder: $mypath" ;return  ;fi
	if [ $rename_it -eq $true ];then # leading and tailing spaces are not very good
		find "$mypath" -type f  | 
		while IFS='' read file;do 
			[ "${file:${#file}-1:1}" != " " ] && continue
			mv "${file}" "$(trim_space  $file)"
		done
    fi
	title="filename nb_streams nb_programs format_name format_long_name start_time duration size bit_rate probe_score \
title artist album track genre composer date encoder"
	IFS=" ";arr=($title);unset IFS  
    echo "id $title" | tr ' ' '|' > "$tagfile"
    #~ find "$mypath" -type f -print0 | xargs -0 -i -n 1 echo "{}" | grep ".mp3\|.ogg\|.wav" | grep -v ".lnk"  >> "$tagfile";return 
	
    #~ (find "$mypath" -type f -print0 | grep ".mp3\|.ogg\|.wav" | 
		#~ xargs -0 -i -n 1 ffprobe -hide_banner -show_format -print_format flat {} 2>> /tmp/ffprobe.txt | 
		#~ grep 'format.';echo "format.filename=end") |
	(find "$mypath" -type f -print0 | xargs -0 -i -n 1 echo \"{}\" | grep ".mp3\|.ogg\|.wav" | grep -v ".lnk"  | 
		xargs -i -n 1 ffprobe -hide_banner -show_format -print_format flat "{}" 2>> /tmp/ffprobe.txt | 
		grep 'format.';echo "format.filename=end") |
    while IFS='=' read field value;do
		value=$(echo $value | tr -d '"')
		test -z "${value//[0-9\.\,]}"; [ $? -eq $false ] && value="\"$value\""
		case "$field" in
			format.filename) 				if 	[ "${val[0]}" != "" ]; then
												[ "$zi" = "" ] && zi=1 || : $((zi++))
												[ $((zi%100)) -eq 0 ] && echo "verarbeite $zi"
												line="$zi" 
												for ((ia=0;ia<${#arr[@]};ia++)) ;do
													line="${line}|${val[$ia]}"
													val[$ia]=""
												done
												echo $line >> "$tagfile"
											fi;;
			format.tags.StreamTitle)		field="format.tags.title";;  
			format.tags.icy_name)			field="format.tags.artist";; 		
			format.tags.icy_description)	field="format.tags.album";; 			
			format.tags.icy_genre)			field="format.tags.genre";; 			
			format.tags.icy_url)			field="format.tags.composer";; 		
			*) :
		esac
		field="${field##*\.}"
		for ((ia=0;ia<${#arr[@]};ia++)) ;do
			[ "$field" = "${arr[$ia]}" ] &&  val[$ia]="$value" && break
		done
    done
}
function read_path_to_import_neu () {
	local mypath=$* 
	log   mypath*
	if [ ! -d "$mypath" ];then setmsg -w --width=300 "no folder: $mypath" ;return  ;fi
	if [ $rename_it -eq $true ];then # leading and tailing spaces are not very good
		find "$mypath" -type f  | 
		while IFS='' read file;do 
			[ "${file:${#file}-1:1}" != " " ] && continue
			mv "${file}" "$(trim_space  $file)"
		done
    fi
	[ -f "$tagfile" ]  && rm "$tagfile" 
    (find "$mypath" -type f -print | grep ".mp3\|.ogg\|.wav" | sort | 
	 xargs -i -n 1 ffprobe -hide_banner -show_format -print_format flat "{}" 2> /dev/null | 
	 grep 'format.';echo "format.filename=end") |
    while IFS='=' read field value;do
		case "$field" in
			format.filename) 			if [ "$filename" != "" ]; then
											echo -n "${filename}|${nb_streams}|${nb_programs}|${format_name}|${format_long_name}"	
											echo -n	"|${start_time}|${duration}|${size}|${bit_rate}|${probe_score}"
											echo -n	"|${title}|${artist}|${album}|${track}|${genre}|${composer}|${date}"
											echo 	"|$encoder"
										fi
										filename="$value";nb_streams="";nb_programs="";format_name="";format_long_name=""	
										start_time="";duration="";size="";bit_rate="";probe_score=""
										title="";artist="";album="";track="";genre="";composer="";date="";encoder="" 
										;;
			format.nb_streams)			nb_streams="$value"	;;
			format.nb_programs)			nb_programs="$value"	;;
			format.format_name)			format_name="$value"	;;
			format.format_long_name)	format_long_name="$value"	;;
			format.start_time)			start_time="$value"	;;
			format.duration)			duration="$value"	;;
			format.size)				size="$value"	;;
			format.bit_rate)			bit_rate="$value"	;;
			format.probe_score)			probe_score="$value"	;;
			format.tags.title|format.tags.StreamTitle)  
										title="$value" ;; 
			format.tags.artist|format.tags.icy_name) 		
										artist="$value" ;; 
			format.tags.album|format.tags.icy_description) 			
										album="$value" ;; 
			format.tags.track) 			track="$value" ;; 
			format.tags.genre|format.tags.icy_genre) 			
										genre="$value" ;; 
			format.tags.composer|format.tags.icy_url) 		
										composer="$value" ;; 
			format.tags.date)	 		date="$value" ;;
			format.tags.encoder)	 	encoder="$value" ;;
			*) :
		esac
    done
}
function read_path_to_import_alt () {
	local path=$* 
	log path*
	if [ ! -d "$path" ];then setmsg -w --width=300 "no folder: $path" ;return  ;fi
	if [ $rename_it -eq $true ];then # leading and tailing spaces are not very good
		find "$path" -type f  | 
		while IFS='' read file;do 
			[ "${file:${#file}-1:1}" != " " ] && continue
			mv "${file}" "$(trim_space  $file)"
		done
    fi
	[ -f "$tagfile" ]  && rm "$tagfile" 
	echoenable=$true
    find "$path" -type f |  
    while IFS='' read file;do
		[ "$zl" = "" ] && zl=0 || zl=$((zl+1))
		[ $((zl%100)) -eq 0 ] && log verarbeite $zl 
		[ ! -f "$file" ] && log error $zl $file && continue
		get_id3 "$file" >> "$tagfile"
	done  
}
function get_id3 () {
	local file=$*
	case "${file##*.}" in
		mp3*|ogg*|wav*)	;;
		*) log debug "keine verarbeitung: $type $file";return
	esac
#	[ ! -f "$file" ] && log error $file;return  

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
 	line="$zl";del="|"
 	for arg in "${arr[@]}";do line=$line$del$arg;done
 	unset arr
 	if [ "$line" = "" ];then return  ;fi
	echo $line
}
function get_id3_ffprobe () {
	ffprobe -show_format -print_format flat "$*"
	if [ $? -gt 0 ];then log "error  $*";fi
#	ffprobe -hide_banner -show_format -print_format flat "$*" 2> /dev/null | grep -A16 'format.filename' 
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
function sql_import () {
	cat << EOF
	update import set title = replace(filename, rtrim(filename, replace(filename,'/','')), '') where title = "";
	update import set composer = 'Pratchett, Terry' where filename like '%pratchett%' and composer = "";
	update import set album = 'Der Winterschmied CD1' where album = '' and filename like '%pratchett%' and filename like '%winterschmied%' and filename like '%cd1%';
	update import set album = 'Der Winterschmied CD2' where album = '' and filename like '%pratchett%' and filename like '%winterschmied%' and filename like '%cd2%';
	update import set album = 'Der Winterschmied CD3' where album = '' and filename like '%pratchett%' and filename like '%winterschmied%' and filename like '%cd3%';
	update import set album = 'Der Winterschmied CD4' where album = '' and filename like '%pratchett%' and filename like '%winterschmied%' and filename like '%cd4%';
	update import set album = 'Der Winterschmied CD5' where album = '' and filename like '%pratchett%' and filename like '%winterschmied%' and filename like '%cd5%';
	update import set album = 'Der fünfte Elefant CD1' where album = '' and filename like '%pratchett%' and filename like '%elefant%' and filename like '%cd1%';
	update import set album = 'Der fünfte Elefant CD2' where album = '' and filename like '%pratchett%' and filename like '%elefant%' and filename like '%cd2%';
	update import set album = 'Der fünfte Elefant CD3' where album = '' and filename like '%pratchett%' and filename like '%elefant%' and filename like '%cd3%';
	update import set album = 'Total verhext CD1' where album = '' and filename like '%pratchett%' and filename like '%verhext%' and filename like '%cd 1%';
	update import set album = 'Total verhext CD2' where album = '' and filename like '%pratchett%' and filename like '%verhext%' and filename like '%cd 2%';
	update import set album = 'Total verhext CD3' where album = '' and filename like '%pratchett%' and filename like '%verhext%' and filename like '%cd 3%';
	update import set album = 'Total verhext CD4' where album = '' and filename like '%pratchett%' and filename like '%verhext%' and filename like '%cd 4%';
	update import set album = 'Total verhext CD5' where album = '' and filename like '%pratchett%' and filename like '%verhext%' and filename like '%cd 5%';
	update import set album = 'Total verhext CD6' where album = '' and filename like '%pratchett%' and filename like '%verhext%' and filename like '%cd 6%';
	update import set album = 'Pyramiden CD1' where album = '' and filename like '%pratchett%' and filename like '%pyramiden 1%';
	update import set album = 'Pyramiden CD2' where album = '' and filename like '%pratchett%' and filename like '%pyramiden 2%';
	update import set album = 'Pyramiden CD3' where album = '' and filename like '%pratchett%' and filename like '%pyramiden 3%';
	update import set album = 'Pyramiden CD4' where album = '' and filename like '%pratchett%' and filename like '%pyramiden 4%';
	update import set album = 'Wachen! Wachen! CD1' where album = '' and filename like '%pratchett%' and filename like '%wachen%' and filename like '%cd 1%'; 
	update import set album = 'Wachen! Wachen! CD2' where album = '' and filename like '%pratchett%' and filename like '%wachen%' and filename like '%cd 2%'; 
	update import set album = 'Wachen! Wachen! CD3' where album = '' and filename like '%pratchett%' and filename like '%wachen%' and filename like '%cd 3%'; 
	update import set album = 'Wachen! Wachen! CD4' where album = '' and filename like '%pratchett%' and filename like '%wachen%' and filename like '%cd 4%'; 
	update import set album = 'Wachen! Wachen! CD5' where album = '' and filename like '%pratchett%' and filename like '%wachen%' and filename like '%cd 5%'; 
	update import set album = 'Helle Barden' where album = '' and filename like '%pratchett%' and filename like '%barden%'; 
	update import set album = 'Lords and Ladies CD1' where album = '' and filename like '%pratchett%' and filename like '%ladies%' and filename like '%cd1%'; 
	update import set album = 'Lords and Ladies CD2' where album = '' and filename like '%pratchett%' and filename like '%ladies%' and filename like '%cd2%'; 
	update import set album = 'Lords and Ladies CD3' where album = '' and filename like '%pratchett%' and filename like '%ladies%' and filename like '%cd3%'; 
	update import set album = 'Lords and Ladies CD4' where album = '' and filename like '%pratchett%' and filename like '%ladies%' and filename like '%cd4%'; 
	update import 
		set    title = (select  replace(filename,rtrim(filename,replace(filename, '/', '')),''))
		where  title = ''; 
#	update import  
#		set   track =  (select count(*) + 1
#						from   (select distinct b.title 
#								from   import b 
#								where b.filename < filename and 
#									replace(  filename,replace(  filename, rtrim(  filename, replace(  filename, '/', '')), ''),'') = 
#									replace(b.filename,replace(b.filename, rtrim(b.filename, replace(b.filename, '/', '')), ''),'')  
#								)
#						)
#		where track = '';
	#select replace(filename, rtrim(filename, replace(filename, '/', '')), '') from import where title = "" and filename like '%pratchett%';
	#select replace(fls_track_filename, rtrim(fls_track_filename, replace(fls_track_filename, '/', '')), '') from track where track_id < 10;
	#select replace(filename, rtrim(filename, replace(filename, '/', '')), '') from import where title = "" and filename like '%pratchett%';
EOF
	sql_execute "$db" ".headers off\nselect id,filename from import where album = ''" |
	while IFS=',' read  id file;do
		IFS='/';arr=($file);ix=${#arr[@]};album=${arr[$ix-2]};unset IFS
		echo "update import set album = \"$album\" where id = $id ;"
	done
	cat << EOF > $tpath/readfile2.sql
.headers off
	    SELECT  distinct
		a.id
       ,(
		select count(*) + 1
		from  (select distinct b.title 
			   from   import b 
			   where b.filename < a.filename and 
                     replace(a.filename,replace(a.filename, rtrim(a.filename, replace(a.filename, '/', '')), ''),'') = 
                     replace(b.filename,replace(b.filename, rtrim(b.filename, replace(b.filename, '/', '')), ''),'')  
             )
	    )
	   ,a.album
	   ,a.title
       ,replace(a.filename, rtrim(a.filename, replace(a.filename, '/', '')), '')
    from import a
	where
 		a.track = ""
	order by a.album,a.title;
EOF
	sql_execute "$db" ".read $tpath/readfile2.sql" |
	while IFS=',' read  id nr rest;do
		echo "update import set track = $nr where id = $id;"
	done
}
function y_get_create_stmt () {
	eval 'y_get_create_tb_'$* ' | grep -v "#"'
}
function y_get_create_tb_album () {
	cat << EOF
	CREATE TABLE album(
	  "album_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "album_name"					TEXT,
	  "album_opus_nr"				TEXT,
	  "album_catalog_id"			INTEGER,
	  "album_instrumentation_id"	INTEGER,
	  "album_tracks"				INTEGER,
	  "album_path"				    TEXT,
	  "album_info"					TEXT
	);
	create unique index ix_u_1_album on album(album_path,album_name);
EOF
}
function y_get_create_tb_artgrp () {
	cat << EOF
	CREATE TABLE artgrp(
	  "artgrp_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "artgrp_artist_id"			INTEGER,
	  "artgrp_grp_id"				INTEGER,
	  "artgrp_info"					TEXT
	);
	create unique index ix_u_1_artgrp on artgrp(artgrp_artist_id,artgrp_grp_id);
EOF
}
function y_get_create_tb_artist () {
	cat << EOF
	CREATE TABLE artist(
	  "artist_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "artist_name"					TEXT UNIQUE,
	  "artist_name_first"			TEXT,
	  "artist_name_last"			TEXT,
	  "artist_name_short"			TEXT,
	  "artist_from"					TEXT,
	  "artist_to"					TEXT,
	  "artist_info"					TEXT
	);
EOF
}
function y_get_create_tb_catalog () {
	cat << EOF
	CREATE TABLE catalog(
	  "catalog_id" INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
	  "catalog_name" TEXT,
	  "catalog_short" TEXT,
	  "catalog_composer" TEXT,
	  "catalog_info" TEXT
	);
	insert into catalog(catalog_name,catalog_short,catalog_composer,catalog_info)
	values
	 ("Verzeichnis nach Knape","Kn","Carl Friedrich Abel","")
	,("Wotquenne-Verzeichnis","Wq","Carl Philipp Emanuel Bach","")
    ,("Bach-Compendium","BC","Johann Sebastian Bach","")
    ,("Bach-Werke-Verzeichnis","BWV","Johann Sebastian Bach","")
    ,("Falck-Verzeichnis","F (WFB)","Wilhelm Friedemann Bach","")
    ,("Szőllősy-Verzeichnis","Sz","Béla Bartók","")
    ,("Verzeichnis nach László Somfai","BB","Béla Bartók","")
    ,("Verzeichnis nach Kinsky/Halm","KH","Ludwig van Beethoven","")
    ,("Verzeichnis nach D. Kern Holoman","H (HB)","Hector Berlioz","")
    ,("Werkverzeichnis Winton Dean","WD","Georges Bizet","")
    ,("Gérard-Verzeichnis","G","Luigi Boccherini","")
    ,("Werkverzeichnis Anton Bruckner","WAB","Anton Bruckner","")
    ,("Kindermannverzeichnis","KiV","Ferruccio Busoni","")
    ,("Buxtehude-Werke-Verzeichnis","BuxWV","Dieterich Buxtehude","")
    ,("Hitchcock-Verzeichnis","H (MC)","Marc-Antoine Charpentier","")
    ,("Verzeichnis nach Krystyna Kobylańska","KK","Frédéric Chopin","K")
    ,("Verzeichnis nach Maurice J. E. Brown","B (FC)","Frédéric Chopin","(Brown Index) BI")
    ,("Verzeichnis nach Józef Michał Chomiński","CT","Frédéric Chopin","C")
    ,("Verzeichnis nach Vytautas Landsbergis [1]","VL","Mikalojus Konstantinas Čiurlionis","")
    ,("Pechstaedt-Verzeichnis","P (FD)","Franz Danzi","")
    ,("Lesure-Verzeichnis","L","Claude Debussy","")
    ,("Krebs-Verzeichnis nach Carl Krebs","Krebs","Carl Ditters von Dittersdorf","(K)")
    ,("Thematischer Katalog der Werke von Antonín Dvořák nach Jarmil Burghauser","B (AD)","Antonín Dvořák","")
    ,("Hopkinson-Verzeichnis","H (AH)","Arthur Honegger","")
    ,("Franck-Werkverzeichnis von Wilhelm Mohr","FWV","César Franck","(M.)")
    ,("Köchelverzeichnis der Werke von Johann Joseph Fux","K (JF)","Johann Joseph Fux","")
    ,("Graupner-Werke-Verzeichnis","GWV","Christoph Graupner","")
    ,("Händel-Werke-Verzeichnis","HWV","Georg Friedrich Händel","")
    ,("Hoboken-Verzeichnis","Hob","Joseph Haydn","(H)")
    ,("Fanny-Hensel-Werkverzeichnis von Renate Hellwig-Unruh","HWV (FH)","Fanny Hensel","")
    ,("Halbreich-Verzeichnis (AH)","H (AH2)","Arthur Honegger","")
    ,("Hugo-Kaun-Werkverzeichnis","HKW","Hugo Kaun","")
    ,("van-Boer-Verzeichnis","VB","Joseph Martin Kraus","")
    ,("Searle-Verzeichnis","S","Franz Liszt","")
    ,("Raabe-Verzeichnis","R (FL)","Franz Liszt","")
    ,("Halbreich-Verzeichnis (BM)","H (BM)","Bohuslav Martinů","")
    ,("Werkverzeichnis Rudolf Mauersberger","RMWV","Rudolf Mauersberger","")
    ,("Mendelssohn-Werkverzeichnis","MWV","Felix Mendelssohn Bartholdy","")
    ,("Stattkus-Verzeichnis","SV","Claudio Monteverdi","")
    ,("Köchelverzeichnis","KV","Wolfgang Amadeus Mozart","(K)")
    ,("Zimmerman-Verzeichnis","Z","Henry Purcell","")
    ,("Rameau Catalogue Thématique","RCT","Jean-Philippe Rameau","")
    ,("Kirkpatrick-Verzeichnis","K","Domenico Scarlatti","")
    ,("Longo-Verzeichnis","L (DS)","Domenico Scarlatti","")
    ,("Pestelli-Verzeichnis","P (DS)","Domenico Scarlatti","")
    ,("Deutsch-Verzeichnis","D","Franz Schubert","")
    ,("Robert-Schumann-Werkverzeichnis von Margit L. McCorkle","RSW","Robert Schumann","")
    ,("Scholz-Werke-Verzeichnis [2]","SchzWV","Wilhelm Eduard Scholz","")
    ,("Schütz-Werke-Verzeichnis","SWV","Heinrich Schütz","")
    ,("kdm-Verzeichnis","kdm","Klaus Schulze","")
    ,("Jiří-Berkovec-Verzeichnis","JB","Bedřich Smetana","")
    ,("Bartoš-Verzeichnis","B","Bedřich Smetana","")
    ,("Teige-Verzeichnis","T","Bedřich Smetana","")
    ,("Rubio-Verzeichnis","R (AS)","Antonio Soler","")
    ,("Marvin-Verzeichnis","M","Antonio Soler","")
    ,("Fischer-Verzeichnis","StWV","Franz Xaver Sterkel","")
    ,("Trenner-Verzeichnis","TrV","Richard Strauss","")
    ,("Telemann-Werke-Verzeichnis","TWV","Georg Philipp Telemann","")
    ,("Telemann-Vokalwerke-Verzeichnis","TVWV","Georg Philipp Telemann","")
    ,("Ryom-Verzeichnis","RV","Antonio Vivaldi","")
    ,("Pincherle-Verzeichnis","PV","Antonio Vivaldi","(PS P)")
    ,("Fanna-Verzeichnis","F","Antonio Vivaldi","")
    ,("Ricordi-Verzeichnis","RC"," Antonio Vivaldi","(Publisher Ricordi PR)")
    ,("Rinaldi-Verzeichnis","RN","Antonio Vivaldi","")
    ,("Wagner-Werk-Verzeichnis","WWV","Richard Wagner","")
    ,("Zelenka-Werke-Verzeichnis","ZWV","Jan Dismas Zelenka","");
    update catalog set catalog_info = null where catalog_info = "";
EOF
}
function y_get_create_tb_composer () {
	cat << EOF
	CREATE TABLE composer(
		"composer_id" 			INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
		"composer_name" 		TEXT UNIQUE,
		"composer_name_last" 	TEXT,
		"composer_name_first" 	TEXT,
		"composer_title" 		TEXT,
		"composer_date_birth" 	TEXT,
		"composer_place_birth" 	TEXT,
		"composer_date_death" 	TEXT,
		"composer_place_death" 	TEXT,
		"composer_info" 		TEXT
	);
	INSERT INTO composer (composer_name_last,composer_name_first,composer_date_birth,composer_place_birth,composer_date_death,composer_place_death) VALUES
	 ('Albinoni','Tomaso','8.6.1671','Venedig','17.1.1751','Venedig') 
	,('Bach','Johann Sebastian','21.3.1685','Eisenach','28.7.1750','Leipzig')
	,('Beethoven','Ludwig van','17.12.1770','Bonn','26.3.1827','Wien')
	,('Bizet','Georges','25.10.1838','Paris','3.6.1875','Bougival bei Paris')
	,('Brahms','Johannes','7.5.1833','Hamburg','3.4.1897','Wien')
	,('Bruch','Max','6.1.1838','Köln','2.10.1920','Berlin')
	,('Bruckner','Anton','4.9.1824','Ansfelden','11.10.1896','Wien')
	,('Chopin','Frédéric','22.2.1810','Zelazowa Wola, POL','17.10.1849','Paris')
	,('Debussy','Claude','22.8.1862','Saint-Germain','26.3.1918','Paris')
	,('Dvořák','Antonin','8.9.1841','Nelahozeves','1.5.1904','Prag')
	,('Egk','Werner','17.5.1901','Donauwörth','10.7.1983','Inning')
	,('Händel','Georg Friedrich','23.2.1685','Halle','14.4.1759','London')
	,('Haydn','Joseph','31.3.1732','Rohrau','31.5.1809','Wien')
	,('Hindemith','Paul','16.11.1895','Hanau','28.12.1963','Frankfurt')
	,('Lehár','Franz','30.4.1870','Komorn','14.10.1948','Bad Ischl')
	,('Leoncavallo','Ruggero','8.3.1858','Neapel','9.9.1919','Montecatini Terme')
	,('Lincke','Paul','7.11.1866','Berlin','3.9.1946','Goslar')
	,('Liszt','Franz','22.10.1811','Raiding im Burgenland','31.7.1886','Bayreuth')
	,('Mahler','Gustav','7.7.1860','Kalischt Böhmen CZ','18.5.1911','Wien')
	,('Mendelssohn-Bartholdy','Felix','3.2.1809','Hamburg','4.11.1847','Leipzig')
	,('Millöcker','Carl','29.5.1842','Wien','31.12.1899','Baden bei Wien')
	,('Mozart','Wolfgang Amadeus','27.1.1756','Salzburg','5.12.1791','Wien')
	,('Orff','Carl','10.7.1895','München','29.3.1982','München')
	,('Pfitzner','Hans','5.5.1869','Moskau','22.5.1949','Salzburg')
	,('Prokofjew','Sergei','23.4.1891','Bachmut UKR','5.3.1953','Moskau')
	,('Puccini','Giacomo','22.12.1858','Lucca','29.11.1924','Brüssel')
	,('Rachmaninow','Sergei','1.4.1873','Staraja Russa','28.3.1943','Beverly Hills')
	,('Ravel','Maurice','7.3.1875','Ciboure','28.12.1937','Paris')
	,('Reger','Max','19.3.1873','Weiden','11.5.1916','Leipzig')
	,('Rossini','Gioachino','29.2.1792','Pesaro','13.11.1868','Paris-Passy')
	,('Schönberg','Arnold','13.9.1874','Wien','14.8.1951','Los Angeles')
	,('Schubert','Franz','31.1.1797','Wien','19.11.1828','Wien')
	,('Schumann','Robert','8.6.1810','Zwickau','29.7.1856','Endenich bei Bonn')
	,('Smetana','Bedřich','2.3.1824','Litomyšl Böhmen','12.5.1884','Prag')
	,('Strauss','Johann','25.10.1825','Wien','3.6.1899','Wien')
	,('Strauss','Richard','11.6.1864','München','8.9.1949','Garmisch-Partenkirchen')
	,('Strawinsky','Igor','17.6.1882','Oranienbaum bei St. Petersburg','6.4.1971','New York')
	,('Tschaikowsky','Petr Iljitsch','7.5.1840','Wotkinsk','6.11.1893','St. Petersburg')
	,('Verdi','Giuseppe','10.10.1813','Le Roncole bei Parma','27.1.1901','Mailand')
	,('Vivaldi','Antonio','4.3.1678','Venedig','28.7.1741','Wien')
	,('Wagner','Richard','22.5.1813','Leipzig','13.2.1883','Venedig')
	,('Weber','Carl Maria von','18.12.1786','Eutin','5.6.1826','London')
	,('Wolf','Hugo','13.3.1860','Windisch-grätz','22.2.1903','Wien');
	INSERT INTO composer (composer_id,composer_name) values (99,'various'),(100,'unknown');
	update composer set composer_info = null where composer_info = "";
	update composer set composer_name = composer_name_last || ',' || composer_name_first;
EOF
}
function y_get_create_tb_genre () {
	cat << EOF
	CREATE TABLE genre(		
		"genre_id"       		INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE,
		"genre_genrelist_id"	INTEGER,
		"genre_name" 	 		TEXT,
		"genre_info" 	 		TEXT
	);	
    update genre set genre_info = null where genre_info = "";
EOF
}
function y_get_create_tb_genrelist () {
	cat << EOF
	CREATE TABLE genrelist(
		"genrelist_id" 			INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
		"genrelist_name"		TEXT UNIQUE,
		"genrelist_info"		TEXT
	);
	insert into genrelist (genrelist_name) values
EOF
	del=" "
	id3 -L | cut -d ':' --output-delimiter ' ' -f2- | sort -u |
	while read genre;do 
		echo "   	${del}('${genre}')"
		del=","
	done  
	echo ";"
}
function y_get_create_tb_import () {
	cat << EOF
	CREATE TABLE import(
	  "id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "filename" 			TEXT,
	  "nb_streams" 			TEXT,
	  "nb_programs" 		TEXT,
	  "format_name" 		TEXT,
	  "format_long_name" 	TEXT,
	  "start_time" 			TEXT,
	  "duration" 			TEXT,
	  "size" 				TEXT,
	  "bit_rate" 			TEXT,
	  "probe_score" 		TEXT,
	  "tags_title" 			TEXT,
	  "tags_artist" 		TEXT,
	  "tags_album" 			TEXT,
	  "tags_track" 			TEXT,
	  "tags_genre" 			TEXT,
	  "tags_composer" 		TEXT,
	  "tags_date" 			TEXT
	);
EOF
}
function y_get_create_tb_instrument () {
	cat << EOF
	CREATE TABLE instrument ( 
	  "instrument_id" 			INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "instrument_status"		INTEGER DEFAULT 0 ,
	  "instrument_name" 		TEXT ,
	  "instrument_name_short" 	TEXT ,
	  "instrument_info" 		TEXT
	  );
	INSERT INTO instrument (instrument_name,instrument_name_short) VALUES
		 ('Akkordeon (Ziehharmonika)','acc')
		,('Altklarinette','acl')
		,('Altblockflöte','arec')
		,('Altflöte (Altquerflöte in G)','afl')
		,('Alphorn','alp')
		,('Althorn','ahn')
		,('Arpeggione','arp')
		,('Altsaxophon','as')
		,('Altposaune','atb')
		,('Dudelsack (Sackpfeife)','bag')
		,('Bariton','bar')
		,('Baritonsaxophon','bars')
		,('Bass','bass')
		,('Bassbariton','bbar')
		,('Generalbass','bc')
		,('Bassklarinette','bcl')
		,('Glocken','bell')
		,('Bassflöte (Bassquerflöte in C)','bfl')
		,('Banjo','bjo')
		,('Fagott','fg')
		,('Bongos','bo')
		,('Baritonoboe','bob')
		,('Bassblockflöte','brec')
		,('Blechblasinstrument(e)','brs')
		,('Bassposaune','bpos')
		,('Basssaxophon','bsx')
		,('Bassettklarinette','bstcl')
		,('Bassetthorn','bsthn')
		,('Basstrompete','btp')
		,('Signalhorn','bug')
		,('Kontraaltklarinette','cacl')
		,('Kontrabassklarinette','cbcl')
		,('Kontrabassflöte','cbfl')
		,('Kontrafagott','cbn')
		,('Kontrabasssaxophon','cbsx')
		,('Celesta','cel')
		,('Röhrenglocken','chm')
		,('Zimbal','cimb')
		,('Cister','cit')
		,('Cajón','cjn')
		,('Klarinette','cl')
		,('Klavichord','clvd')
		,('Chalumeau','cm')
		,('Konzertina','conc')
		,('Kornett','cor')
		,('Krummhorn','crh')
		,('Zink','crtt')
		,('Kuhglocke','cwb')
		,('Becken','cym')
		,('Kontrabass','db')
		,('Didgeridoo','dgdo')
		,('Djembe','djm')
		,('Dulzian','dlcn')
		,('Domra','dom')
		,('Hackbrett','dulc')
		,('Schlagzeug (Drumset)','dr')
		,('Davul','dv')
		,('Elektrische Gitarre','egtr')
		,('Englischhorn','eh')
		,('E-Bass','el-b')
		,('E-Gitarre','el-g')
		,('E-Piano','el-p')
		,('Elektronische(s) Instrument(e)','elec')
		,('Elektronisches Piano','epf')
		,('gleiche Stimmen','eq')
		,('Euphonium','euph')
		,('Tenorflöte','fda')
		,('Flügelhorn','fgh')
		,('Querpfeife (Spielmannsflöte)','fife')
		,('Flöte','fl')
		,('Flageolett','flag')
		,('Flügelhorn','flhn')
		,('Waldhorn','frhn')
		,('Glasharmonika (Gläserspiel)','ghca')
		,('Glockenspiel','gl')
		,('Gitarre','gtr')
		,('Harmonium','harm')
		,('Mundharmonika','hca')
		,('Heckelphon','heck')
		,('Horn','hrn')
		,('Harfe','harp')
		,('Cembalo (Clavicembalo)','hrp')
		,('Keyboard','keyb')
		,('Kontrabassposaune','kbpos')
		,('Laute','lute')
		,('Lyra','lyre')
		,('Mandoline','mdln')
		,('Marimbaphon','mar')
		,('Melodica','mel')
		,('Mellophon','mlp')
		,('Musette de Cour','mus')
		,('Erzähler / Sprecher','nar')
		,('Oboe','ob')
		,('Okarina','oca')
		,('Oboe d''amore','oda')
		,('Ondes Martenot','om')
		,('Ophikleide','oph')
		,('Orchester','orch')
		,('Orgel','org')
		,('Oud','oud')
		,('Panflöte (Hirtenflöte)','pan')
		,('Schlaginstrument(e) (Percussion)','perc')
		,('Klavier','pf')
		,('Klavier zu 3 Händen','pf3h')
		,('Klavier zu 4 Händen','pf4h')
		,('Klavier zu 5 Händen','pf5h')
		,('Klavier zu 6 Händen','pf6h')
		,('Klavier linkshändig','pflh')
		,('Pedalflügel (Pedalklavier)','pfped')
		,('Klavier rechtshändig','pfrh')
		,('Piccoloflöte','picc')
		,('Piccolotrompete','pictp')
		,('Pipa','pipa')
		,('Piccolotrompete','ptpt')
		,('Rebec','reb')
		,('Blockflöte','rec')
		,('Sarrusophon','sar')
		,('Saxophon','sax')
		,('Säge','saw')
		,('Soundeffekte','sfx')
		,('Sheng','sheng')
		,('Schalmei','shw')
		,('Sitar','sit')
		,('Sackbutt','skbt')
		,('Kleine Trommel (Snare)','sn-dr')
		,('Sousaphon','sous')
		,('Serpent','srp')
		,('Sopransaxophon','ss')
		,('Sopraninosaxophon','sss')
		,('Zugtrompete','stpt')
		,('Streicher','str')
		,('Bügelhorn (Saxhorn)','sxh')
		,('Synthesizer','syth')
		,('Tamburin','tamb')
		,('Tuba','tba')
		,('Posaune','trb')
		,('Tenorhorn','th')
		,('Theremin','thrm')
		,('Timbales','tim')
		,('Pauken','timp')
		,('Trompete','trp')
		,('Triangel','tri')
		,('Tenorsaxophon','ts')
		,('Ukelele','uke')
		,('Bratsche','va')
		,('Viola pomposa','vap')
		,('Violoncello','vlc')
		,('Viola d''amore (Liebesgeige)','vda')
		,('Vibraphon','vib')
		,('Leier (Drehleier)','vie')
		,('Gambe','viol')
		,('Viola (Bratsche)','vla')
		,('Violone','vlne')
		,('Violine (Geige)','vln')
		,('Gesang','voc')
		,('Vuvuzela','vuv')
		,('Wagnertuba','wag')
		,('Trillerpfeife','whs')
		,('Holzblasinstrument','ww')
		,('Xiao','xiao')
		,('Xylophon','xyl')
		,('Concerto Grosso','cg')
		,('Concerto Grosso','cg')
		,('Konzert','ko')
		,('Oper','op')
		,('Messe','ms')
		,('Lied','li')
		,('beliebig','nn')
		,('Sinfonie','sy')
;
EOF
}
function y_get_create_tb_instrumentation () {
	cat << EOF
	CREATE TABLE instrumentation(
	  "instrumentation_id" 			INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
	  "instrumentation_status" 		INTEGER DEFAULT 0, 
	  "instrumentation_name" 		TEXT,
	  "instrumentation_type" 		TEXT,
	  "instrumentation_short" 		TEXT,
	  "instrumentation_count" 		INTEGER,
	  "instrumentation_info" 		TEXT
	);
	INSERT INTO instrumentation VALUES(1,0,'Blasmusik','O','brs',NULL,NULL);
	INSERT INTO instrumentation VALUES(2,0,'Cellokonzert','O','vlc',NULL,NULL);
	INSERT INTO instrumentation VALUES(3,0,'Concerto grosso','O','cg',NULL,NULL);
	INSERT INTO instrumentation VALUES(4,0,'Harmoniemusik','O','ww',NULL,NULL);
	INSERT INTO instrumentation VALUES(5,0,'Holzbläserquintett','C','ww',5,NULL);
	INSERT INTO instrumentation VALUES(6,0,'Horntrio','C','hrn',3,NULL);
	INSERT INTO instrumentation VALUES(7,0,'Instrumentalkonzert','O','nn',NULL,NULL);
	INSERT INTO instrumentation VALUES(8,0,'Kammersinfonie','C','sy',NULL,NULL);
	INSERT INTO instrumentation VALUES(9,0,'Sinfonie','O','sy',NULL,'test');
	INSERT INTO instrumentation VALUES(10,0,'Klarinettenquartett','C','cl',4,NULL);
	INSERT INTO instrumentation VALUES(11,0,'Klarinettenquintett','C','cl',5,NULL);
	INSERT INTO instrumentation VALUES(12,0,'Klavierkonzert','O','pf',NULL,NULL);
	INSERT INTO instrumentation VALUES(13,0,'Klavierquartett','C','pf',4,NULL);
	INSERT INTO instrumentation VALUES(14,0,'Klavierquintett','C','pf',5,NULL);
	INSERT INTO instrumentation VALUES(15,0,'Klaviertrio','C','pf',3,NULL);
	INSERT INTO instrumentation VALUES(16,0,'Kontrabasskonzert','O','vlne',NULL,NULL);
	INSERT INTO instrumentation VALUES(17,0,'Konzert für Orchester','O','ko',NULL,NULL);
	INSERT INTO instrumentation VALUES(18,0,'Nonett','C','nn',9,NULL);
	INSERT INTO instrumentation VALUES(19,0,'Oktett','C','nn',8,NULL);
	INSERT INTO instrumentation VALUES(20,0,'Orchestermusik','O','sy',NULL,NULL);
	INSERT INTO instrumentation VALUES(21,0,'Orgelmusik','C','org',1,NULL);
	INSERT INTO instrumentation VALUES(22,0,'Orgelsinfonie','C','org',1,NULL);
	INSERT INTO instrumentation VALUES(23,0,'Streichquartett','C','str',4,NULL);
	INSERT INTO instrumentation VALUES(24,0,'Violinkonzert','O','vln',NULL,NULL);
	INSERT INTO instrumentation VALUES(25,0,'Violinsonate','C','vln',1,NULL);
EOF
}
function y_get_create_tb_title () {
	cat << EOF
	CREATE TABLE title(
		"title_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
		"title_name"				TEXT UNIQUE,
		"title_name_new"			TEXT,
		"title_album_id"			INTEGER,
		"title_track_nr"			INTEGER,
		"title_opus_nr"				INTEGER,
		"title_catalog_id"			INTEGER,
		"title_instrumentation_id"	INTEGER,
		"title_artist_id"			INTEGER,
		"title_artgrp_id"			INTEGER,
		"title_track_id"			INTEGER,
		"title_info"				TEXT
);
EOF
}
function y_get_create_tb_vtrack () {
	cat << EOF
    CREATE VIEW vtrack AS 
	SELECT
	    track_id 		as rowid,
	    album_name 		as album,
	    title_name		as title,
	    composer_name 	as composer,
	    artist_name 	as artist,
	    genre_name 	    as genre
    FROM
	        track
 INNER JOIN album 	 ON album_id 		= track.track_album_id
 INNER JOIN title 	 ON title_id 		= track.track_title_id
 INNER JOIN composer ON composer_id 	= track.track_composer_id
 INNER JOIN artist	 ON artist_id		= track.track_artist_id
 INNER JOIN genre	 ON genre_id 		= track.track_genre_id
 order by rowid;
EOF
}
function y_get_create_tb_track () {
	cat << EOF
	CREATE TABLE track(
  "track_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "track_status"				INTEGER default 0,
  "track_album"					TEXT,
  "track_album_id"				INTEGER,
  "track_title"					TEXT,
  "track_title_id"				INTEGER,
  "track_nr"					INTEGER,
  "track_nr_total"				INTEGER,
  "track_composer"				TEXT,
  "track_composer_id"			INTEGER,
  "track_artist"				TEXT,
  "track_artist_id"				INTEGER,
  "track_genre"					TEXT,
  "track_genre_id"				INTEGER,
  "track_date"					TEXT,
  "track_comment"				TEXT,
  "track_duration"				TEXT,
  "track_size"					TEXT,
  "track_format_name"			TEXT,
  "track_format_long_name"		TEXT,
  "track_filename"				TEXT,
  "track_nb_streams"			TEXT,
  "track_nb_program"			TEXT,
  "track_start_time"			TEXT,
  "track_bit_rate"				TEXT,
  "track_probe_score"			TEXT,
  "track_timestamp"				TEXT,
  "track_info"					TEXT default 'batch'
);
#CREATE INDEX ix_track_album_id ON track (ref_album_id);
#CREATE INDEX ix_track_title_id ON track (ref_title_id);
#CREATE INDEX ix_track_composer_id ON track (ref_composer_id);
#CREATE INDEX ix_track_artist_id ON track (ref_artist_id);
CREATE TRIGGER track_after_insert 
   AFTER INSERT ON track
BEGIN
	INSERT OR IGNORE INTO album (album_id,album_name,album_tracks,album_path) VALUES ((select max(album_id) + 1 from album),new.track_album,new.track_nr_total,rtrim(new.track_filename,replace(new.track_filename, '/', '')));
    UPDATE track set track_album_id = (select album_id from album where album_name = new.track_album) where track_id = new.track_id;
	INSERT OR IGNORE INTO title (title_id,title_name,title_name_new,title_track_nr) VALUES ((select max(title_id) + 1 from title),new.track_title,new.track_title,new.track_nr);
    UPDATE track set track_title_id = (select title_id from title where title_name = new.track_title) where track_id = new.track_id;
	INSERT OR IGNORE INTO composer (composer_id,composer_name) VALUES ((select max(composer_id) + 1 from composer),new.track_composer);
    UPDATE track set track_composer_id = (select composer_id from composer where composer_name = new.track_composer) where track_id = new.track_id;
	INSERT OR IGNORE INTO artist (artist_id,artist_name) VALUES ((select max(artist_id) + 1 from artist),new.track_artist);
    UPDATE track set track_artist_id = (select artist_id from artist where artist_name = new.track_artist) where track_id = new.track_id;
	INSERT OR IGNORE INTO genre (genre_id,genre_name) VALUES ((select max(genre_id) + 1 from genre),new.track_genre);
    UPDATE track set track_genre_id = (select genre_id from genre where genre_name = new.track_genre) where track_id = new.track_id;
#    UPDATE OR IGNORE genre set genre_genrelist_id = (select genrelist_id from genrelist where genrelist_name = genre_name) where genre_name = genrelist_name;
END;
EOF
}
function y_get_create_tb_ () {
	cat << EOF
EOF
}
	_amain  $*
exit 
# insert into tracks select null,tags_album,tags_title,tags_composer,tags_track,tags_artist,tags_genre,duration,size,filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate,probe_score from file;

