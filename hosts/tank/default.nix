{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./configuration.nix
    ../common
    ../common/torgeir.nix
  ];

  extraServices.podman.enable = true;
}
