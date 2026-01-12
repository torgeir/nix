{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.oci-containers.containers."hello" = {
    image = "traefik/whoami";
    extraOptions = [ "--network=web" ];
    ports = [ "8080:80" ];
  };

  system.activationScripts.createPodmanNetworkWeb = lib.mkAfter ''
    if ! /run/current-system/sw/bin/podman network exists web; then
      /run/current-system/sw/bin/podman network create web
    fi
  '';
}
