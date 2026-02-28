{
  config,
  lib,
  pkgs,
  ...
}:

let
  accent = "sapphire";
  size = "compact";
  variant = "macchiato";
  tweak = "rimless";
  # nix repl --expr import <nixpkgs> {}
  # :b pkgs.catppuccin-cursors.mochaDark
  # inspect path, to figure the names out
  theme-name = "catppuccin-${variant}-${accent}-${size}+${tweak}";
  cursor-name = "catppuccin-mocha-dark-cursors";
  # https://github.com/catppuccin/cursors
  cursor-pkg = pkgs.catppuccin-cursors.mochaDark;
in
{

  home.sessionVariables = {
    GTK_THEME = theme-name;
  };

  home.packages = [
    (pkgs.catppuccin-gtk.override {
      accents = [ accent ];
      size = size;
      tweaks = [ tweak ];
      variant = variant;
    })
  ];

  gtk = {
    enable = true;
    theme.name = theme-name;

    iconTheme = {
      name = "paper";
      # nix-env -qaP '*icon-theme*'
      package = pkgs.paper-icon-theme;
    };

    cursorTheme = {
      name = cursor-name;
      package = cursor-pkg;
    };

  };

  home.pointerCursor = {
    name = cursor-name;
    package = cursor-pkg;
    size = 26;
    gtk.enable = true;
  };
}
