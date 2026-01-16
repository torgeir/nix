{
  config,
  lib,
  pkgs,
  ...
}:

{
  # mounts
  # https://discourse.nixos.org/t/systemd-mounts-and-systemd-automounts-options-causing-an-error/13796/5
  boot.supportedFilesystems = [
    "cifs"
    "zfs"
  ];

  # zfs needs machine-id, its from /etc/machine-id
  networking.hostId = "7592b337";
  environment.etc.machine-id.source = ./machine-id;

  # import zfs pool on boot, use this instead of fileSystems."path" as it uses
  # legacy mounting method using mount.
  # run zpool import and inspect, then zpool import -f fast, then do this:
  boot.zfs.extraPools = [ "fast" ];

  # https://github.com/jakubgs/nixos-config/blob/10b90621c106360a9ae098467df78961f5827699/roles/base/zfs.nix
  # Pin version
  boot.zfs.package = pkgs.zfs_2_4;
  # Enable hibernation
  boot.zfs.allowHibernation = true;
  # Importing a suspended pool can corrupt it
  boot.zfs.forceImportRoot = false;
  boot.zfs.forceImportAll = false;

  # Scrub to find errors
  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

}
