# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, inputs, ... }:

let
  # automounts = [ "torgeir" "music" "delt" "cam" ];
  automounts = [];
  homeManagerSessionVars =
    "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh";
in {

  nixpkgs.overlays = [ (import ./overlay.nix { inherit inputs; }) ];

  imports = [
    ./hardware-configuration.nix
    ./realtime-audio.nix
    ./modules/_1password.nix
    ./modules/qmk.nix
    ./modules/qemu.nix
    ./modules/acme.nix
    ./modules/nginx.nix
    ./modules/immich.nix
    # TODO nix profile
    # ./modules/printer.nix
    ./modules/headtracking.nix
  ];

  networking.hostName = "torgnix";
  networking.hostId = "61433039";

  boot.loader.systemd-boot = {
    enable = true;
    # number of generations to keep
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    # resolution during boot
    "video=DP-1:1920x1080@60Hz"
    "video=DP-2:1920x1080@60Hz"

    # "cgroup_enable=cpuset"

    # https://web.archive.org/web/20171228022907/https://blog.le-vert.net/?p=24
    # https://askubuntu.com/questions/1272026/acpi-bios-error-bug-could-not-resolve-symbol-sb-pcio-sato-prto-gtf-dssp

    # fix wierd bus size thunderbolt usb pci rescan not able to hotplug?
    # https://forum.level1techs.com/t/asrock-x570-phantom-tb3-itx-and-linux-no-bus-number-available-for-hot-added-bridge/156951/7
    # https://bbs.archlinux.org/viewtopic.php?id=253050
    "pci=assign-busses,hpbussize=0x33,realloc"
  ];

  # https://github.com/Mic92/sops-nix/blob/master/README.md
  # a good description of how to deploy to a host
  #   https://sr.ht/~bwolf/dotfiles/
  #
  # create private key
  #   nix-shell -p age --run "age-keygen -o /etc/nix-sops.key"
  # echo public key
  #   nix-shell -p age --run "age-keygen -y /etc/nix-sops.key"
  #
  # https://github.com/Mic92/sops-nix/issues/149
  # needs to live where it is available during boot
  sops.age.keyFile = "/etc/nix-sops.key";

  # put public key in .sops.yml
  #
  # cat <<EOF > .sops.yml
  # keys:
  #   - &torgeir $(nix-shell -p age --run "age-keygen -y /etc/nix-sops.key")
  # creation_rules:
  #   - path_regex: .*
  #     key_groups:
  #     - age:
  #         - *torgeir
  # EOF
  #
  # works around sops issue https://github.com/getsops/sops/pull/1898
  #   mkdir /tmp/nohome
  # insert secrets
  #   HOME=/tmp/nohome SOPS_AGE_KEY_FILE=/etc/nix-sops.key EDITOR=emacsclient nix-shell -p sops --run "sops secrets.yaml"
  # and put e.g.
  #   smb: |
  #     username: <username>
  #     password: <password>
  #
  # to change keys, add new key to .sops.yaml like above (cat <<EOF..)
  # > HOME=/tmp/nohome SOPS_AGE_KEY_FILE=/etc/nix-sops-smb.key EDITOR=vim nix-shell -p sops --run "sops updatekeys secrets.yaml"
  # then edit with the other key
  # > HOME=/tmp/nohome SOPS_AGE_KEY_FILE=/etc/nix-sops.key EDITOR=vim nix-shell -p sops --run "sops updatekeys secrets.yaml"
  #
  # if you don't feel like committing secrets.yaml,
  # check out ./untrack-secrets.sh
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."smb".owner = "torgeir";

  # mounts
  # https://discourse.nixos.org/t/systemd-mounts-and-systemd-automounts-options-causing-an-error/13796/5
  boot.supportedFilesystems = [ "cifs" "zfs" ];

  systemd.mounts = map (mount: {
    description = "Mount ${mount}";
    what = "//fileserver/${mount}";
    where = "/run/mount/${mount}";
    type = "cifs";
    options = "_netdev,credentials=${
        config.sops.secrets."smb".path
      },uid=1000,gid=100,iocharset=utf8,rw,vers=3.0";
  }) automounts;

  systemd.automounts = map (mount: {
    description = "Automount /${mount}";
    where = "/run/mount/${mount}";
    wantedBy = [ "multi-user.target" ];
  }) automounts;

  # https://github.com/jakeisnt/nixcfg/blob/main/modules/security.nix#L4

  # https://nixos.wiki/wiki/MPD
  services.mpd = {
    enable = true;
    user = "torgeir";
    musicDirectory = "/run/mount/music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "My PipeWire Output"
      }
    '';
  };
  systemd.services.mpd.environment = {
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
    # MPD will look inside this directory for the PipeWire socket.
    XDG_RUNTIME_DIR = "/run/user/1000";
  };

  # amd gpu
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.graphics.enable = true;
  environment.variables.AMD_VULKAN_ICD = "RADV";
  # leaving the below out performs better than with amdvlk
  # hardware.graphics.extraPackages = with pkgs; [ amdvlk ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # make xbox controllers able to pair
  hardware.bluetooth.settings = {
    General = {
      # this was already in the config file
      ControllerMode = "dual";
      # this was not, the controllers need a private channel to pair
      Privacy = "device";
    };
  };

  # wireless
  # networking.wireless.enable = true;
  # networking.networkmanager.enable = true;
  #
  # firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    # 80
    443
    # 7860
    8080
    # 11434
  ];
  networking.firewall.allowedUDPPorts = [ 4242 ];

  # sorry stallman, can't live without them
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "slack"
      "firefox-bin"
      "firefox-bin-unwrapped"

      "cnijfilter2"     # canon pixma ink printer drivers

      "1password"
      "1password-cli"
      "1password-gui"
      "1password-gui-beta"

      "dropbox"

      "reaper"
      "linuxsampler"

      "steam"
      "steam-run"
      "steam-original"
      "steam-unwrapped"
    ];

  environment.systemPackages = with pkgs; [
    zfs
    zstd

    deno

    nixd

    git
    kdePackages.ark
    wget
    unzip
    python3
    p7zip
    pciutils  # e.g. lspci
    usbutils  # e.g. lsusb
    dig
    cmake
    gnumake
    coreutils
    lm_sensors

    # rx6800xt
    amdgpu_top

    # yubikey bio
    pam_u2f # setup keys: pamu2fcfg > ~/.config/Yubico/u2f_keys
    yubikey-manager # unlock with: ykman fido access verify-pin
    yubioath-flutter # gui to set fingerprints

    tailscale

    clojure
    leiningen

    krita

    # docker rootless
    slirp4netns


    # kotlin-lsp from overlay.nix
    kotlin-lsp-official
  ];

  services.tailscale.enable = true;

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];
  services.tumbler.enable = true; # thunar thumbnails
  services.gvfs.enable = true; # thunar mount, trash, other functionalities

  # fix missing xdg session vars
  environment.extraInit = ''
    [[ -f ${homeManagerSessionVars} ]] && source ${homeManagerSessionVars}
  '';

  # slack wayland
  # https://nixos.wiki/wiki/Slack
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  hardware.amdgpu.overdrive.ppfeaturemask = "0xffffffff";
  hardware.amdgpu.overdrive.enable = true;

  # add .local/bin/ to front of path
  environment.localBinInPath = true;

  programs = {

    # amd gpu
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/corectrl.nix
    # https://gitlab.com/corectrl/corectrl/-/wikis/Setup#full-amd-gpu-controls

    corectrl = {
      enable = true;
      package = pkgs.stable.corectrl;
    };

    steam.enable = true;
    steam.extraCompatPackages = [ pkgs.proton-ge-bin ];
    steam.protontricks.enable = true;
  };

  # here, and not home-manager, as my own config is in dotfiles/
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  services.dbus.enable = true;
  services.dbus.packages = [ pkgs.rtkit ];

  # sway needs polkit
  security.polkit = {
    enable = true;
    debug = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        polkit.log("User " +  subject.user + " is attempting action " + action.id + " from PID " + subject.pid);
      });
    '';
  };
  # silence polkit errors about missing directories
  systemd.tmpfiles.rules = [
    "d /run/polkit-1/rules.d 0755 root root -"
    "d /usr/local/share/polkit-1/rules.d 0755 root root -"
  ];

  # only wheels sudo
  security.sudo = {
    enable = true;
    execWheelOnly = true;
  };

  # audit, https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
  security.auditd.enable = false;
  security.audit.enable = false;
  security.audit.rules = [ "-a exit,always -F arch=b64 -S execve" ];

  # ssh
  services.openssh = {
    enable = false;
    allowSFTP = false;
    settings = {
      passwordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
  };

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/security/pam.nix#L163
  security.pam.u2f = {
    enable = true;
    # don't require both pw and biometrics
    control = "sufficient";
    # send que when to biometric touch
    settings.cue = true;
    # debug to stdout
    #debug = true;
    #interactive = true;
  };

  # auto login torgeir
  # services.getty.autologinUser = lib.mkForce "torgeir";

  # support yubikey for sudo and login
  security.pam.services.torgeir.u2fAuth = true;

  # thunderbolt
  # owc 11-port dock
  services.hardware.bolt.enable = true;

  # save ssds
  services.fstrim.enable = true;

  # containers
  #   systemctl --user start docker
  virtualisation.docker = {
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        data-root = "/home/torgeir/data";
        # dette rotet til ollama docker-compose.yml
        # dns = ["192.168.2.1" "1.1.1.1"];
      };
    };
  };

  # TODO auto start docker compose for torgeir

  # zram instead of swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # moar https://github.com/NixOS/nixos-hardware

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  #
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";

}

