{ config, lib, pkgs, ... }:

{

  xdg.configFile = {

    # thunar
    "Thunar/accels.scm".text = ''
      (gtk_accel_path "<Actions>/ThunarWindow/open-parent" "Backspace")
      (gtk_accel_path "<Actions>/ThunarWindow/open-parent" "<Alt>Up")
      (gtk_accel_path "<Actions>/ThunarActionManager/open" "<Alt>Down")
    '';

    "Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Terminal here</name>
        <submenu></submenu>
        <unique-id>1698005278620489-1</unique-id>
        <command>alacritty --working-directory %f</command>
        <description>Terminal here</description>
        <range></range>
        <patterns>*</patterns>
        <startup-notify/>
        <directories/>
      </action>
      <action>
        <icon>folder</icon>
        <name>Create folder here</name>
        <submenu></submenu>
        <unique-id>1758474871726653-1</unique-id>
        <command>mkdir %d/New\ Folder</command>
        <description></description>
        <range>*</range>
        <patterns>*</patterns>
        <directories/>
        <audio-files/>
        <image-files/>
        <other-files/>
        <text-files/>
        <video-files/>
      </action>
      </actions>
    '';

  };
}
