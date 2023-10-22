{ config, lib, pkgs, ... }:

{
  imports = [ ./emacs.nix ./nvim.nix ];
}
