{
  config,
  lib,
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [
    qemu
    # share files out of qemu, see overlay.nix
    samba
    tigervnc
  ];
}
