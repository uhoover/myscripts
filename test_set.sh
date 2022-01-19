#!/bin/bash

# shif shif_elif shif_line shcase shfor shfor_each shfor_iterate shfor_iterate_array shwhile shwhile_true shwhile_read sharray sharray_length shstring_length shstring_first shstring_last shstring_change shstring_change_all shstring_delete shstring_delete_all shiterate shfunc shfunc_line shtrap_at shtrap_when shtrap_change 
	source /home/uwe/my_scripts/dbms_functions.sh

t1 () {
	echo hall uwe dani
}
	cat <<EOF
	hallo uwe
	$(t1)
	hallo dani
EOF
exit


function ctrl () {
	label="selectDB"
	db="/home/uwe/my_databases/music.sqlite"
	tb="composer"
	pid="12345"
	tpath="/tmp";epath="/tmp"
	maxcols=30
	terminal="terminal"
	x_get_tb_xml $label $db $tb $pid | grep -v '^terminal' | grep -v '^#' > /tmp/xml.txt
}
function x_get_tb_xml () {
	local label="$1" db="$2" tb="$3" pid="$4" header_visible="true"
	if [ "$label" = "$tb" ]; then
		tb_meta_info "$db" "$tb"
		lb=$(echo $GTBNAME | tr '_,' '-|');sensitiveCBOX="false";sensitiveFSELECT="false";sortcol=$GTBSORT 
	else
		lb="c1";sortcol="1"
		for ((ia=2;ia<=$maxcols;ia++)) ;do
			lb=$lb"|c"$ia
			sortcol=$sortcol"|0"
		done
		sensitiveCBOX="true";ID=0;sensitiveFSELECT="true" 
	fi
    if [ "$label" = "selectDB" ];then 
		visibleFSELECT="true";utils="utils"
		if [ "$header" = "$false" ];then header_visible="false"  ;fi
	else 
		visibleFSELECT="false";utils="db_utils"
	fi
	if [ "$row" != "" ];   		 then row="$(sql_execute $cdb '.header off\nselect count(*) from '$ctb' where rowid < '$row)"  ;fi
	if [ "$row" != "" ];   		 then selected_row="selected-row=\"$row\"" ;else selected_row=""  ;fi
	terminalfile="${tpath}/input_${pid}_${label}_cmd.txt"
	exportfile="$epath/export_${pid}_${label}.csv"
	dbfile="${tpath}/input_${pid}_${label}_db.txt"
	tbfile="${tpath}/input_${pid}_${label}_tb.txt"
	whfile="${tpath}/input_${pid}_${label}_wh.txt"
	script="/home/uwe/my_scripts/dbms.sh"
	cat <<EOF 
## kommentar
## kommentar
## kommentar
## kommentar
	<vbox>
		<entry visible="false">
            <variable>DUMMY$label</variable>
			<input>$script --func tb_ctrl_gui "input | $pid | $label | $db | $tb | defaultwhere"</input>
        </entry>
        <entry auto-refresh="true" visible="false">
            <variable>DUMMY2$label</variable>
			<input file>"$filesocket"</input> 
			<action type="refresh">DUMMY$label</action>
		</entry>
		<tree headers_visible="$header_visible" hover-selection="false" hover-expand="true" auto-refresh="true" 
		 exported_column="$ID" sort-column="$ID" column-sort-function="$sortcol" $selected_row>
			<label>"$lb"</label>
			<variable>TREE$label</variable>
			<input file>"$exportfile"</input>			
			<action>$script $nocmd --func uid_ctrl \$TREE$label \$ENTRY$label \$CBOXTB$label</action>				
		</tree>	
		<hbox homogenoues="true">
		  <hbox>
			<entry space-fill="true" space-expand="true" auto-refresh="true">  
				<variable>ENTRY$label</variable> 
				<sensitive>false</sensitive>  
				<input file>"$dbfile"</input>
			</entry> 
			<button space-fill="false" visible="$visibleFSELECT">
            	<variable>BUTTONFSELECT$label</variable>
            	<input file stock="gtk-open"></input>
				<action>$script --func tb_ctrl_gui "fselect | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
				<action type="refresh">TERMINAL$label</action>
            </button> 
		  </hbox>
			<comboboxtext space-expand="true" space-fill="true"  auto-refresh="true">
				<variable>CBOXTB$label</variable>
				<sensitive>$sensitiveCBOX</sensitive>
				<input file>"$tbfile"</input>			
				<action>$scrip' --func tb_ctrl_gui "table    | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</comboboxtext>	
			<button>
				<label>tb_utils</label>
				<action>$script --func tb_ctrl_gui "b_utiltb | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
		</hbox>
		<hbox>
			<comboboxtext space-expand="true" space-fill="true" auto-refresh="true">
				<variable>CBOXWH$label</variable>
				<input file>"$whfile"</input>
				<action>$script --func tb_ctrl_gui "where    | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>
			</comboboxtext>
			<button visible="true">
				<label>delete</label>
				<variable>BUTTONWHEREDELETE$label</variable>
				<action>$script --func tb_ctrl_gui "b_wh_del  | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>
			</button>
			<button visible="true">
				<label>edit</label>
				<variable>BUTTONWHEREEDIT$label</variable>
				<action>$script --func tb_ctrl_gui "b_wh_new  | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>
			</button>
			<button>
				<label>settings</label>
				<variable>BUTTONCONFIG$label</variable>
				<action>$script --func tb_ctrl_gui "b_config  | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>	
		</hbox>
		<hbox>
			<button>
				<label>help</label>
				<variable>BUTTONHELP$label</variable>
				<action>$script --func tb_ctrl_gui "b_help     | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
			<button>
				<label>workdir</label>
				<action>xdg-open $path &</action>
			</button>
			<button>
				<label>$utils</label>
				<action>$script --func tb_ctrl_gui "b_utils	   | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>'
$terminal			<button>
$terminal				<label>show terminal</label>
$terminal				<variable>BUTTONSHOW$label</variable>
$terminal				<action type="show">TERMINAL$label</action>
$terminal				<action type="show">BUTTONHIDE$label</action>
$terminal				<action type="hide">BUTTONSHOW$label</action>
$terminal			</button>
$terminal			<button visible="false">
$terminal				<label>hide terminal</label>
$terminal				<variable>BUTTONHIDE$label</variable>
$terminal				<action type="hide">TERMINAL$label</action>
$terminal				<action type="show">BUTTONSHOW$label</action>
$terminal				<action type="hide">BUTTONHIDE$label</action>
$terminal			</button>'
			<button>
				<label>clone</label>
				<variable>BUTTONCLONE$label</variable>
				<action>$script --func tb_ctrl_gui "b_clone     | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
			<button>
				<label>insert</label>
				<variable>BUTTONINSERT$label</variable>
				<action>$scrip' --func tb_ctrl_gui "b_insert    | $pid | $label | \$ENTRY$label | \$CBOXTB$label"</action>
			</button>
			<button>
				<label>update</label>
				<variable>BUTTONAENDERN$label</variable>
				<action>$script --func tb_ctrl_gui "b_update    | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$TREE$label"</action>
			</button>
			<button>
				<label>delete</label>
				<variable>BUTTONDELETE$label</variable>
				<action>$script --func tb_ctrl_gui "b_delete    | $pid | $labe' | \$ENTRY$label | \$CBOXTB$label | \$TREE$label"</action>			
			</button>
			<button>
				<label>refresh</label>
				<variable>BUTTONREAD$label</variable>
				<action>$script --func tb_ctrl_gui "b_refresh | $pid | $label | \$ENTRY$label | \$CBOXTB$label | \$CBOXWH$label"</action>'			
$terminal				<action type="clear">TERMINAL$label</action> 
$terminal				<action type="refresh">TERMINAL$label</action>'
			</button>
			<button>
				<label>exit</label>
				<action>$script --func tb_ctrl_gui "b_exit 	| $pid| $label | \$ENTRY$label | \$CBOXTB$label | ${wtitle}#${geometryfile}#${geometrylabel}"</action>			
				<action type="exit">CLOSE</action>
			</button>
		</hbox>'
$terminal		<terminal space-expand="false" space-fill="false" text-background-color="#F2F89B" text-foreground-color="#000000" 
$terminal			autorefresh="true" argv0="/bin/bash" visible="false">
$terminal			<variable>TERMINAL$label</variable>
$terminal			<height>$term_heigth</height>
$terminal			<input file>"$terminalfile"</input>
$terminal		</terminal>'
	</vbox>'
EOF
}  
	ctrl $*
