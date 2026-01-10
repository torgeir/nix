{ config, lib, pkgs, ... }:

{

  # yabridgectl sync
  # yabridgectl status
  xdg.configFile = {

    "yabridgectl/config.toml".text = ''
       plugin_dirs = [
         "/home/torgeir/.wine/drive_c/Program Files/Common Files/Helix Native/",
         "/home/torgeir/.wine/drive_c/Program Files/Common Files/VST3",
         "/home/torgeir/Dropbox/Music/Plugins/vst"
      ]
       vst2_location = 'centralized'
       no_verify = false
       blacklist = []
    '';

  };

  # neural amp modeler
  home.packages = with pkgs; [ neural-amp-modeler-lv2 ];
  home.file.".lv2/${pkgs.neural-amp-modeler-lv2.name}".source =
    pkgs.neural-amp-modeler-lv2;
}
