{ config, lib, pkgs, ... }:

let theme-name = "Catppuccin-Macchiato-Compact-Sapphire-Dark";
in {

  home.sessionVariables = { GTK_THEME = theme-name; };

  gtk = {
    enable = true;
    theme = {
      name = theme-name;
      # https://github.com/NixOS/nixpkgs/blob/7ce8e7c4cf90492a631e96bcfe70724104914381/pkgs/data/themes/catppuccin-gtk/default.nix#L16
      package = pkgs.catppuccin-gtk.override {
        accents = [ "sapphire" ];
        size = "compact";
        tweaks = [ "rimless" ];
        variant = "macchiato";
      };
    };

    iconTheme = {
      name = "papirus";
      # nix-env -qaP papirus
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "catppuccin";
      package = pkgs.catppuccin-cursors;
    };

  };

}
