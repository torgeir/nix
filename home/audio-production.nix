{ config, lib, pkgs, ... }:

{

  # TODO torgeir audio
  xdg.configFile = {

    "yabridgectl/config.toml".text = ''
       plugin_dirs = [
         "/home/torgeir/.wine/drive_c/Program Files/Common Files/VST3",
         "/home/torgeir/Dropbox/Music/Plugins/vst"
      ]
       vst2_location = 'centralized'
       no_verify = false
       blacklist = []
    '';

  };
}
