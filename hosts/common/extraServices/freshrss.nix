{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.extraServices.freshrss;
  dns = [
    "--dns=192.168.20.1"
    "--dns=10.88.0.1"
  ];
in
{
  options.extraServices.freshrss = {
    enable = lib.mkEnableOption "Run FreshRSS in a podman container";
  };

  config = lib.mkIf cfg.enable {

    virtualisation.oci-containers.containers.freshrss = {
      image = "docker.io/freshrss/freshrss:1.28.1";
      ports = [ "8090:80" ];
      networks = [ "freshrss" ];
      extraOptions = [ ] ++ dns;
      environment = {
        TZ = "Europe/Oslo";
        CRON_MIN = "2,32";
        SERVER_DNS = "rss.wa.gd";
      };
      environmentFiles = [ config.age.secrets.freshrss.path ];
      volumes = [
        "/fast/shared/torgeir/freshrss:/var/www/FreshRSS/data"
        "/fast/shared/torgeir/freshrss/extensions:/var/www/FreshRSS/extensions"
      ];
    };

    system.activationScripts.createPodmanNetworkFreshrss = lib.mkAfter ''
      if ! ${pkgs.podman}/bin/podman network exists freshrss; then
        ${pkgs.podman}/bin/podman network create freshrss
      fi
    '';

  };
}
