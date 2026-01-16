{
  pkgs,
  lib,
  config,
  ...
}:

let

  makePublicRoShare = path: {
    name = builtins.baseNameOf path;
    value = {
      inherit path;
      "browseable" = "yes";
      "read only" = "yes";
      "guest only" = "yes";
      "force user" = "nobody";
    };
  };
  makePublicShare = path: {
    name = builtins.baseNameOf path;
    value = {
      inherit path;
      "browseable" = "yes";
      "writeable" = "yes";
      "guest ok" = "yes"; # allow users and guests
      "force group" = "shared";
      "create mask" = "0664";
      "directory mask" = "0775";
    };
  };
  makePrivateShare = user: path: {
    name = builtins.baseNameOf path;
    value = {
      inherit path;
      "browseable" = "yes";
      "writeable" = "yes";
      "guest ok" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
      "force user" = user;
      "force group" = "users"; # gid 100
    };
  };
  shares = {
    music = "/fast/shared/music";
    delt = "/fast/shared/delt";
    maja = "/fast/shared/maja";
    torgeir = "/fast/shared/torgeir";
  };
in
{
  # Tools
  environment.systemPackages = with pkgs; [ samba ];

  # Daemon
  services.samba = {
    enable = true;
    package = pkgs.sambaFull;
    openFirewall = true;
    settings = {
      "global" = {
        "netbios name" = config.networking.hostName;
        "name resolve order" = "bcast host";
        "hosts allow" = "192.168.50. 192.168.20. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "load printers" = false;
        "printcap name" = "/dev/null";
        "printing" = "bsd";
        # avoid ipv6 bind errors
        "bind interfaces only" = true;
        "interfaces" = "eno1 lo";
        "workgroup" = "WORKGROUP";
      };
    }
    // (lib.listToAttrs [ (makePublicRoShare shares.music) ])
    // (lib.listToAttrs [ (makePublicShare shares.delt) ])
    // (lib.listToAttrs [ ((makePrivateShare "maja") shares.maja) ])
    // (lib.listToAttrs [ ((makePrivateShare "torgeir") shares.torgeir) ]);
  };

  # User for /fast/shared/maja
  users.groups.maja = {
    gid = 1001;
    name = "maja";
  };
  users.users.maja = {
    uid = 1001;
    createHome = false;
    isNormalUser = true;
    useDefaultShell = true;
    group = "maja";
    extraGroups = [ "samba" ];
  };

  users.groups.shared = {
    gid = 1020;
    members = [
      "torgeir"
      "maja"
    ];
  };

  # set passwords.
  # sudo smbpasswd -a maja
  # sudo smbpasswd -a torgeir
  #
  # test locally:
  # smbclient -L localhost -U%
  #
  # see settings:
  # sudo testparam -s

  system.activationScripts.smb_users_maja = ''
    set -euo pipefail
    pass="$(cat ${config.age.secrets.smb-maja-password.path})"
    echo -e "$pass\n$pass" | ${pkgs.samba}/bin/smbpasswd -a -s maja || true
  '';
  system.activationScripts.smb_users_torgeir = ''
    set -euo pipefail
    pass="$(cat ${config.age.secrets.smb-torgeir-password.path})"
    echo -e "$pass\n$pass" | ${pkgs.samba}/bin/smbpasswd -a -s torgeir || true
  '';

}
