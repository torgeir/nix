{ config, lib, pkgs, ... }:

{

  # password manager
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "torgeir" ];
    # package = pkgs._1password-gui-beta;
  };

  # 1password save 2fa codes here
  services.gnome.gnome-keyring.enable = true;
  # browse them with seahorse
  programs.seahorse.enable = true;

}
