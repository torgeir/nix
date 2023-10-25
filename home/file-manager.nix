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
        <command>foot --working-directory %f</command>
        <description>Terminal here</description>
        <range></range>
        <patterns>*</patterns>
        <startup-notify/>
        <directories/>
      </action>
      </actions>
    '';

  };
}
