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
  ];

  extraServices.freshrss.enable = true;
}
