{
  config,
  lib,
  pkgs,
  ...
}:

{

  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/security/pam.nix#L163
  security.pam.u2f = {
    enable = true;
    # don't require both pw and biometrics
    control = "sufficient";
    # send que when to biometric touch
    settings.cue = true;
    # debug to stdout
    #debug = true;
    #interactive = true;
  };

  # support yubikey for sudo and login
  security.pam.services.torgeir.u2fAuth = true;
}
