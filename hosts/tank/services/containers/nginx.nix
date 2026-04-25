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
      "wallabag.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8091";
          proxyWebsockets = true;
        };
      };
      "dav.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8092";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
            proxy_set_header Authorization $http_authorization;
            # Rewrite Destination header for WebDAV MOVE: Apache receives the
            # external https URL and tries to reach it directly, causing 502.
            # Rewrite it to http://127.0.0.1:8092 so Apache resolves it locally.
            set $fixed_destination $http_destination;
            if ($fixed_destination ~* ^https://dav\.wa\.gd(.*)$) {
              set $fixed_destination http://127.0.0.1:8092$1;
            }
            proxy_set_header Destination $fixed_destination;
          '';
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
