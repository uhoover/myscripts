#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
 source /home/uwe/my_scripts/my_functions.sh
 trap "xexit" EXIT
 set -e
#
function _amain () {
    echoes fehler
}
xexit () {
	retcode=$? 
	log stop 
}
#	file=eigenes - logfile - logfile=syslog.txt - new log vorher loeschen - debug_on - echo_on - log_on - verbose_on
	log file echo_on start
	_amain test.sh
 	log nach amain
