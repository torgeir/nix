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

    ../../modules/acme.nix

    ./configuration.nix
    ./secrets.nix
    ./zfs.nix
    ./samba.nix
    ./services
  ];
}
