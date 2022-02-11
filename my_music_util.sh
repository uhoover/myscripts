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
	folder="$(basename $0)";path="$HOME/.${folder%%\.*}" 
	[ ! -d "$path" ]     && mkdir "$path" 
	tagfile="$path/tag.txt"
	readfile="$path/find.txt"
	headfile="$path/taghead.txt"
	sqlpath="/home/uwe/db/sql/music/"; [ ! -d "sqlpath" ] && mkdir -p "$sqlpath"
	tmpf="/tmp/tmp.txt"
	db="/home/uwe/my_databases/music_test.sqlite"
	importtb="import"
#
function _amain () {
	pparms=$*;parm="";path="/home/uwe/mnt/daten/music";func=$false;rename_it=$false;drop_it=$false
	while [ "$#" -gt 0 ];do
		case "$1" in
	        "--path"|-p) 					 			shift;path="$1";;
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
 	read_path_to_import $path
#  	import_tags
}
function check_tb () {
	local tb="$*" file drop_it=$true
	[ -f "$tmpf" ] && rm "$tmpf"
	echo ".separator |" > "$tmpf"
	if [ $drop_it = $true ]; then
		echo "drop table if exists $tb;" >> "$tmpf"
	else
		is_table "$db" "$tb"
		[ $? -eq 0 ] && return
	fi
	file="${sqlpath}/create_table_${tb}.sql"
#	[ ! -f "$file" ] && y_get_create_stmt "$tb" > "$file"
	y_get_create_stmt "$tb" > "$file"
	cat "$file" >> "$tmpf"
	sql_execute "$db" ".read $tmpf"	
}
function import_tags () {
	log "starte import" 
 	sql_execute $db ".read $sqlpath/create_table_import.sql";if [ "$?" -gt "0" ];then return  ;fi
 	sql_execute $db ".separator '|'\n.import $tagfile import";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_table_track.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_trigger_on_track.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_table_album.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_table_title.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_table_composer.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_table_genre.sql";if [ "$?" -gt "0" ];then return  ;fi
	sql_execute $db ".read $sqlpath/create_table_artist.sql";if [ "$?" -gt "0" ];then return  ;fi
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	sql="insert into  track select \
	        null,null,tags_album,null,tags_title,null,tags_composer,null,tags_artist, \
            null,tags_genre,null,tags_date,duration,size,format_name,format_long_name, \
            filename,nb_streams,nb_programs,start_time,bit_rate, \
            probe_score,\"$timestamp\",null \
         from import;"
	sql_execute $db "$sql";if [ "$?" -gt "0" ];then return  ;fi
	for tb in import track album title composer genre artist;do
		log "$tb		: $(sql_execute $db '.header off\nselect count(*) from' $tb)" 
	done
}
function write_files () { echo $* >> $readfile; }
function read_path_to_import () {
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
function tracks () {
	:
	#select replace(fls_track_filename, rtrim(fls_track_filename, replace(fls_track_filename, '/', '')), '') from track where track_id < 10;
}
function y_get_create_stmt () {
	eval 'y_get_create_tb_'$*
}
function y_get_create_tb_import () {
	cat << EOF
	CREATE TABLE import(
	  "ID" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
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
function y_get_create_tb_album () {
	cat << EOF
	CREATE TABLE album(
	  "album_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "album_name"					TEXT UNIQUE,
	  "album_track_id"				INTEGER,
	  "album_opus_nr"				TEXT,
	  "album_instrumentation_id"	INTEGER,
	  "album_catalog_id"			TEXT,
	  "album_info"					TEXT
	);
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
function y_get_create_tb_artgrp () {
	cat << EOF
	CREATE TABLE artgrp(
	  "artgrp_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
	  "artgrp_artist_id"			INTEGER,
	  "artgrp_grp_id"				INTEGER,
	  "artgrp_info"					TEXT
	)
	create unique index ix_u_1_artgrp on artgrp(artgrp_artist_id,artgrp_grp_id);
EOF
}
function y_get_create_tb_instrumentation () {
	cat << EOF
	CREATE TABLE instrumentation(
	  "instrumentation_id" 		INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
	  "instrumentation_status" 	INTEGER DEFAULT 0, 
	  "instrumentation_name" 	TEXT,
	  "instrumentation_type" 	TEXT,
	  "instrumentation_short" 	TEXT,
	  "instrumentation_count" 	INTEGER,
	  "instrumentation_info" 	TEXT
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
		"composer_id" INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT,
		"composer_name" TEXT,
		"composer_name_first" TEXT,
		"composer_title" TEXT,
		"composer_date_birth" TEXT,
		"composer_place_birth" TEXT,
		"composer_date_death" TEXT,
		"composer_place_death" TEXT,
		"composer_info" TEXT
	);
	INSERT INTO composer (composer_name,composer_name_first,composer_date_birth,composer_place_birth,composer_date_death,composer_place_death) VALUES
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
EOF
}
function y_get_create_tb_ () {
	cat << EOF
EOF
}
	_amain  $*
exit 
# insert into tracks select null,tags_album,tags_title,tags_composer,tags_track,tags_artist,tags_genre,duration,size,filename,nb_streams,nb_programs,format_name,format_long_name,start_time,bit_rate,probe_score from file;

