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
 sqlite3  << EOF
 select datetime('now')
EOF
echo end
 
