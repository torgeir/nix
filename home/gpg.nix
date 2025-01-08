{ config, lib, inputs, pkgs, ... }:

{

  #https://github.com/tejing1/nixos-config/blob/master/homeConfigurations/tejing/encryption.nix
  # https://freerangebits.com/posts/2023/12/gnupg-broke-emacs/
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg24;
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
      pinentry-program ${pkgs.pinentry-qt}/bin/pinentry-qt
    '';
  };
}
