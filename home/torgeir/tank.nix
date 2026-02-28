{
  config,
  lib,
  inputs,
  dotfiles,
  pkgs,
  ...
}:

{

  imports = [
    (inputs.nix-home-manager + "/modules")
  ];

  programs.t-git.enable = true;
  programs.t-nvim.enable = true;
  programs.t-shell-tooling.enable = true;
  programs.t-zoxide.enable = true;
  programs.t-tmux.enable = true;

  home.file.".config/dotfiles".source = dotfiles;

  home.stateVersion = "23.11";

}
