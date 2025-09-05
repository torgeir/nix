
{ config, ... }: {

  users.groups.immich = {};
  users.users.immich = {
    group = "immich";
    extraGroups = [ "video" "render" ];
    isSystemUser = true;
    createHome = false;
  };

  system.activationScripts.immich-setup = {
    text = ''
      mkdir -p /fast/shared/apps/immich
      chown -R immich:immich /fast/shared/apps/immich
      chmod 701 /fast/shared/apps/
      chmod 755 /fast/shared/apps/immich
      chmod 755 /var/cache/immich
    '';
    deps = [ "users" ];
  };

  services.immich = {
    enable = true;
    mediaLocation = "/fast/shared/apps/immich/";
    # hardware acceleration, needs hardware.graphics.enable = true;
    accelerationDevices = ["/dev/dri/renderD128"];
    machine-learning.environment = {
      MPLCONFIGDIR = "/var/cache/immich/matplotlib";
      # https://github.com/NixOS/nixpkgs/issues/418799
      HF_XET_CACHE = "/var/cache/immich/huggingface-xet";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      "immich.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.immich.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
    };
  };

}
