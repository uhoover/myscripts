#!/bin/bash
#
	source /home/uwe/my_scripts/my_functions.sh
#
	echo $$ >/tmp/script_pid.tmp
	[ ! -d $HOME/tmp ] && mkdir $HOME/tmp
	crontab="$HOME/tmp/crontab.txt"
	fileurl="$HOME/my_scripts/resources/url_list.txt"
	fileparm="$HOME/tmp/parmfile.txt"
	pathvideo="$HOME/Videos";[ ! -d $pathvideo ] && mkdir $pathvideo
	pathmusic="$HOME/Musik/radioripps"; [ ! -d $pathmusic ] && mkdir $pathmusic
function _ctrl () {
	if [ $# -gt 0 ];then 
		func=$1;shift
	else
		func="record"
	fi
	case "$func" in 
		 "cronjob")  		create_cronjob  $@;;
		 "create_cronjob")  create_cronjob  $@;;
		 "delete")   		delete_cronjob  $@;;
		 "delete_cronjob")  delete_cronjob  $@;;
	 	 "record")   		record_channel  $@;;
		 "playlist") 		create_playlist $@;;
		 *) log "parameter unbekannt $func"; 
	esac
}
function _curl_liste () {
	outfile="$1"
	infile="$2"
	[ -f $outfile ] && rm $outfile
	curl --output "$outfile" "$infile" 2> /dev/null
}
function _short_name () {
	sname="$*"
	sname=$(echo $* | tr '[:upper:]' '[:lower:]' | tr '"' ' ')
	sname=${sname%\ hd*} 
	echo ${sname%\(*} | tr -d ' "'
}
function cron_get_url () {
	thischannel=$(_short_name $*)
	echo "not found $* $thischannel" > $fileparm
	case "$thischannel" in
		"wdr2"|"wdr 2") thischannel="wdr2(ruhrgebiet)"	;;
		"wdr3") thischannel="WDR 3 (mp3, 256 kBit/s)"	;;
		"wdr")  thischannel="wdrkoeln"	;;
		"deutschlandfunkkultur")  thischannel="dradiokultur"	;;
		"deutschlandfunknova")  thischannel="dradiowissen"	;;
	esac
	sort -r $fileurl |
	grep "$thischannel " |
	while read -r line;do
		if [ "${line:0:7}" = "deutsch" ] || [ "${line:0:6}" = "dradio" ]; then
		   erg=$(echo $line | grep -i "mp3") 
		   if [ "$erg" = "" ]; then continue;fi
		fi
		echo $line > $fileparm
	done
}
function cron_setparm () {
	log debug_off
	_channel=$1;log debug "channel   $1";shift;schannel=$(_short_name $_channel);log debug "schannel  $schannel"
	_title=$1;log debug "title   $1";shift
	_year=$1;log debug "year   $1";shift
	_month=$1;log debug "month   $1";shift
	_day=$1;log debug "day   $1";shift
	_date=$(printf "%d-%02d-%02d" $_year $_month $_day);log debug "date   $_date"
	_hour=$1;log debug "hour   $1";shift
	_minute=$1;log debug "minute   $1";shift
	_time=$(printf "%02d:%02d" $_hour $_minute);log debug "time   $_time"
	_length=$1;log debug "length   $1";shift
	log debug_off
}
function cron_cmd () {
	func=$1;shift
	if [ $# -gt 0 ];then 
		parm=$*
	else
		parm="WDR#Meister des Alltags#2021#1#28#10#45#30#https://www.swr.de/meister-des-alltags/-/id=13831182/c17p8c/index.html"
	fi
	IFS='#';cron_setparm  $parm;unset IFS
	cron_get_url $_channel
	line=$(<$fileparm)
	IFS='#';set  $line;unset IFS
	type=$(echo $4 | tr -d " ")
	url=$(echo $3 | tr -d " ")
#	target=$(echo "$schannel $_title $_date ${_time}.$type" | tr " :" "_-")
	target=$(echo "$schannel ${_title}.$type" | tr " :" "_-")
	if [ "$type" = "mp4" ];then pathtarget=${pathvideo};else pathtarget=${pathmusic};fi
	[ ! -f "$pathtarget" ] && mkdir -p $pathtarget
	target="${pathtarget}/$target" 
	pfad=$(readlink -f $0)
	if [ "$func" = "delete" ];then echo $target;return;fi
	echo "$_minute $_hour $_day $_month * $pfad \"record\" \"$url\" \"${target}\" \"$_length\""  
}
function create_cronjob () {
	#cronjob {channel_name}#{title}#{start_year}-{start_month}-{start_day}#{start_hour}:{start_minute}#{length_minutes}#{url}
	log "create cronjob $@" 
	cmd=$(cron_cmd create $@)
	set -o noglob
	crontab -l  >  $crontab
	echo "$cmd" >> $crontab
	crontab -u $USER $crontab
	echo "Aufnahme hinzugefuegt: $cmd"
}
function delete_cronjob () {
	log "delete cronjob $@"
	title=$(cron_cmd delete $@) 
	if [ "$(crontab -l | grep -v "^#"  | grep -l $title)" = "" ]; then echo "kein cronjob mit $title";return;fi 
	set -o noglob
	crontab -l | grep "^#"   > $crontab
	crontab -l | grep -v "^#"  | grep -v "$title" >> $crontab
	crontab -u $USER $crontab
	echo "cronjob(s) geloescht mit $title"
}
function record_channel () {
	if [ $# -lt 1 ];then 
		set -- "https://das.erste" "/tmp/daserste.mp4" "30"
	fi
	log "record stream start $1 $2 $3"
	file=$2;first=${file%\.*};last=${file##*\.};file="${first}_$(date +%Y_%m_%d_%H_%M).$last"
	ffmpeg -hide_banner -re -i "$1" -codec: copy "$file" 2> /dev/null &
	lrc=$!
	tsleep=$3;tsleep=$(($tsleep*60))
	sleep $tsleep
	kill -TERM $lrc	 
	log "record strean end"
}
function pl_write_liste () {
	echo "$*" >> $playliste
}
function pl_write_head () {
	if [ "$*" = "tv" ];then ftype="mp4";else ftype="mp3";fi
	pl_write_liste '<?xml version="1.0" encoding="UTF-8"?>'
	pl_write_liste '<playlist xmlns="http://xspf.org/ns/0/" xmlns:vlc="http://www.videolan.org/vlc/playlist/ns/0/" version="1">'
	pl_write_liste '	<title>'$@'</title>'
	pl_write_liste '	<trackList>'
}    
function pl_write_bottom () {
	pl_write_liste '	</trackList>'
	pl_write_liste '	<extension application="http://www.videolan.org/vlc/playlist/0">'
	for ((i=0;i<=$id;i++));do
		pl_write_liste '		<vlc:item tid="'$i'"/>'
	done
	pl_write_liste '	</extension>'
	pl_write_liste '</playlist>'
}    
function pl_write_track () {
	id=$(($id+1))
	if [ "$channel" != "" ]; then ntitle="$channel $title";else ntitle=$title;fi
	ntitle=$(echo "${ntitle//\&quot\;}" | tr -d '"')
	nurl="${url%\?*}"
	nurl=${nurl//\&quot\;}
	pl_write_liste '		<track>'
	pl_write_liste '			<location>'$nurl'</location>'
	pl_write_liste '			<title>'$ntitle'</title>'
	if [ "$image" != "" ]; then pl_write_liste '			<image>'${image//\&quot\;}'</image>';fi
	pl_write_liste '			<extension application="http://www.videolan.org/vlc/playlist/0">'
	pl_write_liste '				<vlc:id>'$id'</vlc:id>'
	pl_write_liste '				<vlc:option>network-caching=1000</vlc:option>'
	pl_write_liste '			</extension>'
	pl_write_liste '		</track>'
	if [ "$channel" != "" ]; then ntitle=$channel;else ntitle=$title;fi
	stitle=$(_short_name $ntitle)
	echo "$stitle # $ntitle # $nurl # $ftype" >> $urlliste
} 
function pl_tv () {
	_curl_liste "$tfile" "https://github.com/Free-IPTV/Countries/blob/master/DE01_GERMANY.m3u"
	playliste=$tvliste
	[ -f $playliste ] && rm $playliste
	channel=""
    pl_write_head tv
    grep 'js-file-line' $tfile |
	while read -r line; do
		str=${line#*\>}
		line=${str%*\<*} 
		if [ "${line:0:7}" = "#EXTINF" ]; then
			str=${line#*=}
			title=${str%% tvg-id*}
			str=${line#*tvg-logo=}
			image=${str%% group-title*}
		fi
		if [ "${line:0:4}" != "http" ]; then continue;fi
		url=$line
		pl_write_track
	done  
	pl_write_bottom
} 
function pl_radio_wdr () {
	playliste=$radioliste
	[ -f $playliste ] && rm $playliste
	_curl_liste "$tfile" "https://www1.wdr.de/unternehmen/der-wdr/serviceangebot/digitalradio/streams-100.html"
	image=""
	channel=""
	pl_write_head radio
	erg=$(grep '<ul><li>' $tfile)
	while true;do
	    erg=${erg#*<li>}
	    line=${erg%%</li>*}
	    if [ "$line" = "" ];then break;fi
	    if [ "$line" = "$lineold" ];then break;fi
	    lineold=$line
	    str=${line#*<strong>}
		title=${str%%</strong*}
		str=${line#*</strong>}
		title="$title${str%% - Url*}"
		url=${line#*Url\: }
		pl_write_track
	done
}
function pl_radio_dlf () {
	playliste=$radioliste2
	if [ $id -lt 0 ];then
	    [ -f $playliste ] && rm $playliste
	    pl_write_head radio
	fi
	site="https://www.deutschlandradio.de/unsere-streaming-adressen-im-einzelnen.3236.de.html"
	_curl_liste "$tfile" "$site"
	grep '<p class=' "$tfile" |
	while read -r erg;do
        image="start"
		erg=${erg#*<p class=}
		line=${erg%%\ class\=\"dradioImage\"*}
		if [ "$line" = "$erg" ];then line=${erg%%>*};image="";fi
		if [ "$line" = "" ];then break;fi
		if [ "$line" = "$lineold" ];then break;fi
		lineold=$line
		channel=${line%%block*}
		if [ "$image" != "" ];then image=$(echo "https://www.deutschlandradio.de/${line#*img src=}" | tr -d '"');fi
		echo "channel: $channel"
		echo "image:   $image"
		while true;do
			erg=${erg#*<a href=}
			line=${erg%%<\/a>*}
			if [ "$line" = "" ];then break;fi
			if [ "$line" = "$lineold" ];then break;fi
			lineold=$line
			url=$(echo ${line%% class=*} | tr -d '"')
#			url="${url%\?*}"
			if [ "${url:0:4}" != "http" ]; then continue;fi
			title=${line#*title=}
			title=${title%% target=*}
			pl_write_track
		done
	done
} 
function pl_radio_rest () {
	playliste=$radioliste3
	if [ $id -lt 0 ];then
	    [ -f $playliste ] && rm $playliste
	    pl_write_head radio
	fi
    image="";title="kriola";url="http://stream.laut.fm/kriola.m3u";pl_write_track	 
} 
function create_playlist () {
	log "create playlist $@" 
	mypath=$HOME'/.config/vlc/'
	mypath=$HOME'/tmp/'
    za=-1;id=-1
    urlliste="${mypath}url_list.txt"
    tvliste="${mypath}tv_channels_list.xspf"
    radioliste="${mypath}radio_channels_list.xspf"
    radioliste2="${mypath}radio_channels_list2.xspf"
    radioliste3="${mypath}radio_channels_list3.xspf"
    tfile=$HOME'/tmp/curl.http'
	ofile=$HOME'/tmp/curl.txt'
	[ -f $urlliste ] && rm $urlliste
#   id=-1;pl_radio_dlf;pl_write_bottom 
	id=-1;pl_radio_wdr;pl_radio_dlf;pl_radio_rest;pl_write_bottom
    id=-1;pl_tv
}
function xexit () {
	exit
}
	log file start
	_ctrl $*
	log stop
xexit	
