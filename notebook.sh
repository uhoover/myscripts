#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
# elif if ifl case                        << snipped    
# for fora fori foria while wtrue read    << snipped    
# str strf strl strc strca strd strda     << snipped    
# func funcl trap	 arr arrl               << snipped    
 source /home/uwe/my_scripts/my_functions.sh
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
function view () {
	cat << EOF > /tmp/nb.txt
    drop view if exists vtrack;
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
 INNER JOIN album 	 ON ref_track_album = track.ref_album_id
 INNER JOIN title 	 ON title_id 		= track.track_id
 INNER JOIN composer ON composer_id 	= track.ref_composer_id
 INNER JOIN artist	 ON artist_id		= track.ref_artist_id
 INNER JOIN genre	 ON genre_id 		= track.ref_genre_id;
--select * from vtrack where id < 100;
EOF
	echo ".read /tmp/nb.txt" | sqlite3 /home/uwe/my_databases/music.sqlite
}
function ctrl () {
	ifile="/tmp/in.txt";[ ! -f "$ifile" ] && echo 1 > "$ifile"
	page=$(<$ifile)
	log logon
#	notebook
    view	
	return
}
function zz () { return; } 
	ctrl notebook.sh
