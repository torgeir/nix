{
  config,
  lib,
  pkgs,
  ...
}:

let
  wallabagHost = "wallabag.wa.gd";
  wallabagRoot = "/fast/shared/apps/wallabag";
  wallabagData = "${wallabagRoot}/data";
in
{
  # Wallabag runs as a rootless podman container under the dedicated `wallabag`
  # system user.  The service is a plain systemd unit rather than an
  # oci-containers entry so we can set User/Group and inject the correct
  # XDG_RUNTIME_DIR that rootless podman requires.
  #
  # Migration from rootful oci-containers – manual steps for server owner:
  # See MIGRATION.md at the root of this repository.

  users.users.wallabag = {
    isSystemUser = true;
    group = "wallabag";
    home = "/var/lib/wallabag"; # rootless podman storage lives here
    createHome = true;
    # These ranges let the kernel map UIDs inside the container's user namespace.
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };
  users.groups.wallabag = { };

  system.activationScripts.createPodmanWallabagFolders = lib.mkAfter ''
    mkdir -p ${wallabagData}
    chown -R wallabag:wallabag ${wallabagData}
  '';

  systemd.services.wallabag = {
    description = "Wallabag (rootless podman)";
    after = [
      "network-online.target"
      "nss-lookup.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      # rootless podman needs XDG_RUNTIME_DIR; RuntimeDirectory below creates
      # /run/wallabag and systemd sets $RUNTIME_DIRECTORY to that path, but
      # podman reads XDG_RUNTIME_DIR directly.
      XDG_RUNTIME_DIR = "/run/wallabag";
      HOME = "/var/lib/wallabag";
      PODMAN_SYSTEMD_UNIT = "%n";
    };

    serviceConfig = {
      User = "wallabag";
      Group = "wallabag";

      # systemd creates /run/wallabag (mode 0700, owned by wallabag) before
      # ExecStartPre and removes it on stop.
      RuntimeDirectory = "wallabag";
      RuntimeDirectoryMode = "0700";

      # Required so systemd hands cgroup management to podman for rootless
      # conmon/cgroups=split to work correctly.
      Delegate = true;

      Type = "notify";
      NotifyAccess = "all";

      ExecStartPre = [
        # Create the per-user podman network if it does not exist yet.
        "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman network exists wallabag || ${pkgs.podman}/bin/podman network create wallabag'"
        # Remove any leftover container from a previous unclean stop.
        "-${pkgs.podman}/bin/podman rm -f wallabag"
      ];

      ExecStart = lib.concatStringsSep " " [
        "${pkgs.podman}/bin/podman run"
        "--rm"
        "--sdnotify=conmon"
        "--cgroups=split"
        "--name=wallabag"
        "--network=wallabag"
        "--pull=newer"
        "-p 8091:80"
        "-e TZ=Europe/Oslo"
        "-e SYMFONY__ENV__DOMAIN_NAME=https://${wallabagHost}"
        "--env-file=${config.age.secrets.wallabag-env.path}"
        "-v ${wallabagData}:/var/www/wallabag/data"
        "docker.io/wallabag/wallabag:2.6.10"
      ];

      ExecStop = "${pkgs.podman}/bin/podman stop -t 10 wallabag";
      ExecStopPost = "-${pkgs.podman}/bin/podman rm -f wallabag";

      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
