{
  config,
  lib,
  pkgs,
  ...
}:

{

  virtualisation.oci-containers.containers."navidrome" = {
    image = "docker.io/deluan/navidrome:0.60.3";
    environment = {
      "TZ" = "Europe/Oslo";
      "LogLevel" = "INFO";
    };
    environmentFiles = [ config.age.secrets.scrobble.path ];
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/fast/shared/apps/navidrome/data:/data:rw"
      "/fast/shared/music:/music:ro"
    ];
    ports = [
      "4533:4533/tcp"
    ];
  };
}
