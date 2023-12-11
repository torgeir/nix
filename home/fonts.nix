{ config, lib, pkgs, ... }:

{

  # discover fonts installed through home.packages and nix-env
  fonts.fontconfig.enable = true;

  # TODO patch fonts yourself
  # https://codeberg.org/municorn/iosevka-muse/src/commit/ca362ea18ef57eef395a96b9f9c9cb06d1fef3f2/flake.nix#L24
  # https://dee.underscore.world/blog/home-manager-fonts/

}
