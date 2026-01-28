{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./podman.nix
    ./freshrss.nix
  ];
}
