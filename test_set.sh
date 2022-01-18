#!/bin/bash

# shif shif_elif shif_line shcase shfor shfor_each shfor_iterate shfor_iterate_array shwhile shwhile_true shwhile_read sharray sharray_length shstring_length shstring_first shstring_last shstring_change shstring_change_all shstring_delete shstring_delete_all shiterate shfunc shfunc_line shtrap_at shtrap_when shtrap_change 

w=1
for i in 1 2 3;do echo $((++w));done
wert[1]=2
echo "${#wert[$@]}"
while : ;do
	echo $((++w))
	if [ $w -gt 10 ];then break  ;fi
done
