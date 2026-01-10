{ config, lib, pkgs, ... }:

{
  imports = [
    ./configuration.nix
    ../common
  ];
}
