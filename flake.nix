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
        # pass inputs to configuration.nix
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/common
          ./hosts/common/torgeir.nix
          # ./modules/openrgb.nix
          #https://github.com/Mic92/sops-nix
          sops-nix.nixosModules.sops
        ];
      };

      # nixos-rebuild switch --flake .#tank --target-host tank --use-remote-sudo --ask-sudo-password
      nixosConfigurations.tank = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/tank
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
