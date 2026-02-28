{
  description = "torgnix flake";

  # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#examples
  #   nix flake update nix-gaming
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-locked.url = "github:NixOS/nixpkgs/1042fd8b148a9105f3c0aca3a6177fd1d9360ba5";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    nix-gaming.url = "github:torgeir/nix-gaming";
    # nix-gaming.url = "github:fufexan/nix-gaming";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs-stable";

    wooz.url = "github:negrel/wooz";
    wooz.inputs.nixpkgs.follows = "nixpkgs";

    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nix flake update dotfiles nix-home-manager
    nix-home-manager.url = "github:torgeir/nix-home-manager";
    dotfiles.url = "github:torgeir/dotfiles";

    m3ta-nixpkgs.url = "git+https://code.m3ta.dev/m3tam3re/nixpkgs";
    m3ta-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/develop";
    nixos-raspberrypi.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      agenix,
      deploy-rs,
      home-manager,
      wooz,
      musnix,
      nix-gaming,
      nixpkgs,
      # nixpkgs-locked,
      nixpkgs-stable,
      nix-home-manager,
      dotfiles,
      m3ta-nixpkgs,
      nixos-raspberrypi,
    }:
    rec {

      # https://github.com/sebastiant/dotfiles/blob/master/flake.nix
      # https://github.com/wiltaylor/dotfiles
      # nixos-rebuild switch --flake .#torgnix
      nixosConfigurations.torgnix = nixpkgs.lib.nixosSystem {
        # pass inputs to configuration.nix
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/torgnix ];
      };

      # nixos-rebuild switch --flake .#tank --target-host tank --use-remote-sudo --ask-sudo-password
      nixosConfigurations.tank = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/tank ];
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

      #nixosConfigurations.rpi5 = nixos-raspberrypi.lib.nixosSystemFull {
      #  specialArgs = { inherit inputs nixos-raspberrypi; };
      #  modules = [
      #    ./hosts/pi5
      #  ];
      #};

      # nix build .#nixosConfigurations.rpi5.config.system.build.sdImage

      # build it with
      #   nix build .#images.torgcam1 .#images.torgcam2
      # burn it with
      #   watch -n1 lsblk
      #   sudo dd if=results/sd-image/torgcam1.img of=/dev/sdb bs=4M status=progress oflag=direct
      images.torgcam1 = nixosConfigurations.torgcam1.config.system.build.sdImage;
      images.torgcam2 = nixosConfigurations.torgcam2.config.system.build.sdImage;
      # build it with
      #   nix build .#images.torgpi4
      # burn it with
      #   watch -n1 lsblk
      #   sudo dd if=/home/torgeir/nixos-config/result/sd-image/torgpi4.img of=/dev/sdb bs=1M status=progress
      images.torgpi4 = nixosConfigurations.torgpi4.config.system.build.sdImage;

      deploy.nodes.torgcam1 = {
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.torgcam1;
        };

        # this is how it ssh's into the target system to send packages/configs over.
        sshUser = "torgeir";
        hostname = "torgcam1";
      };

      deploy.nodes.torgcam2 = {
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.torgcam2;
        };

        # this is how it ssh's into the target system to send packages/configs over.
        sshUser = "torgeir";
        hostname = "torgcam2";
      };
    };
}
