# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, inputs, ... }:

let
  automounts = [ "torgeir" "music" "delt" "cam" ];
  homeManagerSessionVars =
    "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh";
in {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs.overlays = [
    (import ./overlay.nix)
    # TODO torgeir not working
    # https://github.com/musnix/musnix/issues/167
    # (final: prev: {
    #   linuxPackages_torgeir = pkgs.linuxPackagesFor
    #     (pkgs.linuxPackages_6_6_rt.override {
    #       structuredExtraConfig = with prev.pkgs.lib.kernel; {
    #         LATENCYTOP = yes;
    #         SCHEDSTATS = yes;
    #       };
    #     });
    # })

  ];

  imports = [
    ./hardware-configuration.nix

    ./realtime-audio.nix

    inputs.nix-gaming.nixosModules.steamCompat
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # number of generations to keep
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # clean up every once in a while
  #   sudo nix-collect-garbage
  #   sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 21d";
  };
  nix.settings.auto-optimise-store = true;

  boot.kernelParams = [
    # resolution during boot
    "video=DP-1:1920x1080@60Hz"
    "video=DP-2:1920x1080@60Hz"

    # rt kernel tuning
    # - https://ubuntu.com/blog/real-time-kernel-tuning
    # - https://lwn.net/Articles/816298/
    "nohz=on"
    "nohz_full=16-31"
    "kthread_cpus=0-15"
    "irqaffinity=0-15"
    "isolcpus=managed_irq,nohz,domain,16-31"

    # https://web.archive.org/web/20171228022907/https://blog.le-vert.net/?p=24
    # https://askubuntu.com/questions/1272026/acpi-bios-error-bug-could-not-resolve-symbol-sb-pcio-sato-prto-gtf-dssp
    # TODO torgeir did not have an effect?
    # "libata.noacpi=1"

    # fix wierd bus size thunderbolt usb pci rescan not able to hotplug?
    "pci=assign-busses,hpbussize=0x33,realloc"
  ];

  # https://github.com/Mic92/sops-nix/blob/master/README.md
  # a good description of how to deploy to a host
  #   https://sr.ht/~bwolf/dotfiles/
  #
  # create private key
  #   nix-shell -p age --run "age-keygen -o /etc/nix-sops-smb.key"
  # echo public key
  #   nix-shell -p age --run "age-keygen -y /etc/nix-sops-smb.key"
  #
  # https://github.com/Mic92/sops-nix/issues/149
  # needs to live where it is available during boot
  sops.age.keyFile = "/etc/nix-sops-smb.key";

  # put public key in .sops.yml
  #
  # cat <<EOF > .sops.yml
  # keys:
  #   - &torgeir $(nix-shell -p age --run "age-keygen -y /etc/nix-sops-smb.key")
  # creation_rules:
  #   - path_regex: .*
  #     key_groups:
  #     - ace:
  #         - *torgeir
  # EOF
  #
  # insert secrets
  #   nix-shell -p sops --run "sops secrets.yaml"
  #
  # if you don't feel like committing secrets.yaml,
  # check out untrack-secrets.sh
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets."smb".owner = "torgeir";

  # mounts
  # https://discourse.nixos.org/t/systemd-mounts-and-systemd-automounts-options-causing-an-error/13796/5
  boot.supportedFilesystems = [ "cifs" ];
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
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.extraPackages = with pkgs; [ amdvlk ];

  time.timeZone = "Europe/Oslo";
  networking.hostName = "torgnix";

  # wireless
  # networking.wireless.enable = true;
  # networking.networkmanager.enable = true;
  #
  # firewall
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = ...;
  # networking.firewall.allowedUDPPorts = [ ... ];

  # locale
  i18n.defaultLocale = "en_US.UTF-8";

  # set a password with passwd
  users.users.torgeir = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "torgeir"
      "wheel" # enable sudo
      "corectrl" # adjust gpu fans
      "audio" # realtime audio for user
      "pipewire" # realtime audio for pw
    ];
  };

  # sorry stallman, can't live without them
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "slack"

      "1password"
      "1password-cli"
      "1password-gui"

      "dropbox"

      "reaper"

      "steam"
      "steam-run"
      "steam-original"
    ];

  # password manager
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "torgeir" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    ark
    fzf
    wget
    unzip
    python3
    pciutils # e.g. lspci
    usbutils # e.g. lsusb
    cmake
    gnumake
    coreutils
    lm_sensors
  ];

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

  # add .local/bin/ to front of path
  environment.localBinInPath = true;

  programs = {

    # amd gpu
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/corectrl.nix
    # https://gitlab.com/corectrl/corectrl/-/wikis/Setup#full-amd-gpu-controls
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff";
      };
    };

    steam = { enable = true; };

    # shell
    zsh.enable = true;
  };

  # here, and not home-manager, as my own config is in dotfiles/
  programs.sway.enable = true;

  # sway needs polkit
  security.polkit.enable = true;

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

  # services.getty.autologinUser = lib.mkForce "torgeir";

  # thunderbolt
  # owc 11-port dock
  services.hardware.bolt.enable = true;

  # save ssds
  services.fstrim.enable = true;

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

