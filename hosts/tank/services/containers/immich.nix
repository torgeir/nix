{
  config,
  lib,
  pkgs,
  ...
}:

let
  immichHost = "immich.wa.gd";
  immichRoot = "/fast/shared/apps/immich";
  immichPhotos = "${immichRoot}/upload";
  immichAppdataRoot = "${immichRoot}/appdata";
  immichVersion = "v2.5.6"; # 2026-02-13

  postgresRoot = "${immichAppdataRoot}/pgsql";
  postgresUser = "immich";
  postgresDb = "immich";
  dns = [
    # Force DNS resolution to only be the podman dnsname name server; by
    # default podman provides a resolv.conf that includes both this server and
    # the upstream system server, causing resolutions of other pod names to be
    # inconsistent.
    "--dns=10.88.0.1"
    "--dns=192.168.20.1"
  ];
in
{

  # The primary source for this configuration is the recommended docker-compose installation of immich from
  # https://immich.app/docs/install/docker-compose, which linkes to:
  # - https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
  # - https://github.com/immich-app/immich/releases/latest/download/example.env
  # and has been transposed into nixos configuration here.  Those upstream files should probably be checked
  # for serious changes if there are any upgrade problems here.
  #
  # After initial deployment, these in-process configurations need to be done:
  # - create an admin user by accessing the site
  # - login with the admin user
  # - set the "Machine Learning Settings" > "URL" to http://immich_machine_learning:3003
  #
  system.activationScripts.createPodmanImmichFolders = lib.mkAfter ''
    mkdir -p /fast/shared/apps/immich/upload
    mkdir -p /fast/shared/apps/immich/appdata
    mkdir -p /fast/shared/apps/immich/appdata/pgsql
    mkdir -p /fast/shared/apps/immich/appdata/model-cache

    chmod 755 /fast/shared/apps/immich/upload
    chmod 755 /fast/shared/apps/immich/appdata
    chmod 755 /fast/shared/apps/immich/appdata/model-cache
  '';

  system.activationScripts.createPodmanImmichNetworkWeb = lib.mkAfter ''
    if ! ${pkgs.podman}/bin/podman network exists immich; then
      ${pkgs.podman}/bin/podman network create immich
    fi
  '';

  virtualisation.oci-containers.containers.immich_server = {
    ports = [ "2283:2283" ];
    dependsOn = [
      "immich_postgres"
      "immich_redis"
    ];
    networks = [ "immich" ];
    image = "ghcr.io/immich-app/immich-server:${immichVersion}";
    extraOptions = [
      "--pull=newer"
    ]
    ++ dns;
    cmd = [
      "start.sh"
      "immich"
    ];
    environment = {
      IMMICH_VERSION = immichVersion;
      DB_HOSTNAME = "immich_postgres";
      DB_USERNAME = postgresUser;
      DB_DATABASE_NAME = postgresDb;
      REDIS_HOSTNAME = "immich_redis";
    };
    # DB_PASSWORD
    environmentFiles = [ config.age.secrets.immich-db-password.path ];
    volumes = [
      "${immichPhotos}:/usr/src/app/upload"
      "/etc/localtime:/etc/localtime:ro"
    ];
    devices = [ "/dev/dri" ]; # hw acc
  };

  virtualisation.oci-containers.containers.immich_microservices = {
    dependsOn = [
      "immich_postgres"
      "immich_redis"
    ];
    networks = [ "immich" ];
    image = "ghcr.io/immich-app/immich-server:${immichVersion}";
    extraOptions = [
      "--pull=newer"
    ]
    ++ dns;
    cmd = [
      "start.sh"
      "microservices"
    ];
    environment = {
      IMMICH_VERSION = immichVersion;
      DB_HOSTNAME = "immich_postgres";
      DB_USERNAME = postgresUser;
      DB_DATABASE_NAME = postgresDb;
      REDIS_HOSTNAME = "immich_redis";
      # this can't be changed?
      IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
    };
    # DB_PASSWORD
    environmentFiles = [ config.age.secrets.immich-db-password.path ];
    volumes = [
      "${immichPhotos}:/usr/src/app/upload"
      "/etc/localtime:/etc/localtime:ro"
    ];
    devices = [ "/dev/dri" ]; # hw acc
  };

  # hardware acceleration, needs hardware.graphics.enable = true;
  hardware.graphics.enable = true;

  virtualisation.oci-containers.containers.immich_machine_learning = {
    networks = [ "immich" ];
    image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
    extraOptions = [
      "--pull=newer"
      "--network-alias=immich-machine-learning"
    ];
    environment = {
      IMMICH_VERSION = immichVersion;
    };
    volumes = [
      "${immichAppdataRoot}/model-cache:/cache"
    ];
    devices = [ "/dev/dri" ]; # hw acc
  };

  # make redis happy, or else it warns on start
  boot.kernel.sysctl."vm.overcommit_memory" = 1;
  virtualisation.oci-containers.containers.immich_redis = {
    networks = [ "immich" ];
    image = "redis:6.2-alpine@sha256:80cc8518800438c684a53ed829c621c94afd1087aaeb59b0d4343ed3e7bcf6c5";
  };

  # first time, needed to run
  # podman exec -it immich_postgres bash
  # psql -U immich -d immich -c "ALTER SYSTEM SET shared_preload_libraries = 'vectors.so'"
  # it should output "ALTER SYSTEM"
  virtualisation.oci-containers.containers.immich_postgres = {
    networks = [ "immich" ];
    image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
    environment = {
      POSTGRES_USER = postgresUser;
      POSTGRES_DB = postgresDb;
    };
    cmd = [
      "bash"
      "-c"
      "source /run/secrets/db-password && export POSTGRES_PASSWORD=\"$DB_PASSWORD\" && exec docker-entrypoint.sh postgres"
    ];
    volumes = [
      "${postgresRoot}:/var/lib/postgresql/data"
      "${config.age.secrets.immich-db-password.path}:/run/secrets/db-password:ro"
    ];
    extraOptions = [
      "--health-cmd=pg_isready -U ${postgresUser} -d ${postgresDb}"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=5"
      "--network-alias=immich-postgres"
    ];
  };
}
