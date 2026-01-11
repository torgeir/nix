{
  config,
  lib,
  pkgs,
  ...
}:

let
in
{

  # discover fonts installed through home.packages and nix-env
  fonts.fontconfig.enable = true;

  # debug what is installed
  #   nix repl --expr 'import <nixpkgs> {}'
  #   :b pkgs.iosevka-bin.override { variant = "sgr-iosevka-term-ss05"; }
  #   c-d
  #   fd . <the-path-printed-from-the-above-command>
  home.packages = with pkgs.unstable-locked; [
    # https://github.com/be5invis/Iosevka/releases
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/iosevka/default.nix
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/iosevka/variants.nix
    font-awesome
    (callPackage ../../pkgs/patch-nerd-fonts {
      font = iosevka-bin.override { variant = "Etoile"; };
    })
    (callPackage ../../pkgs/patch-nerd-fonts {
      font = iosevka-bin.override { variant = "SGr-IosevkaTermCurlySlab"; };
    })
  ];

}
