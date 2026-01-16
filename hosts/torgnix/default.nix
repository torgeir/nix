{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../common
    ../common/torgeir.nix

    ./configuration.nix
    ./secrets.nix
  ];
}
