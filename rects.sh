#!/bin/bash
	set -- /media/uwe/Seagate Expansion Drive/PVR/REC
	[ $# -eq 0 ] && dir=$(zenity --file-selection --directory) || dir=$*
	[ ! -d "$dir" ] && exit
	tmpf="/tmp/rects.txt"
	[ -f $tmpf ] && rm $tmpf
	parm=""
	find "$dir" -name RECInfo.txt > $tmpf
	while read  -r file;do
		line=$(hexdump -C "$file" | cut -d '|' -f2 | tr -d '.\n' | tr -d "'" | fmt -w 500)
#		echo $line
		channel="${line%%\**}"
		str="${line##*deu}}"
		title="${str%\!*}"
		[ ${#title} -gt 3 ] && [ "${title:0:3}" = "sau" ] && title="Amadeu${title}" 
#		echo $channel $title
		parm="$parm '$channel' '$title' '$file'"
	done < $tmpf
#	echo $parm
 	eval 'zenity --list --height=600 --width=600 --print-column=3 --column channel --column title --column file' $parm |
 	while read -r line;do 
		xdg-open "${line/RECInfo.txt/record.ts}"
	done
	 
