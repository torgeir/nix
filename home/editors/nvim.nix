{ config, lib, pkgs, ... }:

{

  # https://github.com/stefanDeveloper/nixos-lenovo-config/blob/master/modules/apps/editor/vim.nix
  programs.neovim = {
    enable = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

}
