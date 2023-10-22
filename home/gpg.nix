{ config, lib, pkgs, ... }:

{

  #https://github.com/tejing1/nixos-config/blob/master/homeConfigurations/tejing/encryption.nix
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg22;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    maxCacheTtl = 28800;
    defaultCacheTtl = 28800;
    maxCacheTtlSsh = 28800;
    defaultCacheTtlSsh = 28800;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };

}
