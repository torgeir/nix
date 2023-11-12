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

      nixosConfigurations.torgcam1 =
        nixpkgs-stable.legacyPackages.x86_64-linux.pkgsCross.armv7l-hf-multiplatform.nixos {
          imports = [
            "${nixpkgs-stable}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix"
            ./modules/arm/sd-image.nix # sdImage.extraFirmwareConfig
            nixosModules.torgcam1
          ];
        };

      # build it with
      #   nix build .#images.torgcam1
      #   zstdcat nixos-config/result/sd-image/nixos-sd-image-23.05pre-git-armv7l-linux.img.zst | sudo dd of=/dev/sdb bs=4M status=progress oflag=direct,
      images.torgcam1 =
        nixosConfigurations.torgcam1.config.system.build.sdImage;

      nixosModules.torgcam1 = ({ lib, config, pkgs, ... }: {

        boot = {
          initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
          loader = {
            grub.enable = false;
            generic-extlinux-compatible.enable = true;
          };
        };

        fileSystems = {
          "/" = {
            device =
              "/dev/disk/by-label/NIXOS_SD"; # name of sd card when written
            fsType = "ext4";
            options = [ "noatime" ];
          };
        };

        # needed ??
        # deal with that "module ahci not found" error
        nixpkgs.overlays = [
          (final: super: {
            makeModulesClosure = x:
              super.makeModulesClosure (x // { allowMissing = true; });
          })
        ];

        environment.systemPackages = with pkgs; [ neofetch vim ];

        sdImage.extraFirmwareConfig = {
          # Give up VRAM for more Free System Memory
          # - Disable camera which automatically reserves 128MB VRAM
          # start_x = 0;
          # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
          # gpu_mem = 16;
          # Configure display to 800x600 so it fits on most screens
          # * See: https://elinux.org/RPi_Configuration
          hdmi_group = 2;
          hdmi_mode = 8;

          # torgeir
          gpu_mem = 128;
          start_file = "start_x.elf";
          fixup_file = "fixup_x.dat";
          # torgeir fix "camera not enabled in build"
          cma_lwm = "";
          cma_hwm = "";
          cma_offline_start = "";
        };

        services.openssh.enable = true;
        services.timesyncd.enable = true;

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL"
        ];

        hardware.enableRedistributableFirmware = true;

        system.stateVersion = "23.11";

        networking = {
          hostName = "torgcam1";
          wireless = {
            enable = true;
            networks."the-ssid".psk = "the-password";
            interfaces = [ "wlan0" ];
          };
          interfaces."wlan0".useDHCP = true;
        };

        # needed for deploy-rs
        # boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

        # good luck
        # needed for the stlink to work
        # boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_rpi2;

      });

      deploy.nodes.torgcam1 = {
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos
            nixosConfigurations.torgcam1;
        };

        # this is how it ssh's into the target system to send packages/configs over.
        sshUser = "root";
        hostname = "torgcam1";
      };

    };
}
