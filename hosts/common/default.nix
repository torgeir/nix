{ config, lib, inputs, pkgs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

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

  nix = {

    package = pkgs.nixVersions.stable;

    # enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # clean up every once in a while
    #   sudo nix-collect-garbage
    #   sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 21d";
    };

    settings = {
      auto-optimise-store = true;
      trusted-users = ["root" "torgeir"];
    };
  };

  # locale
  i18n.defaultLocale = "en_US.UTF-8";

  # timezone
  time.timeZone = "Europe/Oslo";
}
