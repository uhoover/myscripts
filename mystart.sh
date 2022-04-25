#!/bin/bash
# author uwe suelzle
# created 202?-??-??
# function: 
#
# elif if ifl case                        << snipped    
# for fora fori foria while wtrue read    << snipped    
# str strf strl strc strca strd strda     << snipped    
# func funcl trap	 arr arrl             << snipped    
 source /home/uwe/my_scripts/myfunctions.sh
function _exit() {
	log logoff
}
 trap _exit	 EXIT  
# set -e  # bei fehler sprung nach xexit
#
function ctrl () {
	log logon
	/home/uwe/my_scripts/stream_recorder.sh create_playlist &
}
function zz () { return; } 
	ctrl 
    exit 0 
