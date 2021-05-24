#!/bin/bash  
# author uwe suelzle
# created 202?-??-??
# function: 
# elif if ifl case
# for fora fori foria while wtrue read
 set -o noglob
 source /home/uwe/my_scripts/my_functions.sh
 trap xexit EXIT
 set -e  # bei fehler sprung nach xexit
 declare -t strf strl
#
function _amain () {
	sql_execute "/home/uwe/my_databases/music.sqlite" "select * from track limit 10"
	return
}
function xexit() {
	retcode=0 
	log stop
}
	i=0
	while : ;do
	   i=$((i+1))
	   if [ "$i" -gt "10" ];then  break  ;fi
	   echo $i
	done
	exit 
	log file start
	_amain 
	setmsg -i stop
	
	wtrue
