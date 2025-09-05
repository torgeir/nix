{ config, ... }: {

  sops.secrets."acme_cf".owner = "acme";
  users.users.nginx.extraGroups = [ "acme" ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "torgeir.thoresen@gmail.com";
  security.acme.certs."wa.gd" = {
    domain = "wa.gd";
    extraDomainNames = [ "*.wa.gd" ];
    dnsProvider = "cloudflare";
    dnsResolver = "1.1.1.1:53"; # nescessary
    dnsPropagationCheck = true;

    # secret needs needs CLOUDFLARE_DNS_API_TOKEN=<token>,
    # with cloudflare scopes Zone:Zone:read and Zone:DNS:edit
    # https://go-acme.github.io/lego/dns/cloudflare/
    environmentFile = config.sops.secrets."acme_cf".path;

    # server = "https://acme-staging-v02.api.letsencrypt.org/directory"; # staging, no ratelimit
    server = "https://acme-v02.api.letsencrypt.org/directory"; # prod
  };

}
