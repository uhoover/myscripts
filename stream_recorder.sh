#!/bin/bash
#
	source /home/uwe/my_scripts/myfunctions.sh
	set -o noglob
	

#
function _ctrl () {
	echo $$ > /tmp/script_pid.tmp
	[ ! -d $HOME/tmp ] && mkdir $HOME/tmp
	folder="${0##*\/}"
	mypath="/tmp/.${folder%%\.*}"
	crontab="$HOME/tmp/crontab.txt"
	fileurl="$HOME/my_scripts/resources/url_list.txt"
	fileparm="$HOME/tmp/parmfile.txt"
	pathvideo="$HOME/Videos";[ ! -d $pathvideo ] && mkdir $pathvideo
	pathmusic="$HOME/Musik/radioripps"; [ ! -d $pathmusic ] && mkdir $pathmusic
	urlliste="${mypath}/url_list.txt"
	fileurl="$urlliste"
    tvliste="${mypath}/tv_channels_list.xspf"
    radioliste="${mypath}/radio_channels_list.xspf"
    tmpf="${mypath}/tempfile.txt"
    dbinfo="/home/uwe/my_databases/info.sqlite"
    [ ! -d $mypath ] && mkdir $mypath  
#	ftest;return
	if [ $# -eq 0 ];then 
		func=$(zenity --list --height=300 --column 'action' 'create_cronjob' 'delete_cronjob' 'record' 'create_playlist' 'play' 'play_timeshift' 'play_tv' 'play_tv_timeshift' 'play_radio' 'play_radio_timeshift')
	else
		func=$1;shift
	fi
	case "$func" in 
		 "cronjob")  		create_cronjob  	$@;;
		 "create_cronjob")  create_cronjob  	$@;;
		 "delete")   		delete_cronjob  	$@;;
		 "delete_cronjob")  delete_cronjob  	$@;;
	 	 "record")   		record_channel  	$@;;
	 	 "record_channel")  record_channel  	$@;;
		 "playlist") 		create_playlist 	$@;;
		 "create_playlist") create_playlist 	$@;;
		 "play") 			play_stream_neu	$false ;;
		 "play_timeshift") 	play_stream_neu	$true  ;;
		 "play_tv") 		play_stream	$false tv		$@;;
		 "play_radio") 		play_stream	$false radio	$@;;
		 "play_tv_timeshift") 		play_stream	$true tv	$@;;
		 "play_radio_timeshift") 	play_stream	$true radio	$@;;
		 "play_stream") 	play_stream_neu	$@;;
		 "timeshift_on") 	vputp "-|timeshift|$true"	$@;;
		 "timeshift_off") 	vputp "-|timeshift|$false"	$@;;
		 *) log "parameter unbekannt $func $@"; 
	esac
}
function ftest2 () {
	cat << EOF
			<buttonneu>
				<label>help</label>
				<variable>BUTTONHELP$label</variable>
				<action>$script --func tb_ctrl_gui "b_help     | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
EOF
}
function ftest () {
	set -x
	create_cronjob "Deutschlandfunk Kultur#Nachrichten#2022#4#15#20#0#3"
	set +x
}
function play_stream () {
	timeshift=$1;shift;func=$1;shift;line="";start=$false
	while IFS='#' read short channel url trash;do 
		[ "$(trim_space $short)" = 'daserste' ] 		&& start=$true
		[  $start -ne $true ] && [ "$func" = "tv" ]		&& continue
		[  $start -eq $true ] && [ "$func" = "radio" ]	&& break
		line="$line '$(trim_space $channel)' '$(trim_space $url)'"
	done < "${mypath}/url_list.txt"
	while : ;do
		url=$(eval 'zenity --width=650 --height=800 --list --print-column 2 --column sender --column url' $line)
		[ "$url" = "" ] && break
		if [ $timeshift -eq $true ]; then  
			file="/tmp/ts_${func}_$(date "+%Y_%m_%d_%H_%M").ts"
			[ -f "$file" ] && rm "$file"
			(ffmpeg -hide_banner -re -i "$url" -codec: copy "$file"  & ) 2> /dev/null
			zprogress
			url="$file"
		fi
		ffplay "$url" &
	done
	[ $timeshift -eq $false ] && return
	setmsg -q ffmpeg beenden
	[ $? -eq 0 ] && killall ffmpeg
}
function play_stream_neu () {
	if [ $# -eq 1 ]; then
		vputp "play|timeshift|$*"
		/home/uwe/my_scripts/dbms.sh "$dbinfo" "channels" 
		return
	fi
	timeshift=$(vgetp "parm_value" "play" "timeshift")
	shift;parm="$*";IFS='|';arr=($parm);unset IFS;db=$(trim_space ${arr[3]});tb=$(trim_space ${arr[4]});id=$(trim_space ${arr[5]})
#	setmsg -i "timeshift $timeshift\ndb ${arr[3]}\ntb ${arr[4]}\nid ${arr[5]}"
	stmt=".separator |\nselect title,url from $tb where rowid = $id"
	rc=$(sql_execute "$db" "$stmt" | tr -d '"');title=$(trim_space ${rc%%\|*});url=$(trim_space ${rc#*\|})
	setmsg -i "title $title\nurl $url"
	ffplay -window_title "$title" "$url"
}
function zprogress ()    {
(for i in 20 40 70 100;do echo "$i";sleep 1;done) | zenity --progress --text="buffering..." --percentage=0 --auto-close
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
		echo $line # > $fileparm
		return
	done
}
function cron_setparm_del () {
# Deutschlandfunk Kultur#Nachrichten#2022#4#15#20#0#3
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
    log $@ 	
    func=$1;shift
	parm=$*
	IFS='#';arr=($parm);unset IFS
	_channel=${arr[0]};schannel=$(_short_name $_channel)
	_title=${arr[1]} 
	_year=${arr[2]} 
	_month=${arr[3]} 
	_day=${arr[4]} 
	_date=$(printf "%d-%02d-%02d" $_year $_month $_day)
	_hour=${arr[5]} 
	_minute=${arr[6]} 
	_time=$(printf "%02d:%02d" $_hour $_minute) 
	_length=${arr[7]}
	line=$(cron_get_url $_channel)
	IFS='#';arr2=($line);unset IFS
	type=$(echo ${arr2[3]} | tr -d " ")
	[ "$type" = "radio" ] && type="mp3"
	[ "$type" = "tv" ]    && type="mp4"
	url=$(echo ${arr2[2]} | tr -d " ")
	target=$(echo "$schannel ${_title}.$type" | tr " :" "_-")
	if [ "$type" = "mp4" ] || [ "$type" = "tv" ];then pathtarget=${pathvideo};else pathtarget=${pathmusic};fi
	[ ! -f "$pathtarget" ] && mkdir -p $pathtarget
	target="${pathtarget}/$target" 
	pfad=$(readlink -f $0)
	if [ "$func" = "delete" ];then echo $target;return;fi
	echo "$_minute $_hour $_day $_month * $pfad \"record\" \"$url\" \"${target}\" \"$_length\""  
}
function create_cronjob () {
	#cronjob {channel_name}#{title}#{start_year}-{start_month}-{start_day}#{start_hour}:{start_minute}#{length_minutes}#{url}
	log "$@" 
	cmd=$(cron_cmd create $@)
	log $cmd
	set -o noglob
	crontab -l  >  $crontab
	echo "$cmd" >> $crontab
	crontab -u $USER $crontab
	echo "Aufnahme hinzugefuegt: $cmd"
}
function delete_cronjob () {
	log "$@"
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
	file="$2";first=${file%\.*};last=${file##*\.};file="${first}_$(date +%Y_%m_%d_%H_%M).$last"
	log "record stream start $1 $2 $3 $file"
#	ffmpeg -hide_banner -re -i "$1" -codec: copy "$file" 2> /dev/null &
    ffmpeg -hide_banner -re -i "$1" -codec: copy "$file"  &
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
	ftype="$*"
	pl_write_liste '<?xml version="1.0" encoding="UTF-8"?>'
	pl_write_liste '<playlist xmlns="http://xspf.org/ns/0/" xmlns:vlc="http://www.videolan.org/vlc/playlist/ns/0/" version="1">'
	pl_write_liste '	<title>'$@'</title>'
	pl_write_liste '	<trackList>'
}    
function pl_write_bottom () {
	pl_write_liste '	</trackList>'
	#~ pl_write_liste '	<extension application="http://www.videolan.org/vlc/playlist/0">'
	#~ for ((i=0;i<=$id;i++));do
		#~ pl_write_liste '		<vlc:item tid="'$i'"/>'
	#~ done
	#~ pl_write_liste '	</extension>'
	pl_write_liste '</playlist>'
}    
function pl_write_track () {
	id=$(($id+1))
	if [ "$channel" != "" ]; then ntitle="$channel $title";else ntitle=$title;fi
	ntitle=$(echo "${ntitle//\&quot\;}" | tr -d '"\Ⓖ\Ⓢ')
	[ "$(echo $ntitle | grep '48 kbit')" != "" ] && return
	[ "$(echo $ntitle | grep '96 kbit')" != "" ] && return
	[ "$(echo $ntitle | grep '24 kbit')" != "" ] && return
	nurl="${url%\?*}"
	nurl=${nurl//\&quot\;}
	pl_write_liste '		<track>'
	pl_write_liste '			<location>'$nurl'</location>'
	pl_write_liste '			<title>'$ntitle'</title>'
	if [ "$image" != "" ]; then pl_write_liste '			<image>'${image//\&quot\;}'</image>';fi
	#~ pl_write_liste '			<extension application="http://www.videolan.org/vlc/playlist/0">'
	#~ pl_write_liste '				<vlc:id>'$id'</vlc:id>'
	#~ pl_write_liste '				<vlc:option>network-caching=1000</vlc:option>'
	#~ pl_write_liste '			</extension>'
	pl_write_liste '		</track>'
	if [ "$channel" != "" ]; then ntitle=$channel;else ntitle=$title;fi
	stitle=$(_short_name $ntitle)
	echo "$stitle # $ntitle # $nurl # $ftype" >> $urlliste
} 
function pl_tv () {
#	_curl_liste "$tfile" "https://github.com/Free-IPTV/Countries/blob/master/DE01_GERMANY.m3u"
    _curl_liste "$tfile" "https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8"
	playliste=$tvliste
	[ -f $playliste ] && rm $playliste
	channel="";found=$false
    pl_write_head tv
#   grep 'js-file-line' $tfile |
	curl "https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8" 2> /dev/null |
	while read -r line; do
		line=$(echo $line | tr -d 'Ⓢ' | tr -d 'Ⓖ')
		str=${line#*\>}
		line=${str%*\<*} 
        if [ "${line:0:7}" = "#EXTINF" ]; then
            echo $line | grep -iq germany 
            [ $? -eq $true ] && found=$true || found=$false
        fi
        [ $found -eq $false ] && continue
		if [ "${line:0:7}" = "#EXTINF" ]; then
			str=$(echo $str | cut -d '"' --output-delimiter='|' -f2,4) 
			title=${str%%\|*}
			image=${str##*\|}
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
	playliste=$radioliste
	if [ $id -lt 0 ];then
	    [ -f $playliste ] && rm $playliste
	    pl_write_head radio
	fi
#	site="https://www.deutschlandradio.de/unsere-streaming-adressen-im-einzelnen.3236.de.html"
	site="https://www.deutschlandradio.de/streamingdienste.3236.de.html"
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
			title=${title%%\>*}
			pl_write_track
		done
	done
} 
function pl_radio_rest () {
	playliste=$radioliste
	if [ $id -lt 0 ];then
	    [ -f $playliste ] && rm $playliste
	    pl_write_head radio
	fi
    image="";title="kriola";url="http://stream.laut.fm/kriola.m3u";pl_write_track	 
} 
function pl_xine () {
	start=$false
	while read -r line;do
		str=${line#*<};tag=${str%%\>*}
		str2=${str#*>};url=${str2%%\<*}
		[ "$tag" = "trackList" ] 	&& start=$true && continue
		[  $start -ne $true ]		 			   && continue
		case "$tag" in
			  track)	echo "entry {" ;;
			  title)	echo "	identifier = $url"  
						echo "$str3;";;
			  location)	str3="	mrl = $url;"  ;;
			  /track)	echo "};" ;;
			*) :
		esac
	done < "$*"
}
function create_playlist () {
	log "create playlist $@" 
    za=-1;id=-1
    radioliste2="${mypath}/radio_channels_list2.xspf"
    radioliste3="${mypath}/radio_channels_list3.xspf"
    tfile="${mypath}/curl.http"
	ofile="${mypath}/curl.txt"
#	[ -f $urlliste ] && rm $urlliste
	echo "short#title#url#type" > "$urlliste"
#   id=-1;pl_radio_dlf;pl_write_bottom 
	id=-1;pl_radio_wdr;pl_radio_dlf;pl_radio_rest;pl_write_bottom
    id=-1;pl_tv
    pl_xine "$tvliste" > "${mypath}/tv_channels_list.tox" 
	pl_xine "$radioliste" > "${mypath}/radio_channels_list.tox" 
	return
	echo "drop table if exists channels;" > "$tmpf"
	echo ".separator #"  >> "$tmpf"
	echo ".import  $urlliste channels"  >> "$tmpf"
	sql_execute "$dbinfo" ".read $tmpf"
}
function xexit () {
	exit
}
	log logon
	_ctrl $*
	log logoff
#xexit	
