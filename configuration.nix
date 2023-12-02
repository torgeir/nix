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

  nixpkgs.overlays = [ (import ./overlay.nix) ];

  imports = [
    ./hardware-configuration.nix

    inputs.musnix.nixosModules.musnix

    inputs.nix-gaming.nixosModules.steamCompat
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # number of generations to keep
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # blacklist pci sound card, use usb arturia audiofuse
  boot.blacklistedKernelModules = [ "snd_hda_intel" ];

  boot.postBootCommands = ''
    #!/bin/bash
    echo 2048 > /sys/class/rtc/rtc0/max_user_freq
    echo 2048 > /proc/sys/dev/hpet/max-user-freq
    setpci -v -d *:* latency_timer=b0
    for p in $(lspci | grep -i thunderbolt | awk '{print $1}'); do
      setpci -v -s $p latency_timer=ff
    done
  '';

  # clean up every once in a while
  #   sudo nix-collect-garbage
  #   sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 21d";
  };
  nix.settings.auto-optimise-store = true;

  # emacs 29 needs older gnupg than 2.4.1 due to hangs, pkgs.gnupg22 seems to
  # work it needs this older libcrypt
  nixpkgs.config.permittedInsecurePackages = [ "libgcrypt-1.8.10" ];

  # cat /proc/cmdline
  boot.kernelParams = [
    # realtime audio tuning
    "preemt=full"
    # resolution during boot
    "video=DP-1:1920x1080@60Hz"
    "video=DP-2:1920x1080@60Hz"
  ];

  # realtime audio
  boot.kernel.sysctl = { "vm.swappiness" = 10; };

  musnix.kernel.realtime = true;
  musnix.kernel.packages = pkgs.linuxPackages_6_4_rt;

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
      "jackaudio"
    ];
  };

  # TODO torgeir
  fonts = {
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/iosevka/variants.nix
    packages = with pkgs;
    # [ (iosevka-bin.override { variant = "curly-slab"; }) ];
      [ (iosevka-bin.override { variant = "sgr-iosevka-term-curly-slab"; }) ];
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
    wget
    unzip
    #TODO remove
    python3
    pciutils # e.g. lspci
    usbutils # e.g. lsusb
    cmake
    gnumake
    coreutils
    lm_sensors
    # TODO moar wayland
    dmenu-wayland
    # TODO torgeir
    irqbalance
  ];

  # TODO torgeir mer
  # disable bluetooth
  # disable wifi

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
  security.auditd.enable = true;
  security.audit.enable = true;
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

  # make helix native activation happy
  environment.etc.machine-id.source = ./machine-id;

  # low latency audio tuning
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface

  # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning#rlimits
  # https://linuxmusicians.com/viewtopic.php?t=25556
  # https://github.com/chmaha/ArchProAudio
  # https://nixos.wiki/wiki/PipeWire
  #   pw-dump to check pipewire config
  #   systemctl --user status pipewire wireplumber
  #   systemctl --user restart pipewire wireplumber
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true; # alsa support
    jack.enable = true; # pipewire jack emulation
    pulse.enable = true; # pipewire pulse emulation
    wireplumber.enable = true;
  };

  # pw-metadata -n settings 0 clock.force-quantum 512
  # for p in $(ps -eLo pid,cmd | grep -i pipewire | grep -v grep | awk '{print $1}'); do sudo chrt -f -p 99 $p; done
  environment.etc."wireplumber/main.lua.d/98-alsa-no-pop.lua".text = ''
    table.insert(alsa_monitor.rules, {
      matches = {
        {
          { "node.name", "matches", "alsa_output.*" },
        },
      },
      apply_properties = {
        ["session.suspend-timeout-seconds"] = 0,
        ["suspend-node"] = false,
        ["node.pause-on-idle"] = false,
        ["api.alsa.rate"] = 48000,
        --["api.alsa.period-size"] = 168,
        --["api.alsa.period-size"] = 256,
        ["api.alsa.period-size"] = 512,
        ["api.alsa.period-num"] = 3,
      },
    })
  '';

  # ensure realtime processes don't hack the machine
  services.das_watchdog.enable = true;

  services.getty.autologinUser = lib.mkForce "torgeir";

  # help reaper control cpu latency, when you start it from audio group user
  # control power mgmt from userspace (audio) group
  # https://wiki.linuxaudio.org/wiki/system_configuration#quality_of_service_interface
  services.udev.extraRules = ''
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
  '';

  # cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  powerManagement.cpuFreqGovernor = "performance";

  security.rtkit.enable = true;

  #  jackd -R -P 99 -d alsa -d hw:AudioFuse,0 -r 48000 -p 168 -n 3
  #  for p in $(ps -eLo pid,cmd | grep -i jack | grep -v grep | awk '{print $1}'); do chrt -f -p 99 $p; done
  # TODO torgeir
  services.irqbalance.enable = true;

  systemd.services.adjust-sound-card-irqs = {
    description = "IRQ thread tuning for realtime kernels";
    after = [ "multi-user.target" "sound.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ nix gawk gnugrep gnused procps ];
    serviceConfig = {
      User = "root";
      # run it once
      Type = "oneshot";
      # its ok that it exits
      RemainAfterExit = true;
      ExecStart = pkgs.writers.writeBash "adjust-sound-card-irqs" ''
        # https://www.reddit.com/r/linuxaudio/comments/8isvxn/comment/dywjory/
        # run xhci_hcd driver (extensible host controller interface, used for usb 3.0) # with real time priority on cpu 2
        # check it with top -c 0.2

        pidof_xhci=$(ps -eLo pid,cmd | grep -i xhci | head -1 | awk '{print $1}')
        intof_xhci=$(cat /proc/interrupts | grep xhci_hcd | cut -f1 -d: | sed s/\ //g)

        # set realtime priority for all pids
        PATH=/run/current-system/sw/bin/:$PATH chrt -f -p 99 $pidof_xhci

        # pin them to a single cpu
        cpu=10
        PATH=/run/current-system/sw/bin:$PATH taskset -cp $cpu $pidof_xhci
        for i in $intof_xhci; do
          echo $cpu > /proc/irq/$i/smp_affinity
          cat /proc/irq/$i/smp_affinity

          echo $cpu > /proc/irq/$i/smp_affinity_list
          cat /proc/irq/$i/smp_affinity_list
        done
      '';
    };
  };

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "98";
    }
    {
      domain = "@audio";
      item = "nice";
      type = "-";
      value = "-11";
    }
    # these two needed?
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "99999";
    }
  ];

  # thunderbolt
  # owc 11-port dock
  services.hardware.bolt.enable = true;

  # save ssds
  services.fstrim.enable = true;

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

