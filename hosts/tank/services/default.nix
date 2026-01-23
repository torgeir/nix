{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./containers
  ];

  extraServices.podman.enable = true;

  virtualisation.oci-containers.backend = "podman";
}
