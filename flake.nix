{
  description = "torgnix flake";

  # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples
  #   nix flake update nix-gaming
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-locked.url =
      "github:NixOS/nixpkgs/1042fd8b148a9105f3c0aca3a6177fd1d9360ba5";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    nix-gaming.url = "github:torgeir/nix-gaming";
    # nix-gaming.url = "github:fufexan/nix-gaming";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs-stable";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nix flake update nix-home-manager
    nix-home-manager.url = "github:torgeir/nix-home-manager";
    # nix flake update dotfiles
    dotfiles.url = "github:torgeir/dotfiles";
  };

  outputs = inputs@{ self, deploy-rs, home-manager, musnix, nix-gaming, nixpkgs
    , nixpkgs-locked, nixpkgs-stable, sops-nix
    , nix-home-manager, dotfiles }: rec {

      # https://github.com/sebastiant/dotfiles/blob/master/flake.nix
      # https://github.com/wiltaylor/dotfiles
      nixosConfigurations.torgnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # pass inputs to configuration.nix
        specialArgs = { inherit inputs; };

        modules = [

          # os config
          ./configuration.nix

          # ./modules/openrgb.nix

          #https://github.com/Mic92/sops-nix
          sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
          {

            # globally installed packages should be user available
            home-manager.useGlobalPkgs = true;

            # user packages can be installed without admin privileges
            home-manager.useUserPackages = true;

            # pass inputs to imported modules for users
            home-manager.extraSpecialArgs = {
              inherit inputs;

              # https://github.com/torgeir/nix-home-manager/tree/main/modules/ .nix files need dotfiles parameter
              dotfiles = inputs.dotfiles;

              # hack around infinite recursion with pkgs.stdenv.isLinux in nix-home-manager modules
              isLinux = true;
            };
            home-manager.users.torgeir = import ./home;
          }
        ];
      };

      # or pkgs.callPackage?
      nixosConfigurations.torgcam1 = import ./modules/torgcam.nix {
        inherit nixpkgs;
        name = "torgcam1";
      };
      nixosConfigurations.torgcam2 = import ./modules/torgcam.nix {
        inherit nixpkgs;
        name = "torgcam2";
      };

      nixosConfigurations.torgpi4 = import ./modules/torgpi4.nix {
        nixpkgs = nixpkgs-stable;
        inherit inputs;
        name = "torgpi4";
      };

      # build it with
      #   nix build .#images.torgcam1 .#images.torgcam2
      # burn it with
      #   watch -n1 lsblk
      #   sudo dd if=results/sd-image/torgcam1.img of=/dev/sdb bs=4M status=progress oflag=direct
      images.torgcam1 =
        nixosConfigurations.torgcam1.config.system.build.sdImage;
      images.torgcam2 =
        nixosConfigurations.torgcam2.config.system.build.sdImage;
      # build it with
      #   nix build .#images.torgpi4
      # burn it with
      #   watch -n1 lsblk
      #   sudo dd if=/home/torgeir/nixos-config/result/sd-image/torgpi4.img of=/dev/sdb bs=1M status=progress
      images.torgpi4 =
        nixosConfigurations.torgpi4.config.system.build.sdImage;

      deploy.nodes.torgcam1 = {
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            nixosConfigurations.torgcam1;
        };

        # this is how it ssh's into the target system to send packages/configs over.
        sshUser = "torgeir";
        hostname = "torgcam1";
      };

      deploy.nodes.torgcam2 = {
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            nixosConfigurations.torgcam2;
        };

        # this is how it ssh's into the target system to send packages/configs over.
        sshUser = "torgeir";
        hostname = "torgcam2";
      };
    };
}
