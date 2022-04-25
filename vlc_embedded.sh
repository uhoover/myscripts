#!/bin/bash

file=$*
[ "$file" = "" ] && file=$(zenity --file-selection --filename=/media/uwe/media/Videos/)
[ "$file" = "" ] && exit 1

gtkdialog -s <<< '<window title="VLC Controls" width-request="600" height-request="450">
<vbox>
<button><label>Play/Stop</label><action>echo pause | nc localhost 123</action></button>
<button><label>Quit</label><action>echo quit | nc localhost 123</action><action type="exit">EXIT_NOW</action></button>
</vbox>
</window>' &
sleep 1
OSC_WID="$(xwininfo -name "VLC Controls" | grep -m1 'Window id: ' | cut -f4 -d' ')"
echo OSC_WID = $OSC_WID
export OSC_WID
#exit
cvlc --extraintf rc --rc-host localhost:123 --drawable-xid  $OSC_WID "$file" 
exit 0
