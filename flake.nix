{
  description = "torgnix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, home-manager
    , nixpkgs-wayland, sops-nix, deploy-rs }: rec {
      #
      # https://github.com/sebastiant/dotfiles/blob/master/flake.nix
      # https://github.com/wiltaylor/dotfiles
      nixosConfigurations.torgnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [

          # os config
          ./configuration.nix

          #https://github.com/Mic92/sops-nix
          sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
          {

            # globally installed packages should be user available
            home-manager.useGlobalPkgs = true;

            # user packages can be installed without admin privileges
            home-manager.useUserPackages = true;

            # pass inputs to imported modules for users
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.torgeir = import ./home;
          }
        ];
      };

      nixosConfigurations.torgcam2 =
        nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform.nixos {
          imports = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
            ./modules/arm/sd-image.nix
            nixosModules.torgcam
          ];
        };

      # build it with
      #   nix build .#images.torgcam2
      #   zstdcat nixos-config/result/sd-image/nixos-sd-image-23.05pre-git-armv7l-linux.img.zst | sudo dd of=/dev/sdb bs=4M status=progress oflag=direct,
      images.torgcam2 =
        nixosConfigurations.torgcam2.config.system.build.sdImage;

      nixosModules.torgcam = ({ lib, config, pkgs, ... }: {

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
        };

        fileSystems = {
          "/" = {
            device =
              "/dev/disk/by-label/NIXOS_SD"; # name of sd card when written
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

        environment.systemPackages = with pkgs; [ neofetch vim htop ];

        # ! Need a trusted user for deploy-rs.
        nix.settings.trusted-users = [ "@wheel" ];

        sdImage.compressImage = false;
        sdImage.imageName = "torgcam2.img";
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
          hostName = "torgcam2";
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

      });

      deploy.nodes.torgcam2 = {
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos
            nixosConfigurations.torgcam2;
        };

        # this is how it ssh's into the target system to send packages/configs over.
        sshUser = "torgeir";
        hostname = "torgcam2";
      };

    };
}
