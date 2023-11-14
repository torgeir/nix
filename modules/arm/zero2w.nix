{ lib, config, modulesPath, pkgs, ... }: {
  imports = [ ./sd-image.nix ];

  nixpkgs.hostPlatform = "aarch64-linux";
  # nixpkgs.hostPlatform = "armv7l-linux";

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  boot.kernelPackages =
    lib.mkForce (config.boot.zfs.package.latestCompatibleLinuxPackages);

  # ! Need a trusted user for deploy-rs.
  nix.settings.trusted-users = [ "@wheel" ];
  system.stateVersion = "23.11";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
    compressImage = false;
    imageName = "zero2w.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      # start_x = 0;
      # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
      # gpu_mem = 32;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;

      # torgeir
      start_file = "start_x.elf";
      fixup_file = "fixup_x.dat";
      gpu_mem = 128;
      cma_lwm = "";
      cma_hwm = "";
      cma_offline_start = "";
    };
  };

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  boot = {
    # TODO doesn't work
    # kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;

    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;
  };

  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      # ! Change the following to connect to your own network
      networks = { "the-network" = { psk = "the-password"; }; };
    };
  };

  services.sshd.enable = true;
  services.timesyncd.enable = true;

  # ! Change the following configuration
  users.users.alarmpi = {
    isNormalUser = true;
    home = "/home/alarm";
    description = "alarm";
    extraGroups = [ "wheel" "networkmanager" ];
    # ! Be sure to put your own public key here
    openssh.authorizedKeys.keys = [''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL
    ''];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # ! Be sure to change the autologinUser.
  # services.getty.autologinUser = "alarm";
}
