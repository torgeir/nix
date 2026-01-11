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
    ./services
  ];

  extraServices.podman.enable = true;
}
