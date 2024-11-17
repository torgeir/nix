{ dotfiles, config, lib, pkgs, ... }:

{

  home.packages = with pkgs; [ mangohud ];

  home.file.".config/MangoHud".source = dotfiles + "/config/MangoHud";

}
