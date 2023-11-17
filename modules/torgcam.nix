{ name, nixpkgs }:

nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform.nixos {
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
    ./arm/sd-image.nix
    ({ lib, config, pkgs, ... }: {
      boot = {
        initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];

        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };

        kernelPackages = lib.mkForce (pkgs.linuxPackages_latest);

        # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
        # See: https://github.com/NixOS/nixpkgs/issues/254807
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

      environment.systemPackages = with pkgs; [ neofetch vim ];

      # ! Need a trusted user for deploy-rs.
      nix.settings.trusted-users = [ "@wheel" ];

      sdImage.compressImage = false;
      sdImage.imageName = "${name}.img";
      sdImage.extraFirmwareConfig = {
        # Give up VRAM for more Free System Memory
        # - Disable camera which automatically reserves 128MB VRAM
        # start_x = 0;
        # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
        # gpu_mem = 16;

        # torgeir
        gpu_mem = 128;
        start_file = "start_x.elf";
        fixup_file = "fixup_x.dat";
        # torgeir fix "camera not enabled in build"
        cma_lwm = "";
        cma_hwm = "";
        cma_offline_start = "";
      };

      # Make sure wifi works
      hardware.enableRedistributableFirmware = lib.mkForce false;
      hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

      services.openssh.enable = true;
      services.timesyncd.enable = true;

      system.stateVersion = "23.11";

      networking = {
        hostName = name;
        wireless = {
          enable = true;
          networks."ssid".psk = "pw";
          interfaces = [ "wlan0" ];
        };
        interfaces."wlan0".useDHCP = true;
      };

      # users.users.root.openssh.authorizedKeys.keys = [ ];

      users.users.torgeir = {
        isNormalUser = true;
        home = "/home/torgeir";
        description = "torgeir";
        extraGroups = [ "wheel" "networkmanager" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
        ];
      };

      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      # services.getty.autologinUser = lib.mkForce "torgeir";

    })

  ];
}
