{ ... }: {

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "torgnix.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/".extraConfig = ''
          add_header Content-Type text/plain;
          return 200 'awyeah!';
        '';
      };
      "ai.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
      };
      "sd.wa.gd" = {
        useACMEHost = "wa.gd";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:7860";
          proxyWebsockets = true;
        };
      };
    };
  };
}
