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
  ];
}
