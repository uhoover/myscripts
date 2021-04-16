#! /bin/bash
 source /home/uwe/my_scripts/my_functions.sh
set -o noglob
script=$(readlink -f $0)
save_geometry_o(){
   XWININFO=$(xwininfo -stats -name SizeMe)
   HEIGHT=$(echo "$XWININFO" | grep 'Height:' | awk '{print $2}')
   WIDTH=$(echo "$XWININFO" | grep 'Width:' | awk '{print $2}')
   X1=$(echo "$XWININFO" | grep 'Absolute upper-left X' | awk '{print $4}')
   Y1=$(echo "$XWININFO" | grep 'Absolute upper-left Y' | awk '{print $4}')
   X2=$(echo "$XWININFO" | grep 'Relative upper-left X' | awk '{print $4}')
   Y2=$(echo "$XWININFO" | grep 'Relative upper-left Y' | awk '{print $4}')
   X=$(($X1-$X2))
   Y=$(($Y1-$Y2))
   echo "export HEIGHT=$HEIGHT"   > /tmp/geometry
   echo "export WIDTH=$WIDTH"      >> /tmp/geometry
   echo "export X=$X"            >> /tmp/geometry
   echo "export Y=$Y"            >> /tmp/geometry
   chmod 700 /tmp/geometry
}
function cmd () {
	db=$*
	echo ".exit" 	> /tmp/cmd.txt 
	echo "sqlite3 $db" 						>> /tmp/cmd.txt 
}
if [ "$1" = "--func" ];then shift;$*;exit;fi
gfile="/tmp/geometry";title="Size Me"
# 				echo -e ".separator |\n.headers off\nselect * from genre;"| sqlite3 /home/uwe/my_databases/music.sqlite

[ -f "$gfile" ] && . $gfile
[ ! -f "/tmp/cmd.txt" ] && cmd "/home/uwe/.my_squirrel_all/parm.sqlite" 

export DIALOG='
<window title="'$title'" default_height="'$HEIGHT'" default_width="'$WIDTH'" window-position="3"
	default_x_position="50" default_y_position="50">
  <vbox>
      <table column-visible="false|true|false|true" selected-row="2" selection-mode="3">
			<label>"genre-id|genre-name|genrelist-id|genre-info"</label>
			<variable>tree</variable>
			<input>'"echo  \".separator | \n.headers off\nselect * from genre;\" | sqlite3 /home/uwe/my_databases/music.sqlite"'</input>
      </table>
      <text>
        <label>If you resize or move this window, it will be remembered for next time.</label>
      </text>
      <text>
        <label>If you resize or move this window, it will be remembered for next time.</label>
      </text>
      <text>
        <label>If you resize or move this window, it will be remembered for next time.</label>
      </text>
      <text>
        <label>If you resize or move this window, it will be remembered for next time.</label>
      </text>
      <text>
        <label>If you resize or move this window, it will be remembered for next time.</label>
      </text>
    <hbox>
      <button>
			<label>music</label>
            <action>'$0' --func cmd /home/uwe/my_databases/music.sqlite</action>	
            <action type="refresh">terminal</action>
      </button>
      <button>
			<label>info</label>
            <action>'$0' --func cmd /home/uwe/my_databases/info.sqlite</action>	
            <action type="refresh">terminal</action>
      </button>
      <button>
			<label>ok</label>
			<action signal="hide">'$0' --func save_geometry</action>	
            <action>'$0' --func save_geometry '${title}#${gfile}'</action>	
            <action type="exit">CLOSE</action>
      </button>
    </hbox>
    <terminal space-expand="false" space-fill="false" text-background-color="white" text-foreground-color="#000000" 
			autorefresh="true" argv0="/bin/bash">
		<variable>terminal</variable>
		<height>5</height>
		<input file>"/tmp/cmd.txt"</input>
    </terminal>
  </vbox>
</window>'
gtkdialog --program=DIALOG --geometry="10x10"  # 1> /dev/null
#save_geometry
#            <action>"echo sqlite3 > /tmp/cmd.txt;echo  .open /home/uwe/my_databases/info.sqlite >> /tmp/cmd.txt"</action>	
