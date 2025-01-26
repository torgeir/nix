
{ name, nixpkgs }:

nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform.nixos {
  imports = [

    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"

    ({ lib, config, pkgs, ... }: {

      # need a trusted user for deploy-rs.
      nix.settings.trusted-users = [ "@wheel" ];

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

      users.users.nam = {
        isNormalUser = true;
        home = "/home/nam";
        description = "nam";
        extraGroups = [ "wheel" "networkmanager" "video" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
        ];
      };

      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      services.getty.autologinUser = lib.mkForce "nam";

    })

  ];
}
