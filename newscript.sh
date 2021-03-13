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
	echo "#!/bin/bash" 		    							>	$file	
	echo "# author uwe suelzle" 							>>	$file	
	echo "# created 202?-??-??" 							>>	$file	
	echo "# function: "  		 							>>	$file	
	echo "#"			  		 							>>	$file	
	echo " source /home/uwe/my_scripts/my_functions.sh"		>>	$file
	echo " trap "xexit" EXIT"								>>	$file
	echo " set -e  # bei fehler sprung nach xexit"			>>	$file
	echo "#"			  		 							>>	$file	
	echo "function _amain () {"	  		 					>>	$file	
	echo "	return"			  	 							>>	$file
	echo "}"			  		 							>>	$file
	echo "function xexit() {"	  		 					>>	$file	
	echo "	retcode=$? "		 							>>	$file
	echo "	log stop"	  		 							>>	$file
	echo "}"			  		 							>>	$file
	echo "	log file start"		 							>>	$file
	echo "	_amain $@"	 		 							>>	$file
	chmod +x $file 
exit


	
