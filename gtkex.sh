#!/bin/bash
function read_table () {
	db=$1;tb=$2
	echo -e ".separator |\n.header off\nselect * from $tb;" | sqlite3 $db
}
func=$1;shift
case "$func" in
	"read_table") read_table $@	;;
	*) echo command not found: func $@
esac
