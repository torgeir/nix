{
  config,
  lib,
  pkgs,
  ...
}:

{
  # answer dns queries from tailnet, to make local domain work

  services.unbound = {
    enable = true;
    settings =
      let
        ip = "100.103.93.10";
        services = [
          "ha"
          "rss"
          "immich"
        ];
      in
      {
        server = {
          interface = [
            "127.0.0.1"
            "::1"
            "${ip}"
          ];
          access-control = [
            "127.0.0.0/8 allow"
            "::1/128 allow"
            "100.64.0.0/10 allow"
          ];
          local-zone = [ "\"wa.gd.\" static" ];
          local-data = map (s: "\"${s}.wa.gd.  A ${ip}\"") services;
        };
      };
  };
}
