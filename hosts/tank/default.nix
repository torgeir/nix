{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.agenix.nixosModules.default

    ../common
    ../common/torgeir.nix

    ./configuration.nix
    ./zfs.nix
    ./secrets.nix
    ./services
  ];

  extraServices.podman.enable = true;
}
