{ config, lib, pkgs, ... }:

{

  # password manager
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "torgeir" ];
    # package = pkgs._1password-gui-beta;
  };

}
