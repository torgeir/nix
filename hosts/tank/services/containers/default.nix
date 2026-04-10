{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./echo.nix
    ./nginx.nix
    ./immich.nix
    ./unbound.nix
    ./ha.nix
    ./navidrome.nix
    ./wallabag.nix
  ];

  extraServices.freshrss.enable = true;
}
