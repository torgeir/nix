{
  description = "torgnix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    nix-gaming.url = "github:torgeir/nix-gaming";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, home-manager
    , nixpkgs-wayland, musnix, nix-gaming, sops-nix, deploy-rs }: rec {

      # https://github.com/sebastiant/dotfiles/blob/master/flake.nix
      # https://github.com/wiltaylor/dotfiles
      nixosConfigurations.torgnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # pass inputs to configuration.nix
        specialArgs = { inherit inputs; };

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

      # or pkgs.callPackage?
      nixosConfigurations.torgcam1 = import ./modules/torgcam.nix {
        inherit nixpkgs;
        name = "torgcam1";
      };
      nixosConfigurations.torgcam2 = import ./modules/torgcam.nix {
        inherit nixpkgs;
        name = "torgcam2";
      };

      # build it with
      #   nix build .#images.torgcam1 .#images.torgcam2
      # burn it with
      #   sudo dd if=results/sd-image/torgcam1.img of=/dev/sdb bs=4M status=progress oflag=direct
      images.torgcam1 =
        nixosConfigurations.torgcam1.config.system.build.sdImage;
      images.torgcam2 =
        nixosConfigurations.torgcam2.config.system.build.sdImage;

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
