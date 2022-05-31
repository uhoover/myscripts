#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
# elif if ifl case                        << snipped    
# for fora fori foria while wtrue read    << snipped    
# str strf strl strc strca strd strda     << snipped    
# func funcl trap	 arr arrl               << snipped    
 source /home/uwe/my_scripts/myfunctions.sh
function aexit() {
	retcode=0 
	log logoff
}
 trap aexit	 EXIT
 set -e  # bei fehler sprung nach xexit
#
function notebook () {
	cat << EOF > /tmp/nb.txt
	<window>
	<vbox>
	<hbox>
	<notebook tab-labels="eins|zwei|drei" page="$page" height-request="400" width-request="400">
		<vbox><text><label>uwe ist lieb</label></text></vbox>
		<vbox><text><label>uwe ist doof</label></text></vbox>
		<vbox><text><label>uwe ist cool</label></text></vbox>
		<variable>varname</variable>
		<input file autorefresh="true">$ifile</input>
		<output file>$ifile</output>
        <action signal="focus-out-event">save:varname</action>
	</notebook>
	</hbox>
	<button type="exit"></button>
	<button><label>refresh</label><action type="refresh">varname</action></button>
	</vbox>
	</window>
EOF
	gtkdialog -f /tmp/nb.txt
}
function actions () {
	[ -z $GTKDIALOG ] && GTKDIALOG=gtkdialog

MAIN_DIALOG='
<window title="Signals" icon-name="gtk-dialog-warning">
	<vbox>
		<frame Widgets>
			<text>
				<label>Label</label>
				<action signal="button-press-event">echo Label: button-press-event</action>
				<action signal="button-release-event">echo Label: button-release-event</action>
				<action signal="configure-event">echo Label: configure-event</action>
				<action signal="enter-notify-event">echo Label: enter-notify-event</action>
				<action signal="leave-notify-event">echo Label: leave-notify-event</action>
				<action signal="focus-in-event">echo Label: focus-in-event</action>
				<action signal="focus-out-event">echo Label: focus-out-event</action>
				<action signal="key-press-event">echo Label: key-press-event</action>
				<action signal="key-release-event">echo Label: key-release-event</action>
				<action signal="hide">echo Label: hide</action>
				<action signal="show">echo Label: show</action>
				<action signal="realize">echo Label: realize</action>
				<action signal="map-event">echo Label: map-event</action>
				<action signal="unmap-event">echo Label: unmap-event</action>
			</text>
			<entry>
				<default>Entry</default>
				<action signal="button-press-event">echo Entry: button-press_event</action>
				<action signal="button-release-event">echo Entry: button-release-event</action>
				<action signal="configure-event">echo Entry: configure-event</action>
				<action signal="enter-notify-event">echo Entry: enter-notify-event</action>
				<action signal="leave-notify-event">echo Entry: leave-notify-event</action>
				<action signal="focus-in-event">echo Entry: focus-in-event</action>
				<action signal="focus-out-event">echo Entry: focus-out-event</action>
				<action signal="key-press-event">echo Entry: key-press-event</action>
				<action signal="key-release-event">echo Entry: key-release-event</action>
				<action signal="hide">echo Entry: hide</action>
				<action signal="show">echo Entry: show</action>
				<action signal="realize">echo Entry: realize</action>
				<action signal="map-event">echo Entry: map-event</action>
				<action signal="unmap-event">echo Entry: unmap-event</action>
			</entry>
		</frame>
		<hbox>
			<button ok>
				<action signal="button-press-event">echo Button: button-press_event</action>
				<action signal="button-release-event">echo Button: button-release-event</action>
				<action signal="configure-event">echo Button: configure-event</action>
				<action signal="enter-notify-event">echo Button: enter-notify-event</action>
				<action signal="leave-notify-event">echo Button: leave-notify-event</action>
				<action signal="focus-in-event">echo Button: focus-in-event</action>
				<action signal="focus-out-event">echo Button: focus-out-event</action>
				<action signal="key-press-event">echo Button: key-press-event</action>
				<action signal="key-release-event">echo Button: key-release-event</action>
				<action signal="hide">echo Button: hide</action>
				<action signal="show">echo Button: show</action>
				<action signal="realize">echo Button: realize</action>
				<action signal="map-event">echo Button: map-event</action>
				<action signal="unmap-event">echo Button: unmap-event</action>
			</button>
		</hbox>
	</vbox>
	<action signal="button-press-event">echo Window: button-press_event</action>
	<action signal="button-release-event">echo Window: button-release-event</action>
	<action signal="configure-event">echo Window: configure-event</action>
	<action signal="delete-event">echo Window: delete-event</action>
	<action signal="destroy-event">echo Window: destroy-event</action>
	<action signal="enter-notify-event">echo Window: enter-notify-event</action>
	<action signal="leave-notify-event">echo Window: leave-notify-event</action>
	<action signal="focus-in-event">echo Window: focus-in-event</action>
	<action signal="focus-out-event">echo Window: focus-out-event</action>
	<action signal="key-press-event">echo Window: key-press-event</action>
	<action signal="key-release-event">echo Window: key-release-event</action>
	<action signal="hide">echo Window: hide</action>
	<action signal="show">echo Window: show</action>
	<action signal="realize">echo Window: realize</action>
	<action signal="map-event">echo Window: map-event</action>
	<action signal="unmap-event">echo Window: unmap-event</action>
</window>
'
export MAIN_DIALOG

case $1 in
	-d | --dump) echo "$MAIN_DIALOG" ;;
	*) $GTKDIALOG --program=MAIN_DIALOG ;;
