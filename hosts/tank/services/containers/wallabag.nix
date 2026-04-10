{
  config,
  lib,
  pkgs,
  ...
}:

let
  wallabagHost = "wallabag.wa.gd";
  wallabagRoot = "/fast/shared/apps/wallabag";
  wallabagData = "${wallabagRoot}/data";
in
{
  system.activationScripts.createPodmanWallabagFolders = lib.mkAfter ''
    mkdir -p ${wallabagData}
    chown -R nobody:nogroup ${wallabagData}
  '';

  system.activationScripts.createPodmanWallabagNetwork = lib.mkAfter ''
    if ! ${pkgs.podman}/bin/podman network exists wallabag; then
      ${pkgs.podman}/bin/podman network create wallabag
    fi
  '';

  virtualisation.oci-containers.containers.wallabag = {
    image = "docker.io/wallabag/wallabag:2.6.10";
    ports = [ "8091:80" ];
    networks = [ "wallabag" ];
    extraOptions = [
      "--pull=newer"
    ];
    environment = {
      TZ = "Europe/Oslo";
      SYMFONY__ENV__DOMAIN_NAME = "https://${wallabagHost}";
    };
    environmentFiles = [ config.age.secrets.wallabag-env.path ];
    volumes = [
      "${wallabagData}:/var/www/wallabag/data"
    ];
  };

}
