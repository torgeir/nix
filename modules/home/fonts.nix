{ config, lib, pkgs, ... }:

{

  # discover fonts installed through home.packages and nix-env
  fonts.fontconfig.enable = true;

}
