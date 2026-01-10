{ config, lib, pkgs, ... }:

{
  imports = [
    ./torgeir.nix
  ];

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
