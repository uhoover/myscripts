#!/bin/bash
	if [ $# -lt 1 ];then 
		file=$(zenity --file-selection --save --filename=/home/uwe/my_scripts/) 
	else
		file=$*
		path=$(basename $file)
		if [ "$path" = "$file" ]; then file="/home/uwe/my_scripts/${file}"
		fi
	fi 
	if [ "$file" = "" ]; then
	    echo "no filename selected...bye"
	    exit 
	fi
	echo "#!/bin/bash" 		    									>	$file	
	echo "# author uwe suelzle" 									>>	$file	
	echo "# created 202?-??-??" 									>>	$file	
	echo "# function: "  		 									>>	$file	
	echo "#"			  		 									>>	$file
	echo "# elif if ifl case                        << snipped    " >> 	$file
	echo "# for fora fori foria while wtrue read    << snipped    " >> 	$file
	echo "# str strf strl strc strca strd strda     << snipped    " >> 	$file
	echo "# func funcl trap	 arr arrl               << snipped    " >> 	$file
	echo " source /home/uwe/my_scripts/my_functions.sh"				>>	$file
	echo "function aexit() {"	  		 							>>	$file	
	echo "	retcode=$? "		 									>>	$file
	echo "	log stop"	  		 									>>	$file
	echo "}"			  		 									>>	$file
	echo " trap aexit	 EXIT"										>>	$file
	echo " set -e  # bei fehler sprung nach xexit"					>>	$file
	echo "#"			  		 									>>	$file	
	echo "function ctrl () {"	  		 							>>	$file	
	echo "	log file start"		 									>>	$file
	echo "	log $*"				 									>>	$file
	echo "	return"			  	 									>>	$file
	echo "}"			  		 									>>	$file
	echo "function zz () { return; } "								>>	$file
	echo "	ctrl $@"	 		 									>>	$file
	chmod +x $file 
exit


	
