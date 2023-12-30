{ config, lib, pkgs, ... }:

let
in {

  # discover fonts installed through home.packages and nix-env
  fonts.fontconfig.enable = true;

  # debug what is installed
  #   nix repl --expr 'import <nixpkgs> {}'
  #   :b pkgs.iosevka-bin.override { variant = "sgr-iosevka-term-ss05"; }
  #   c-d
  #   fd . <the-path-printed-from-the-above-command>
  home.packages = with pkgs; [
    # https://github.com/be5invis/Iosevka/releases
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/iosevka/default.nix
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/iosevka/variants.nix
    (pkgs.callPackage ./../pkgs/patch-nerd-fonts {
      font = pkgs.iosevka-bin.override { variant = "sgr-iosevka-etoile"; };
    })
    (pkgs.callPackage ./../pkgs/patch-nerd-fonts {
      font =
        pkgs.iosevka-bin.override { variant = "sgr-iosevka-term-curly-slab"; };
    })
  ];

}
