{
  description = "torgnix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    home-manager,
    nixpkgs-wayland
  }: {
    nixosConfigurations = {

      torgnix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [

          # os config
          ./configuration.nix

          home-manager.nixosModules.home-manager {

            # globally installed packages should be user available
            home-manager.useGlobalPkgs = true;

            # users can install packages without admin privileges
            home-manager.useUserPackages = false;

            # pass inputs to imported modules for users
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.torgeir = import ./modules/home;
          }
        ];
      };
    };
  };
}
