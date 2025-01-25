{ inputs, name, pkgs, lib, stdenv, fetchFromGitHub, ... }:

{
  # make nix crosscompile, from an x86 linux box, to an arm image
  nixpkgs.buildPlatform.system = "x86_64-linux";
  nixpkgs.hostPlatform.system = "aarch64-linux";

  nixpkgs.config.allowUnfree = true; # reaper

  # need a trusted user for deploy-rs.
  nix.settings.trusted-users = [ "@wheel" ];

  nix.settings.substituters = [ "https://cache.nixos.org" ];

  boot = {
    kernelParams = [ "console=ttyAMA0,115200n8" "console=ttyS0,115200n8" ];
    kernelModules = [ "i2c-dev" ];
    initrd.availableKernelModules = pkgs.lib.mkForce [ "mmc_block" ];

    # v4l2-loopback? https://gist.github.com/TheSirC/93130f70cc280cdcdff89faf8d4e98ab

    # supportedFilesystems = [ "cifs" ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    kernelPackages = lib.mkForce (pkgs.linuxPackages_latest);

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set.
    # This will cause the `mdmon` service to crash.
    # https://github.com/NixOS/nixpkgs/issues/254807
    # swraid.enable = lib.mkForce false;

    # needed for deploy-rs
    binfmt.emulatedSystems = [ "x86_64-linux" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD"; # name of sd card when written
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  environment.systemPackages = with pkgs; [
    # neofetch
    # vim
    # htop

    # https://man.archlinux.org/man/calf.7.en
    # https://github.com/andyb2000/rivendell-tools/blob/8902fec1027be2e4f7c222b4ea5afcdd837ac613/calf_forever.sh
    jalv
    # guitarix
    # neural-amp-modeler-lv2
    # jack2
    # qjackctl
  ];

  sdImage.compressImage = false;
  sdImage.imageName = "${name}.img";

  # make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  time.timeZone = "Europe/Oslo";

  services.openssh.enable = true;
  services.timesyncd.enable = true;

  system.stateVersion = "24.11";

  networking = {
    hostName = name;
    wireless = {
      enable = true;
      networks."znort-guest".psk = "";
      interfaces = [ "wlan0" ];
    };
    interfaces."wlan0".useDHCP = true;
  };

  # users.users.root.openssh.authorizedKeys.keys = [ ];

  nixpkgs.overlays = [
    (final: prev: {
      makeModulesClosure = x:
        prev.makeModulesClosure (x // { allowMissing = true; });
    })

    (final: prev:
      let inherit (prev) callPackage;
      in {
        neural-amp-modeler-lv2 = callPackage ../pkgs/neural-amp-modeler-lv2 { };
      })
  ];

  users.users.nam = {
    isNormalUser = true;
    home = "/home/nam";
    description = "nam";
    extraGroups = [ "wheel" "networkmanager" "video" "jackaudio"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.getty.autologinUser = lib.mkForce "nam";


  services.xserver = {
    enable = true;
    autorun = true;
    displayManager = {
      lightdm.enable = true;
    };
    windowManager = {
      dwm.enable = true;
    };
  };
  services.displayManager.defaultSession = "none+dwm";
  # services.displayManager.autoLogin = true;


  ##
  ## nam sound specific setup
  ##

  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  # https://nixos.wiki/wiki/JACK

  # services.jack = {
  #   jackd.enable = true;
  #   # support ALSA only programs via ALSA JACK PCM plugin
  #   alsa.enable = false;
  #   # support ALSA only programs via loopback device (supports programs like Steam)
  #   loopback = {
  #     enable = true;
  #     # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
  #     #dmixConfig = ''
  #     #  period_size 2048
  #     #'';
  #   };
  # };


  # TODO LV2 path home sessionVariable

}
