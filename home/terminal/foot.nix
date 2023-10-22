{ config, lib, pkgs, ... }:

{

  xdg.configFile = {
    "foot/foot.ini".text = ''
      font=JetBrainsMono Nerd Font:style=Regular:size=12
    '';
  };

}
