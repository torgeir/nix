{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.oci-containers.containers."nginx" = {
    image = "docker.io/nginx:alpine";
    environmentFiles = [ config.age.secrets.secret1.path ];
  };

}
