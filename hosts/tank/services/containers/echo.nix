{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.oci-containers.containers."hello" = {
    image = "traefik/whoami";
    ports = [ "8080:80" ];
  };
}
