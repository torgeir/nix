{ name, nixpkgs }:

nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform.nixos {
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
    ./arm/sd-image.nix
    ({ lib, config, pkgs, ... }: {

      # need a trusted user for deploy-rs.
      nix.settings.trusted-users = [ "@wheel" ];

      boot = {
        # https://discourse.nixos.org/t/load-automatically-kernel-module-and-deal-with-parameters/9200
        initrd.availableKernelModules =
          [ "xhci_pci" "usbhid" "usb_storage" "bcm2835-v4l2" ];
        blacklistedKernelModules =
          [ "i2c_bcm2708" "i2c_bcm2835" ]; # TODO bcm2835?
        # TODO is this true
        extraModprobeConfig = ''
          options bcm2835-v4l2 max_video_width=3240 max_video_height=2464
        '';

        # v4l2-loopback? https://gist.github.com/TheSirC/93130f70cc280cdcdff89faf8d4e98ab

        supportedFilesystems = [ "cifs" ];

        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };

        kernelPackages = lib.mkForce (pkgs.linuxPackages_latest);

        # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
        # https://github.com/NixOS/nixpkgs/issues/254807
        swraid.enable = lib.mkForce false;

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

      nixpkgs.overlays = [
        (final: super: {
          makeModulesClosure = x:
            super.makeModulesClosure (x // { allowMissing = true; });
        })
      ];

      environment.systemPackages = with pkgs; [
        neofetch
        vim
        htop
        # https://www.tomshardware.com/how-to/use-raspberry-pi-camera-with-bullseye
        libcamera # cam -h
        # https://raspberrypi.stackexchange.com/questions/112743/v4l2-ctl-single-frame-capture-produces-image-with-green-ending
        (v4l-utils.override { withGUI = false; }) # mismatched qt dependencies
      ];

      image.fileName = "${name}.img";
      sdImage.compressImage = false;
      sdImage.extraFirmwareConfig = {
        # camera setup
        gpu_mem = 128;
        start_file = "start_x.elf";
        fixup_file = "fixup_x.dat";
        # fix "camera not enabled in build"
        cma_lwm = "";
        cma_hwm = "";
        cma_offline_start = "";
      };

      # make sure wifi works
      hardware.enableRedistributableFirmware = lib.mkForce false;
      hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

      services.openssh.enable = true;
      services.timesyncd.enable = true;

      # cannot be used with networking.wireless
      networking.networkmanager.enable = lib.mkForce false;
      # TODO disable ipv6
      networking = {
        hostName = name;
        wireless = {
          enable = true;
          networks."ssid".psk = "asdfasdf";
          interfaces = [ "wlan0" ];
        };
        interfaces."wlan0".useDHCP = true;
      };

      # users.users.root.openssh.authorizedKeys.keys = [ ];

      users.users.torgeir = {
        isNormalUser = true;
        home = "/home/torgeir";
        description = "torgeir";
        extraGroups = [ "wheel" "networkmanager" "video" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
        ];
      };

      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      # services.getty.autologinUser = lib.mkForce "torgeir";

      users.users.motion = {
        group = "motion";
        description = "motion camera user";
        uid = 510;
        extraGroups = [ "video" ];
      };
      users.groups.motion.gid = 510;

      systemd.mounts = map (mount: {
        description = "Mount ${mount}";
        what = "//fileserver/${mount}";
        where = "/run/mount/${mount}";
        type = "cifs";
        options =
          "_netdev,username=,password=,uid=1000,gid=1000,iocharset=utf8,rw,vers=3.0";
      }) [ "cam" ];

      systemd.automounts = map (mount: {
        description = "Automount /${mount}";
        where = "/run/mount/${mount}";
        wantedBy = [ "multi-user.target" ];
      }) [ "cam" ];

    })

  ];

  system.stateVersion = "23.11";
}
