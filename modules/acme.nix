{ config, lib, ... }:

let
  cfg = config.extraServices.acme-cloudflare;
in
{
  options.extraServices.acme-cloudflare = {
    enable = lib.mkEnableOption "ACME with Cloudflare DNS";

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to environment file containing CLOUDFLARE_DNS_API_TOKEN";
    };

    staging = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Let's Encrypt staging server for testing";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.nginx.extraGroups = [ "acme" ];

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "torgeir.thoresen@gmail.com";
    security.acme.certs."wa.gd" = {
      domain = "*.wa.gd";
      # need to turn of that NAT rule in the router if this fails
      dnsProvider = "cloudflare";
      dnsResolver = "192.168.20.1:53";
      dnsPropagationCheck = true;
      environmentFile = cfg.environmentFile;
      server =
        if cfg.staging then
          "https://acme-staging-v02.api.letsencrypt.org/directory"
        else
          "https://acme-v02.api.letsencrypt.org/directory";
    };
  };
}
