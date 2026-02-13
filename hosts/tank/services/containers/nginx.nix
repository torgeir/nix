{
  config,
  lib,
  pkgs,
  ...
}:

{
  extraServices.acme-cloudflare = {
    enable = true;
    staging = false;
    environmentFile = config.age.secrets."acme-cloudflare".path;
  };

  networking.firewall.allowedTCPPorts = [
    443
  ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "tank.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/".extraConfig = ''
          add_header Content-Type text/plain;
          return 200 'awyeah!';
        '';
      };
      "ha.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8123";
          proxyWebsockets = true;
        };
      };
      "music.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:4533";
          proxyWebsockets = true;
        };
      };
      "rss.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8090";
          proxyWebsockets = true;
        };
      };
      "immich.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout       600s;
          client_max_body_size 50000M;
        '';
      };
    };
  };

}
