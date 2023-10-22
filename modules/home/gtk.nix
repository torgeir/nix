{ config, lib, pkgs, ... }:

{

  gtk = {
    enable = true;
    theme = {
      name = "arc-theme";
      package = pkgs.arc-theme;
    };
    iconTheme = {
      name = "Arc";
      package = pkgs.arc-icon-theme;
    };
    cursorTheme = {
      name = "Arc";
      package = pkgs.arc-icon-theme;
    };
  };

}
