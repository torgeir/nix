{
  description = "torgnix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixpkgs-wayland, sops-nix }: {
    nixosConfigurations = {

      torgnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [

          # os config
          ./configuration.nix

          #https://github.com/Mic92/sops-nix
          #
          # cat <<EOF > .sops.yml
          # keys:
          #   - &torgeir 922E681804CA8D82F1FAFCB177836712DAEA8B95
          # creation_rules:
          #   - path_regex: .*
          #     key_groups:
          #     - pgp:
          #         - *torgeir
          # EOF
          #
          # nix-shell -p sops --run "sops secrets.yaml"
          #
          # sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
          {

            # globally installed packages should be user available
            home-manager.useGlobalPkgs = true;

            # user packages can be installed without admin privileges
            home-manager.useUserPackages = true;

            # pass inputs to imported modules for users
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.torgeir = import ./modules/home;
          }
        ];
      };
    };
  };
}
