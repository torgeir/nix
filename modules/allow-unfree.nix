{
  config,
  lib,
  pkgs,
  ...
}:

{

  # sorry stallman, can't live without them
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "slack"
      "firefox-bin"
      "firefox-bin-unwrapped"

      "cnijfilter2" # canon pixma ink printer drivers

      "1password"
      "1password-cli"
      "1password-gui"
      "1password-gui-beta"

      "dropbox"

      "reaper"
      "linuxsampler"

      "steam"
      "steam-run"
      "steam-original"
      "steam-unwrapped"
    ];
}
