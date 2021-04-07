#! /bin/bash

export MAIN_DIALOG='
  <vbox>
    <frame Space>
      <hbox spacing="10">
        <text><label>spacing</label></text>
        <entry></entry>
      </hbox>
      <hbox homogeneous="true">
        <text><label>homogeneous</label></text>
        <entry></entry>
      </hbox>
    </frame>
    <frame Description>
      <hbox>
        <pixmap>
          <input file stock="gtk-info"></input>
        </pixmap>
        <text>
          <label>
"This is a label with a rather long text, so it must be wrapped as the user
resizes the window. However, the default label width is 30 characters."
          </label>
        </text>
      </hbox>
    </frame>
    <frame Description>
    <hbox fill="true" expand="true">
        <pixmap>
          <input file stock="gtk-info"></input>
        </pixmap>
        <text>
          <label>
"This is a label with a rather long text, so it must be wrapped as the user
resizes the window. However, the default label width is 30 characters."
          </label>
        </text>
      </hbox>
    </frame>

    <hbox>
      <button cancel></button>
      <button help></button>
    </hbox>
  </vbox>
'

gtkdialog --program=MAIN_DIALOG