esac
}
function tree () {
	cat << EOF  | grep -v '^#' > /tmp/nb.txt
	<window>
	<vbox>
	<tree>
		<label>composer_id|composer_status|composer_name|composer_name_last|composer_name_first|composer_name_short|composer_title|composer_from|composer_birthplace|composer_to|composer_place_of_death|composer_info</label>
		<variable>tree</variable>
		<input file autorefresh="true">/home/uwe/.dbms/export/export_composer_home_uwe_my_databases_test#sqlite.csv</input>
#        <action signal="enter-notify-event">show:button</action>
#        <action signal="leave-notify-event">hide:button</action>
#        <action signal="focus-in-event">show:button</action>
#        <action signal="focus-out-event">hide:button</action>
#        <action signal="key-press-event">show:button</action>
#        <action signal="key-release-event">hide:button</action>
#		 <action signal="row-activated">show:button</action>
		 <action signal="changed">show:button</action>
	</tree>
	<hbox>
	<button type="exit"></button>
	<button visible="false">
		<label>refresh</label>
		<variable>button</variable>
		<action type="hide">button</action>
	</button>
	</hbox>
	</vbox>
	</window>
EOF
	gtkdialog -f /tmp/nb.txt --geometry=800x600+100+100
}
function view () {
	cat << EOF > /tmp/nb.txt
    drop view if exists vtrack;
    CREATE VIEW vtrack AS 
	SELECT
	    track_id 		as id,
	    album_name 		as album,
	    title_name		as title,
	    composer_name 	as composer,
	    artist_name 	as artist,
	    genre_name 	    as genre
    FROM
	        track
 INNER JOIN album 	 ON ref_track_album = track.ref_album_id
 INNER JOIN title 	 ON title_id 		= track.track_id
 INNER JOIN composer ON composer_id 	= track.ref_composer_id
 INNER JOIN artist	 ON artist_id		= track.ref_artist_id
 INNER JOIN genre	 ON genre_id 		= track.ref_genre_id
 order by id;
--select * from vtrack where id < 100;
EOF
	echo ".read /tmp/nb.txt" | sqlite3 /home/uwe/my_databases/music.sqlite
}
function ctrl () {

	ifile="/tmp/in.txt";[ ! -f "$ifile" ] && echo 1 > "$ifile"
	echo "pdb=\"$db\";ptb=\"$tb\";delim=\"|\" # $ifile" > "$ifile"
	db="/home/uwe/my_databases/music.sqlite";tb="catalog";separator="|"
	line=$(grep "$ifile" "$ifile");[ "$line" != "" ] && eval "$line"
#	echo "db $pdb"
#	echo "tb $ptb"
#	echo "dl $delim"
#	return
#	page=$(<$ifile)
#	log logon
#	notebook
#    view	
# 	tree
#	actions
#	preparedStatement
	import
	return
}
function import () {
	import='/tmp/import.txt'
	read='/tmp/read.sql'
	cat << EOF > $import
catalog_id,catalog_name,catalog_short
1,"Verzeichnis nach Fritz",Kn
70,"Verzeichnis nach Uwe",Uwe
,"Verzeichnis nach Dani",Dani
EOF
	tb_meta_info "$db" "$tb"
	header=$(head -n 1 $import)
	IFS=',';fields=($GTBNAME);cols=($header)
	IFS='|';meta=($GTBMETA);unset IFS
	declare -p fields meta cols
	for ((ib=0;ib<${#fields[@]};ib++)) ;do 
		af[$ib]='null'
		key=${meta[$ib]}
		ak[$ib]=${key##*\,}
		am[$ib]=${key%%\,*}
	done
	update="";insert="";pk="";pkb="";pkt="";tmp="tmp";select="";on=""
	for ((ia=0;ia<${#cols[@]};ia++)) ;do
		found=$false 
		for ((ib=0;ib<${#fields[@]};ib++)) ;do
			[ "${cols[$ia]}" != "${fields[$ib]}" ] && continue
			found=$true
			af[$ib]="${fields[$ib]}"
			break
		done
		[ $found -eq $true ] && continue
		echo "column not known ${cols[$ib]}"
		return 1
	done
	(
	echo "drop table if exists $tmp;"
	echo ".separator ,"
	echo ".import \"$import\" $tmp"
	echo "-- null value in primary key for insert to force autoincrement"
	) > $read
	for ((ib=0;ib<${#fields[@]};ib++)) ;do
		select="${select},a.${af[$ib]}"
		if 	[ ${ak[$ib]} -lt 1 ];then
			if [ "${af[$ib]}" != "null" ];then 
				update="${update},${fields[$ib]}"
				set="${set},${tmp}.${fields[$ib]}"
			fi
			continue
		fi
		on="${on}and a.${fields[$ib]} = b.${fields[$ib]}" 
		[ "$pk" = "" ] && pk="${fields[$ib]}"
		wh="${wh}or b.${fields[$ib]} is null" 
		echo "update $tmp set ${fields[$ib]} = null where abs(${fields[$ib]}) = 0;" >> $read
	done
	select=${select//a.null/null}
	[ "$on" = "" ] && echo no pk && return
	(
	echo "-- file may contain new rows"		 
	echo "insert into $tb"		 
	echo "select ${select:1}"					 
	echo "from   $tmp as a left join $tb as b on ${on:4}"	
	echo "where  ${wh:3};"	
	echo "-- update only rows matching primaray key"		 
	echo  "update $tb set (${update:1}) ="
	echo  "       (select  ${update:1} from $tmp"
	on=${on//a\./$tb\.};on=${on//b\./$tmp\.}
	echo  " 	   where ${on:4}) "
	echo  " 	   where ${pk} in (select a.${pk} from $tmp as a inner join $tb as b on a.${pk} = b.${pk});"
	) >> $read
}
function preparedStatement () { 
	parm='5 Sülzle Uwe'
	eval 'printf "set id = %s,name = \"%s\", vorname = \"%s\"\n" $parm'
} 
function zz () { return; } 
	ctrl notebook.sh
