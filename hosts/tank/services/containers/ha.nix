{
  config,
  lib,
  pkgs,
  ...
}:

let
in
{
  virtualisation.oci-containers.containers."ha" = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    environment = {
      "TZ" = "Europe/Oslo";
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "/home/torgeir/homeassistant/data:/config:rw"
    ];
    ports = [
      "8123:8123/tcp"
    ];
    devices = [ "/dev/ttyUSB0" ];
    log-driver = "journald";
    extraOptions = [
      "--pull=newer"
      "--network=host"
      "--privileged"
    ];
  };
}
