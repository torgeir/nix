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
    if ! ${pkgs.podman}/bin/podman network exists web; then
      ${pkgs.podman}/bin/podman network create web
    fi
  '';
}
